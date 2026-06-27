import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/app/camera/page/video_reg_page.dart';

class CameraAwesomePage extends StatefulWidget {
  const CameraAwesomePage({super.key});

  @override
  State<CameraAwesomePage> createState() => _CameraAwesomePageState();
}

class _CameraAwesomePageState extends State<CameraAwesomePage> {
  bool _navigated = false;

  void _onMediaCaptureEvent(MediaCapture? mediaCapture) {
    if (mediaCapture == null) return;
    if (mediaCapture.status != MediaCaptureStatus.success) return;
    if (_navigated) return;

    final path = mediaCapture.captureRequest.path;
    if (path == null) return;

    final file = File(path);

    if (mediaCapture.isVideo) {
      _navigated = true;
      // 녹화 종료 직후 UI가 잠시 멈출 수 있으므로 다음 프레임에서 네비게이션
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoRegPage(videoFile: file),
          ),
        );
      });
    }
  }

  Future<void> _openGallery() async {
    final XFile? picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VideoRegPage(videoFile: File(picked.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photoAndVideo(
          initialCaptureMode: CaptureMode.video,
        ),
        onMediaCaptureEvent: _onMediaCaptureEvent,
        topActionsBuilder: (state) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 닫기 버튼
              AwesomeCircleButton(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
              // 갤러리 버튼
              AwesomeCircleButton(
                onTap: _openGallery,
                child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
              ),
            ],
          );
        },
        theme: AwesomeTheme(
          bottomActionsBackgroundColor: Colors.black54,
        ),
      ),
    );
  }
}

/// camerawesome 기본 위젯에 없는 간단한 원형 버튼
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
