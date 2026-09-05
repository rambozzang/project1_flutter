import 'dart:io';

import 'package:flutter/services.dart';
import 'package:project1/utils/log_utils.dart';

/// OS가 소유하는 파일 전송 작업 한 건.
///
/// 업로드 URL은 Cloudflare가 발급한 일회용 URL이며 인증 비밀값은 포함하지 않는다.
/// 파일은 되도록 PendingUploadStore의 문서 폴더 복사본을 가리켜야 한다 — 임시 폴더의
/// 원본은 전송 도중 OS가 지울 수 있다.
class NativeBackgroundUploadRequest {
  const NativeBackgroundUploadRequest({
    required this.id,
    required this.batchId,
    required this.filePath,
    required this.uploadUrl,
    this.protocol = 'multipart',
    this.uploadLength,
  });

  final String id;

  /// 같은 게시물의 사진은 플랫폼 전송기에서 순서대로 처리한다.
  final String batchId;
  final String filePath;
  final String uploadUrl;

  /// SkySnap은 Cloudflare Direct Creator Upload를 multipart POST로만 쓴다.
  /// 네이티브에 tus 경로가 함께 있지만 이 앱에서는 쓰지 않는다.
  final String protocol;
  final int? uploadLength;

  Map<String, Object> toMap() => {
        'id': id,
        'batchId': batchId,
        'filePath': filePath,
        'uploadUrl': uploadUrl,
        'protocol': protocol,
        'uploadLength': uploadLength ?? File(filePath).lengthSync(),
      };
}

class NativeBackgroundUploadState {
  const NativeBackgroundUploadState({
    required this.id,
    required this.status,
    this.error,
  });

  final String id;

  /// queued | running | success | failed | missing
  final String status;
  final String? error;

  bool get isSuccess => status == 'success';
  bool get isTerminalFailure => status == 'failed' || status == 'missing';
}

/// Android WorkManager / iOS background URLSession으로 직접 업로드를 넘긴다.
///
/// Dart isolate가 멈추거나 앱 UI가 사라져도 네이티브 OS 작업은 계속된다. 단,
/// Android의 사용자가 설정에서 "강제 종료"하거나 iOS에서 앱을 직접 쓸어 종료한
/// 경우는 OS 정책상 다음 실행 전까지 백그라운드 재실행을 보장할 수 없다. 이 경우에도
/// 기존 영속 큐가 남아 다음 앱 실행 때 이어서 전송한다.
class NativeBackgroundUpload {
  NativeBackgroundUpload._();

  static const _channel = MethodChannel('com.skysnap/background_upload');

  static bool get isAvailable => Platform.isAndroid || Platform.isIOS;

  static Future<bool> enqueue(
      List<NativeBackgroundUploadRequest> requests) async {
    if (!isAvailable || requests.isEmpty) return false;
    try {
      await _channel.invokeMethod<void>('enqueue', {
        'uploads': requests.map((request) => request.toMap()).toList(),
      });
      return true;
    } on MissingPluginException {
      // 호출 실패만으로 OS 등록 여부를 단정하지 않는다. 상위 큐가 기록을 보존한다.
      return false;
    } on PlatformException catch (e) {
      lo.g('네이티브 백그라운드 업로드 등록 실패: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      lo.g('네이티브 백그라운드 업로드 등록 오류: $e');
      return false;
    }
  }

  /// null은 네이티브 상태 저장소 자체를 읽지 못했다는 뜻이다. 이 경우 전송이
  /// 실제로 사라졌다고 단정하면 기존 Dart 업로더와 중복 전송될 수 있다.
  static Future<Map<String, NativeBackgroundUploadState>?> states(
      List<String> ids) async {
    if (!isAvailable) return null;
    if (ids.isEmpty) return const {};
    try {
      final raw =
          await _channel.invokeMethod<List<dynamic>>('states', {'ids': ids});
      final states = <String, NativeBackgroundUploadState>{};
      for (final value in raw ?? const <dynamic>[]) {
        if (value is! Map) continue;
        final map = Map<Object?, Object?>.from(value);
        final id = map['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        states[id] = NativeBackgroundUploadState(
          id: id,
          status: map['status']?.toString() ?? 'unknown',
          error: map['error']?.toString(),
        );
      }
      return states;
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      lo.g('네이티브 백그라운드 업로드 상태 조회 실패: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      lo.g('네이티브 백그라운드 업로드 상태 조회 오류: $e');
      return null;
    }
  }

  /// 완료/실패 상태는 게시물 저장이 끝난 뒤 지운다. OS의 전송 자체는 취소하지 않는다.
  static Future<void> forget(List<String> ids) async {
    if (!isAvailable || ids.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('forget', {'ids': ids});
    } on MissingPluginException {
      // 개발 환경은 상태 저장소가 없으므로 무시한다.
    } on PlatformException catch (e) {
      lo.g('네이티브 백그라운드 업로드 상태 정리 실패: ${e.code} ${e.message}');
    } catch (e) {
      lo.g('네이티브 백그라운드 업로드 상태 정리 오류: $e');
    }
  }

  /// 대기 큐에는 아직 서버에 없는 원본과 일회용 URL이 들어 있다. 복원 백업으로
  /// 다른 기기에 복제되지 않도록 플랫폼별 백업 제외 속성을 적용한다.
  static Future<void> excludeFromBackup(String path) async {
    if (!isAvailable || path.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', {'path': path});
    } on MissingPluginException {
      // 테스트/지원하지 않는 플랫폼은 백업 대상이 아니다.
    } on PlatformException catch (e) {
      lo.g('대기 업로드 백업 제외 설정 실패: ${e.code} ${e.message}');
    } catch (e) {
      lo.g('대기 업로드 백업 제외 설정 오류: $e');
    }
  }
}
