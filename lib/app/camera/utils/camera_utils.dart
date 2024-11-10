import 'dart:io';

import 'package:camera/camera.dart';

class CameraUtils {
  /// Returns a CameraController with the specified configuration.
  Future<CameraController> getCameraController({
    ResolutionPreset resolutionPreset = ResolutionPreset.high, // 해상도: 720x1280
    // ResolutionPreset resolutionPreset = ResolutionPreset.veryHigh, // 해상도: 1080x1920
    required CameraLensDirection lensDirection,
  }) async {
    // Retrieve the list of available cameras on the device
    final cameras = await availableCameras();

    // 추가: 카메라가 없는 경우 예외를 던집니다.
    if (cameras.isEmpty) {
      throw CameraException('NoCameraAvailable', '디바이스에 카메라가 없습니다.');
    }

    // lensDirection에 해당하는 카메라를 찾습니다.

    // Find the camera that matches the specified lens direction
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == lensDirection,
      orElse: () => cameras.first, // If not found, default to the first camera
    );
    // Create a CameraController instance with the selected camera and configuration
    return CameraController(
      camera,
      resolutionPreset,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.yuv420 : null, // iOS-specific configuration
    );
  }
}
