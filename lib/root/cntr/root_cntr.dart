import 'dart:async';
import 'dart:io';

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
import 'package:project1/services/durable_upload.dart';
import 'package:project1/services/upload_policy.dart';
import 'package:project1/services/upload_notifier.dart';
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

  final StreamController<bool> bottomBarStreamController =
      StreamController<bool>();

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
    hideButtonController1
        .addListener(() => changeScrollListner(hideButtonController1));
    // hideButtonController11.addListener(() => changeScrollListner(hideButtonController11));
    hideButtonController12
        .addListener(() => changeScrollListner(hideButtonController12));
    hideButtonController2
        .addListener(() => changeScrollListner(hideButtonController2));
    hideButtonController3
        .addListener(() => changeScrollListner(hideButtonController3));
    hideButtonController4
        .addListener(() => changeScrollListner(hideButtonController4));
    hideButtonController5
        .addListener(() => changeScrollListner(hideButtonController5));

    super.onInit();
  }

  // 스크롤에 따라 bottom bar hide
  void changeScrollListner(ScrollController scrollData) {
    if (scrollData.position.userScrollDirection == ScrollDirection.reverse) {
      if (isVisible.value) {
        isVisible.value = false;
        bottomBarStreamController.sink.add(isVisible.value);
      }
    } else if (scrollData.position.userScrollDirection ==
        ScrollDirection.forward) {
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
  Future<void> _uploadCloudflare(File videoFile, BoardSaveData boardSaveData,
      {PendingUpload? resume}) async {
    isFileUploading.value = UploadingType.UPLOADING;

    // 바이트를 한 개도 보내기 전에 먼저 적어둔다. 압축 중이든 전송 중이든 여기서
    // 앱이 죽으면, 다음 실행이 이 기록과 큐 폴더의 사본을 보고 이어 올린다.
    final PendingUpload? job = resume ??
        await PendingUploadStore.enqueue(
            files: [videoFile], data: boardSaveData, isVideo: true);
    if (job == null) {
      _markUploadFailed('원본 보관 실패', null);
      Utils.alert('업로드 파일을 보관하지 못했습니다. 저장 공간을 확인해주세요.');
      return;
    }
    await PendingUploadStore.touch(job.id);
    final journal = UploadJournal(job);
    videoFile = job.files.first;

    // 날씨는 영상 업로드와 "병렬"로 가져온다.
    // 사용자는 게시 버튼을 누른 즉시 백그라운드 업로드로 넘어가고,
    // 느린 파일 업로드가 진행되는 동안 현위치 날씨를 받아 저장 직전에 합친다.
    final DirectUploadRepo directUpload = DirectUploadRepo();
    final CloudflareRepo cloudflare = CloudflareRepo();

    try {
      if (journal.data['published'] == true) {
        await _finishUpload(journal);
        isFileUploading.value = UploadingType.SUCCESS;
        return;
      }
      if (await _resumePublication(journal)) return;
      final Future<BoardSaveWeatherData> weatherFuture =
          WeatherForBoard.fetch();
      final ticket =
          await _uploadVideoPreferNative(directUpload, videoFile, journal);
      CloudflareReqSaveData cloudSaveData = CloudflareReqSaveData();
      cloudSaveData.uid = ticket.uid;
      cloudSaveData.preview = ticket.preview;
      cloudSaveData.size = (journal.data['videoSize'] as num?)?.toInt();
      // 썸네일은 정적 JPG 로 저장한다. animatedThumbnail(GIF)은 한 장이 수 MB 라
      // 목록 화면에서 데이터·메모리를 크게 먹고, 정지 화면이어야 할 그리드에서 혼자 움직인다.
      cloudSaveData.thumbnail = ticket.thumbnail;
      cloudSaveData.dash = ticket.dash;
      cloudSaveData.hls = ticket.hls;
      cloudSaveData.mp4 = '';
      cloudSaveData.range =
          (journal.data['videoDuration'] as num?)?.toInt() ?? 0;
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
      lo.g(
          '📤[영상] 게시 contents="${boardSaveData.boardMastInVo?.contents}" subject="${boardSaveData.boardMastInVo?.subject}"');
      lo.g('📤[영상] payload=${boardSaveData.toJson()}');

      ResData resData = await _publishUpload(boardRepo, boardSaveData, journal);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        // 실패 경로에서는 원본/압축본을 지우지 않는다(이전엔 여기서 지워 재개 근거가 사라졌다).
        _markUploadFailed('boardRepo.save 실패: ${resData.msg}', job);
        return;
      }
      isFileUploading.value = UploadingType.SUCCESS;
      // 게시까지 끝났다 — 이제서야 큐에서 지운다(사본도 같이 사라진다).
      await _finishUpload(journal);
      // 영상 업로드 성공 계측 + 긍정적 순간 리뷰 요청(게이팅)
      AnalyticsService.instance.logContentUpload(
          contentType: 'video', feel: boardSaveData.boardWeatherVo?.feelCd);
      ReviewService.instance.onPositiveMoment();
      // Utils.alert('정상 등록되었습니다!');
    } on UploadTooLargeException catch (e) {
      // 압축 뒤에도 상한을 넘는 파일은 다음 실행에 다시 올려도 결과가 같다.
      // 큐에 남기면 실행할 때마다 같은 실패를 되풀이하므로 여기서 내린다.
      await _abandonUpload(journal, '영상 크기 초과: $e');
      Utils.alert('영상이 너무 커서 올릴 수 없어요 (압축 후 ${e.megabytes}MB, '
          '최대 ${kDirectUploadMaxMegabytes}MB). 더 짧게 잘라서 올려주세요.');
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
  Future<void> _uploadPhotos(List<File> photoFiles, BoardSaveData boardSaveData,
      {PendingUpload? resume}) async {
    isFileUploading.value = UploadingType.UPLOADING;

    // 영상과 같은 규칙 — 첫 바이트를 보내기 전에 먼저 적어둔다.
    final PendingUpload? job = resume ??
        await PendingUploadStore.enqueue(
            files: photoFiles, data: boardSaveData, isVideo: false);
    if (job == null) {
      _markUploadFailed('원본 보관 실패', null);
      Utils.alert('업로드 파일을 보관하지 못했습니다. 저장 공간을 확인해주세요.');
      return;
    }
    await PendingUploadStore.touch(job.id);
    final journal = UploadJournal(job);
    photoFiles = job.files;

    final DirectUploadRepo directUpload = DirectUploadRepo();

    try {
      final List<String> imageUrls = [];
      if (journal.data['published'] == true) {
        await _finishUpload(journal);
        isFileUploading.value = UploadingType.SUCCESS;
        return;
      }
      if (await _resumePublication(journal)) return;
      final Future<BoardSaveWeatherData> weatherFuture =
          WeatherForBoard.fetch();
      final List<String> imageIds = [];

      // 각 사진을 순차 업로드(안정성 우선). 백엔드가 발급한 일회용 URL로 직접 업로드.
      // 전송 자체는 가능하면 OS 에 넘긴다 — 앱을 닫아도 이어진다.
      final List<ImageUploadResult> results =
          await _uploadPhotosPreferNative(directUpload, photoFiles, journal);
      for (final ImageUploadResult res in results) {
        imageUrls.add(res.url);
        imageIds.add(res.id);
      }

      // 사진 EXIF 촬영일 → 게시물 대표 촬영일(capturedAt). 2a 타임라인이 이 값으로 그룹핑(없으면 서버가 업로드일 폴백).
      boardSaveData.boardMastInVo?.capturedAt =
          await ExifUtil.earliestCapturedAt(photoFiles);

      // 병렬 수집한 날씨를 합쳐 게시.
      final BoardSaveWeatherData weatherVo = await weatherFuture;
      weatherVo.imageUrls = imageUrls;
      weatherVo.imageIds = imageIds;
      weatherVo.thumbnailPath =
          imageUrls.isNotEmpty ? imageUrls.first : null; // 대표 썸네일=첫 사진
      // 사용자가 고른 체감 날씨 태그 보존
      weatherVo.feelCd = boardSaveData.boardWeatherVo?.feelCd;
      boardSaveData.boardWeatherVo = weatherVo;

      // 🔎 진단: 게시 직전 실제 전송되는 내용(contents) 확인
      lo.g(
          '📤[사진] 게시 contents="${boardSaveData.boardMastInVo?.contents}" subject="${boardSaveData.boardMastInVo?.subject}"');
      lo.g('📤[사진] payload=${boardSaveData.toJson()}');

      BoardRepo boardRepo = BoardRepo();
      ResData resData = await _publishUpload(boardRepo, boardSaveData, journal);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        _markUploadFailed('사진 boardRepo.save 실패: ${resData.msg}', job);
        return;
      }

      isFileUploading.value = UploadingType.SUCCESS;
      // 게시까지 끝났다 — 이제서야 큐에서 지운다(사본도 같이 사라진다).
      await _finishUpload(journal);

      // 사진 업로드 성공 계측 + 긍정적 순간 리뷰 요청(게이팅)
      AnalyticsService.instance.logContentUpload(
          contentType: 'photo', feel: boardSaveData.boardWeatherVo?.feelCd);
      ReviewService.instance.onPositiveMoment();

      // 사진 게시도 영상 업로드와 동일하게 오늘 챌린지를 완료 처리한다.
      _completeTodayChallengeAfterUpload();
    } catch (e) {
      // 예외로 빠져나와도 job 은 남긴다 — 다음 실행에서 이어 올린다.
      _markUploadFailed('사진 업로드 예외: $e', job);
    }
  }

  DurableUpload _uploader(DirectUploadRepo repo) => DurableUpload(
        nativeAvailable: NativeBackgroundUpload.isAvailable,
        enqueue: NativeBackgroundUpload.enqueue,
        states: NativeBackgroundUpload.states,
        sendDirect: repo.uploadTicket,
      );

  // 새 업로드와 재개 업로드 모두 한 큐를 통과한다. 전역 상태/압축기가 경합하지 않는다.
  Future<void> _uploadTail = Future<void>.value();
  Timer? _uploadNoticeTimer;
  Future<void> _serialUpload(Future<void> Function() action) {
    final next = _uploadTail.then((_) async {
      _uploadNoticeTimer?.cancel();
      await action();
      // 재개/정리만 수행한 성공도 동일하게 안내를 닫는다. 다음 작업 표시를 지우지 않는다.
      if (isFileUploading.value == UploadingType.SUCCESS) {
        _uploadNoticeTimer = Timer(const Duration(seconds: 2), () {
          if (isFileUploading.value == UploadingType.SUCCESS) {
            isFileUploading.value = UploadingType.NONE;
          }
        });
      }
    });
    _uploadTail =
        next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> uploadCloudflare(File file, BoardSaveData data,
          {PendingUpload? resume}) =>
      _acceptUpload([file], data, true, resume);

  Future<void> uploadPhotos(List<File> files, BoardSaveData data,
          {PendingUpload? resume}) =>
      _acceptUpload(files, data, false, resume);

  Future<void> _acceptUpload(List<File> files, BoardSaveData data, bool video,
      PendingUpload? resume) async {
    final owner = AuthCntr.to.resLoginData.value.custId.toString();
    // 새 게시는 사용자가 게시 버튼을 누른 전면 시점이다. Android 13+ 알림 권한을 여기서
    // 묻는다 — 게시가 끝나는 백그라운드 시점에는 물을 수 없다. 기다리지 않는다(내부 try/catch).
    if (resume == null) UploadNotifier.ensureAndroidPermission();
    // 대기열 앞 작업이 오래 걸려도 새 파일은 즉시 디스크에 보관한다.
    final job = resume ??
        await PendingUploadStore.enqueue(
            files: files, data: data, isVideo: video);
    if (job == null) {
      _markUploadFailed('원본 보관 실패', null);
      Utils.alert('업로드 파일을 보관하지 못했습니다. 저장 공간을 확인해주세요.');
      return;
    }
    try {
      if (resume == null) {
        final journal = UploadJournal(job);
        journal.data['owner'] = owner;
        await journal.save();
      }
      await _serialUpload(() async {
        if (AuthCntr.to.resLoginData.value.custId.toString() != owner) {
          throw StateError('업로드 계정이 변경되었습니다.');
        }
        final current =
            (await PendingUploadStore.list()).where((j) => j.id == job.id);
        if (current.isEmpty) return; // 앞서 같은 작업이 완료되어 정리된 경우
        final restored = current.single;
        // 재개 요청의 오래된 스냅샷으로 진행 중 작업 기록을 덮어쓰지 않는다.
        final journal = UploadJournal(restored);
        if (journal.data['owner'] != null && journal.data['owner'] != owner) {
          throw StateError('업로드를 시작한 계정으로 로그인해주세요.');
        }
        if (journal.data['owner'] == null) {
          journal.data['owner'] = owner;
          await journal.save();
          restored.checkpoint['owner'] = owner;
        }
        if (video) {
          await _uploadCloudflare(restored.files.first, restored.data,
              resume: restored);
        } else {
          await _uploadPhotos(restored.files, restored.data, resume: restored);
        }
      });
    } catch (e) {
      _markUploadFailed('업로드 준비 실패: $e', job);
    }
  }

  Future<VideoUploadTicket> _uploadVideoPreferNative(
    DirectUploadRepo repo,
    File file,
    UploadJournal journal,
  ) async {
    final result = await _uploader(repo).transfer(
      journal: journal,
      slot: 'video',
      prepare: () => _prepareUploadVideo(file, journal),
      issueTicket: () async {
        final ticket = await repo.issueVideoTicket();
        if (ticket == null) throw StateError('영상 업로드 주소 발급 실패');
        return {
          'uploadUrl': ticket.uploadUrl,
          'uid': ticket.uid,
          'hls': ticket.hls,
          'dash': ticket.dash,
          'thumbnail': ticket.thumbnail,
          'animatedThumbnail': ticket.animatedThumbnail,
          'preview': ticket.preview,
        };
      },
    );
    return VideoUploadTicket.fromMap(result);
  }

  Future<File> _prepareUploadVideo(File source, UploadJournal journal) async {
    final savedPath = journal.data['preparedVideo'] as String?;
    if (savedPath != null && await File(savedPath).exists()) {
      return _ensureUploadable(File(savedPath));
    }
    final needsCompression = await shouldCompressVideo(source.path);
    MediaInfo info;
    try {
      info = needsCompression
          ? (await VideoCompress.compressVideo(source.path,
                  // 1080p 다운스케일. HighestQuality 는 해상도를 유지해 iOS 는 용량이
                  // 안 줄고 Android 는 3.7Mbps 고정으로 화질만 깨졌다(upload_policy.dart).
                  quality: VideoQuality.Res1920x1080Quality,
                  deleteOrigin: false,
                  includeAudio: true) ??
              await VideoCompress.getMediaInfo(source.path))
          : await VideoCompress.getMediaInfo(source.path);
    } catch (_) {
      info = await VideoCompress.getMediaInfo(source.path);
    }
    File prepared = File(info.path ?? source.path);
    // 압축 결과도 큐 폴더에 보관한다. Android 전송 중 임시 캐시가 사라져도 유지된다.
    if (prepared.path != source.path) {
      final temporary = prepared;
      prepared =
          await temporary.copy('${source.parent.path}/prepared-video.mp4');
      await _deleteQuietly(temporary.path);
    }
    journal.data['preparedVideo'] = prepared.path;
    journal.data['videoSize'] = await prepared.length();
    journal.data['videoDuration'] = info.duration?.toInt() ?? 0;
    await journal.save();
    return _ensureUploadable(prepared);
  }

  /// 압축을 거쳐도 [kDirectUploadMaxBytes] 를 넘으면 전송해봐야 서버가 거부한다.
  /// 재시도로 달라질 게 없으니 종료형 예외로 끊고, 호출자가 큐에서 내린다.
  Future<File> _ensureUploadable(File file) async {
    final int bytes = await file.length();
    if (bytes > kDirectUploadMaxBytes) {
      throw UploadTooLargeException(bytes);
    }
    return file;
  }

  Future<List<ImageUploadResult>> _uploadPhotosPreferNative(
    DirectUploadRepo repo,
    List<File> files,
    UploadJournal journal,
  ) async {
    final tickets = await _uploader(repo).transferMany(journal, [
      for (var i = 0; i < files.length; i++)
        UploadItem(
          slot: 'photo-$i',
          prepare: () => _prepareUploadPhoto(repo, files[i], i),
          issueTicket: () async {
            final ticket = await repo.issueImageTicket();
            if (ticket == null) throw StateError('사진 업로드 주소 발급 실패');
            return {
              'uploadUrl': ticket.uploadUrl,
              'id': ticket.id,
              'url': ticket.url
            };
          },
        ),
    ]);
    return [
      for (final ticket in tickets)
        ImageUploadResult(
            id: ticket['id'] as String, url: ticket['url'] as String),
    ];
  }

  Future<File> _prepareUploadPhoto(
      DirectUploadRepo repo, File source, int index) async {
    final saved = File('${source.parent.path}/prepared-photo-$index.png');
    if (await saved.exists()) return saved;
    final converted = await repo.convertIfHeif(source);
    if (converted.path == source.path) return source;
    // 변환 캐시가 OS에 의해 지워져도 등록된 백그라운드 전송의 파일은 남긴다.
    final staged = await converted.copy('${saved.path}.tmp');
    final result = await staged.rename(saved.path);
    await _deleteQuietly(converted.path);
    return result;
  }

  Future<void> _finishUpload(UploadJournal journal) async {
    journal.data['published'] = true;
    await journal.save();
    // 게시 완료를 먼저 영속화한다. 정리 중 종료되어도 다음 실행에서 재게시하지 않는다.
    await NativeBackgroundUpload.forget(journal.transferIds);
    await PendingUploadStore.remove(journal.job.id);
    // 큐 정리까지 끝난 뒤에 알린다. 알림을 보고 앱을 열었을 때 "올리다 만 게시물"
    // 팝업이 같이 뜨면 안 된다. 전면이면 인디케이터가 보여주므로 내부에서 건너뛴다.
    await UploadNotifier.notifyPublished(
        isVideo: journal.job.isVideo, count: journal.job.files.length);
  }

  Future<ResData> _publishUpload(
      BoardRepo repo, BoardSaveData data, UploadJournal journal) async {
    // 응답 유실 후 재시도해도 날씨/촬영일 등 본문이 달라지지 않도록 확정본을 저장한다.
    journal.data['publishPayload'] ??= data.toMap();
    await journal.save();
    final frozen = BoardSaveData.fromMap(
        Map<String, dynamic>.from(journal.data['publishPayload'] as Map));
    if (journal.data['owner'] !=
        AuthCntr.to.resLoginData.value.custId.toString()) {
      throw StateError('업로드를 시작한 계정으로 로그인해주세요.');
    }
    return repo.saveUpload(frozen, 'skysnap-${journal.job.id}');
  }

  Future<bool> _resumePublication(UploadJournal journal) async {
    final payload = journal.data['publishPayload'];
    if (payload == null) return false;
    final result = await _publishUpload(
        BoardRepo(),
        BoardSaveData.fromMap(Map<String, dynamic>.from(payload as Map)),
        journal);
    if (result.code != '00') throw StateError('게시 저장을 완료하지 못했습니다.');
    await _finishUpload(journal);
    isFileUploading.value = UploadingType.SUCCESS;
    return true;
  }

  // ───────────────────────── 업로드 영속 큐(재개) ─────────────────────────

  /// 실패 공통 처리. **job 과 큐 폴더의 사본은 절대 지우지 않는다** —
  /// 그게 아직 서버 어디에도 없는 유일본이고, 이어올릴 유일한 근거다.
  void _markUploadFailed(String reason, PendingUpload? job) {
    isFileUploading.value = UploadingType.FAIL;
    lo.g('업로드 실패 → 대기 큐 보존(job=${job?.id ?? '기록없음'}): $reason');
    if (job != null) {
      Utils.alert('업로드를 완료하지 못했습니다. 파일은 보관되어 다음 실행에서 다시 시도할 수 있어요.');
    }
  }

  /// 종료형 실패 전용. [_markUploadFailed] 와 달리 job 과 사본을 **지운다** —
  /// 재시도해도 같은 결과가 나오는 실패(파일 크기 초과 등)를 큐에 남기면
  /// 실행할 때마다 사용자에게 같은 실패를 알리게 된다. 안내는 호출자가 사유별로 띄운다.
  Future<void> _abandonUpload(UploadJournal journal, String reason) async {
    isFileUploading.value = UploadingType.FAIL;
    lo.g('업로드 포기 → 큐에서 제거(job=${journal.job.id}): $reason');
    await NativeBackgroundUpload.forget(journal.transferIds);
    await PendingUploadStore.remove(journal.job.id);
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
    _uploadNoticeTimer?.cancel();
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

  /// 압축 여부. 판단 규칙은 `upload_policy.dart` 의 [needsVideoCompression] 에 있다.
  /// 여기서는 플러그인에서 규격·비트레이트만 읽어 넘긴다.
  Future<bool> shouldCompressVideo(String filePath) async {
    final MediaInfo mediaInfo = await VideoCompress.getMediaInfo(filePath);
    // MediaInfo.duration 은 ms 다. (이전에는 초로 나눠 비트레이트가 1000분의 1로
    // 나왔고, 그래서 비트레이트 조건이 한 번도 걸리지 않았다.)
    final double durationSec = (mediaInfo.duration ?? 0) / 1000;
    final int fileSize = mediaInfo.filesize ?? await File(filePath).length();
    final double bitrate = durationSec > 0 ? fileSize * 8 / durationSec : 0;
    final bool needed = needsVideoCompression(
      width: mediaInfo.width ?? 0,
      height: mediaInfo.height ?? 0,
      bitrate: bitrate,
    );
    lo.g('압축 판단: ${mediaInfo.width}x${mediaInfo.height} '
        '${(bitrate / 1e6).toStringAsFixed(1)}Mbps '
        '${(fileSize / (1 << 20)).toStringAsFixed(0)}MB → ${needed ? '압축' : '원본'}');
    return needed;
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
      if (todayChallenge?.challengeId == null ||
          todayChallenge?.completeYn == 'Y') return;

      final completeRes = await ChallengeRepo()
          .completeChallenge(todayChallenge!.challengeId!, custId);
      if (completeRes.code == '00') {
        final ChallengeCompleteData? result =
            ChallengeRepo.parseCompleteData(completeRes.data);
        if (result?.message != null && result!.message!.isNotEmpty) {
          Utils.alertIcon(result.message!,
              icontype: 'S', duration: const Duration(seconds: 3));
        } else {
          Utils.alertIcon('챌린지 완료! 오늘도 출석 체크 되었어요.',
              icontype: 'S', duration: const Duration(seconds: 2));
        }
      }
    } catch (e) {
      lo.g('_completeTodayChallengeAfterUpload error: $e');
    }
  }
}
