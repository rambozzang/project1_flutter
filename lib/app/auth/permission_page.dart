import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  @override
  void initState() {
    super.initState();
    permissionRequest();
  }

  // 최초 회원 강비ㅅ
  Future<void> permissionRequest() async {
    Map<Permission, PermissionStatus> status = await [Permission.location, Permission.notification].request(); // [] 권한배열에 권한을

    // var status = await Permission.location.request();
    // var status = await Permission.notification.request();
    // var status = await Permission.camera.request();

    // if (await Permission.location.isGranted) {
    //   return Future.value(true);
    // } else {
    //   return Future.value(false);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF262B49),
      body: Center(
        child: Text(
          '권한 체크...',
          style: TextStyle(color: Colors.white, fontSize: 8),
        ),
      ),
    );
  }
}
