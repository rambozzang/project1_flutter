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
import 'package:project1/services/native_background_upload.dart';
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

/// 네이티브 전송 한 건 — 보낼 파일과 그 파일을 받을 일회용 URL.
class _NativeTransfer {
  const _NativeTransfer({required this.id, required this.file, required this.uploadUrl});

  final String id;
  final File file;
  final String uploadUrl;
}

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
      // 백엔드에서 일회용 업로드 URL 발급 → 해당 URL로 직접 업로드 (앱에 Cloudflare 토큰 없음).
      // 전송 자체는 가능하면 OS 에 넘긴다 — 앱을 닫아도 이어진다.
      final VideoUploadTicket? ticket = await _uploadVideoPreferNative(directUpload, uploadVideoFile, job);

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
      // 전송 자체는 가능하면 OS 에 넘긴다 — 앱을 닫아도 이어진다.
      final List<ImageUploadResult>? results = await _uploadPhotosPreferNative(directUpload, photoFiles, job);
      if (results == null) {
        Utils.alert('사진 업로드에 실패했습니다.');
        // 실패 — job 과 사본을 남긴다. 재개 시 처음부터 다시 올린다.
        _markUploadFailed('사진 업로드 실패(${photoFiles.length}장)', job);
        return;
      }
      for (final ImageUploadResult res in results) {
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

  // ─────────────────────── 네이티브(OS) 백그라운드 전송 ───────────────────────
  //
  // 앱을 닫아도 파일 전송이 이어지도록 **바이트 전송만** OS 에 넘긴다
  // (Android WorkManager / iOS background URLSession). 티켓 발급과 게시는 인증이
  // 필요해 Dart 만 할 수 있으므로 여기서 하고, 그 사이의 전송만 위임한다.
  //
  // 전송 성공/실패 판정은 오직 [NativeBackgroundUpload.states] 로만 한다.
  // SkySnap 백엔드에는 업로드 세션 조회 API 가 없어 서버에 되물을 방법이 없다.

  /// 폴링 간격. iOS 는 앱이 백그라운드로 가면 Dart 타이머가 멈췄다가 복귀할 때 이어진다.
  static const Duration _nativePollInterval = Duration(seconds: 2);

  /// 상태 조회가 연달아 실패한 횟수의 상한. null 은 "네이티브 저장소를 못 읽었다"는
  /// 뜻이지 "전송이 사라졌다"는 뜻이 아니라, 한 번으로 실패를 단정하지 않는다.
  static const int _nativeStateFailureLimit = 5;

  /// 무한 대기 방지용 최후 방어선. queued/running 이 보이는 동안은 OS 가 실제로
  /// 들고 있다는 뜻이므로 그 자체로는 포기하지 않는다.
  static const Duration _nativeTransferDeadline = Duration(hours: 2);

  /// 영상 한 건을 올리고 성공한 전송에 대응하는 티켓을 돌려준다.
  /// 네이티브가 없거나 실패하면 기존 Dart 업로드로 그대로 내려간다.
  Future<VideoUploadTicket?> _uploadVideoPreferNative(
    DirectUploadRepo directUpload,
    File file,
    PendingUpload? job,
  ) async {
    // 영상은 큐 사본이 아니라 **압축본**을 올려야 한다(큐에는 원본이 들어 있다).
    // 압축본은 임시 폴더에 있어 OS 가 지울 수 있는데, 그때는 네이티브가 file_missing
    // 으로 실패하고 아래 폴백이 받는다. 원본은 큐에 그대로 남아 있어 잃지 않는다.
    final VideoUploadTicket? ticket = await directUpload.issueVideoTicket();
    if (ticket != null && ticket.uploadUrl.isNotEmpty) {
      final String batchId = 'video-${job?.id ?? DateTime.now().microsecondsSinceEpoch}';
      final bool sent = await _transferViaNative(batchId, [
        _NativeTransfer(id: '$batchId-0', file: file, uploadUrl: ticket.uploadUrl),
      ]);
      if (sent) return ticket;
    }
    // 폴백 — 위 URL 은 일회용이라 재사용하지 않는다. 새 티켓을 받아 Dart 가 올린다.
    return directUpload.uploadVideoFile(file);
  }

  /// 사진 묶음을 올리고 결과를 **입력 순서대로** 돌려준다. 한 장이라도 실패하면 null.
  Future<List<ImageUploadResult>?> _uploadPhotosPreferNative(
    DirectUploadRepo directUpload,
    List<File> photoFiles,
    PendingUpload? job,
  ) async {
    // 큐 사본이 있으면 그쪽을 쓴다. 갤러리·카메라가 준 원본은 임시 폴더에 있어
    // 전송 도중 OS 가 지울 수 있다. 개수가 다르면(복사 중 일부 유실) 짝을 맞출 수
    // 없으므로 원본을 쓴다.
    final List<File> sources =
        (job != null && job.files.length == photoFiles.length) ? job.files : photoFiles;
    // heic/heif 는 png 로 바꿔 올린다. 네이티브도 같은 변환본을 써야 한다.
    final List<File> prepared = [
      for (final File f in sources) await directUpload.convertIfHeif(f),
    ];

    final String batchId = 'photo-${job?.id ?? DateTime.now().microsecondsSinceEpoch}';
    final List<ImageUploadTicket> tickets = [];
    for (var i = 0; i < prepared.length; i++) {
      final ImageUploadTicket? ticket = await directUpload.issueImageTicket();
      if (ticket == null) break;
      tickets.add(ticket);
    }
    // 한 장이라도 티켓을 못 받으면 묶음 전체를 네이티브로 넘기지 않는다.
    if (tickets.length == prepared.length) {
      final bool sent = await _transferViaNative(batchId, [
        for (var i = 0; i < prepared.length; i++)
          _NativeTransfer(id: '$batchId-$i', file: prepared[i], uploadUrl: tickets[i].uploadUrl),
      ]);
      if (sent) return [for (final ImageUploadTicket t in tickets) t.result];
    }

    // 폴백 — 위 URL 들은 일회용이라 재사용하지 않는다. 새 티켓으로 한 장씩 올린다.
    final List<ImageUploadResult> results = [];
    for (final File f in prepared) {
      final ImageUploadResult? res = await directUpload.uploadImageFile(f);
      if (res == null) return null;
      results.add(res);
    }
    return results;
  }

  /// 묶음을 네이티브 전송기에 넘기고 전부 끝날 때까지 기다린다.
  /// true 는 **모든 파일이 실제로 전송 완료**됐다는 뜻이다.
  Future<bool> _transferViaNative(String batchId, List<_NativeTransfer> items) async {
    if (items.isEmpty) return false;
    final List<String> ids = [for (final _NativeTransfer item in items) item.id];
    final bool queued = await NativeBackgroundUpload.enqueue([
      for (final _NativeTransfer item in items)
        NativeBackgroundUploadRequest(
          id: item.id,
          batchId: batchId,
          filePath: item.file.path,
          uploadUrl: item.uploadUrl,
        ),
    ]);
    // 네이티브가 없는 환경(테스트·미지원 플랫폼)은 여기서 조용히 빠진다.
    if (!queued) return false;

    try {
      return await _awaitNativeTransfer(ids);
    } finally {
      // 상태 기록만 지운다. OS 가 진행 중인 전송을 취소하지는 않는다.
      await NativeBackgroundUpload.forget(ids);
    }
  }

  /// 모든 id 가 success 가 될 때까지 폴링한다. 하나라도 종료 실패면 즉시 false.
  Future<bool> _awaitNativeTransfer(List<String> ids) async {
    final Set<String> pending = ids.toSet();
    final DateTime deadline = DateTime.now().add(_nativeTransferDeadline);
    int consecutiveUnknown = 0;

    while (pending.isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        lo.g('네이티브 전송 대기 한도 초과 — Dart 업로드로 내려갑니다(남은 ${pending.length}건)');
        return false;
      }

      final states = await NativeBackgroundUpload.states(pending.toList());
      if (states == null) {
        // 저장소를 못 읽었다. 전송이 사라졌다고 단정하면 중복 전송이 된다.
        consecutiveUnknown++;
        if (consecutiveUnknown >= _nativeStateFailureLimit) {
          lo.g('네이티브 전송 상태를 읽지 못했습니다 — Dart 업로드로 내려갑니다');
          return false;
        }
        await Future.delayed(_nativePollInterval);
        continue;
      }
      consecutiveUnknown = 0;

      for (final String id in pending.toList()) {
        final NativeBackgroundUploadState? state = states[id];
        // 조회 결과에 없으면 판정을 미루고 다음 폴링에서 다시 본다.
        if (state == null) continue;
        if (state.isSuccess) {
          pending.remove(id);
        } else if (state.isTerminalFailure) {
          lo.g('네이티브 전송 실패($id): ${state.status} ${state.error ?? ''}');
          return false;
        }
      }
      if (pending.isEmpty) break;
      await Future.delayed(_nativePollInterval);
    }
    return true;
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
