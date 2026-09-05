import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/services/durable_upload.dart';
import 'package:project1/services/native_background_upload.dart';
import 'package:project1/services/pending_upload_store.dart';

void main() {
  late Directory temp;
  late PendingUpload job;
  late File source;
  late Map<String, NativeBackgroundUploadState> os;
  late List<NativeBackgroundUploadRequest> requests;
  var issued = 0;
  var unknown = false;
  var rejectRegistration = false;

  Future<UploadJournal> reopen() async =>
      UploadJournal((await PendingUploadStore.list()).single);

  UploadItem item(String slot) => UploadItem(
        slot: slot,
        prepare: () async => source,
        issueTicket: () async {
          issued++;
          return {
            'uploadUrl': 'https://upload.example/$issued',
            'uid': 'media-$issued'
          };
        },
      );

  DurableUpload uploader({bool native = true, bool directOk = true}) =>
      DurableUpload(
        nativeAvailable: native,
        enqueue: (batch) async {
          // OS 등록 전에 같은 ID와 티켓이 디스크에 저장됐는지 확인한다.
          final saved = (await reopen()).data['files'] as Map;
          for (final request in batch) {
            expect(
                saved.values.any((v) =>
                    v['id'] == request.id &&
                    v['ticket']['uploadUrl'] == request.uploadUrl),
                isTrue);
          }
          requests.addAll(batch);
          return !rejectRegistration;
        },
        states: (ids) async => unknown
            ? null
            : {
                for (final id in ids)
                  id: os[id] ??
                      NativeBackgroundUploadState(id: id, status: 'missing'),
              },
        sendDirect: (_, __) async => directOk,
        pollInterval: Duration.zero,
        maxPolls: 5,
      );

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('durable_upload_test');
    PendingUploadStore.debugRootOverride = temp;
    source = File('${temp.path}/photo.jpg');
    await source.writeAsString('photo');
    job = (await PendingUploadStore.enqueue(
        files: [source], data: BoardSaveData(), isVideo: false))!;
    os = {};
    requests = [];
    issued = 0;
    unknown = false;
    rejectRegistration = false;
  });

  tearDown(() async {
    PendingUploadStore.debugRootOverride = null;
    await temp.delete(recursive: true);
  });

  test('OS 성공 후 재시작: 기존 티켓을 반환하고 재발급·재등록하지 않는다', () async {
    // 등록 응답을 받기 전에 앱이 종료된 상황.
    rejectRegistration = true;
    await expectLater(
        uploader().transferMany(UploadJournal(job), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    final original = requests.single;
    os[original.id] =
        NativeBackgroundUploadState(id: original.id, status: 'success');
    final result =
        await uploader().transferMany(await reopen(), [item('photo-0')]);
    expect(result.single['uid'], 'media-1');
    expect(issued, 1);
    expect(requests, hasLength(1));
    expect(((await reopen()).data['files'] as Map)['photo-0']['status'],
        'success');
  });

  test('상태 불명 시 기록을 보존하고 새 전송이나 폴백을 하지 않는다', () async {
    rejectRegistration = true;
    await expectLater(
        uploader().transferMany(UploadJournal(job), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    unknown = true;
    await expectLater(
        uploader().transferMany(await reopen(), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    expect(issued, 1);
    expect(requests, hasLength(1));
    expect((await reopen()).transferIds, [requests.single.id]);
  });

  test('진행 중 대기 한도에 도달해도 기록을 보존한다', () async {
    rejectRegistration = true;
    await expectLater(
        uploader().transferMany(UploadJournal(job), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    os[requests.single.id] =
        NativeBackgroundUploadState(id: requests.single.id, status: 'running');
    await expectLater(
        uploader().transferMany(await reopen(), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    expect(issued, 1);
  });

  test('명시적 실패만 새 ID와 티켓으로 재등록한다', () async {
    rejectRegistration = true;
    await expectLater(
        uploader().transferMany(UploadJournal(job), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    final old = requests.single;
    os[old.id] = NativeBackgroundUploadState(id: old.id, status: 'failed');
    await expectLater(
        uploader().transferMany(await reopen(), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    expect(issued, 2);
    expect(requests.last.id, isNot(old.id));
    expect(requests.last.uploadUrl, isNot(old.uploadUrl));
  });

  test('사진 묶음을 한 번에 등록하고 성공한 사진은 재전송하지 않는다', () async {
    rejectRegistration = true;
    final items = [item('photo-0'), item('photo-1')];
    await expectLater(uploader().transferMany(UploadJournal(job), items),
        throwsA(isA<UploadDeferred>()));
    expect(requests, hasLength(2));
    expect(requests[0].batchId, requests[1].batchId);
    os[requests[0].id] =
        NativeBackgroundUploadState(id: requests[0].id, status: 'success');
    os[requests[1].id] =
        NativeBackgroundUploadState(id: requests[1].id, status: 'failed');
    await expectLater(uploader().transferMany(await reopen(), items),
        throwsA(isA<UploadDeferred>()));
    expect(issued, 3);
    expect(requests, hasLength(3));
    expect(((await reopen()).data['files'] as Map)['photo-0']['status'],
        'success');
  });

  test('디스크 성공 기록이 있으면 OS 상태 정리 후에도 재전송하지 않는다', () async {
    final results = await uploader(native: false)
        .transferMany(UploadJournal(job), [item('photo-0')]);
    final resumed =
        await uploader().transferMany(await reopen(), [item('photo-0')]);
    expect(resumed, results);
    expect(issued, 1);
    expect(requests, isEmpty);
  });

  test('체크포인트 저장 실패 시 OS에 전송하지 않는다', () async {
    await PendingUploadStore.remove(job.id);
    await expectLater(
        uploader().transferMany(UploadJournal(job), [item('photo-0')]),
        throwsStateError);
    expect(requests, isEmpty);
  });

  test('확정 게시 본문과 완료 단계는 재시작 후에도 유지한다', () async {
    final journal = UploadJournal(job);
    journal.data['publishPayload'] = {
      'boardMastInVo': {'communityId': 77}
    };
    journal.data['published'] = true;
    await journal.save();
    final restored = await reopen();
    expect(restored.data['published'], true);
    expect(restored.data['publishPayload']['boardMastInVo']['communityId'], 77);
  });

  test('이전 버전 큐의 OS 작업이 실행 중이면 새 티켓을 발급하지 않는다', () async {
    await PendingUploadStore.touch(job.id);
    final id = 'photo-${job.id}-0';
    os[id] = NativeBackgroundUploadState(id: id, status: 'running');
    await expectLater(
        uploader().transferMany(await reopen(), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    expect(issued, 0);
    expect(requests, isEmpty);
  });

  test('이전 버전 성공 상태는 새 티켓의 성공으로 오인하지 않는다', () async {
    await PendingUploadStore.touch(job.id);
    final id = 'photo-${job.id}-0';
    os[id] = NativeBackgroundUploadState(id: id, status: 'success');
    rejectRegistration = true;
    await expectLater(
        uploader().transferMany(await reopen(), [item('photo-0')]),
        throwsA(isA<UploadDeferred>()));
    expect(issued, 1);
    expect(requests.single.id, isNot(id));
    expect(((await reopen()).data['files'] as Map)['photo-0']['status'],
        'prepared');
  });
}
