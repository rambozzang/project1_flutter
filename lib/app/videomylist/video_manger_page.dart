import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_update_data.dart';
import 'package:project1/app/community/widget/album_target_selector.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';

/// 내 게시물 관리 바텀시트 (내정보 > 내 영상 상세의 '...' 버튼).
///
/// 2026-07-06 전면 개편:
/// - 시트 높이 375px 고정 → 화면의 90%.
/// - 숨기기/익명은 "무엇이 달라지는지" 설명이 붙은 카드 타일 + 스위치.
/// - 삭제는 스위치(켜고 수정완료를 눌러야 하는 혼란) → 명시적 버튼 + 확인 다이얼로그.
///   (기존엔 확인 전에 시트를 먼저 닫아 isDelete 반환이 유실되던 버그도 있었음)
class VideoManagePageSheet {
  Future<dynamic> open(BuildContext context, String boardId, String hideYn, String anonyYn, String contents,
      {int? communityId}) async {
    Map<String, dynamic>? returnMap = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      backgroundColor: const Color(0xFF17181C),
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
              // 화면의 90% 높이로 크게 연다(키보드가 올라오면 viewInsets만큼 위로 밀림).
              height: MediaQuery.of(context).size.height * 0.9,
              child: VideoManagePage(
                contextParent: context,
                boardId: boardId,
                hideYn: hideYn,
                anonyYn: anonyYn,
                contents: contents,
                communityId: communityId,
              )),
        );
      },
    );
    return returnMap;
  }
}

class VideoManagePage extends StatefulWidget {
  const VideoManagePage({
    super.key,
    required this.contextParent,
    required this.boardId,
    required this.hideYn,
    required this.anonyYn,
    required this.contents,
    this.communityId,
  });
  final BuildContext contextParent;
  final String boardId;
  final String hideYn;
  final String anonyYn;
  final String contents;
  final int? communityId;

  @override
  State<VideoManagePage> createState() => _VideoManagePageState();
}

class _VideoManagePageState extends State<VideoManagePage> {
  static const Color _surface = Color(0xFF23252C);
  static const Color _accent = CupertinoColors.activeOrange;

  final ValueNotifier<bool> isHide = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAnony = ValueNotifier<bool>(false);
  // 내용/스위치가 원래 값에서 바뀌었을 때만 저장 버튼 활성화.
  final ValueNotifier<bool> isModify = ValueNotifier<bool>(false);
  // 게시 대상 앨범ID(null=전체 피드). 원래 값(widget.communityId)에서 바뀌면 저장 활성화.
  int? _communityId;

  final TextEditingController textController = TextEditingController();
  final FocusNode currentTextNode = FocusNode();

  @override
  void initState() {
    super.initState();
    isHide.value = widget.hideYn == 'Y';
    isAnony.value = widget.anonyYn == 'Y';
    _communityId = widget.communityId;
    textController.text = widget.contents;
    textController.addListener(_checkModification);
  }

  @override
  void dispose() {
    textController.removeListener(_checkModification);
    textController.dispose();
    currentTextNode.dispose();
    isHide.dispose();
    isAnony.dispose();
    isModify.dispose();
    super.dispose();
  }

  void _checkModification() {
    isModify.value = textController.text != widget.contents ||
        isHide.value != (widget.hideYn == 'Y') ||
        isAnony.value != (widget.anonyYn == 'Y') ||
        _communityId != widget.communityId;
  }

  /// 숨기기/익명/내용 수정 저장.
  Future<void> save() async {
    try {
      BoardRepo repo = BoardRepo();
      BoardUpdateData boardUpdateData = BoardUpdateData();
      boardUpdateData.boardId = widget.boardId;
      boardUpdateData.hideYn = isHide.value ? 'Y' : 'N';
      boardUpdateData.anonyYn = isAnony.value ? 'Y' : 'N';
      boardUpdateData.contents = textController.text;
      if (_communityId != widget.communityId) {
        boardUpdateData.communityId = (_communityId ?? 0).toString(); // '0'=전체 피드로 이동
      }
      ResData res = await repo.updateBoard(boardUpdateData);
      if (res.code == '00') {
        Utils.alert('수정 되었습니다.');
        if (!mounted) return;
        Map<String, dynamic> returnMap = <String, dynamic>{};
        returnMap['contents'] = textController.text;
        returnMap['hideYn'] = isHide.value ? 'Y' : 'N';
        returnMap['anonyYn'] = isAnony.value ? 'Y' : 'N';
        returnMap['boardId'] = widget.boardId;
        returnMap['communityId'] = _communityId;
        Navigator.pop(context, returnMap);
      } else {
        Utils.alert('수정 중 에러가 발생했습니다.${res.msg}');
      }
    } catch (e) {
      Utils.alert('저장시 에러가 발생했습니다.');
    }
  }

  /// 삭제 — 확인 다이얼로그 후 즉시 처리하고, 시트를 isDelete와 함께 닫는다.
  Future<void> _delete() async {
    Utils.showConfirmDialog('게시물 삭제', '이 게시물을 영구적으로 삭제할까요?\n삭제 후에는 되돌릴 수 없어요.', BackButtonBehavior.none,
        cancel: () {}, confirm: () async {
      try {
        BoardUpdateData boardUpdateData = BoardUpdateData();
        boardUpdateData.boardId = widget.boardId;
        boardUpdateData.delYn = 'Y';
        ResData res = await BoardRepo().updateBoard(boardUpdateData);
        lo.g('res ${res.toString()}');
        if (res.code == '00') {
          Utils.alert('삭제되었습니다.');
          if (mounted) {
            Navigator.pop(context, <String, dynamic>{'isDelete': 'Y'});
          }
        } else {
          Utils.alert('삭제 중 에러가 발생했습니다.${res.msg}');
        }
      } catch (e) {
        lo.g('삭제 중 에러 ${e.toString()}');
        Utils.alert('삭제 중 에러가 발생했습니다.');
      }
    }, backgroundReturn: () {});
  }

  /// 커서 위치에 ' #'를 삽입(앞이 공백이면 '#'만)하고 포커스를 준다.
  void _insertHashTag() {
    final currentText = textController.text;
    final TextSelection selection = textController.selection;
    final int cursorPosition = selection.base.offset;

    String newText;
    int newCursorPosition;

    if (cursorPosition >= 0 && cursorPosition <= currentText.length) {
      if (cursorPosition == 0 || currentText[cursorPosition - 1] != ' ') {
        newText = currentText.replaceRange(cursorPosition, cursorPosition, ' #');
        newCursorPosition = cursorPosition + 2;
      } else {
        newText = currentText.replaceRange(cursorPosition, cursorPosition, '#');
        newCursorPosition = cursorPosition + 1;
      }
    } else {
      if (currentText.isNotEmpty && !currentText.endsWith(' ')) {
        newText = '$currentText #';
        newCursorPosition = newText.length;
      } else {
        newText = '$currentText#';
        newCursorPosition = newText.length;
      }
    }

    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
    FocusScope.of(context).requestFocus(currentTextNode);
    _checkModification();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 헤더: 그랩바 + 제목 + 닫기 ──
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(100)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
          child: Row(
            children: [
              const Text(
                '게시물 관리',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (widget.hideYn == 'Y') ...[
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: _accent, size: 12),
                      Gap(3),
                      Text('숨김 중', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70, size: 24),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 내용 수정 ──
                const Text('내용', style: TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const Gap(8),
                HashTagTextField(
                  controller: textController,
                  focusNode: currentTextNode,
                  basicStyle: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white, decorationThickness: 0),
                  decoratedStyle: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF6FB2FF)),
                  keyboardType: TextInputType.multiline,
                  maxLines: 6,
                  cursorColor: _accent,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _surface,
                    contentPadding: const EdgeInsets.all(12),
                    hintText: "내용을 입력해주세요!\n#태그1 #태그2 #태그3",
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accent, width: 1.2),
                    ),
                  ),
                  onChanged: (text) => _checkModification(),
                ),
                const Gap(8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _insertHashTag,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      backgroundColor: _surface,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.tag, size: 15),
                    label: const Text('태그 추가', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const Gap(18),

                // ── 공개 설정 ──
                const Text('공개 설정', style: TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const Gap(8),
                _settingTile(
                  icon: Icons.lock_outline_rounded,
                  title: '게시물 숨기기',
                  subtitle: '피드에 노출되지 않고 나만 볼 수 있어요',
                  state: isHide,
                ),
                const Gap(10),
                _settingTile(
                  icon: Icons.visibility_off_outlined,
                  title: '익명으로 표시',
                  subtitle: '닉네임 대신 익명으로 표시돼요',
                  state: isAnony,
                ),
                const Gap(24),

                // ── 게시 대상 (전체 피드 / 앨범) ──
                const Text('게시 대상', style: TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const Gap(4),
                Row(
                  children: [
                    Icon(_communityId == null ? Icons.public : Icons.photo_album_outlined, size: 15, color: _accent),
                    const Gap(5),
                    Text(_communityId == null ? '지금: 전체 피드' : '지금: 앨범',
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Gap(8),
                AlbumTargetSelector(
                  dark: true,
                  selectedCommunityId: _communityId,
                  onChanged: (c) {
                    setState(() => _communityId = c?.communityId);
                    _checkModification();
                  },
                ),
                const Gap(24),

                // ── 삭제 (스위치가 아닌 명시적 버튼) ──
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                const Gap(14),
                Center(
                  child: TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5A5A),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    label: const Text('게시물 삭제', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── 하단 저장 버튼(변경이 있을 때만 활성) ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color(0xFF17181C),
          child: SafeArea(
            child: ValueListenableBuilder<bool>(
                valueListenable: isModify,
                builder: (context, value, child) {
                  return CustomButton(
                    text: ' 저장 ',
                    type: 'XL',
                    isEnable: value,
                    onPressed: value ? () => save() : null,
                  );
                }),
          ),
        ),
      ],
    );
  }

  /// 공개 설정 타일 — 아이콘 + 제목/설명 + 스위치가 한 카드에 들어간 풀와이드 타일.
  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ValueNotifier<bool> state,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: state,
      builder: (context, on, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on ? _accent.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: on ? _accent : Colors.white54, size: 21),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const Gap(2),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.3)),
                  ],
                ),
              ),
              const Gap(8),
              CupertinoSwitch(
                value: on,
                activeTrackColor: _accent,
                inactiveTrackColor: Colors.white24,
                onChanged: (bool v) {
                  state.value = v;
                  _checkModification();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
