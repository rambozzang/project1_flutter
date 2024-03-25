import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/widget/custom_button.dart';

// flutter_cache_manager.
// preload_page_view,
// cdn 동영상 파일 업로드시 40M -> 5M 압축(약간의화질저하) ->video_compress: ^3.1.2

class MainView3 extends StatefulWidget {
  const MainView3({
    super.key,
  });

  @override
  State<MainView3> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MainView3> {
  @override
  void initState() {
    super.initState();
  }

  void goRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            return CameraBloc(
              cameraUtils: CameraUtils(),
              permissionUtils: PermissionUtils(),
            )..add(const CameraInitialize(recordingLimit: 15));
          },
          child: const CameraPage(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 50, child: CustomButton(text: '+', type: 'S', onPressed: () => goRecord())),
              const Gap(20),
              SizedBox(width: 70, child: CustomButton(text: 'tictok', type: 'S', onPressed: () => Get.toNamed('/ListPage'))),
            ],
          ),
        )));
  }
}
