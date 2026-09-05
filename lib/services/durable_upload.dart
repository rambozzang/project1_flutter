import 'dart:convert';
import 'dart:io';

import 'package:project1/services/native_background_upload.dart';
import 'package:project1/services/pending_upload_store.dart';
import 'package:uuid/uuid.dart';

/// 게시 성공까지 유지되는 작업 기록. 파일별 전송과 게시 단계를 함께 보존한다.
class UploadJournal {
  UploadJournal(this.job)
      : data = jsonDecode(jsonEncode(job.checkpoint)) as Map<String, dynamic>;

  final PendingUpload job;
  final Map<String, dynamic> data;

  Future<void> save() => PendingUploadStore.saveCheckpoint(job.id, data);

  List<String> get transferIds => [
        ...List<String>.from(data['retiredIds'] as List? ?? []),
        for (final value in (data['files'] as Map? ?? {}).values)
          if (value is Map && value['mode'] == 'native') value['id'] as String,
      ];
}

class UploadDeferred implements Exception {
  const UploadDeferred();
  @override
  String toString() => '전송 상태를 확인하지 못했습니다. 파일을 보관했으니 다시 시도해주세요.';
}

class UploadItem {
  const UploadItem(
      {required this.slot, required this.prepare, required this.issueTicket});
  final String slot;
  final Future<File> Function() prepare;
  final Future<Map<String, dynamic>> Function() issueTicket;
}

/// 전송 ID와 티켓은 한 쌍이다. OS 등록 전에 저장하고 게시 완료 전에는 버리지 않는다.
/// 네이티브 상태가 불명확하면 새 전송을 만들지 않는다.
class DurableUpload {
  DurableUpload({
    required this.nativeAvailable,
    required this.enqueue,
    required this.states,
    required this.sendDirect,
    this.pollInterval = const Duration(seconds: 2),
    this.maxPolls = 3600,
  });

  final bool nativeAvailable;
  final Future<bool> Function(List<NativeBackgroundUploadRequest>) enqueue;
  final Future<Map<String, NativeBackgroundUploadState>?> Function(List<String>)
      states;
  final Future<bool> Function(String, File) sendDirect;
  final Duration pollInterval;
  final int maxPolls;

  Future<Map<String, dynamic>> transfer({
    required UploadJournal journal,
    required String slot,
    required Future<File> Function() prepare,
    required Future<Map<String, dynamic>> Function() issueTicket,
  }) async =>
      (await transferMany(journal, [
        UploadItem(slot: slot, prepare: prepare, issueTicket: issueTicket),
      ]))
          .single;

  Future<List<Map<String, dynamic>>> transferMany(
    UploadJournal journal,
    List<UploadItem> items,
  ) async {
    final files =
        Map<String, dynamic>.from(journal.data['files'] as Map? ?? {});
    journal.data['files'] = files;
    // 이전 버전 큐에는 티켓이 없다. 당시 OS 전송이 살아 있으면 먼저 기다린다.
    // 완료된 기존 티켓의 결과를 복구할 수 없으므로 종료 확인 뒤 새 ID로 이관한다.
    if (nativeAvailable &&
        files.isEmpty &&
        journal.job.attempts > 0 &&
        journal.data['legacyChecked'] != true) {
      final legacyIds = [
        for (var i = 0; i < items.length; i++)
          '${journal.job.isVideo ? 'video' : 'photo'}-${journal.job.id}-$i',
      ];
      for (final id in legacyIds) {
        await _wait(id);
      }
      journal.data['legacyChecked'] = true;
      journal.data['retiredIds'] = legacyIds;
      await journal.save();
    }
    final toSend = <Map<String, dynamic>>[];
    final batchId = 'batch-${const Uuid().v4()}';
    for (final item in items) {
      Map<String, dynamic>? record = files[item.slot] == null
          ? null
          : Map<String, dynamic>.from(files[item.slot] as Map);
      if (record != null) {
        files[item.slot] = record;
        if (record['status'] == 'success') continue;
        if (record['mode'] == 'native') {
          final status = await _wait(record['id'] as String);
          if (status == 'success') {
            record['status'] = 'success';
            await journal.save();
            continue;
          }
          // OS가 failed/missing을 확인한 경우에만 새 티켓을 발급한다.
          journal.data['retiredIds'] = [
            ...List<String>.from(journal.data['retiredIds'] as List? ?? []),
            record['id'] as String,
          ];
        }
      }
      final file = await item.prepare();
      final ticket = await item.issueTicket();
      final uploadUrl = ticket['uploadUrl'] as String? ?? '';
      if (uploadUrl.isEmpty) throw StateError('업로드 주소를 발급하지 못했습니다.');
      record = {
        'id': 'upload-${const Uuid().v4()}',
        'ticket': ticket,
        'path': file.path,
        'mode': nativeAvailable ? 'native' : 'direct',
        'status': 'prepared',
      };
      files[item.slot] = record;
      toSend.add(record);
    }
    // 묶음 전체 계획을 확정한 뒤 한 번에 OS에 넘긴다. 앱이 정지돼도 다음 사진을 보낸다.
    await journal.save();
    if (nativeAvailable && toSend.isNotEmpty) {
      final registered = await enqueue([
        for (final record in toSend)
          NativeBackgroundUploadRequest(
            id: record['id'] as String,
            batchId: batchId,
            filePath: record['path'] as String,
            uploadUrl: (record['ticket'] as Map)['uploadUrl'] as String,
          ),
      ]);
      if (!registered) throw const UploadDeferred();
    }
    for (final record in toSend) {
      if (nativeAvailable) {
        if (await _wait(record['id'] as String) != 'success') {
          throw StateError('파일 전송에 실패했습니다. 다시 시도해주세요.');
        }
      } else {
        if (!await sendDirect((record['ticket'] as Map)['uploadUrl'] as String,
            File(record['path'] as String))) {
          throw StateError('파일 전송에 실패했습니다. 다시 시도해주세요.');
        }
      }
      record['status'] = 'success';
      await journal.save();
    }
    return [
      for (final item in items)
        Map<String, dynamic>.from((files[item.slot] as Map)['ticket'] as Map),
    ];
  }

  Future<String> _wait(String id) async {
    var unknownCount = 0;
    for (var poll = 0; poll < maxPolls; poll++) {
      final state = (await states([id]))?[id];
      if (state == null) {
        if (++unknownCount >= 5) throw const UploadDeferred();
      } else {
        unknownCount = 0;
        if (state.isSuccess || state.isTerminalFailure) return state.status;
      }
      await Future<void>.delayed(pollInterval);
    }
    throw const UploadDeferred();
  }
}
