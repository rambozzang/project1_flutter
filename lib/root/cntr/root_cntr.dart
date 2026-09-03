import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:project1/app/achievement/service/achievement_service.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';
import 'package:project1/repo/board/weather_for_board.dart';
import 'package:project1/repo/challenge/challenge_repo.dart';
import 'package:project1/repo/challenge/data/challenge_complete_data.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/cloudflare/data/cloudflare_req_save_data.dart';
import 'package:project1/repo/cloudflare/direct_upload_repo.dart';
import 'package:project1/services/analytics_service.dart';
import 'package:project1/services/pending_upload_store.dart';
import 'package:project1/services/review_service.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/exif_util.dart';
import 'package:project1/utils/utils.dart';
import 'package:video_compress/video_compress.dart';
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

  // 카메라 진입 시 대상 모임ID(모임 홈에서 '글 올리기'로 진입하면 설정).
  // 일반 카메라 진입(하단 + 탭, 푸시 등)에서는 항상 null로 초기화되어 누수 방지.
  int? pendingCommunityId;

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

  // Cloudflare STREAM 파일 업로드 (Direct Creator Upload — 앱은 백엔드가 발급한 일회용 URL로만 업로드)
  //
  // [resume] 가 있으면 영속 큐에서 되살린 재시도다. 이때는 큐에 다시 적지 않는다 —
  // 다시 적으면 같은 영상의 사본이 두 벌 쌓인다.
  Future<void> uploadCloudflare(File videoFile, BoardSaveData boardSaveData, {PendingUpload? resume}) async {
    isFileUploading.value = UploadingType.UPLOADING;

    // 바이트를 한 개도 보내기 전에 먼저 적어둔다. 압축 중이든 전송 중이든 여기서
    // 앱이 죽으면, 다음 실행이 이 기록과 큐 폴더의 사본을 보고 이어 올린다.
    final PendingUpload? job =
        resume ?? await PendingUploadStore.enqueue(files: [videoFile], data: boardSaveData, isVideo: true);
    if (job != null) await PendingUploadStore.touch(job.id);

    // 날씨는 영상 업로드와 "병렬"로 가져온다.
    // 사용자는 게시 버튼을 누른 즉시 백그라운드 업로드로 넘어가고,
    // 느린 파일 업로드가 진행되는 동안 현위치 날씨를 받아 저장 직전에 합친다.
    final Future<BoardSaveWeatherData> weatherFuture = WeatherForBoard.fetch();

    final DirectUploadRepo directUpload = DirectUploadRepo();
    final CloudflareRepo cloudflare = CloudflareRepo();

    try {
      bool needsCompression = await shouldCompressVideo(videoFile.path);
      late MediaInfo? pickedFile;

      lo.e('shouldCompressVideo needsCompression : $needsCompression');
      if (kDebugMode && needsCompression) {
        Utils.alert('압축 진행합니다.');
      }
      try {
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
      } catch (e) {
        lo.g('비디오 압축 에러 : $e');
        if (needsCompression) {
          // VideoCompress.cancelCompression();
        }
        pickedFile = await VideoCompress.getMediaInfo(videoFile.path);
      }

      Lo.g('비디오 압축 결과 : ${pickedFile!.toJson()}');

      File uploadVideoFile = File(pickedFile.path.toString());
      // 백엔드에서 일회용 업로드 URL 발급 → 해당 URL로 직접 업로드 (앱에 Cloudflare 토큰 없음)
      final VideoUploadTicket? ticket = await directUpload.uploadVideoFile(uploadVideoFile);

      if (ticket == null) {
        Utils.alert('파일 업로드에 실패했습니다.');
        // 실패 — job 과 사본을 남긴다. 지우면 이어올릴 게 없어진다.
        _markUploadFailed('영상 업로드 티켓 발급/전송 실패', job);
        return;
      }
      CloudflareReqSaveData cloudSaveData = CloudflareReqSaveData();
      cloudSaveData.uid = ticket.uid;
      cloudSaveData.preview = ticket.preview;
      cloudSaveData.size = pickedFile.filesize;
      // 썸네일은 정적 JPG 로 저장한다. animatedThumbnail(GIF)은 한 장이 수 MB 라
      // 목록 화면에서 데이터·메모리를 크게 먹고, 정지 화면이어야 할 그리드에서 혼자 움직인다.
      cloudSaveData.thumbnail = ticket.thumbnail;
      cloudSaveData.dash = ticket.dash;
      cloudSaveData.hls = ticket.hls;
      cloudSaveData.mp4 = '';
      cloudSaveData.range = pickedFile.duration?.toInt() ?? 0;
      cloudSaveData.total = 0;

      ResData resCloudData = await cloudflare.save(cloudSaveData);
      if (resCloudData.code != '00') {
        Utils.alert(resCloudData.msg.toString());
        // 실패 경로에서는 원본/압축본을 지우지 않는다(이전엔 여기서 지워 재개 근거가 사라졌다).
        _markUploadFailed('cloudflare.save 실패: ${resCloudData.msg}', job);
        return;
      }

      // 저장 — 병렬로 받아온 날씨를 합쳐 게시한다.
      BoardRepo boardRepo = BoardRepo();
      // 업로드가 진행되는 동안 이미 날씨를 받아두었으므로 거의 즉시 반환된다.
      final BoardSaveWeatherData weatherVo = await weatherFuture;
      // 게시물 목록·지도·상세가 모두 참조하는 대표 썸네일 — 정적 JPG 로 저장한다(위와 동일한 이유).
      weatherVo.thumbnailPath = ticket.thumbnail;
      weatherVo.thumbnailId = ticket.thumbnail;
      weatherVo.videoPath = ticket.hls;
      weatherVo.videoId = ticket.uid;
      // 사용자가 선택한 체감 날씨 태그는 백그라운드 자동수집엔 없으므로 보존
      weatherVo.feelCd = boardSaveData.boardWeatherVo?.feelCd;
      boardSaveData.boardWeatherVo = weatherVo;

      // 🔎 진단: 게시 직전 실제 전송되는 내용(contents) 확인
      lo.g('📤[영상] 게시 contents="${boardSaveData.boardMastInVo?.contents}" subject="${boardSaveData.boardMastInVo?.subject}"');
      lo.g('📤[영상] payload=${boardSaveData.toJson()}');

      ResData resData = await boardRepo.save(boardSaveData);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        // 실패 경로에서는 원본/압축본을 지우지 않는다(이전엔 여기서 지워 재개 근거가 사라졌다).
        _markUploadFailed('boardRepo.save 실패: ${resData.msg}', job);
        return;
      }
      isFileUploading.value = UploadingType.SUCCESS;
      // 게시까지 끝났다 — 이제서야 큐에서 지운다(사본도 같이 사라진다).
      if (job != null) await PendingUploadStore.remove(job.id);
      // 영상 업로드 성공 계측 + 긍정적 순간 리뷰 요청(게이팅)
      AnalyticsService.instance.logContentUpload(contentType: 'video', feel: boardSaveData.boardWeatherVo?.feelCd);
      ReviewService.instance.onPositiveMoment();
      // Utils.alert('정상 등록되었습니다!');
      final String compressedPath = pickedFile.path.toString();
      Future.delayed(const Duration(milliseconds: 2000), () {
        isFileUploading.value = UploadingType.NONE;
        // 성공 경로에서만 지운다. 큐 정리로 이미 사라졌을 수 있어 조용히 처리한다.
        _deleteQuietly(compressedPath);
        _deleteQuietly(videoFile.path);
        if (needsCompression) {
          // VideoCompress.deleteAllCache();
          // VideoCompress.cancelCompression();
        }
      });
    } catch (e) {
      // 예외로 빠져나와도 job 은 남긴다 — 다음 실행에서 이어 올린다.
      _markUploadFailed('영상 업로드 예외: $e', job);
      // VideoCompress.deleteAllCache();
      // VideoCompress.cancelCompression();
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
    Future.delayed(const Duration(microseconds: 350), () {
      // Cloudflare R2 파일 업로드
      // uploadR2Storage(videoFile, boardSaveData);
      // Cloudflare Stream 파일 업로드
      uploadCloudflare(videoFile, boardSaveData);
    });
  }

  // photo_reg_page.dart 에서 호출 — 사진(다중) 업로드 후 등록 처리.
  void goTimerPhotos(List<File> photoFiles, BoardSaveData boardSaveData) {
    Future.delayed(const Duration(microseconds: 350), () {
      uploadPhotos(photoFiles, boardSaveData);
    });
  }

  // 사진(다중)을 Cloudflare Images에 업로드하고 typeDtCd='I'로 게시한다.
  // 영상 업로드(uploadCloudflare)와 동일하게 날씨는 병렬로 수집해 저장 직전에 합친다.
  //
  // [resume] 가 있으면 영속 큐에서 되살린 재시도다(영상과 동일).
  Future<void> uploadPhotos(List<File> photoFiles, BoardSaveData boardSaveData, {PendingUpload? resume}) async {
    isFileUploading.value = UploadingType.UPLOADING;

    // 영상과 같은 규칙 — 첫 바이트를 보내기 전에 먼저 적어둔다.
    final PendingUpload? job =
        resume ?? await PendingUploadStore.enqueue(files: photoFiles, data: boardSaveData, isVideo: false);
    if (job != null) await PendingUploadStore.touch(job.id);

    final Future<BoardSaveWeatherData> weatherFuture = WeatherForBoard.fetch();

    final DirectUploadRepo directUpload = DirectUploadRepo();

    try {
      final List<String> imageUrls = [];
      final List<String> imageIds = [];

      // 각 사진을 순차 업로드(안정성 우선). 백엔드가 발급한 일회용 URL로 직접 업로드.
      for (final File f in photoFiles) {
        final ImageUploadResult? res = await directUpload.uploadImageFile(f);
        if (res == null) {
          Utils.alert('사진 업로드에 실패했습니다.');
          // 실패 — job 과 사본을 남긴다. 재개 시 처음부터 다시 올린다.
          _markUploadFailed('사진 업로드 실패(${f.path})', job);
          return;
        }
        imageUrls.add(res.url);
        imageIds.add(res.id);
      }

      // 사진 EXIF 촬영일 → 게시물 대표 촬영일(capturedAt). 2a 타임라인이 이 값으로 그룹핑(없으면 서버가 업로드일 폴백).
      boardSaveData.boardMastInVo?.capturedAt = await ExifUtil.earliestCapturedAt(photoFiles);

      // 병렬 수집한 날씨를 합쳐 게시.
      final BoardSaveWeatherData weatherVo = await weatherFuture;
      weatherVo.imageUrls = imageUrls;
      weatherVo.imageIds = imageIds;
      weatherVo.thumbnailPath = imageUrls.isNotEmpty ? imageUrls.first : null; // 대표 썸네일=첫 사진
      // 사용자가 고른 체감 날씨 태그 보존
      weatherVo.feelCd = boardSaveData.boardWeatherVo?.feelCd;
      boardSaveData.boardWeatherVo = weatherVo;

      // 🔎 진단: 게시 직전 실제 전송되는 내용(contents) 확인
      lo.g('📤[사진] 게시 contents="${boardSaveData.boardMastInVo?.contents}" subject="${boardSaveData.boardMastInVo?.subject}"');
      lo.g('📤[사진] payload=${boardSaveData.toJson()}');

      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.save(boardSaveData);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        _markUploadFailed('사진 boardRepo.save 실패: ${resData.msg}', job);
        return;
      }

      isFileUploading.value = UploadingType.SUCCESS;
      // 게시까지 끝났다 — 이제서야 큐에서 지운다(사본도 같이 사라진다).
      if (job != null) await PendingUploadStore.remove(job.id);

      // 사진 업로드 성공 계측 + 긍정적 순간 리뷰 요청(게이팅)
      AnalyticsService.instance.logContentUpload(contentType: 'photo', feel: boardSaveData.boardWeatherVo?.feelCd);
      ReviewService.instance.onPositiveMoment();

      // 사진 게시도 영상 업로드와 동일하게 오늘 챌린지를 완료 처리한다.
      _completeTodayChallengeAfterUpload();

      Future.delayed(const Duration(milliseconds: 2000), () {
        isFileUploading.value = UploadingType.NONE;
      });
    } catch (e) {
      // 예외로 빠져나와도 job 은 남긴다 — 다음 실행에서 이어 올린다.
      _markUploadFailed('사진 업로드 예외: $e', job);
    }
  }

  // ───────────────────────── 업로드 영속 큐(재개) ─────────────────────────

  /// 실패 공통 처리. **job 과 큐 폴더의 사본은 절대 지우지 않는다** —
  /// 그게 아직 서버 어디에도 없는 유일본이고, 이어올릴 유일한 근거다.
  void _markUploadFailed(String reason, PendingUpload? job) {
    isFileUploading.value = UploadingType.FAIL;
    lo.g('업로드 실패 → 대기 큐 보존(job=${job?.id ?? '기록없음'}): $reason');
  }

  /// 성공 경로 전용 파일 정리. 큐 정리(remove)로 이미 사라졌거나 OS 가 먼저 지운
  /// 파일이 섞여 있어도 예외를 밖으로 내보내지 않는다 — 지우기 실패가 게시 성공을
  /// 되돌리면 안 된다. (이전에는 await/catch 없이 delete() 를 불러 파일이 없으면
  /// 처리되지 않은 비동기 예외가 났다.)
  Future<void> _deleteQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      lo.g('임시 파일 삭제 실패(무시): $path / $e');
    }
  }

  /// 재개가 겹쳐 돌지 않게 하는 빗장. 같은 job 을 두 번 올리면 게시물이 두 개 생긴다.
  bool _resumingPending = false;

  /// 대기 큐에 남은 업로드를 **순차로** 재시도한다.
  ///
  /// 순차인 이유: [isFileUploading] 이 전역 인디케이터 하나를 공유하므로 동시에
  /// 돌리면 상태가 서로를 덮어쓴다. 오래된 것부터(=[PendingUploadStore.list] 정렬)
  /// 올려야 찍은 순서대로 게시된다.
  Future<void> resumeAllPending() async {
    if (_resumingPending) return;
    if (isFileUploading.value == UploadingType.UPLOADING) return;
    _resumingPending = true;
    try {
      final jobs = await PendingUploadStore.list();
      lo.g('업로드 재개 시작: ${jobs.length}건');
      for (final job in jobs) {
        if (job.isVideo) {
          await uploadCloudflare(job.files.first, job.data, resume: job);
        } else {
          await uploadPhotos(job.files, job.data, resume: job);
        }
        // 한 건이 실패하면 멈춘다. 대개 네트워크가 없는 상황이라 남은 건까지
        // 줄줄이 실패시켜봐야 시도 횟수만 올라가고 사용자만 기다린다.
        // 남은 job 은 큐에 그대로 있으니 다음 실행에서 다시 묻는다.
        if (isFileUploading.value == UploadingType.FAIL) {
          lo.g('업로드 재개 중단 — 실패한 건이 있어 나머지는 다음 기회에');
          break;
        }
      }
    } catch (e) {
      lo.g('업로드 재개 중 오류: $e');
    } finally {
      _resumingPending = false;
    }
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
    // int sizeThreshold = 50 * 1024 * 1024, // 50MB
    // int widthThreshold = 1920,
    // int heightThreshold = 1080,
    // double bitrateThreshold = 5000000, // 5 Mbps
    int sizeThreshold = 70 * 1024 * 1024, // 60MB
    int widthThreshold = 1080,
    int heightThreshold = 1920,
    double bitrateThreshold = 7000000, // 7 Mbps
  }) async {
    File file = File(filePath);
    int fileSize = await file.length();

    MediaInfo? mediaInfo = await VideoCompress.getMediaInfo(filePath);

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
    if (fileSize > sizeThreshold) {
      return true;
    }

    // width, height 체크 더 큰게 height 으로 재설정
    int widthT = 0;
    int heightT = 0;

    if (width > height) {
      heightT = width;
      widthT = height;
    } else {
      heightT = height;
      widthT = width;
    }
    width = widthT;
    height = heightT;

    if (width > widthThreshold || height > heightThreshold) {
      return true;
    }
    if (bitrate > bitrateThreshold) {
      return true;
    }

    return false;
  }

  /// 영상 업로드 성공 후 오늘 챌린지 완료 처리
  Future<void> _completeTodayChallengeAfterUpload() async {
    // 업로드 직후, 새로 달성된 업적이 있는지 확인해 알림/배지에 반영한다.
    // (오늘 챌린지 완료 여부와 무관하게 항상 실행되도록 메서드 초반에 호출)
    if (Get.isRegistered<AchievementService>()) {
      AchievementService.to.syncAndNotify();
    }
    try {
      final custId = AuthCntr.to.custId.value;
      if (custId.isEmpty) return;

      final todayRes = await ChallengeRepo().getTodayChallenge(custId);
      if (todayRes.code != '00') return;

      final todayChallenge = ChallengeRepo.parseTodayData(todayRes.data);
      if (todayChallenge?.challengeId == null || todayChallenge?.completeYn == 'Y') return;

      final completeRes = await ChallengeRepo().completeChallenge(todayChallenge!.challengeId!, custId);
      if (completeRes.code == '00') {
        final ChallengeCompleteData? result = ChallengeRepo.parseCompleteData(completeRes.data);
        if (result?.message != null && result!.message!.isNotEmpty) {
          Utils.alertIcon(result.message!, icontype: 'S', duration: const Duration(seconds: 3));
        } else {
          Utils.alertIcon('챌린지 완료! 오늘도 출석 체크 되었어요.', icontype: 'S', duration: const Duration(seconds: 2));
        }
      }
    } catch (e) {
      lo.g('_completeTodayChallengeAfterUpload error: $e');
    }
  }
}
