import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/app/camera/page/photo_reg_page.dart';
import 'package:project1/app/camera/page/video_reg_page.dart';

/// 카메라 권한 화면 상태.
enum _CamPermState { checking, granted, denied, permanentlyDenied }

class CameraAwesomePage extends StatefulWidget {
  const CameraAwesomePage({super.key});

  @override
  State<CameraAwesomePage> createState() => _CameraAwesomePageState();
}

class _CameraAwesomePageState extends State<CameraAwesomePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _navigated = false;
  final List<File> _photos = [];

  // ── 카메라 권한 게이트 ──
  // Apple 심사 가이드라인 5.1.1: 권한 거부("허용 안 함") 시 앱이 자동으로
  // 설정 앱으로 리다이렉트해서는 안 됨. 사용자가 명시적으로 탭해야만 이동한다.
  _CamPermState _permState = _CamPermState.checking;

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

  // 축 잠금: 제스처 초반 이만큼 움직인 뒤 우세 축을 정하고 그 축만 적용
  // (좌우 스와이프인데 밝기가 같이 바뀌던 문제 방지 — 느슨하게 판단)
  int _panAxis = 0; // 0=미결정, 1=좌우(줌), 2=상하(밝기)
  double _panAccumDx = 0.0, _panAccumDy = 0.0;
  static const double _axisLockThreshold = 16.0;

  void _captureState(CameraState state) {
    if (identical(_cameraState, state)) return;
    _cameraState = state;
    _zoomSub?.cancel();
    _zoomSub = state.sensorConfig.zoom$.listen((z) => _lastZoom = z);
  }

  void _onScaleStart() {
    _pinchBaseZoom = _lastZoom;
    // 축 잠금 초기화
    _panAxis = 0;
    _panAccumDx = 0.0;
    _panAccumDy = 0.0;
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
      // 한 손가락 드래그 → 우세 축 하나만 적용(좌우:줌 / 상하:밝기)
      final double dx = details.focalPointDelta.dx;
      final double dy = details.focalPointDelta.dy;

      // 아직 축 미결정: 누적 이동이 임계 넘으면 큰 쪽으로 잠금
      if (_panAxis == 0) {
        _panAccumDx += dx;
        _panAccumDy += dy;
        if (_panAccumDx.abs() < _axisLockThreshold && _panAccumDy.abs() < _axisLockThreshold) {
          return; // 아직 방향 판단 전 → 아무것도 안 함
        }
        _panAxis = _panAccumDx.abs() >= _panAccumDy.abs() ? 1 : 2;
      }

      if (_panAxis == 1) {
        // 좌우 → 줌만
        _lastZoom = (_lastZoom + dx * _dragZoomFactor).clamp(0.0, 1.0);
        _cameraState!.sensorConfig.setZoom(_lastZoom);
      } else {
        // 상하 → 밝기만. 위로 드래그(dy<0) = 더 밝게.
        // sensorConfig.setBrightness는 500ms 디바운스라 setCorrection을 직접 호출해 즉시 반영.
        _brightness = (_brightness - dy * _dragBrightFactor).clamp(0.0, 1.0);
        CamerawesomePlugin.setBrightness(_brightness);
        // 밝기 게이지 표시 → 마지막 조작 900ms 후 자동 숨김
        _brightnessVN.value = _brightness;
        _gaugeVN.value = true;
        _gaugeHideTimer?.cancel();
        _gaugeHideTimer = Timer(const Duration(milliseconds: 900), () {
          if (mounted) _gaugeVN.value = false;
        });
      }
    }
  }

  // 카메라 초기화 시 조작 안내(↕밝기·↔줌)를 잠깐 띄웠다 사라지게 한다.
  bool _showGestureHint = false;
  Timer? _hintTimer;
  // 힌트 캡슐 내부의 손가락(점)이 왕복 스와이프하는 애니메이션(0↔1 반복).
  late final AnimationController _swipeCtrl;
  late final Animation<double> _swipeAnim;

  // 밝기 게이지: 상하 드래그로 밝기 조절 중에만 잠깐 표시.
  final ValueNotifier<double> _brightnessVN = ValueNotifier<double>(0.5);
  final ValueNotifier<bool> _gaugeVN = ValueNotifier<bool>(false);
  Timer? _gaugeHideTimer;

  // 제스처 힌트는 앱 실행당 1번만 노출한다(카메라 재진입 시 생략).
  static bool _gestureHintShownThisRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
    // 손가락 왕복 스와이프 애니메이션(0→1→0 반복, 부드럽게) — 힌트 노출 중에만 구동.
    _swipeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
    _swipeAnim = CurvedAnimation(parent: _swipeCtrl, curve: Curves.easeInOut);
    // 다음 프레임에 페이드인 → 3.4초 후 페이드아웃(스와이프 왕복이 몇 번 보이도록)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _gestureHintShownThisRun) return;
      _gestureHintShownThisRun = true;
      _swipeCtrl.repeat(reverse: true);
      setState(() => _showGestureHint = true);
      _hintTimer = Timer(const Duration(milliseconds: 3400), () {
        if (!mounted) return;
        setState(() => _showGestureHint = false);
        _swipeCtrl.stop();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _gaugeHideTimer?.cancel();
    _swipeCtrl.dispose();
    _brightnessVN.dispose();
    _gaugeVN.dispose();
    _zoomSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 설정 앱에서 권한을 바꾸고 돌아왔을 때 자동으로 다시 확인(사용자가 직접 재요청할 필요 없게).
    if (state == AppLifecycleState.resumed && _permState != _CamPermState.granted) {
      _checkCameraPermission();
    }
  }

  // 카메라 권한 상태만 확인한다(마이크는 녹화 버튼을 누를 때 camerawesome이 자체 요청).
  // 이미 결정된 상태(허용/거부)는 조용히 조회만 하고, 아직 결정 전(notDetermined)일 때만
  // 시스템 권한 다이얼로그를 1회 띄운다 — 화면 진입만으로 반복 요청하지 않기 위함.
  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    setState(() {
      _permState = status.isGranted
          ? _CamPermState.granted
          : status.isPermanentlyDenied
              ? _CamPermState.permanentlyDenied
              : _CamPermState.denied;
    });
  }

  // 카메라 접근 안내 화면 — "허용 안 함" 후에도 절대 자동으로 설정 앱을 열지 않는다.
  // 사용자가 버튼을 직접 탭해야만(명시적 동작) 재요청하거나 설정으로 이동한다.
  Widget _buildPermissionGate() {
    final bool permanentlyDenied = _permState == _CamPermState.permanentlyDenied;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: _topGlassButton(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_rounded, color: Colors.white54, size: 56),
                    const SizedBox(height: 20),
                    const Text(
                      '카메라 접근 권한이 필요합니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      permanentlyDenied
                          ? '사진·영상 촬영을 위해 카메라 접근이 필요해요.\n설정에서 카메라 권한을 허용해주세요.'
                          : '사진과 영상을 촬영하려면 카메라 접근을\n허용해주세요.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: permanentlyDenied ? openAppSettings : _checkCameraPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C8DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        permanentlyDenied ? '설정에서 허용하기' : '카메라 권한 허용',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  // ── 상단 바 버튼(글래스 스타일 통일) ──────────────────────

  Widget _topGlassButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permState == _CamPermState.checking) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }
    if (_permState != _CamPermState.granted) {
      return _buildPermissionGate();
    }
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
                children: [
                  _topGlassButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  // 사진 모드에서 촬영한 사진이 있으면 "다음" 버튼
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _goToPhotoRegPage,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
          // 밝기 게이지: 상하 드래그 중에만 좌측 중앙에 표시 후 자동 사라짐
          Positioned(
            left: 22,
            top: 0,
            bottom: 0,
            child: Center(
              child: IgnorePointer(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _gaugeVN,
                  builder: (context, visible, _) {
                    return AnimatedOpacity(
                      opacity: visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: _glassPill(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD54F), size: 18),
                            const SizedBox(height: 10),
                            Container(
                              width: 6,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: ValueListenableBuilder<double>(
                                valueListenable: _brightnessVN,
                                builder: (context, b, __) {
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      heightFactor: b.clamp(0.02, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [Color(0xFFFF9A3C), Color(0xFFFFD54F), Colors.white],
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                          boxShadow: [BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.5), blurRadius: 6)],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // 초기화 시 조작 안내(앱 실행당 1회): 상하(밝기)=우측 측면, 좌우(줌)=중앙.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showGestureHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
                child: Stack(
                  children: [
                    Center(child: _buildZoomHint()),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: _buildBrightnessHint(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 제스처 안내 (좌우=줌 / 상하=밝기) — 프로스티드 글래스 + 코멧 인디케이터 ──

  // 반투명 유리 알약(블러 + 은은한 흰 테두리). 검정 불투명 캡슐 대비 훨씬 가볍고 고급스럽다.
  Widget _glassPill({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.28), width: 0.8),
          ),
          child: child,
        ),
      ),
    );
  }

  // 손가락 아이콘이 좌우/상하로 스와이프하는 애니메이션. 정적인 점(코멧) 대신
  // 실제 제스처처럼 보이는 손가락 + 양쪽 화살표로 "스와이프"임을 명확히 전달한다.
  Widget _swipeFinger({required bool horizontal, IconData? fingerIcon}) {
    return AnimatedBuilder(
      animation: _swipeAnim,
      builder: (context, _) {
        final double t = _swipeAnim.value; // 0~1 easeInOut 왕복
        final double pos = (t * 2 - 1); // -1~1
        final double head = pos * (horizontal ? 36 : 28);
        return Transform.translate(
          offset: horizontal ? Offset(head, 0) : Offset(0, head),
          child: Icon(
            fingerIcon ?? Icons.touch_app_rounded,
            color: Colors.white,
            size: horizontal ? 22 : 20,
          ),
        );
      },
    );
  }

  // 상하(밝기): 우측의 세로 글래스 알약 — 해 아이콘 + 위/아래 화살표 + 손가락 왕복.
  Widget _buildBrightnessHint() {
    return _glassPill(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 22),
          const SizedBox(height: 10),
          SizedBox(
            width: 28,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 은은한 트랙
                Container(width: 3, decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(2))),
                // 위/아래 화살표
                const Positioned(top: 0, child: Icon(Icons.arrow_upward_rounded, color: Colors.white54, size: 14)),
                const Positioned(bottom: 0, child: Icon(Icons.arrow_downward_rounded, color: Colors.white54, size: 14)),
                _swipeFinger(horizontal: false),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('밝기', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          const SizedBox(height: 2),
          Text('스와이프', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 좌우(줌): 중앙의 가로 글래스 알약 — 돋보기 아이콘 + 좌/우 화살표 + 손가락 왕복.
  Widget _buildZoomHint() {
    return _glassPill(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(height: 3, decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(2))),
                const Positioned(left: 0, child: Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 14)),
                const Positioned(right: 0, child: Icon(Icons.arrow_forward_rounded, color: Colors.white54, size: 14)),
                _swipeFinger(horizontal: true),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('줌', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          const SizedBox(width: 2),
          Text('스와이프', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500)),
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

  // ── 줌 배율 캡 — 초광각(0.5x)을 렌즈 전환 없이 "줌아웃"으로 처리 ──
  // camerawesome 2.5.0의 Android getBackSensors()는 미구현(TODO)이라 물리 렌즈 전환이 불가능.
  // 대신 두 플랫폼 모두 줌 팩터로 초광각에 도달한다(핀치아웃→0.5x가 끊김 없이 이어짐).
  // - Android: CameraX 논리 카메라의 minZoomRatio<1.0 이면 linearZoom 0 = 초광각 화각.
  // - iOS: 가상 멀티카메라(트리플/듀얼와이드)로 1회 전환 후 videoZoomFactor 1.0=0.5x,
  //        _iosWideFactor(보통 2.0)=표시 1x. 이후 줌은 전부 팩터 램프라 렌즈 점프 없음.
  static const MethodChannel _lensChannel = MethodChannel('com.skysnap/camera_lens');
  bool _zoomCapsLoaded = false;
  bool _zoomCapsLoading = false;
  double _minRatio = 1.0; // Android 전용: minZoomRatio (0.5면 초광각 포함)
  double _maxRatio = 1.0; // Android: maxZoomRatio / iOS: max videoZoomFactor(플러그인이 50 상한)
  double _iosWideFactor = 2.0; // iOS: 초광각→광각 전환 팩터(=표시 1x 기준)
  bool _hasUltraWide = false; // 0.5x 핀 노출 여부

  bool get _isFrontCamera {
    final sensors = widget.state.sensorConfig.sensors;
    return sensors.isNotEmpty && sensors.first.position == SensorPosition.front;
  }

  @override
  void initState() {
    super.initState();
    _checkRecordingState();
    _loadZoomCaps();
  }

  // 기기의 줌 배율 범위를 조회해 0.5x 지원 여부와 핀 매핑을 계산한다.
  // 카메라 준비 전엔 실패할 수 있어, 성공할 때까지 상태 갱신마다 재시도(didUpdateWidget)한다.
  Future<void> _loadZoomCaps() async {
    if (_zoomCapsLoaded || _zoomCapsLoading) return;
    if (widget.state is PreparingCameraState) return;
    _zoomCapsLoading = true;
    try {
      if (Platform.isAndroid) {
        final double? minZ = await CamerawesomePlugin.getMinZoom();
        final double? maxZ = await CamerawesomePlugin.getMaxZoom();
        // 진단: 이 기기의 논리 카메라 줌 범위(초광각 미지원 원인 파악용)
        debugPrint('[CAM] zoom caps(Android): min=$minZ max=$maxZ');
        if (minZ == null || maxZ == null || maxZ <= minZ) return;
        _minRatio = minZ;
        _maxRatio = maxZ;
        _hasUltraWide = !_isFrontCamera && minZ < 0.95;
      } else if (_isFrontCamera) {
        // 전면 카메라: 초광각 없음, 팩터 항등 매핑(1x=factor 1.0)
        final double? maxZ = await CamerawesomePlugin.getMaxZoom();
        if (maxZ == null || maxZ <= 1.0) return;
        _iosWideFactor = 1.0;
        _maxRatio = maxZ;
        _hasUltraWide = false;
      } else {
        final Map<dynamic, dynamic>? info =
            await _lensChannel.invokeMethod<Map<dynamic, dynamic>>('getVirtualBackCamera');
        debugPrint('[CAM] virtual back camera(iOS): $info');
        if (info == null) {
          // 초광각 없는 기기(iPhone SE 등): 1x부터 디지털 줌만
          final double? maxZ = await CamerawesomePlugin.getMaxZoom();
          if (maxZ == null || maxZ <= 1.0) return;
          _iosWideFactor = 1.0;
          _maxRatio = maxZ;
          _hasUltraWide = false;
        } else {
          final List<dynamic> switchOver = info['switchOver'] as List<dynamic>? ?? const [];
          _iosWideFactor = switchOver.isNotEmpty ? (switchOver.first as num).toDouble() : 2.0;
          widget.state.setSensorType(0, SensorType.wideAngle, info['uid'] as String);
          // 세션 재구성을 기다린 뒤 가상 디바이스 기준 maxZoom을 읽는다.
          await Future.delayed(const Duration(milliseconds: 400));
          final double? maxZ = await CamerawesomePlugin.getMaxZoom();
          _maxRatio = (maxZ == null || maxZ <= 1.0) ? 16.0 : maxZ;
          _hasUltraWide = true;
        }
      }
      _zoomCapsLoaded = true;
      // 시작 화각을 1x로 고정: iOS 가상 디바이스는 factor 1.0(=0.5x)로 시작하므로 필수,
      // Android는 ratio 1.0 그대로라 화면 변화 없음(핀 하이라이트 동기화용).
      widget.state.sensorConfig.setZoom(_zoomValueFor(1.0));
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[CAM] zoom caps error: $e');
    } finally {
      _zoomCapsLoading = false;
    }
  }

  // 표시 배율(0.5, 1, 2, 5…) → camerawesome setZoom 값(0~1) 변환.
  // Android linearZoom은 크롭폭 선형: L = maxZ(R−minZ) / (R(maxZ−minZ))
  // iOS는 팩터 선형: F = 표시배율 × _iosWideFactor, value = (F−1)/(maxF−1)
  double _zoomValueFor(double display) {
    if (Platform.isAndroid) {
      if (_maxRatio <= _minRatio) return 0.0;
      final double r = display.clamp(_minRatio, _maxRatio);
      return ((_maxRatio * (r - _minRatio)) / (r * (_maxRatio - _minRatio))).clamp(0.0, 1.0);
    } else {
      if (_maxRatio <= 1.0) return 0.0;
      final double f = (display * _iosWideFactor).clamp(1.0, _maxRatio);
      return ((f - 1.0) / (_maxRatio - 1.0)).clamp(0.0, 1.0);
    }
  }

  // 전/후면 전환 후 현재 카메라 기준으로 줌 캡을 다시 계산한다.
  Future<void> _reloadZoomCapsAfterFlip() async {
    _zoomCapsLoaded = false;
    _hasUltraWide = false;
    if (mounted) setState(() {});
    // 네이티브 세션 전환이 끝난 뒤 조회해야 새 카메라의 값이 나온다.
    await Future.delayed(const Duration(milliseconds: 350));
    await _loadZoomCaps();
  }

  @override
  void didUpdateWidget(covariant CamerAwesomeBottomActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkRecordingState();
    // 카메라가 준비되면(상태 갱신) 줌 캡 재시도.
    if (!_zoomCapsLoaded) _loadZoomCaps();
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
              final bool active = flashMode != FlashMode.none;
              return _buildQuickActionButton(
                icon: icon,
                label: label,
                // 꺼짐=흰색, 그 외(켜짐/자동/손전등)=노란색으로 상태 인지
                color: active ? const Color(0xFFFFD54F) : Colors.white,
                onTap: () {
                  state.sensorConfig.setFlashMode(_getNextFlashMode(flashMode));
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
              final String label = switch (ratio) {
                CameraAspectRatios.ratio_4_3 => '4:3',
                CameraAspectRatios.ratio_16_9 => '16:9',
                CameraAspectRatios.ratio_1_1 => '1:1',
              };
              return _buildQuickActionButton(
                icon: Icons.aspect_ratio_rounded,
                label: label,
                onTap: () {
                  state.sensorConfig.setAspectRatio(_getNextRatio(ratio));
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
              // 줌 캡 로드 전엔 기존 고정값, 로드 후엔 실제 배율 위치로 매핑.
              // 0.5x는 기기가 초광각을 지원할 때만 노출(줌아웃으로 도달).
              final List<MapEntry<String, double>> pills = _zoomCapsLoaded
                  ? [
                      if (_hasUltraWide) MapEntry('0.5x', _zoomValueFor(0.5)),
                      MapEntry('1x', _zoomValueFor(1)),
                      MapEntry('2x', _zoomValueFor(2)),
                      MapEntry('5x', _zoomValueFor(5)),
                    ]
                  : const [
                      MapEntry('1x', 0.0),
                      MapEntry('2x', 0.3),
                      MapEntry('5x', 0.6),
                    ];
              // 현재 줌에 가장 가까운 핀 하나만 활성 표시
              int activeIdx = 0;
              double best = double.infinity;
              for (int i = 0; i < pills.length; i++) {
                final double d = (pills[i].value - zoom).abs();
                if (d < best) {
                  best = d;
                  activeIdx = i;
                }
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < pills.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _buildZoomPill(state, pills[i].key, pills[i].value, i == activeIdx),
                  ],
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
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
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

  Widget _buildZoomPill(CameraState state, String label, double value, bool isActive) {
    // 0.5x는 라벨이 길어 캡슐형(38px), 나머지는 원형(30px). radius 15로 둘 다 자연스럽다.
    final double pillWidth = label == '0.5x' ? 38 : 30;
    return GestureDetector(
      onTap: () => state.sensorConfig.setZoom(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: pillWidth,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(15),
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
    final IconData icon = mode == CaptureMode.photo ? Icons.photo_camera_rounded : Icons.videocam_rounded;
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        state.setState(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.black : Colors.white60),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
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
              ? const SizedBox(width: 48)
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
              ? const SizedBox(width: 48)
              : _buildCameraSwitchButton(state),
        ],
      ),
    );
  }

  // 갤러리 = 사진 프레임 느낌의 라운드 사각(원형 셔터·전환과 형태로 구분)
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: () => widget.onGalleryTap(widget.state),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.4),
        ),
        child: const Icon(Icons.image_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCameraSwitchButton(CameraState state) {
    return GestureDetector(
      onTap: () async {
        await state.switchCameraSensor();
        // 전환된 카메라 기준으로 줌 배율 캡 재계산(iOS는 후면 복귀 시 가상 디바이스 재적용).
        _reloadZoomCapsAfterFlip();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.4),
        ),
        // cached(새로고침)보다 카메라 전환 의미가 분명한 아이콘으로 교체
        child: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 22),
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
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4.5),
      ),
      // 녹화 시에는 작은 사각형(정지 버튼)을 중앙에 그려 흰 원 안에 들어오게 한다.
      // (사각형을 원 크기만큼 크게 그리면 모서리가 원 밖으로 삐져나옴)
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: isRecording ? 30 : 60,
        height: isRecording ? 30 : 60,
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

