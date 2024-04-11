import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_save_main_data.dart';
import 'package:project1/repo/cloudinary/cloudinary_page.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:video_compress/video_compress.dart';

class RootCntrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RootCntr>(
      () => RootCntr(),
    );
  }
}

enum UploadingType { NONE, UPLOADING, SUCCESS, FAIL }

class RootCntr extends GetxController {
  static RootCntr get to => Get.find();

  final StreamController<bool> bottomBarStreamController = StreamController<bool>();

  RxInt rootPageIndex = 0.obs;
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RxBool isCategoryPageOpen = false.obs;
  var isFileUploading = UploadingType.NONE.obs;

  ScrollController hideButtonController1 = ScrollController();
  ScrollController hideButtonController11 = ScrollController();
  ScrollController hideButtonController12 = ScrollController();

  // 내정보
  ScrollController hideButtonController2 = ScrollController();

  // 설정
  ScrollController hideButtonController3 = ScrollController();
  ScrollController hideButtonController4 = ScrollController();
  late TabController tabController;

  // 하단 바 숨기기 변수
  // RxDouble isVisible = 1.0.obs;
  RxBool isVisible = true.obs;

  @override
  void onInit() {
    hideButtonController1.addListener(() => changeScrollListner(hideButtonController1));
    hideButtonController11.addListener(() => changeScrollListner(hideButtonController11));
    hideButtonController12.addListener(() => changeScrollListner(hideButtonController12));
    hideButtonController2.addListener(() => changeScrollListner(hideButtonController2));
    hideButtonController3.addListener(() => changeScrollListner(hideButtonController3));
    hideButtonController4.addListener(() => changeScrollListner(hideButtonController4));

    super.onInit();
  }

  // 스크롤에 따라 bottom bar hide
  void changeScrollListner(ScrollController scrollData) {
    if (scrollData.position.userScrollDirection == ScrollDirection.reverse) {
      if (isVisible.value) {
        isVisible.value = false;
        bottomBarStreamController.sink.add(isVisible.value);
      }
    } else if (scrollData.position.userScrollDirection == ScrollDirection.forward) {
      if (!isVisible.value) {
        isVisible.value = true;
        bottomBarStreamController.sink.add(isVisible.value);
      }
    }
  }

  void changeRootPageIndex(int index) {
    rootPageIndex(index);
  }

  Future<bool> onWillPop() async {
    setCategoryPage(false);
    return !await navigatorKey.currentState!.maybePop();
  }

  void setCategoryPage(bool ck) {
    isCategoryPageOpen(ck);
  }

  void back() {
    setCategoryPage(false);
    onWillPop();
  }

  late MediaInfo? pickedFile;
  late String? thumbnailFile;
  // 비디오 파일 압축 및 썸네일 생성
  Future<void> compressVideo(videoFile) async {
    try {
      // pickedFile = await VideoCompress.compressVideo(
      //   videoFile.path,
      //   quality: VideoQuality.LowQuality,
      //   deleteOrigin: false,
      //   includeAudio: true,
      // );
      // Lo.g('비디오 압축 결과 : ${pickedFile?.toJson()}');
      // File ff = await VideoCompress.getFileThumbnail(videoFile.path, quality: 50);
      // thumbnailFile = ff.path;
      final List list;
      list = await Future.wait([
        VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        ),
        VideoCompress.getFileThumbnail(videoFile.path, quality: 50),
      ]);
      pickedFile = list[0];
      thumbnailFile = list[1].path;
      // // return pickedFile;
    } catch (e) {
      Lo.g('비디오 압축 에러 : $e');
      VideoCompress.cancelCompression();
      //return null;
    }
  }

  // 파일 업로드
  void upload(File videoFile, BoardSaveData boardSaveData) async {
    isFileUploading.value = UploadingType.UPLOADING;
    Lo.g("Root upload() videoFilePath : ${videoFile.path}");
    Lo.g("Root upload() videoFilePath : ${videoFile.path}");
    Lo.g("Root upload() videoFilePath : ${videoFile.path}");
    Lo.g("Root upload() videoFilePath : ${videoFile.path}");

    Lo.g("==> ${File(videoFile.path).exists()}");
    Lo.g("1 ==> ${File(videoFile.path).existsSync()}");

    String today = Utils.getToday();

    //  MediaInfo? pickedFile = await compressVideo();

    // try {
    //   Lo.g(videoFile.path.toString());
    //   Lo.g("2 ==> ${File(videoFile.path).existsSync()}");
    //   pickedFile = await VideoCompress.compressVideo(
    //     videoFile.path,
    //     quality: VideoQuality.MediumQuality,
    //     deleteOrigin: false,
    //     includeAudio: true,
    //   );
    //   Lo.g("3 ==> ${File(videoFile.path).existsSync()}");
    //   Lo.g('비디오 압축 결과 : ${pickedFile?.toJson()}');
    //   if (pickedFile == null) {
    //     Utils.alert('비디오 압축에 실패했습니다.');
    //     return;
    //   }
    // } catch (e) {
    //   Lo.g('비디오 압축 에러 : $e');
    //   Utils.alert('비디오 압축 에러 : $e');
    // }

    try {
      await compressVideo(videoFile);
      // File ff = await VideoCompress.getFileThumbnail(videoFile.path, quality: 50);
      // thumbnailFile = ff.path;
      Lo.g('비디오 압축 결과 : ${pickedFile!.toJson()}');
      if (pickedFile == null) {
        Utils.alert('비디오 압축에 실패했습니다.');
        isFileUploading.value = UploadingType.FAIL;
        VideoCompress.deleteAllCache();
        VideoCompress.cancelCompression();
        return;
      }

      if (thumbnailFile == null) {
        Utils.alert('썸네일 압축에 실패했습니다.');
        isFileUploading.value = UploadingType.FAIL;
        VideoCompress.cancelCompression();
        return;
      }
      final List list;
      list = await Future.wait([
        cloudinaryImage.uploadFile(
          CloudinaryFile.fromFile(
            thumbnailFile.toString(),
            resourceType: CloudinaryResourceType.Image,
            folder: today,
            // context: {
            //   'alt': 'Hello',
            //   'caption': 'An example image',
            // },
          ),
          onProgress: (count, total) {
            //  uploadingPercentage2.value = (count / total) * 100;
          },
        ),
        cloudinaryVideo.uploadFile(
          CloudinaryFile.fromFile(
            pickedFile!.path.toString(),
            resourceType: CloudinaryResourceType.Video,
            folder: today,
            // context: {
            //   'alt': 'Hello',
            //   'caption': 'An example image',
            // },
          ),
          onProgress: (count, total) {
            // uploadingPercentage1.value = (count / total) * 100;
          },
        )
      ]);
      CloudinaryResponse res2 = list[0];
      CloudinaryResponse res = list[1];
      // final res2 = await cloudinaryImage.uploadFile(
      //   CloudinaryFile.fromFile(
      //     thumbnailFile.toString(),
      //     resourceType: CloudinaryResourceType.Image,
      //     folder: today,
      //     // context: {
      //     //   'alt': 'Hello',
      //     //   'caption': 'An example image',
      //     // },
      //   ),
      //   onProgress: (count, total) {
      //     //  uploadingPercentage2.value = (count / total) * 100;
      //   },
      // );
      lo.g("썸네일 업로드 결과 : " + res2.toString());

      // final res = await cloudinaryVideo.uploadFile(
      //   CloudinaryFile.fromFile(
      //     pickedFile.path.toString(),
      //     resourceType: CloudinaryResourceType.Video,
      //     folder: today,
      //     // context: {
      //     //   'alt': 'Hello',
      //     //   'caption': 'An example image',
      //     // },
      //   ),
      //   onProgress: (count, total) {
      //     // uploadingPercentage1.value = (count / total) * 100;
      //   },
      // );
      lo.g("영상업로드 업로드 결과 : " + res.toString());

      // 저장
      BoardRepo boardRepo = BoardRepo();
      boardSaveData.boardWeatherVo?.thumbnailPath = res2.secureUrl;
      boardSaveData.boardWeatherVo?.thumbnailId = res2.assetId;
      boardSaveData.boardWeatherVo?.videoPath = res.secureUrl;
      boardSaveData.boardWeatherVo?.videoId = res.assetId;
      ResData resData = await boardRepo.save(boardSaveData);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        isFileUploading.value = UploadingType.FAIL;
        return;
      }
      isFileUploading.value = UploadingType.SUCCESS;
      // Utils.alert('정상 등록되었습니다!');
      Future.delayed(const Duration(milliseconds: 2000), () {
        isFileUploading.value = UploadingType.NONE;
        File(pickedFile!.path.toString()).delete();
        File(thumbnailFile!.toString()).delete();
        File(videoFile.path!.toString()).delete();

        VideoCompress.deleteAllCache();
        VideoCompress.cancelCompression();
      });

      // {asset_id: 589dcec7931c12efb379ea632472b541, public_id: VID_2024-03-26_09-53-54-688112223_euuauj, created_at: 2024-03-26 12:54:04.000Z, url: http://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-688112223_euuauj.mp4, secure_url: https://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-688112223_euuauj.mp4, original_filename: VID_2024-03-26 09-53-54-688112223, tags: [], context: {}, data: {asset_id: 589dcec7931c12efb379ea632472b541, public_id: VID_2024-03-26_09-53-54-688112223_euuauj, version: 1711457644, version_id: 399c18d5612ddbc8dba302632442ea62, signature: f6b7e4ec4e869f18d4112882bdf5d37aba8d582d, width: 640, height: 1136, format: mp4, resource_type: video, created_at: 2024-03-26T12:54:04Z, tags: [], pages: 0, bytes: 1612764, type: upload, etag: 116c06206b2f85fb10ca3fdfdfbe273e, placeholder: false, url: http://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-6881
    } on CloudinaryException catch (e) {
      //   lo.g(e.message);
      isFileUploading.value = UploadingType.FAIL;
      lo.g("ERRRRRRR=> " + e.request.toString());
      lo.g("ERRRRRRR=> " + e.toString());
      VideoCompress.deleteAllCache();
      VideoCompress.cancelCompression();
    }
  }

  // Video__reg_page.dart 파일에서 호출 후 등록 처리.
  void goTimer(File videoFile, BoardSaveData boardSaveData) {
    Future.delayed(const Duration(microseconds: 300), () {
      upload(videoFile, boardSaveData);
    });
  }

  @override
  void dispose() {
    hideButtonController1.dispose();
    hideButtonController11.dispose();
    hideButtonController12.dispose();
    hideButtonController2.dispose();
    hideButtonController3.dispose();
    bottomBarStreamController.close();

    super.dispose();
  }

  changePage(int i) {}
}
