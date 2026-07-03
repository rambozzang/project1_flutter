import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';

/// 전역 업로드 상태 인디케이터.
/// GetMaterialApp.builder의 최상위 Stack에 올려 모든 라우트(푸시된 앨범 상세/몰입 화면 포함)
/// 위에 표시된다. (기존에는 root_page Stack 안에 있어 탭 화면에서만 보였음)
class GlobalUploadIndicator extends StatefulWidget {
  const GlobalUploadIndicator({super.key});

  @override
  State<GlobalUploadIndicator> createState() => _GlobalUploadIndicatorState();
}

class _GlobalUploadIndicatorState extends State<GlobalUploadIndicator> {
  // MaterialApp.builder는 라우트 전환 시 rebuild되지 않으므로,
  // 앱 시작 시점(RootCntr 등록 전)에 그려졌다면 등록될 때까지 기다렸다 활성화한다.
  Timer? _waitTimer;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<RootCntr>()) {
      _waitTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (Get.isRegistered<RootCntr>()) {
          t.cancel();
          if (mounted) setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RootCntr>()) return const SizedBox.shrink();
    return IgnorePointer(
      child: Obx(() {
        final status = RootCntr.to.isFileUploading.value;
        if (status == UploadingType.UPLOADING) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Utils.progressUpload(size: 25),
              const Gap(5),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(3),
                child: const Text(
                  "Uploading..",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }
        if (status == UploadingType.SUCCESS) {
          return Container(
            color: Colors.black,
            padding: const EdgeInsets.all(5),
            child: const Text(
              "게시물이 정상 게시 되었습니다.",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
