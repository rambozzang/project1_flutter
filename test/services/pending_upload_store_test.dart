import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_save_main_data.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';
import 'package:project1/services/pending_upload_store.dart';

/// 업로드 영속 큐 테스트.
///
/// `path_provider` 는 플랫폼 채널이라 `flutter test`(VM)에서 그대로는 못 쓴다.
/// 그래서 저장소가 열어둔 [PendingUploadStore.debugRootOverride] 로 큐 위치만
/// 임시 폴더로 갈아끼우고, 파일 복사·job.json 쓰기·삭제는 **실제로** 돌린다.
/// (경로 결정만 대체했을 뿐 검증 대상 로직은 프로덕션 코드 그대로다.)
void main() {
  late Directory tmp;

  /// 큐에 넣을 원본 파일을 흉내낸다 — 카메라/갤러리가 주는 임시 파일 자리.
  Future<File> makeSource(String name, String body) async {
    final f = File('${tmp.path}/src/$name');
    await f.parent.create(recursive: true);
    await f.writeAsString(body, flush: true);
    return f;
  }

  BoardSaveData makeBoard(
          {int? communityId, String? capturedAt, String? feelCd}) =>
      BoardSaveData()
        ..boardMastInVo = (BoardSaveMainData()
          ..contents = '오늘 하늘'
          ..typeCd = 'V'
          ..typeDtCd = 'I'
          ..anonyYn = 'N'
          ..hideYn = 'N'
          ..communityId = communityId
          ..capturedAt = capturedAt)
        ..boardWeatherVo = (BoardSaveWeatherData()..feelCd = feelCd);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pending_upload_store_test');
    PendingUploadStore.debugRootOverride = tmp;
  });

  tearDown(() async {
    PendingUploadStore.debugRootOverride = null;
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('enqueue / list 왕복', () {
    test('넣은 job 을 그대로 되읽는다', () async {
      final src = await makeSource('a.mp4', 'video-bytes');
      final job = await PendingUploadStore.enqueue(
        files: [src],
        data: makeBoard(feelCd: 'SUNNY'),
        isVideo: true,
      );

      expect(job, isNotNull);
      expect(job!.attempts, 0);
      expect(job.isVideo, isTrue);

      final listed = await PendingUploadStore.list();
      expect(listed, hasLength(1));
      expect(listed.first.id, job.id);
      expect(listed.first.isVideo, isTrue);
      expect(listed.first.attempts, 0);
      expect(listed.first.files, hasLength(1));
      expect(await listed.first.files.first.readAsString(), 'video-bytes');
      expect(listed.first.data.boardMastInVo?.contents, '오늘 하늘');
      expect(listed.first.data.boardWeatherVo?.feelCd, 'SUNNY');
    });

    test('모임ID·촬영일이 왕복에서 살아남는다 — 이어올릴 때 모임 게시물이 전체 피드로 새면 안 된다', () async {
      final src = await makeSource('a.jpg', 'photo');
      await PendingUploadStore.enqueue(
        files: [src],
        data: makeBoard(communityId: 77, capturedAt: '2026-08-30T10:11:12'),
        isVideo: false,
      );

      final restored = (await PendingUploadStore.list()).single.data;
      expect(restored.boardMastInVo?.communityId, 77);
      expect(restored.boardMastInVo?.capturedAt, '2026-08-30T10:11:12');
    });

    test('사진 다중은 순서대로 전부 복사된다', () async {
      final files = [
        await makeSource('p0.jpg', 'one'),
        await makeSource('p1.jpg', 'two'),
        await makeSource('p2.jpg', 'three'),
      ];
      await PendingUploadStore.enqueue(
          files: files, data: makeBoard(), isVideo: false);

      final listed = (await PendingUploadStore.list()).single;
      expect(listed.isVideo, isFalse);
      expect(
        await Future.wait(listed.files.map((f) => f.readAsString())),
        ['one', 'two', 'three'],
      );
    });

    test('원본이 사라져도 큐 사본은 남는다 — 이게 경로가 아니라 복사를 하는 이유다', () async {
      final src = await makeSource('a.mp4', 'video-bytes');
      await PendingUploadStore.enqueue(
          files: [src], data: makeBoard(), isVideo: true);

      // OS 가 임시 폴더를 비운 상황.
      await src.delete();

      final listed = await PendingUploadStore.list();
      expect(listed, hasLength(1));
      expect(await listed.single.files.single.readAsString(), 'video-bytes');
    });

    test('빈 목록과 존재하지 않는 파일은 job 을 만들지 않는다', () async {
      expect(
          await PendingUploadStore.enqueue(
              files: [], data: makeBoard(), isVideo: true),
          isNull);

      final ghost = File('${tmp.path}/src/없는파일.mp4');
      expect(
          await PendingUploadStore.enqueue(
              files: [ghost], data: makeBoard(), isVideo: true),
          isNull);
      expect(await PendingUploadStore.list(), isEmpty);
    });

    test('오래된 것부터 돌려준다 — 찍은 순서대로 올라가야 한다', () async {
      final first = await PendingUploadStore.enqueue(
          files: [await makeSource('1.jpg', '1')],
          data: makeBoard(),
          isVideo: false);
      final second = await PendingUploadStore.enqueue(
          files: [await makeSource('2.jpg', '2')],
          data: makeBoard(),
          isVideo: false);

      final ids = (await PendingUploadStore.list()).map((j) => j.id).toList();
      expect(ids, [first!.id, second!.id]);
    });

    test('여러 원본 중 하나가 없으면 일부 사진만 접수하지 않는다', () async {
      final first = await makeSource('first.jpg', 'first');
      final missing = File('${tmp.path}/src/missing.jpg');
      final job = await PendingUploadStore.enqueue(
          files: [first, missing], data: makeBoard(), isVideo: false);
      expect(job, isNull);
      expect(await PendingUploadStore.list(), isEmpty);
      expect(await first.readAsString(), 'first');
    });

    test('보관 파일이 사라져도 슬롯을 제거하여 사진 순서를 바꾸지 않는다', () async {
      final job = (await PendingUploadStore.enqueue(files: [
        await makeSource('first.jpg', 'first'),
        await makeSource('second.jpg', 'second'),
      ], data: makeBoard(), isVideo: false))!;
      await job.files.first.delete();
      final restored = (await PendingUploadStore.list()).single;
      expect(restored.files, hasLength(2));
      expect(restored.files.first.path, job.files.first.path);
      expect(await restored.files.first.exists(), isFalse);
      expect(await restored.files[1].readAsString(), 'second');
    });
  });

  group('job.json 쓰기', () {
    test('원자적 쓰기 — 임시(.tmp) 파일을 남기지 않고 유효한 JSON 만 남는다', () async {
      final src = await makeSource('a.mp4', 'v');
      final job = await PendingUploadStore.enqueue(
          files: [src], data: makeBoard(), isVideo: true);
      await PendingUploadStore.touch(job!.id);

      final jobDir = Directory('${tmp.path}/pending_uploads/${job.id}');
      final names =
          await jobDir.list().map((e) => e.path.split('/').last).toList();
      expect(names.where((n) => n.endsWith('.tmp')), isEmpty,
          reason: '임시 파일이 남으면 원자적 교체가 안 된 것');

      final map =
          jsonDecode(await File('${jobDir.path}/job.json').readAsString())
              as Map<String, dynamic>;
      expect(map['id'], job.id);
      expect(map['isVideo'], true);
      expect(map['files'], ['f0.mp4']);
    });

    test('touch 는 시도 횟수를 올린다', () async {
      final src = await makeSource('a.mp4', 'v');
      final job = await PendingUploadStore.enqueue(
          files: [src], data: makeBoard(), isVideo: true);

      await PendingUploadStore.touch(job!.id);
      expect((await PendingUploadStore.list()).single.attempts, 1);

      await PendingUploadStore.touch(job.id);
      await PendingUploadStore.touch(job.id);
      expect((await PendingUploadStore.list()).single.attempts, 3);
    });

    test('touch 가 겹쳐도 카운트를 잃지 않는다 — job 단위 쓰기 직렬화', () async {
      final src = await makeSource('a.mp4', 'v');
      final job = await PendingUploadStore.enqueue(
          files: [src], data: makeBoard(), isVideo: true);

      await Future.wait(
          List.generate(5, (_) => PendingUploadStore.touch(job!.id)));
      expect((await PendingUploadStore.list()).single.attempts, 5);
    });

    test('job.json 이 깨져도 .bak 으로 복구한다', () async {
      final src = await makeSource('a.mp4', 'v');
      final job = await PendingUploadStore.enqueue(
          files: [src], data: makeBoard(), isVideo: true);
      // .bak 이 생기려면 한 번 더 써야 한다(첫 쓰기는 이전본이 없다).
      await PendingUploadStore.touch(job!.id);

      final meta = File('${tmp.path}/pending_uploads/${job.id}/job.json');
      await meta.writeAsString('{반쯤 쓰다 만', flush: true);

      final listed = await PendingUploadStore.list();
      expect(listed, hasLength(1), reason: '백업이 있으면 항목을 잃지 않아야 한다');
      expect(listed.single.id, job.id);
      // 복구본은 .bak 시점(= touch 이전, attempts 0)이다.
      expect(listed.single.attempts, 0);
    });

    test('메타가 아예 없으면 자동 삭제하지 않고 보존한다 — 서버에 없는 유일본이다', () async {
      final src = await makeSource('a.mp4', 'v');
      final job = await PendingUploadStore.enqueue(
          files: [src], data: makeBoard(), isVideo: true);
      final jobDir = Directory('${tmp.path}/pending_uploads/${job!.id}');
      await File('${jobDir.path}/job.json').delete();

      // 목록엔 안 나오지만(복원할 정보가 없다) 파일은 그대로 남아 있어야 한다.
      expect(await PendingUploadStore.list(), isEmpty);
      expect(await jobDir.exists(), isTrue);
      expect(await File('${jobDir.path}/f0.mp4').exists(), isTrue);
    });
  });

  group('remove / removeAll', () {
    test('remove 는 job 과 복사본을 함께 지운다', () async {
      final src = await makeSource('a.mp4', 'v');
      final job = await PendingUploadStore.enqueue(
          files: [src], data: makeBoard(), isVideo: true);

      await PendingUploadStore.remove(job!.id);

      expect(await PendingUploadStore.list(), isEmpty);
      expect(await Directory('${tmp.path}/pending_uploads/${job.id}').exists(),
          isFalse);
    });

    test('없는 id 를 지워도 던지지 않는다', () async {
      await PendingUploadStore.remove('존재하지-않는-id');
      expect(await PendingUploadStore.list(), isEmpty);
    });

    test('removeAll 은 전부 비운다', () async {
      await PendingUploadStore.enqueue(
          files: [await makeSource('1.jpg', '1')],
          data: makeBoard(),
          isVideo: false);
      await PendingUploadStore.enqueue(
          files: [await makeSource('2.jpg', '2')],
          data: makeBoard(),
          isVideo: false);
      expect(await PendingUploadStore.list(), hasLength(2));

      await PendingUploadStore.removeAll();
      expect(await PendingUploadStore.list(), isEmpty);
    });
  });

  group('staleAfter / maxJobs — 안내용 기준(자동 삭제 아님)', () {
    PendingUpload jobQueuedAt(DateTime at) => PendingUpload(
          id: 'x',
          files: const [],
          data: BoardSaveData(),
          isVideo: true,
          queuedAt: at,
          attempts: 0,
        );

    test('staleAfter 경계 — 딱 7일이면 오래된 것으로 본다', () {
      final now = DateTime(2026, 9, 3, 12);
      expect(PendingUploadStore.staleAfter, const Duration(days: 7));

      expect(
          PendingUploadStore.isStale(
              jobQueuedAt(now.subtract(const Duration(days: 7))),
              now: now),
          isTrue);
      expect(
        PendingUploadStore.isStale(
            jobQueuedAt(now.subtract(
                const Duration(days: 7) - const Duration(seconds: 1))),
            now: now),
        isFalse,
      );
      expect(
          PendingUploadStore.isStale(
              jobQueuedAt(now.subtract(const Duration(days: 30))),
              now: now),
          isTrue);
      expect(PendingUploadStore.isStale(jobQueuedAt(now), now: now), isFalse);
    });

    test('오래된 항목도 purgeStale 이 지우지 않는다 — 자동 삭제 금지 정책', () async {
      final src = await makeSource('a.mp4', 'v');
      await PendingUploadStore.enqueue(
          files: [src], data: makeBoard(), isVideo: true);

      await PendingUploadStore.purgeStale();

      expect(await PendingUploadStore.list(), hasLength(1));
    });

    test('maxJobs 경계 — 19건은 아니고 20건부터 넘친 것으로 본다', () async {
      expect(PendingUploadStore.maxJobs, 20);

      for (var i = 0; i < PendingUploadStore.maxJobs - 1; i++) {
        await PendingUploadStore.enqueue(
          files: [await makeSource('f$i.jpg', '$i')],
          data: makeBoard(),
          isVideo: false,
        );
      }
      expect(await PendingUploadStore.list(), hasLength(19));
      expect(await PendingUploadStore.isOverflowing(), isFalse);

      await PendingUploadStore.enqueue(
          files: [await makeSource('f19.jpg', '19')],
          data: makeBoard(),
          isVideo: false);
      expect(await PendingUploadStore.isOverflowing(), isTrue);
    });

    test('상한을 넘겨도 새 항목을 거절하지 않는다 — 거절하면 그 영상이 어디에도 안 남는다', () async {
      for (var i = 0; i <= PendingUploadStore.maxJobs; i++) {
        await PendingUploadStore.enqueue(
          files: [await makeSource('f$i.jpg', '$i')],
          data: makeBoard(),
          isVideo: false,
        );
      }
      final extra = await PendingUploadStore.enqueue(
        files: [await makeSource('extra.jpg', 'extra')],
        data: makeBoard(),
        isVideo: false,
      );
      expect(extra, isNotNull);
      expect(await PendingUploadStore.list(),
          hasLength(PendingUploadStore.maxJobs + 2));
    });
  });
}
