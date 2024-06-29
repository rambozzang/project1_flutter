import 'dart:async';
import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
// import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/cloudflare/R2_repo.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/cloudflare/data/cloudflare_req_save_data.dart';
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
  // ScrollController hideButtonController11 = ScrollController();
  ScrollController hideButtonController12 = ScrollController();

  // 내정보
  ScrollController hideButtonController2 = ScrollController();

  // 설정
  ScrollController hideButtonController3 = ScrollController();

  //검색 페이지
  ScrollController hideButtonController4 = ScrollController();

  //날씨 메인
  ScrollController hideButtonController5 = ScrollController();

  late TabController tabController;

  // 하단 바 숨기기 변수
  // RxDouble isVisible = 1.0.obs;
  RxBool isVisible = true.obs;

  late Cloudflare cloudflare;
  String? cloudflareInitMessage;

  // ad loading flag
  RxBool isAdLoading = false.obs;

  @override
  void onInit() {
    hideButtonController1.addListener(() => changeScrollListner(hideButtonController1));
    // hideButtonController11.addListener(() => changeScrollListner(hideButtonController11));
    hideButtonController12.addListener(() => changeScrollListner(hideButtonController12));
    hideButtonController2.addListener(() => changeScrollListner(hideButtonController2));
    hideButtonController3.addListener(() => changeScrollListner(hideButtonController3));
    hideButtonController4.addListener(() => changeScrollListner(hideButtonController4));
    hideButtonController5.addListener(() => changeScrollListner(hideButtonController5));

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

  late File uploadVideoFile;
  late File uploadThumbnailFile;

  void compressClose() async {
    Utils.alert('비디오 압축에 실패했습니다.');
    isFileUploading.value = UploadingType.FAIL;
    VideoCompress.deleteAllCache();
    VideoCompress.cancelCompression();
  }

  // 비디오 파일 압축 및 썸네일 생성
  Future<List<File>> compressVideo(videoFile) async {
    try {
      final List list;
      list = await Future.wait([
        VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.HighestQuality,
          deleteOrigin: false,
          includeAudio: true,
        ),
        VideoCompress.getFileThumbnail(videoFile.path, quality: 50),
      ]);
      pickedFile = list[0];
      thumbnailFile = list[1].path;
      uploadVideoFile = File(pickedFile!.path.toString());
      uploadThumbnailFile = File(thumbnailFile!.toString());
      return [uploadVideoFile, uploadThumbnailFile];
      // // return pickedFile;
    } catch (e) {
      Lo.g('비디오 압축 에러 : $e');
      VideoCompress.cancelCompression();
      return [];
    }
  }

  void uploadR2Storage(File videoFile, BoardSaveData boardSaveData) async {
    isFileUploading.value = UploadingType.UPLOADING;
    String today = Utils.getToday();
    try {
      // 비디오 파일 압축
      MediaInfo? pickedFile = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      // 썸네일 생성
      File? thumbnailFile = await VideoCompress.getFileThumbnail(videoFile.path, quality: 50);
      if (pickedFile == null || thumbnailFile == null) {
        compressClose();
        return;
      }

      // 비디오 파일 업로드
      BucketUpload bucketUpload = BucketUpload('p1-video', 'us-east-1', videoFile);
      R2Repo r2Repo = R2Repo();
      ResData resVideoData = await r2Repo.uploadFile(bucketUpload);
      Lo.g('비디오 : ${resVideoData.code.toString()}');
      Lo.g('비디오 : ${resVideoData.msg.toString()}');
      Lo.g('비디오 : ${resVideoData.data.toString()}');

      // 썸네일 업로드
      CloudflareRepo cloudflare = CloudflareRepo();
      await cloudflare.init();
      CloudflareHTTPResponse<CloudflareImage?>? resthumbnail = await cloudflare.imageFileUpload(thumbnailFile);
      if (resthumbnail?.isSuccessful == false) {
        Utils.alert('썸네일 업로드에 실패했습니다.');
        compressClose();
        return;
      }
      Lo.g('썸네일 : ${resthumbnail!.base.reasonPhrase.toString()}');
      Lo.g('썸네일 : ${resthumbnail!.base.toString()}');
      Lo.g('썸네일 : ${resthumbnail!.body?.id.toString()}');
      Lo.g('썸네일 : ${resthumbnail.body?.filename.toString()}');
      Lo.g('썸네일 : ${resthumbnail.body?.imageDeliveryId.toString()}');
      Lo.g('썸네일 : ${resthumbnail.body?.imageDeliveryId.toString()}');

      Lo.g('썸네일 : ${resthumbnail.body.toString()}');

      // 저장
      BoardRepo boardRepo = BoardRepo();
      boardSaveData.boardWeatherVo?.thumbnailPath = resthumbnail.body?.variants[0].toString();
      boardSaveData.boardWeatherVo?.thumbnailId = resthumbnail!.body?.id.toString();
      boardSaveData.boardWeatherVo?.videoPath = resVideoData.data.toString();
      boardSaveData.boardWeatherVo?.videoId = '';
      ResData resData = await boardRepo.save(boardSaveData);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        isFileUploading.value = UploadingType.FAIL;
        File(pickedFile!.path.toString()).delete();
        File(thumbnailFile!.toString()).delete();
        File(videoFile.path!.toString()).delete();

        VideoCompress.deleteAllCache();
        VideoCompress.cancelCompression();
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
    } catch (e) {
      lo.g("ERRRRRRR=> " + e.toString());
      compressClose();
    }
  }

  // Cloudflare  STREAM 파일 업로드
  void uploadCloudflare(File videoFile, BoardSaveData boardSaveData) async {
    isFileUploading.value = UploadingType.UPLOADING;
    CloudflareRepo cloudflare = CloudflareRepo();
    await cloudflare.init();
    String today = Utils.getToday();

    try {
      MediaInfo? pickedFile = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.HighestQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      Lo.g('비디오 압축 결과 : ${pickedFile!.toJson()}');
      if (pickedFile == null) {
        Utils.alert('비디오 압축에 실패했습니다.');
        isFileUploading.value = UploadingType.FAIL;
        VideoCompress.deleteAllCache();
        VideoCompress.cancelCompression();
        return;
      }

      File uploadVideoFile = File(pickedFile.path.toString());

      CloudflareHTTPResponse<CloudflareStreamVideo?>? videoRes = await cloudflare.videoStreamUpload(uploadVideoFile);

      CloudflareStreamVideo? video = videoRes?.body;

      lo.g("영상업로드 업로드 결과 : ${videoRes!.body!.toString()}");

      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.id}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.input}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.preview}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.size}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.uploadExpiry}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.customAccountSubdomainUrl}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.animatedThumbnail}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.meta.toString()}");

      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.preview}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.thumbnail}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.animatedThumbnail}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.playback!.hls.toString()}");
      lo.g("영상업로드 업로드 결과 : ${videoRes.body!.playback!.dash.toString()}");

      if (videoRes?.isSuccessful == false || videoRes.body!.id == null) {
        // if (videoRes?.isSuccessful == false || thumbnailres?.isSuccessful == false) {
        Utils.alert('파일 업로드에 실패했습니다.');
        isFileUploading.value = UploadingType.FAIL;
        VideoCompress.deleteAllCache();
        VideoCompress.cancelCompression();
        return;
      }
      // mp4 파일 주소 가져오기
      // CloudflareRepo repo = CloudflareRepo();
      // var resMp4 = await repo.videoDownload(video!.id);
      // Lo.g("resMp4 : " + resMp4.toString());

      CloudflareReqSaveData cloudSaveData = CloudflareReqSaveData();
      cloudSaveData.uid = video!.id;
      cloudSaveData.preview = video.preview;
      cloudSaveData.size = video.size;
      cloudSaveData.thumbnail = video.animatedThumbnail;
      // cloudSaveData.thumbnail = video.thumbnail;
      cloudSaveData.dash = video.playback!.dash.toString();
      cloudSaveData.hls = video.playback!.hls.toString();
      cloudSaveData.mp4 = ''; //resMp4['result']['default']['url'];
      cloudSaveData.range = pickedFile?.duration!.toInt() ?? 0;
      cloudSaveData.total = 0;

      ResData resCloudData = await cloudflare.save(cloudSaveData);
      if (resCloudData.code != '00') {
        Utils.alert(resCloudData.msg.toString());
        isFileUploading.value = UploadingType.FAIL;
        File(pickedFile!.path.toString()).delete();
        File(thumbnailFile!.toString()).delete();
        File(videoFile.path!.toString()).delete();

        VideoCompress.deleteAllCache();
        VideoCompress.cancelCompression();
        return;
      }

      // 저장
      BoardRepo boardRepo = BoardRepo();
      // boardSaveData.boardWeatherVo?.thumbnailPath = video.thumbnail;
      boardSaveData.boardWeatherVo?.thumbnailPath = video.animatedThumbnail;
      boardSaveData.boardWeatherVo?.thumbnailId = video.id;
      boardSaveData.boardWeatherVo?.videoPath = video.playback!.hls.toString();
      boardSaveData.boardWeatherVo?.videoId = video.id;
      ResData resData = await boardRepo.save(boardSaveData);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        isFileUploading.value = UploadingType.FAIL;
        File(pickedFile!.path.toString()).delete();
        File(thumbnailFile!.toString()).delete();
        File(videoFile.path!.toString()).delete();

        VideoCompress.deleteAllCache();
        VideoCompress.cancelCompression();
        return;
      }
      isFileUploading.value = UploadingType.SUCCESS;
      // Utils.alert('정상 등록되었습니다!');
      Future.delayed(const Duration(milliseconds: 2000), () {
        isFileUploading.value = UploadingType.NONE;
        File(pickedFile!.path.toString()).delete();
        // File(thumbnailFile!.toString()).delete();
        File(videoFile.path!.toString()).delete();

        VideoCompress.deleteAllCache();
        VideoCompress.cancelCompression();
      });
    } catch (e) {
      //   lo.g(e.message);
      isFileUploading.value = UploadingType.FAIL;
      lo.g("ERRRRRRR=> " + e.toString());
      VideoCompress.deleteAllCache();
      VideoCompress.cancelCompression();
    }
  }

  // Video__reg_page.dart 파일에서 호출 후 등록 처리.
  void goTimer(File videoFile, BoardSaveData boardSaveData) {
    Future.delayed(const Duration(microseconds: 300), () {
      // Cloudflare R2 파일 업로드
      // uploadR2Storage(videoFile, boardSaveData);

      // Cloudflare Stream 파일 업로드
      uploadCloudflare(videoFile, boardSaveData);
    });
  }

  @override
  void dispose() {
    hideButtonController1.dispose();
    // hideButtonController11.dispose();
    hideButtonController12.dispose();
    hideButtonController2.dispose();
    hideButtonController3.dispose();
    hideButtonController4.dispose();
    hideButtonController5.dispose();
    bottomBarStreamController.close();

    super.dispose();
  }

  changePage(int i) {}
}
