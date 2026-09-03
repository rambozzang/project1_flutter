import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/services/pending_upload_store.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 올리다 만 업로드가 있으면 "이어서 올릴까요?" 를 묻는다.
///
/// 앱 부트 시퀀스(RootPage) 맨 끝에서 부른다 — 버전/강제 업데이트 안내 다음.
/// 다이얼로그가 겹치면 사용자가 업데이트 안내를 놓친다.
///
/// 앱의 기존 다이얼로그(`Utils.showConfirmDialog`)를 그대로 쓴다. BotToast 기반이라
/// BuildContext 없이 뜨고, 라우트가 바뀌어도(crossPage) 살아 있다.
class PendingUploadPrompt {
  PendingUploadPrompt._();

  static Future<void> showIfAny() async {
    // 자동 삭제는 하지 않는다(정책). 호출 자리만 지켜둔다.
    await PendingUploadStore.purgeStale();

    if (!Get.isRegistered<RootCntr>()) return;

    final jobs = await PendingUploadStore.list();
    if (jobs.isEmpty) return;

    // 이미 뭔가 올리는 중이면 끼어들지 않는다 — 다음 실행에서 다시 묻는다.
    if (RootCntr.to.isFileUploading.value == UploadingType.UPLOADING) return;

    final int count = jobs.length;
    final bool hasStale = jobs.any(PendingUploadStore.isStale);
    lo.g('대기 중인 업로드 $count건 발견(오래된 항목 포함=$hasStale)');

    final String detail = hasStale
        ? '$count건이 아직 올라가지 않았습니다. 일부는 올린 지 오래된 항목입니다.\n지금 이어서 올릴까요?'
        : '$count건이 아직 올라가지 않았습니다.\n지금 이어서 올릴까요?';

    Utils.showConfirmDialog(
      '올리다 만 게시물이 있어요',
      detail,
      BackButtonBehavior.none,
      confirm: () {
        // 기다리지 않는다 — 진행 상황은 전역 인디케이터(isFileUploading)가 보여주고,
        // 홈은 바로 쓸 수 있어야 한다.
        RootCntr.to.resumeAllPending();
      },
      cancel: () => _confirmDiscard(count),
      // 배경 탭으로 닫으면 아무것도 하지 않는다. 다음 실행에서 다시 묻는다.
      backgroundReturn: () {},
    );
  }

  /// 지우는 쪽은 한 번 더 묻는다. 큐에 있는 파일은 **아직 서버에 없는 유일본**이라
  /// 한 번의 오탭으로 사라지면 되돌릴 방법이 없다.
  static void _confirmDiscard(int count) {
    Utils.showConfirmDialog(
      '대기 중인 게시물을 삭제할까요?',
      '$count건은 이 기기에만 있고 아직 서버에 올라가지 않았습니다. '
          '삭제하면 되돌릴 수 없습니다.\n[취소]를 누르면 그대로 두고 다음에 다시 여쭤봅니다.',
      BackButtonBehavior.none,
      confirm: () async {
        await PendingUploadStore.removeAll();
        Utils.alert('대기 중이던 게시물을 삭제했습니다.');
      },
      // 취소 = 그대로 둔다. 이 다이얼로그의 어떤 경로도 사용자가 명시로 확인하지 않으면 지우지 않는다.
      cancel: () {},
      backgroundReturn: () {},
    );
  }
}
