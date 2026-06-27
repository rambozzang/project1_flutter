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
              return CamerAwesomeBottomActions(
                state: state,
                onGalleryTap: _openGallery,
                photos: _photos,
                onRemovePhoto: (index) {
                  setState(() {
                    _photos.removeAt(index);
                  });
                },
              );
            },
            theme: AwesomeTheme(
              bottomActionsBackgroundColor: Colors.transparent,
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
  final Function(CameraState) onGalleryTap;
  final List<File> photos;
  final Function(int) onRemovePhoto;

  const CamerAwesomeBottomActions({
    super.key,
    required this.state,
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

  @override
  void initState() {
    super.initState();
    _checkRecordingState();
  }

  @override
  void didUpdateWidget(covariant CamerAwesomeBottomActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkRecordingState();
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.85),
          ],
          stops: const [0.0, 0.3, 1.0],
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
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
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
    final bool isActive = (currentValue - value).abs() < 0.15;
    return GestureDetector(
      onTap: () => state.sensorConfig.setZoom(value),
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
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
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
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}
