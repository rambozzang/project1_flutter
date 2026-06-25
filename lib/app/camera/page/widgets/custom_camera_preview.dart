// import 'package:camera/camera.dart'; // 임시 주석 처리
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CustomCameraPreview extends StatelessWidget {
  final CameraController controller;

  const CustomCameraPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * controller.value.aspectRatio;

    if (scale < 1) scale = 1 / scale;

    return ClipRect(
      child: SizedBox(
        width: size.width - 10, // 좌우 5px 여백
        height: size.height - 28, // 위아래 14px 여백
        child: Transform.scale(
          scale: scale,
          child: Center(
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
