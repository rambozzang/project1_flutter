import 'dart:io';

import 'package:camera/camera.dart';

// import 'package:camera/camera.dart'; // 임시 주석 처리

class CameraUtils {
  // 카메라 목록은 기기에서 고정이므로 한 번만 열거하고 캐싱한다.
  // (매 초기화/카메라 전환마다 availableCameras()를 부르면 수백 ms 낭비)
  static List<CameraDescription>? _cachedCameras;

  /// 앱 시작 시 미리 호출해두면 첫 카메라 진입이 더 빠르다(선택).
  static Future<void> warmUp() async {
    _cachedCameras ??= await availableCameras();
  }

  /// Returns a CameraController with the specified configuration.
  Future<CameraController> getCameraController({
    ResolutionPreset resolutionPreset = ResolutionPreset.high, // 해상도: 720x1280
    // ResolutionPreset resolutionPreset = ResolutionPreset.veryHigh, // 해상도: 1080x1920
    required CameraLensDirection lensDirection,
  }) async {
    // Retrieve the list of available cameras on the device (캐시 우선)
    final cameras = _cachedCameras ??= await availableCameras();

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
