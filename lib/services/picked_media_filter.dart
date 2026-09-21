import 'dart:io';

import 'package:project1/utils/log_utils.dart';

/// 고른 파일 중 **올릴 수 없는 것**을 미리 걸러낸다.
///
/// 갤러리가 주는 경로가 늘 멀쩡한 파일을 가리키지는 않는다. iCloud·Google 포토
/// 동기화가 덜 끝났거나, 원본이 기기에 없고 썸네일만 있는 경우 **0바이트이거나
/// 아예 없는 파일**이 온다. 그대로 두면 여러 장을 다 고르고 글까지 쓴 뒤
/// **업로드 단계에서야** 실패한다 — 사용자가 제일 늦게, 제일 비싸게 알게 되는
/// 실패다.
///
/// 고르는 순간에 걸러내면 그 자리에서 알 수 있고, 나머지 사진은 그대로 올라간다.
///
/// ⚠️ **크기 상한은 두지 않는다.** 자매 앱(모모앨범)에서 "Cloudflare Images 가
/// 10MB 에서 막는다"고 알고 상한을 넣으려다, 운영 계정에 **직접 올려 확인하니
/// 9MB·11MB·15MB 가 전부 통과했다**(2026-09-20). 근거 없는 상한은 멀쩡한 사진을
/// 거절할 뿐이다. 실제로 막히는 크기를 확인하면 그때 여기에 넣는다.
class PickedMediaFilter {
  PickedMediaFilter._();

  /// 올릴 수 있는 것만 남긴다.
  ///
  /// [onSkipped] 에는 걸러진 파일 수가 넘어간다. 호출부가 안내 문구를 띄울지
  /// 정하는 데 쓴다 — 여기서 알림을 띄우지 않는 이유는, 부르는 화면마다 보여 줄
  /// 자리와 문구가 다르기 때문이다.
  static Future<List<File>> usable(
    Iterable<File> files, {
    void Function(int skipped)? onSkipped,
  }) async {
    final kept = <File>[];
    var skipped = 0;
    for (final f in files) {
      if (await _isUsable(f)) {
        kept.add(f);
      } else {
        skipped++;
      }
    }
    if (skipped > 0) {
      lo.g('올릴 수 없는 파일 $skipped개를 제외했다(없거나 0바이트).');
      onSkipped?.call(skipped);
    }
    return kept;
  }

  /// 파일 하나가 쓸 만한가. 예외는 "못 쓴다"로 본다 —
  /// 권한이 없거나 경로가 깨진 경우도 결국 업로드에서 실패한다.
  static Future<bool> _isUsable(File f) async {
    try {
      if (!await f.exists()) return false;
      return await f.length() > 0;
    } catch (e) {
      lo.g('파일 확인 실패(제외): ${f.path} — $e');
      return false;
    }
  }
}
