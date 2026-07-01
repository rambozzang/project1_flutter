import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/app/camera/page/photo_reg_page.dart';
import 'package:project1/app/camera/page/video_reg_page.dart';

class CameraAwesomePage extends StatefulWidget {
  const CameraAwesomePage({super.key});

  @override
  State<CameraAwesomePage> createState() => _CameraAwesomePageState();
}

class _CameraAwesomePageState extends State<CameraAwesomePage> {
  bool _navigated = false;
  final List<File> _photos = [];

  /// Camera brightness correction (0.0 ~ 1.0). 0.5 is the neutral value
  /// and can be used to compensate the auto exposure.
  double _brightness = 0.5;

  // ── 핀치(손가락) 줌: 비례식으로 세밀하고 빠르게 ──
  // camerawesome 기본 핀치는 고정스텝 래칫이라 느려서, 직접 GestureDetector로 처리한다.
  CameraState? _cameraState; // setZoom 호출용 (빌더에서 캡처)
  StreamSubscription<double>? _zoomSub; // 현재 줌값 추적(핀 버튼/핀치 공통)
  double _lastZoom = 0.0; // 최신 줌(0~1)
  double _pinchBaseZoom = 0.0; // 핀치 시작 시점의 줌
  static const double _zoomSensitivity = 1.6; // 핀치: 클수록 빠르게 줌

  // 한 손가락 드래그: 좌우=줌, 상하=밝기 (화면 아무데나 드래그)
  static const double _dragZoomFactor = 0.006; // px당 줌 변화
  static const double _dragBrightFactor = 0.005; // px당 밝기 변화

  void _captureState(CameraState state) {
    if (identical(_cameraState, state)) return;
    _cameraState = state;
    _zoomSub?.cancel();
    _zoomSub = state.sensorConfig.zoom$.listen((z) => _lastZoom = z);
  }

  void _onScaleStart() {
    _pinchBaseZoom = _lastZoom;
  }

  // 화면 드래그/핀치 → 줌·밝기 조절
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_cameraState == null) return;
    if (details.pointerCount >= 2) {
      // 두 손가락 핀치 → 줌
      final double z = (_pinchBaseZoom + (details.scale - 1.0) * _zoomSensitivity).clamp(0.0, 1.0);
      _lastZoom = z;
      _cameraState!.sensorConfig.setZoom(z);
    } else {
      // 한 손가락 드래그 → 좌우:줌 / 상하:밝기
      final double dx = details.focalPointDelta.dx;
      final double dy = details.focalPointDelta.dy;
      if (dx.abs() > 0.01) {
        _lastZoom = (_lastZoom + dx * _dragZoomFactor).clamp(0.0, 1.0);
        _cameraState!.sensorConfig.setZoom(_lastZoom);
      }
      if (dy.abs() > 0.01) {
        // 위로 드래그(dy<0) = 더 밝게
        _brightness = (_brightness - dy * _dragBrightFactor).clamp(0.0, 1.0);
        _cameraState!.sensorConfig.setBrightness(_brightness);
      }
    }
  }

  @override
  void dispose() {
    _zoomSub?.cancel();
    super.dispose();
  }

  void _onMediaCaptureEvent(MediaCapture? mediaCapture) {
    if (mediaCapture == null) return;
    if (mediaCapture.status != MediaCaptureStatus.success) return;
    if (_navigated) return;

    final path = mediaCapture.captureRequest.path;
    if (path == null) return;

    final file = File(path);

    if (mediaCapture.isVideo) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoRegPage(videoFile: file),
          ),
        );
      });
    } else if (mediaCapture.isPicture) {
      // 사진 모드: 즉시 이동하지 않고 목록에 누적
      setState(() {
        _photos.add(file);
      });
    }
  }

  void _goToPhotoRegPage() {
    if (_photos.isEmpty) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PhotoRegPage(photoFiles: List.from(_photos)),
      ),
    );
  }

  Future<void> _openGallery(CameraState state) async {
    final isPhoto = state is PhotoCameraState;
    if (isPhoto) {
      final List<XFile> picked = await ImagePicker().pickMultiImage();
      if (picked.isNotEmpty && mounted) {
        setState(() {
          _photos.addAll(picked.map((e) => File(e.path)));
        });
        _goToPhotoRegPage();
      }
    } else {
      final XFile? picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoRegPage(videoFile: File(picked.path)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraAwesomeBuilder.awesome(
            sensorConfig: SensorConfig.single(
              sensor: Sensor.position(SensorPosition.back),
              aspectRatio: CameraAspectRatios.ratio_16_9,
            ),
            saveConfig: SaveConfig.photoAndVideo(
              initialCaptureMode: CaptureMode.video,
            ),
            previewFit: CameraPreviewFit.cover,
            onPreviewTapBuilder: (state) => OnPreviewTap(
              onTap: (position, flutterPreviewSize, pixelPreviewSize) {
                state.when(
                  onPreparingCamera: (_) {},
                  onPhotoMode: (photoState) => photoState.focusOnPoint(
                    flutterPosition: position,
                    flutterPreviewSize: flutterPreviewSize,
                    pixelPreviewSize: pixelPreviewSize,
                  ),
                  onVideoMode: (videoState) => videoState.focusOnPoint(
                    flutterPosition: position,
                    flutterPreviewSize: flutterPreviewSize,
                    pixelPreviewSize: pixelPreviewSize,
                  ),
                  onVideoRecordingMode: (recordingState) => recordingState.focusOnPoint(
                    flutterPosition: position,
                    flutterPreviewSize: flutterPreviewSize,
                    pixelPreviewSize: pixelPreviewSize,
                  ),
                );
              },
            ),
            onMediaCaptureEvent: _onMediaCaptureEvent,
            topActionsBuilder: (state) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AwesomeCircleButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                  // 사진 모드에서 촬영한 사진이 있으면 "다음" 버튼
                  if (_photos.isNotEmpty)
                    GestureDetector(
                      onTap: _goToPhotoRegPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C8DFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '다음 (${_photos.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            bottomActionsBuilder: (state) {
              _captureState(state); // 핀치줌 setZoom용 상태 캡처 + 줌값 추적
              return CamerAwesomeBottomActions(
                state: state,
                brightness: _brightness,
                onBrightnessChanged: (value) {
                  setState(() {
                    _brightness = value;
                  });
                  state.sensorConfig.setBrightness(value);
                },
                onGalleryTap: _openGallery,
                photos: _photos,
                onRemovePhoto: (index) {
                  setState(() {
                    _photos.removeAt(index);
                  });
                },
              );
            },
            // 기본 middleContent(camerawesome 기본 PHOTO/VIDEO 모드 선택기 + 필터)를 제거한다.
            // → 하단 커스텀 '사진/영상' 토글과 중복되던 것을 없앰.
            middleContentBuilder: (state) => const SizedBox.shrink(),
            theme: AwesomeTheme(
              bottomActionsBackgroundColor: Colors.transparent,
            ),
          ),
          // 화면 드래그 오버레이(맨 위): 한 손가락 좌우=줌·상하=밝기, 두 손가락=핀치줌.
          // 부모 래핑 대신 최상위 오버레이로 둬야 camerawesome 내부 제스처에 안 먹힘.
          // translucent라 버튼 탭은 아래로 통과(탭>스케일), 드래그/핀치만 여기서 처리.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: (_) => _onScaleStart(),
              onScaleUpdate: _onScaleUpdate,
            ),
          ),
        ],
      ),
    );
  }
}

/// CamerAwesome Bottom actions
class CamerAwesomeBottomActions extends StatefulWidget {
  final CameraState state;
  final double brightness;
  final ValueChanged<double> onBrightnessChanged;
  final Function(CameraState) onGalleryTap;
  final List<File> photos;
  final Function(int) onRemovePhoto;

  const CamerAwesomeBottomActions({
    super.key,
    required this.state,
    required this.brightness,
    required this.onBrightnessChanged,
    required this.onGalleryTap,
    required this.photos,
    required this.onRemovePhoto,
  });

  @override
  State<CamerAwesomeBottomActions> createState() => _CamerAwesomeBottomActionsState();
}

class _CamerAwesomeBottomActionsState extends State<CamerAwesomeBottomActions> {
  Timer? _timer;
  int _seconds = 0;

  // 렌즈(센서) 정보 — 초광각(0.5x) 지원 감지 및 전환용.
  SensorDeviceData? _sensors;
  SensorType _currentLens = SensorType.wideAngle;


  bool get _hasUltraWide => _sensors?.ultraWideAngle != null;
  bool get _onUltraWide => _currentLens == SensorType.ultraWideAngle;

  @override
  void initState() {
    super.initState();
    _checkRecordingState();
    _loadSensors();
  }

  // 기기의 후면 렌즈 목록을 조회해 초광각 지원 여부를 감지한다.
  // 카메라 준비 전엔 빈 결과가 올 수 있어, 유효한 값(availableBackSensors>0)일 때만 채택하고
  // 그전까진 상태 갱신마다 재시도(didUpdateWidget)한다.
  void _loadSensors() {
    try {
      widget.state.getSensors().then((data) {
        if (!mounted) return;
        // 진단: 이 기기가 어떤 후면 렌즈를 보고하는지 (초광각 미노출 원인 파악용)
        debugPrint('[CAM] backSensors=${data.availableBackSensors} '
            'ultraWide=${data.ultraWideAngle != null} wide=${data.wideAngle != null} tele=${data.telephoto != null}');
        if (data.availableBackSensors > 0) {
          setState(() => _sensors = data);
        }
      }).catchError((e) => debugPrint('[CAM] getSensors error: $e'));
    } catch (e) {
      debugPrint('[CAM] getSensors throw: $e');
    }
  }

  // 광각 ↔ 초광각 물리 렌즈 전환. (디지털 줌과 별개)
  void _switchLens(SensorType type) {
    final details = type == SensorType.ultraWideAngle ? _sensors?.ultraWideAngle : _sensors?.wideAngle;
    if (details == null) return;
    try {
      widget.state.setSensorType(0, type, details.uid);
      if (mounted) setState(() => _currentLens = type);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant CamerAwesomeBottomActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkRecordingState();
    // 카메라가 준비되면(상태 갱신) 초광각 렌즈 재감지.
    if (_sensors == null) _loadSensors();
  }

  void _checkRecordingState() {
    final isRecording = widget.state is VideoRecordingCameraState;
    if (isRecording) {
      if (_timer == null) {
        _seconds = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _seconds++;
            });
          }
        });
      }
    } else {
      _timer?.cancel();
      _timer = null;
      _seconds = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  FlashMode _getNextFlashMode(FlashMode current) {
    switch (current) {
      case FlashMode.none:
        return FlashMode.on;
      case FlashMode.on:
        return FlashMode.auto;
      case FlashMode.auto:
        return FlashMode.always;
      case FlashMode.always:
        return FlashMode.none;
    }
  }

  CameraAspectRatios _getNextRatio(CameraAspectRatios current) {
    switch (current) {
      case CameraAspectRatios.ratio_4_3:
        return CameraAspectRatios.ratio_16_9;
      case CameraAspectRatios.ratio_16_9:
        return CameraAspectRatios.ratio_1_1;
      case CameraAspectRatios.ratio_1_1:
        return CameraAspectRatios.ratio_4_3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.state is VideoRecordingCameraState;

    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      decoration: BoxDecoration(
        // 하단 스크림: 컨트롤 가독성용 최소한의 그라데이션(과한 검정 제거).
        // 상단 절반 이상은 완전 투명 → 카메라 화면이 어둡게 안 보이게, 맨 아래만 옅게.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.40),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 사진 썸네일 스트립 (촬영한 사진이 있을 때만)
            if (widget.photos.isNotEmpty && !isRecording) ...[
              _buildPhotoStrip(),
              const SizedBox(height: 12),
            ],
            // 밝기/줌은 화면 드래그로 조절(상하=밝기, 좌우=줌) → 별도 UI 없음
            if (!isRecording) ...[
              _buildQuickSettings(widget.state),
              const SizedBox(height: 16),
            ],
            if (!isRecording) ...[
              _buildModeToggle(widget.state),
              const SizedBox(height: 16),
            ],
            _buildMainCaptureRow(widget.state),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoStrip() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    widget.photos[index],
                    width: 44,
                    height: 52,
                    fit: BoxFit.cover,
                    cacheWidth: 88,
                    cacheHeight: 104,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => widget.onRemovePhoto(index),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickSettings(CameraState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<FlashMode>(
            stream: state.sensorConfig.flashMode$,
            builder: (context, snapshot) {
              final flashMode = snapshot.data ?? FlashMode.none;
              IconData icon;
              String label;
              switch (flashMode) {
                case FlashMode.none:
                  icon = Icons.flash_off_rounded;
                  label = '꺼짐';
                  break;
                case FlashMode.on:
                  icon = Icons.flash_on_rounded;
                  label = '켜짐';
                  break;
                case FlashMode.auto:
                  icon = Icons.flash_auto_rounded;
                  label = '자동';
                  break;
                case FlashMode.always:
                  icon = Icons.flashlight_on_rounded;
                  label = '손전등';
                  break;
              }
              return _buildQuickActionButton(
                icon: icon,
                label: label,
                onTap: () {
                  final nextMode = _getNextFlashMode(flashMode);
                  state.sensorConfig.setFlashMode(nextMode);
                },
              );
            },
          ),
          Container(
            height: 16,
            width: 1,
            color: Colors.white.withOpacity(0.2),
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),
          StreamBuilder<CameraAspectRatios>(
            stream: state.sensorConfig.aspectRatio$,
            builder: (context, snapshot) {
              final ratio = snapshot.data ?? CameraAspectRatios.ratio_16_9;
              String label;
              switch (ratio) {
                case CameraAspectRatios.ratio_4_3:
                  label = '4:3';
                  break;
                case CameraAspectRatios.ratio_16_9:
                  label = '16:9';
                  break;
                case CameraAspectRatios.ratio_1_1:
                  label = '1:1';
                  break;
              }
              return _buildQuickActionButton(
                icon: Icons.aspect_ratio_rounded,
                label: label,
                onTap: () {
                  final nextRatio = _getNextRatio(ratio);
                  state.sensorConfig.setAspectRatio(nextRatio);
                },
              );
            },
          ),
          Container(
            height: 16,
            width: 1,
            color: Colors.white.withOpacity(0.2),
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),
          StreamBuilder<double>(
            stream: state.sensorConfig.zoom$,
            builder: (context, snapshot) {
              final zoom = snapshot.data ?? 0.0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 초광각(0.5x) — 기기에 초광각 렌즈가 있을 때만 노출
                  if (_hasUltraWide) ...[
                    _buildUltraWidePill(),
                    const SizedBox(width: 6),
                  ],
                  _buildZoomPill(state, '1x', 0.0, zoom),
                  const SizedBox(width: 6),
                  _buildZoomPill(state, '2x', 0.3, zoom),
                  const SizedBox(width: 6),
                  _buildZoomPill(state, '5x', 0.6, zoom),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomPill(CameraState state, String label, double value, double currentValue) {
    // 초광각(0.5x)에 있을 땐 디지털 줌 핀은 비활성 표시.
    final bool isActive = !_onUltraWide && (currentValue - value).abs() < 0.15;
    return GestureDetector(
      onTap: () {
        // 초광각 상태에서 1x/2x/5x를 누르면 먼저 광각 렌즈로 복귀 후 줌 적용.
        if (_onUltraWide) _switchLens(SensorType.wideAngle);
        state.sensorConfig.setZoom(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: isActive ? null : Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 초광각(0.5x) 렌즈 전환 핀
  Widget _buildUltraWidePill() {
    final bool isActive = _onUltraWide;
    return GestureDetector(
      onTap: () => _switchLens(SensorType.ultraWideAngle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(15),
          border: isActive ? null : Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Text(
          '0.5x',
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(CameraState state) {
    final bool currentIsPhoto = state.when(
          onPreparingCamera: (_) => false,
          onPhotoMode: (_) => true,
          onVideoMode: (_) => false,
          onVideoRecordingMode: (_) => false,
        ) ??
        false;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeChip(state, '사진', currentIsPhoto, CaptureMode.photo),
          _buildModeChip(state, '영상', !currentIsPhoto, CaptureMode.video),
        ],
      ),
    );
  }

  Widget _buildModeChip(CameraState state, String label, bool isSelected, CaptureMode mode) {
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        state.setState(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMainCaptureRow(CameraState state) {
    final isRecording = state is VideoRecordingCameraState;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isRecording
              ? const SizedBox(width: 52)
              : _buildGalleryButton(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRecording) ...[
                _buildRecordingTimer(),
                const SizedBox(height: 12),
              ],
              _buildShutterButton(state),
            ],
          ),
          isRecording
              ? const SizedBox(width: 52)
              : _buildCameraSwitchButton(state),
        ],
      ),
    );
  }

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: () => widget.onGalleryTap(widget.state),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.4),
        ),
        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCameraSwitchButton(CameraState state) {
    return GestureDetector(
      onTap: () async {
        await state.switchCameraSensor();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.4),
        ),
        child: const Icon(Icons.cached_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildRecordingTimer() {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingDot(),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShutterButton(CameraState state) {
    return state.when(
      onPreparingCamera: (_) => const SizedBox(
        width: 76,
        height: 76,
        child: CircularProgressIndicator(color: Colors.white),
      ),
      onPhotoMode: (photoState) => GestureDetector(
        onTap: () async {
          await photoState.takePhoto();
        },
        child: _shutterButtonDecoration(
          innerColor: Colors.white,
          isRecording: false,
        ),
      ),
      onVideoMode: (videoState) => GestureDetector(
        onTap: () async {
          await videoState.startRecording();
        },
        child: _shutterButtonDecoration(
          innerColor: Colors.redAccent,
          isRecording: false,
        ),
      ),
      onVideoRecordingMode: (recordingState) => GestureDetector(
        onTap: () async {
          await recordingState.stopRecording();
        },
        child: _shutterButtonDecoration(
          innerColor: Colors.redAccent,
          isRecording: true,
        ),
      ),
    );
  }

  Widget _shutterButtonDecoration({required Color innerColor, required bool isRecording}) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4.5),
      ),
      padding: const EdgeInsets.all(5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: innerColor,
          borderRadius: BorderRadius.circular(isRecording ? 8 : 40),
        ),
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class AwesomeCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const AwesomeCircleButton({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
        ),
        child: child,
      ),
    );
  }
}
