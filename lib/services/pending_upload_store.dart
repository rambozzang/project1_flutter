import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/services/native_background_upload.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:uuid/uuid.dart';

/// 아직 못 올린 업로드 한 건.
class PendingUpload {
  const PendingUpload({
    required this.id,
    required this.files,
    required this.data,
    required this.isVideo,
    required this.queuedAt,
    required this.attempts,
    this.checkpoint = const {},
  });

  final String id;

  /// 큐 폴더에 복사해둔 파일. 원본이 사라져도 이건 남는다.
  final List<File> files;
  final BoardSaveData data;

  /// true 면 영상 1건(uploadCloudflare), false 면 사진 다중(uploadPhotos).
  final bool isVideo;
  final DateTime queuedAt;

  /// 시도한 횟수. 계속 실패하는 건을 가려내는 용도.
  final int attempts;
  final Map<String, dynamic> checkpoint;
}

/// 올리다 만 업로드를 기기에 남겨두는 큐.
///
/// **올리기 전에 먼저 적어두고 성공했을 때만 지운다.** 순서가 핵심이다 —
/// 올리면서 적으면 갑자기 죽었을 때 기록이 안 남는다.
///
/// 파일은 경로만 기억하지 않고 **복사해 둔다.** 갤러리·카메라가 준 파일은 임시
/// 폴더에 있어서 OS 가 언제든 지운다. 경로만 들고 있으면 이어올릴 때 파일이 없다.
///
/// 파일 **전송**은 가능하면 OS 에 넘긴다(`NativeBackgroundUpload`). 다만 티켓 발급과
/// 게시(`boardRepo.save`)는 인증이 필요해 Dart 만 할 수 있으므로, 전송이 끝난 뒤
/// 나머지는 `RootCntr.uploadCloudflare` / `uploadPhotos` 가 이어서 처리한다.
/// 네이티브 미지원 플랫폼만 Dart로 전송한다. OS 상태 조회 실패 시에는 큐를 보존한다.
///
/// checkpoint에는 파일별 티켓·전송 ID·완료 결과와 게시 단계를 저장한다.
/// 네이티브 상태는 반드시 같은 티켓의 ID로 조회하고, 게시 성공 이후에만 지운다.
class PendingUploadStore {
  PendingUploadStore._();

  /// 같은 job.json을 touch 등이 동시에 덮어쓰지 않도록 job 단위로 직렬화한다.
  /// 파일 쓰기 자체도 아래의 rename 방식으로 원자 처리한다.
  static final Map<String, Future<void>> _writeTails = {};

  /// 테스트에서만 큐 위치를 갈아끼운다. `path_provider` 는 플랫폼 채널이라
  /// `flutter test`(VM)에서 그대로는 못 쓰므로, 경로 결정만 주입 가능하게 열어둔다.
  @visibleForTesting
  static Directory? debugRootOverride;

  /// 캐시가 아니라 문서 폴더인 이유: 캐시는 OS 가 언제든 지운다.
  /// 여기 있는 건 아직 서버에 없는 유일본이라 지워지면 영상이 사라진다.
  static Future<Directory> _root() async {
    final Directory base =
        debugRootOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/pending_uploads');
    if (!await dir.exists()) await dir.create(recursive: true);
    // 큐에는 아직 서버 어디에도 없는 원본과 일회용 업로드 URL 이 들어 있다. 복원
    // 백업으로 다른 기기에 복제되지 않도록 백업 제외 속성을 건다(iOS 파일 속성 /
    // Android 는 manifest 에서 allowBackup=false 라 네이티브가 no-op 로 받는다).
    // _root() 는 자주 불리므로 실행당 한 번만 건다. 네이티브가 없는 환경(테스트)에서는
    // MissingPluginException 을 서비스가 삼키므로 조용히 지나간다.
    if (!_backupExclusionApplied) {
      _backupExclusionApplied = true;
      await NativeBackgroundUpload.excludeFromBackup(dir.path);
    }
    return dir;
  }

  static bool _backupExclusionApplied = false;

  /// 사용자에게 정리가 필요함을 알릴 때 쓰는 소프트 기준이다.
  /// 아직 서버에 없는 유일본이므로 이 수치를 넘었다고 자동 삭제하지 않는다.
  static const int maxJobs = 20;

  /// 오래된 대기 항목을 구분하는 안내 기준이다. 자동 삭제 기준이 아니다.
  static const Duration staleAfter = Duration(days: 7);

  /// 안내용 판정 — 오래 묵은 항목인가. 삭제 트리거가 아니다.
  static bool isStale(PendingUpload job, {DateTime? now}) =>
      (now ?? DateTime.now()).difference(job.queuedAt) >= staleAfter;

  /// 안내용 판정 — 큐가 소프트 상한에 닿았는가. 넘겨도 새 항목은 계속 받는다
  /// (받지 않으면 그 순간의 영상이 어디에도 남지 않는다).
  static Future<bool> isOverflowing() async => (await list()).length >= maxJobs;

  /// 업로드를 **시작하기 전에** 부른다. 원본을 큐 폴더로 복사하고 job.json 을 남긴다.
  static Future<PendingUpload?> enqueue({
    required List<File> files,
    required BoardSaveData data,
    required bool isVideo,
  }) async {
    if (files.isEmpty) return null;
    Directory? jobDir;
    try {
      final root = await _root();
      final id = const Uuid().v4();
      jobDir = Directory('${root.path}/$id');
      await jobDir.create(recursive: true);

      final names = <String>[];
      final copied = <File>[];
      for (var i = 0; i < files.length; i++) {
        final src = files[i];
        if (!await src.exists()) throw StateError('업로드 원본이 없습니다.');
        final name = 'f$i${_extOf(src.path)}';
        final dst = await src.copy('${jobDir.path}/$name');
        names.add(name);
        copied.add(dst);
      }
      if (copied.isEmpty) {
        await jobDir.delete(recursive: true);
        return null;
      }

      final queuedAt = DateTime.now();
      await _writeMapAtomically(
        File('${jobDir.path}/job.json'),
        {
          'id': id,
          'isVideo': isVideo,
          'queuedAt': queuedAt.toIso8601String(),
          'attempts': 0,
          'files': names,
          'board': jsonDecode(data.toJson()),
        },
      );

      return PendingUpload(
        id: id,
        files: copied,
        data: data,
        isVideo: isVideo,
        queuedAt: queuedAt,
        attempts: 0,
      );
    } catch (e) {
      lo.g('업로드 큐 기록 실패: $e');
      try {
        await jobDir?.delete(recursive: true);
      } catch (_) {}
      return null;
    }
  }

  /// 오래된 것부터 돌려준다 — 먼저 찍은 영상이 먼저 올라가야 자연스럽다.
  static Future<List<PendingUpload>> list() async {
    try {
      final root = await _root();
      final jobs = <PendingUpload>[];
      await for (final entry in root.list()) {
        if (entry is! Directory) continue;
        final job = await _read(entry);
        if (job != null) jobs.add(job);
      }
      jobs.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
      return jobs;
    } catch (e) {
      lo.g('업로드 큐 조회 실패: $e');
      return const [];
    }
  }

  static Future<PendingUpload?> _read(Directory dir) async {
    try {
      final meta = File('${dir.path}/job.json');
      if (!await meta.exists()) {
        // 파일 복사가 끝난 직후 종료됐을 수 있다. 메타가 없다고 유일본을 자동 삭제하면
        // 안 된다. 사용자 정리 때까지 그대로 보존한다.
        lo.g('업로드 큐 메타가 없어 항목을 보존합니다: ${dir.path}');
        return null;
      }
      final map = await _readMapWithBackup(meta);
      if (map == null) return null;
      final files = <File>[];
      for (final name in (map['files'] as List? ?? const [])) {
        final f = File('${dir.path}/$name');
        // 일부 파일이 사라져도 순번을 당기지 않는다. 다른 사진의 완료 결과와 섞이면 안 된다.
        files.add(f);
      }
      if (files.isEmpty) {
        // 올릴 파일이 하나도 안 남았으면 이 job 으로 할 수 있는 일이 없다.
        await dir.delete(recursive: true);
        return null;
      }
      return PendingUpload(
        id: map['id']?.toString() ?? dir.path.split('/').last,
        files: files,
        data: BoardSaveData.fromMap(
            Map<String, dynamic>.from(map['board'] as Map)),
        isVideo: map['isVideo'] == true,
        queuedAt: DateTime.tryParse(map['queuedAt']?.toString() ?? '') ??
            DateTime.now(),
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        checkpoint:
            Map<String, dynamic>.from(map['checkpoint'] as Map? ?? const {}),
      );
    } catch (e) {
      lo.g('업로드 큐 항목 읽기 실패(${dir.path}): $e');
      return null;
    }
  }

  /// 시도 횟수를 올린다. 실패가 반복되는 건을 알아보기 위해서다.
  static Future<void> touch(String id) async {
    try {
      await _mutate(id, (map) {
        map['attempts'] = ((map['attempts'] as num?)?.toInt() ?? 0) + 1;
      });
    } catch (e) {
      lo.g('업로드 큐 시도 기록 실패: $e');
    }
  }

  /// 전송/게시 전에 반드시 완료해야 하는 체크포인트. 저장 실패를 삼키지 않는다.
  static Future<void> saveCheckpoint(
      String id, Map<String, dynamic> checkpoint) async {
    final saved = await _mutate(id, (map) => map['checkpoint'] = checkpoint);
    if (!saved) throw StateError('업로드 진행 정보를 저장하지 못했습니다.');
  }

  /// 올라갔으면 지운다. 복사해둔 파일도 같이 사라진다.
  /// **성공을 확인한 뒤에만** 부를 것.
  static Future<void> remove(String id) async {
    try {
      final dir = Directory('${(await _root()).path}/$id');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      lo.g('업로드 큐 삭제 실패: $e');
    }
  }

  static Future<void> removeAll() async {
    for (final job in await list()) {
      await remove(job.id);
    }
  }

  /// 대기 파일은 서버에 없는 유일본일 수 있으므로 오래됐다는 이유만으로 지우지
  /// 않는다. 삭제는 재시도 안내에서 사용자가 두 번 확인한 경우에만 수행한다.
  static Future<void> purgeStale() async {
    // Intentionally empty. 자동 삭제 금지 정책은 이 메서드의 이름보다 중요하다.
    // [staleAfter]/[isStale]은 사용자에게 "오래됐다"를 알리는 데에만 쓴다.
  }

  static String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf('/');
    if (dot <= slash || dot == -1) return '';
    final ext = path.substring(dot);
    // 이상한 확장자가 파일명을 망가뜨리지 않게 막는다.
    return ext.length <= 6 ? ext : '';
  }

  /// 원자적 rename 전에는 마지막 정상본을 .bak 에 남긴다. 앱이 write 중 강제 종료돼도
  /// job.json 또는 .bak 중 하나는 완전한 JSON 으로 남아 업로드 대상을 잃지 않는다.
  static Future<void> _writeMapAtomically(File target, Map<String, dynamic> map,
      {bool keepPrevious = true}) async {
    final json = jsonEncode(map);
    if (keepPrevious && await target.exists()) {
      final previous = await target.readAsString();
      await _writeStringAtomically(File('${target.path}.bak'), previous);
    }
    await _writeStringAtomically(target, json);
  }

  static Future<void> _writeStringAtomically(File target, String value) async {
    final temp =
        File('${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
    try {
      await temp.writeAsString(value, flush: true);
      // Android/iOS의 POSIX rename 은 기존 파일을 한 번에 교체한다. delete → write 와
      // 달리 어느 순간에도 비어 있거나 반쯤 쓴 job.json 을 노출하지 않는다.
      await temp.rename(target.path);
    } finally {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
    }
  }

  static Future<Map<String, dynamic>?> _readMapWithBackup(File meta) async {
    try {
      return _decodeMap(await meta.readAsString());
    } catch (error) {
      final backup = File('${meta.path}.bak');
      try {
        final recovered = _decodeMap(await backup.readAsString());
        // 손상된 본문을 백업으로 덮어쓰지 않도록 이전본 백업은 보존한 채 복구한다.
        await _writeMapAtomically(meta, recovered, keepPrevious: false);
        lo.g('업로드 큐 메타 백업으로 복구: ${meta.parent.path} ($error)');
        return recovered;
      } catch (_) {
        lo.g('업로드 큐 항목 메타와 백업을 읽지 못해 보존합니다: ${meta.parent.path}');
        return null;
      }
    }
  }

  static Map<String, dynamic> _decodeMap(String raw) =>
      Map<String, dynamic>.from(jsonDecode(raw) as Map);

  static Future<bool> _mutate(
      String id, void Function(Map<String, dynamic> map) mutate) {
    return _serialiseJob(id, () async {
      final meta = File('${(await _root()).path}/$id/job.json');
      if (!await meta.exists()) return false;
      final map = await _readMapWithBackup(meta);
      if (map == null) return false;
      mutate(map);
      await _writeMapAtomically(meta, map);
      return true;
    });
  }

  static Future<T> _serialiseJob<T>(String id, Future<T> Function() operation) {
    final previous = _writeTails[id] ?? Future<void>.value();
    final run = previous.then((_) => operation());
    late final Future<void> tail;
    tail = run.then<void>((_) {}, onError: (_, __) {});
    _writeTails[id] = tail;
    return run.whenComplete(() {
      if (identical(_writeTails[id], tail)) _writeTails.remove(id);
    });
  }
}
