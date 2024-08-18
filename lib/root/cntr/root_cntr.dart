import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloudflare/cloudflare.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/cloudflare/R2_repo.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/cloudflare/data/cloudflare_req_save_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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

  // late TabController tabController;

  final RxBool isInterstitialAdReady = false.obs;

  void updateInterstitialAdStatus(bool isReady) {
    isInterstitialAdReady.value = isReady;
  }

  // 광고 로드 여부
  // 각 화면의 광고 로딩 상태를 저장하는 Map
  final Map<String, RxBool> adLoadingStatus = <String, RxBool>{}.obs;
  // 전체 앱의 광고 로딩 상태
  final RxBool isAdLoading = false.obs;

  // 특정 화면의 광고 로딩 상태를 업데이트하는 함수
  void updateAdLoadingStatus(String screenName, bool isLoaded) {
    // 해당 화면의 광고 로딩 상태를 업데이트
    adLoadingStatus[screenName] = RxBool(isLoaded);

    // 전체 앱의 광고 로딩 상태 업데이트
    // 하나라도 로딩 중인 광고가 있으면 true, 아니면 false
    isAdLoading.value = adLoadingStatus.values.any((status) => status.value);
  }

  // 특정 화면의 광고 로딩 상태를 확인하는 함수
  bool isAdLoaded(String screenName) {
    // 해당 화면의 광고 로딩 상태를 반환
    // 만약 해당 화면의 상태가 없으면 false 반환
    return adLoadingStatus[screenName]?.value ?? false;
  }

  // 하단 바 숨기기 변수
  // RxDouble isVisible = 1.0.obs;
  RxBool isVisible = true.obs;

  late Cloudflare cloudflare;
  String? cloudflareInitMessage;

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
  // Future<List<File>> compressVideo(videoFile) async {
  //   try {
  //     final List list;
  //     list = await Future.wait([
  //       VideoCompress.compressVideo(
  //         videoFile.path,
  //         quality: VideoQuality.HighestQuality,
  //         deleteOrigin: false,
  //         includeAudio: true,
  //       ),
  //       VideoCompress.getFileThumbnail(videoFile.path, quality: 50),
  //     ]);
  //     pickedFile = list[0];
  //     thumbnailFile = list[1].path;
  //     uploadVideoFile = File(pickedFile!.path.toString());
  //     uploadThumbnailFile = File(thumbnailFile!.toString());
  //     return [uploadVideoFile, uploadThumbnailFile];
  //     // // return pickedFile;
  //   } catch (e) {
  //     Lo.g('비디오 압축 에러 : $e');
  //     VideoCompress.cancelCompression();
  //     return [];
  //   }
  // }

  void uploadR2Storage(File videoFile, BoardSaveData boardSaveData) async {
    isFileUploading.value = UploadingType.UPLOADING;

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

      // 저장
      BoardRepo boardRepo = BoardRepo();
      boardSaveData.boardWeatherVo?.thumbnailPath = resthumbnail!.body?.variants[0].toString();
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
      lo.g("ERRRRRRR=> $e");
      compressClose();
    }
  }

  // Cloudflare  STREAM 파일 업로드
  void uploadCloudflare(File videoFile, BoardSaveData boardSaveData) async {
    isFileUploading.value = UploadingType.UPLOADING;
    CloudflareRepo cloudflare = CloudflareRepo();
    await cloudflare.init();

    try {
      bool needsCompression = await shouldCompressVideo(videoFile.path);
      late MediaInfo? pickedFile;

      if (needsCompression) {
        pickedFile = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.HighestQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
      } else {
        pickedFile = await VideoCompress.getMediaInfo(videoFile.path);
      }

      Lo.g('비디오 압축 결과 : ${pickedFile!.toJson()}');
      if (pickedFile == null) {
        Utils.alert('비디오 압축에 실패했습니다.');
        isFileUploading.value = UploadingType.FAIL;
        if (needsCompression) {
          VideoCompress.deleteAllCache();
          VideoCompress.cancelCompression();
        }
        return;
      }

      File uploadVideoFile = File(pickedFile.path.toString());
      CloudflareHTTPResponse<CloudflareStreamVideo?>? videoRes = await cloudflare.videoStreamUpload(uploadVideoFile);
      CloudflareStreamVideo? video = videoRes?.body;

      if (videoRes?.isSuccessful == false || videoRes!.body!.id == null) {
        // if (videoRes?.isSuccessful == false || thumbnailres?.isSuccessful == false) {
        Utils.alert('파일 업로드에 실패했습니다.');
        isFileUploading.value = UploadingType.FAIL;
        if (needsCompression) {
          VideoCompress.deleteAllCache();
          VideoCompress.cancelCompression();
        }
        return;
      }
      CloudflareReqSaveData cloudSaveData = CloudflareReqSaveData();
      cloudSaveData.uid = video!.id;
      cloudSaveData.preview = video.preview;
      cloudSaveData.size = video.size;
      cloudSaveData.thumbnail = video.animatedThumbnail;

      // cloudSaveData.thumbnail = video.thumbnail;
      cloudSaveData.dash = video.playback!.dash.toString();
      cloudSaveData.hls = video.playback!.hls.toString();
      cloudSaveData.mp4 = ''; //resMp4['result']['default']['url'];
      cloudSaveData.range = pickedFile.duration!.toInt() ?? 0;
      cloudSaveData.total = 0;

      ResData resCloudData = await cloudflare.save(cloudSaveData);
      if (resCloudData.code != '00') {
        Utils.alert(resCloudData.msg.toString());
        isFileUploading.value = UploadingType.FAIL;
        File(pickedFile!.path.toString()).delete();
        File(thumbnailFile!.toString()).delete();
        File(videoFile.path!.toString()).delete();
        if (needsCompression) {
          VideoCompress.deleteAllCache();
          VideoCompress.cancelCompression();
        }
        return;
      }

      // 저장
      BoardRepo boardRepo = BoardRepo();
      // boardSaveData.boardWeatherVo?.thumbnailPath = video.thumbnail;
      boardSaveData.boardWeatherVo?.thumbnailPath = video.animatedThumbnail;
      boardSaveData.boardWeatherVo?.thumbnailId = video.thumbnail;
      boardSaveData.boardWeatherVo?.videoPath = video.playback!.hls.toString();
      boardSaveData.boardWeatherVo?.videoId = video.id;
      // m3u8 파일 다운 받아 내용 저장 - m3u8 파일은 cloudflare에서 동영상 파일이 업로드 이후에 생성이 되어 배치로 받는 수 뿐이 없다.
      // String m3u8 = await downloadAndSaveM3U8File(video.playback!.hls.toString(), video.id!);
      // boardSaveData.boardWeatherVo?.thumbnailId = m3u8;

      ResData resData = await boardRepo.save(boardSaveData);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        isFileUploading.value = UploadingType.FAIL;
        File(pickedFile!.path.toString()).delete();
        File(thumbnailFile!.toString()).delete();
        File(videoFile.path!.toString()).delete();
        if (needsCompression) {
          VideoCompress.deleteAllCache();
          VideoCompress.cancelCompression();
        }
        return;
      }
      isFileUploading.value = UploadingType.SUCCESS;
      // Utils.alert('정상 등록되었습니다!');
      Future.delayed(const Duration(milliseconds: 2000), () {
        isFileUploading.value = UploadingType.NONE;
        File(pickedFile!.path.toString()).delete();
        // File(thumbnailFile!.toString()).delete();
        File(videoFile.path!.toString()).delete();
        if (needsCompression) {
          VideoCompress.deleteAllCache();
          VideoCompress.cancelCompression();
        }
      });
    } catch (e) {
      isFileUploading.value = UploadingType.FAIL;
      lo.g("ERRRRRRR=> " + e.toString());
      VideoCompress.deleteAllCache();
      VideoCompress.cancelCompression();
    }
  }

  //m3u8 파일 다운로드받아 내용을 저장하려면 다음과 같이 작성하면 됩니다.
  // 하지만 m3u8 파일은 cloudflare에서 동영상 파일이 얼로드 이후에 생성이 되어 배치로 받는 수 뿐이 없다.
  Future<String> downloadAndSaveM3U8File(String url, String fileName) async {
    final http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final String fileContent = response.body;
      return fileContent;
    } else {
      return '';
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

  // 압축여부
  //   bool needsCompression = await VideoCompressionHelper.shouldCompressVideo(videoPath);

  Future<bool> shouldCompressVideo(
    String filePath, {
    int sizeThreshold = 50 * 1024 * 1024, // 50MB
    int widthThreshold = 1920,
    int heightThreshold = 1080,
    double bitrateThreshold = 5000000, // 5 Mbps
  }) async {
    File file = File(filePath);
    int fileSize = await file.length();

    MediaInfo? mediaInfo = await VideoCompress.getMediaInfo(filePath);

    if (mediaInfo == null) {
      throw Exception('Failed to get video metadata');
    }

    int width = mediaInfo.width ?? 0;
    int height = mediaInfo.height ?? 0;

    // bitrate를 직접 계산합니다 (bps 단위)
    double bitrate = 0;
    if (mediaInfo.filesize != null && mediaInfo.duration != null) {
      // duration이 이미 초 단위일 수 있으므로, 직접 사용합니다.
      double durationInSeconds = mediaInfo.duration ?? 0;
      if (durationInSeconds > 0) {
        bitrate = (mediaInfo.filesize! * 8) / durationInSeconds;
      }
    }

    print('File size: $fileSize bytes');
    print('Resolution: ${width}x$height');
    print('Calculated bitrate: $bitrate bps');

    if (fileSize > sizeThreshold) {
      print('File size exceeds threshold');
      return true;
    }

    if (width > widthThreshold || height > heightThreshold) {
      print('Resolution exceeds threshold');
      return true;
    }

    if (bitrate > bitrateThreshold) {
      print('Bitrate exceeds threshold');
      return true;
    }

    print('Compression not needed');
    return false;
  }
}
