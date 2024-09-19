import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CustomCameraPreview extends StatelessWidget {
  final CameraController controller;

  const CustomCameraPreview({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * controller.value.aspectRatio;

    if (scale < 1) scale = 1 / scale;

    return ClipRect(
      child: Container(
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
