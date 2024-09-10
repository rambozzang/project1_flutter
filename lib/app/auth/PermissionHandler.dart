import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class PermissionHandler {
  Future<bool> completed() async {
    await handleNotificationPermission(); // 알림 권한 요청 (필수 아님)
    bool locationPermission = await handleLocationPermission(); // 위치 권한 요청 (필수)
    return locationPermission; // 위치 권한만 필수이므로 이 값만 반환
  }

  Future<void> handleNotificationPermission() async {
    var status = await Permission.notification.request();
    if (status.isDenied) {
      // Utils.alert('알림 권한이 거부되었습니다. 일부 기능이 제한될 수 있습니다.');
    }
  }

  Future<bool> handleLocationPermission() async {
    lo.g("permission_page.dart > handleLocationPermission()");
    LocationPermission locationPermission = await Geolocator.checkPermission();
    lo.g(locationPermission.toString());

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        return await showLocationExplanationDialog();
      }
    } else if (locationPermission == LocationPermission.deniedForever) {
      return await showOpenSettingsDialog('위치');
    }

    return locationPermission == LocationPermission.always || locationPermission == LocationPermission.whileInUse;
  }

  Future<bool> handleMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      return await showMicrophoneExplanationDialog();
    } else if (status.isPermanentlyDenied) {
      return await showOpenSettingsDialog('마이크');
    }
    return status.isGranted;
  }

  Future<bool> showLocationExplanationDialog() async {
    bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('위치 권한 필요'),
        content: const Text('정확한 서비스 제공을 위해 위치 권한이 필요합니다. 권한을 허용하시겠습니까?'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Get.back(result: false),
          ),
          TextButton(
            child: const Text('허용'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (result == true) {
      var newStatus = await Permission.location.request();
      if (newStatus.isPermanentlyDenied) {
        return await showOpenSettingsDialog('위치');
      }
      return newStatus.isGranted;
    }
    return false;
  }

  Future<bool> showMicrophoneExplanationDialog() async {
    bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('마이크 권한 필요'),
        content: const Text('동영상 촬영 시 오디오 녹음을 위해 마이크 권한이 필요합니다. 권한을 허용하시겠습니까?'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Get.back(result: false),
          ),
          TextButton(
            child: const Text('허용'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (result == true) {
      var newStatus = await Permission.microphone.request();
      if (newStatus.isPermanentlyDenied) {
        return await showOpenSettingsDialog('마이크');
      }
      return newStatus.isGranted;
    }
    return false;
  }

  Future<bool> showOpenSettingsDialog(String permissionName) async {
    bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('$permissionName 권한 설정'),
        content: Text('$permissionName 권한이 거부되었습니다.\n휴대폰 설정에서 직접 권한을 허용해주세요.'),
        actions: [
          TextButton(
            child: const Text('설정으로 이동'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (result == true) {
      await openAppSettings();
    }
    return false;
  }
}
