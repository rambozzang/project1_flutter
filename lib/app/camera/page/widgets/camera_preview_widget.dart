import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:project1/app/camera/utils/zoom_widget.dart';

class CameraPreviewWidget extends StatefulWidget {
  final CameraController controller;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  CameraLensDirection? _lastZoomResetDirection;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final deviceRatio = mediaSize.aspectRatio;
    final scale = 1 / (widget.controller.value.aspectRatio * deviceRatio);

    // 프론트 치메라 기본 줌: lensDirection이 변경될 때만 한 번 호출
    final currentDirection = widget.controller.description.lensDirection;
    if (currentDirection == CameraLensDirection.front && _lastZoomResetDirection != currentDirection) {
      _lastZoomResetDirection = currentDirection;
      widget.controller.setZoomLevel(1.0).catchError((_) {});
    } else if (currentDirection == CameraLensDirection.back) {
      _lastZoomResetDirection = currentDirection;
    }

    return ZoomableWidget(
      onTapUp: (scaledPoint) {
        widget.controller.setFocusPoint(scaledPoint);
      },
      onZoom: (zoom) {
        if (zoom < 11) {
          widget.controller.setZoomLevel(zoom);
        }
      },
      child: ClipRect(
        clipper: _MediaSizeClipper(mediaSize),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: CameraPreview(widget.controller),
        ),
      ),
    );
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    // mediaSize는 빌드 중 변하지 않으므로 재클립 불필요
    return false;
  }
}
