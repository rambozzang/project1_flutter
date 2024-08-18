import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class PermissionHandler {
  Future<void> complated() async {
    await handlePermissions();
  }

  Future<void> handlePermissions() async {
    await handleNotificationPermission();
    await handleLocationPermission();
  }

  Future<void> handleNotificationPermission() async {
    var status = await Permission.notification.request();
    if (status.isDenied) {
      Utils.alert('알림 권한이 거부되었습니다. 일부 기능이 제한될 수 있습니다.');
    } else if (status.isPermanentlyDenied) {
      await showOpenSettingsDialog('알림');
    }
  }

  Future<void> handleLocationPermission() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();
    lo.g(locationPermission.toString());

    if (locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) {
        // Utils.showConfirmDialog('위치 권한은 필수입니다.', '위치 설정을 변경 권한 > 위치 해주세요!', BackButtonBehavior.none, cancel: () {}, confirm: () async {
        //   await openAppSettings();
        // }, backgroundReturn: () async {
        //   handleLocationPermission();
        // });
        showLocationExplanationDialog();
      }
    }
  }

  Future<void> showLocationExplanationDialog() async {
    bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('위치 권한 필요'),
        content: const Text('정확한 서비스 제공을 위해 위치 권한이 필요합니다. 권한을 허용하시겠습니까?'),
        actions: [
          // TextButton(
          //   child: const Text('나중에'),
          //   onPressed: () => Get.back(result: false),
          // ),
          TextButton(
            child: const Text('허용'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (result == true) {
      var newStatus = await Permission.location.request();
      lo.g('newStatus.isGranted  : ${newStatus.isGranted}');
      lo.g('newStatus.isPermanentlyDenied  : ${newStatus.isPermanentlyDenied}');
      lo.g('newStatus.isDenied  : ${newStatus.isDenied}');
      if (newStatus.isPermanentlyDenied || newStatus.isDenied) {
        await showOpenSettingsDialog('위치');
      }
    }
  }

  Future<void> showOpenSettingsDialog(String permissionName) async {
    bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('$permissionName 권한 설정'),
        content: Text('$permissionName 권한이 거부되었습니다. 앱 설정에서 수동으로 권한을 허용해주세요.'),
        actions: [
          TextButton(
            child: const Text('나중에'),
            onPressed: () => Get.back(result: false),
          ),
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
  }
}
