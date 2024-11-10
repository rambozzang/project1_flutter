import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_update_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';

class VideoManagePageSheet {
  Future<dynamic> open(BuildContext context, String boardId, String hideYn, String anonyYn, String contents) async {
    Map<String, dynamic>? returnMap = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      backgroundColor: Colors.black, //.withOpacity(0.8),
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
              height: 375,
              child: VideoManagePage(
                contextParent: context,
                boardId: boardId,
                hideYn: hideYn,
                anonyYn: anonyYn,
                contents: contents,
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
  });
  final BuildContext contextParent;
  final String boardId;
  final String hideYn;
  final String anonyYn;
  final String contents;

  @override
  State<VideoManagePage> createState() => _VideoManagePageState();
}

class _VideoManagePageState extends State<VideoManagePage> {
  // 게시물 숨김 여부
  ValueNotifier<bool> isHide = ValueNotifier<bool>(false);
  ValueNotifier<bool> isAnony = ValueNotifier<bool>(false);
  ValueNotifier<bool> isDelete = ValueNotifier<bool>(false);
  ValueNotifier<bool> isModify = ValueNotifier<bool>(false);

  TextEditingController textController = TextEditingController();
  FocusNode currentTextNode = FocusNode();
  @override
  void initState() {
    super.initState();
    isHide.value = widget.hideYn == 'Y';
    isAnony.value = widget.anonyYn == 'Y';
    textController.text = widget.contents;

    // 텍스트 변경 리스너 추가
    textController.addListener(_onTextChanged);

    // 스위치 상태 변경 리스너 추가
    isHide.addListener(_onSwitchChanged);
    isAnony.addListener(_onSwitchChanged);
    isDelete.addListener(_onSwitchChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    textController.removeListener(_onTextChanged);
    isHide.removeListener(_onSwitchChanged);
    isDelete.removeListener(_onSwitchChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (textController.text != widget.contents) {
      isModify.value = true;
    } else {
      _checkModification();
    }
  }

  void _onSwitchChanged() {
    _checkModification();
  }

  void _checkModification() {
    isModify.value = textController.text != widget.contents ||
        isHide.value != (widget.hideYn == 'Y') ||
        isDelete.value ||
        isAnony.value != (widget.anonyYn == 'Y');
  }

  Future<void> save() async {
    try {
      BoardRepo repo = BoardRepo();
      BoardUpdateData boardUpdateData = BoardUpdateData();
      boardUpdateData.boardId = widget.boardId;
      // 1.삭제 처리
      if (isDelete.value) {
        Utils.showConfirmDialog('확인', '게시물을 영구적으로 삭제 하시겠습니까?', BackButtonBehavior.none, cancel: () {}, confirm: () async {
          boardUpdateData.delYn = 'Y';
          try {
            ResData res = await repo.updateBoard(boardUpdateData);
            lo.g('res ${res.toString()}');
            if (res.code == '00') {
              Utils.alert('삭제되었습니다.');
              if (mounted) {
                // 여기서 mounted 체크
                Map<String, dynamic> returnMap = <String, dynamic>{};
                returnMap['isDelete'] = 'Y';
                Navigator.pop(context, returnMap);
              }
            } else {
              Utils.alert('삭제 중 에러가 발생했습니다.${res.msg}');
            }
          } catch (e) {
            lo.g('삭제 중 에러 ${e.toString()}');
            Utils.alert('삭제 중 에러가 발생했습니다.');
          }
          // 삭제 Api 호출
        }, backgroundReturn: () {});
        Navigator.pop(context);
        return;
      }

      // 2 수정 Api 호출
      boardUpdateData.hideYn = isHide.value ? 'Y' : 'N';
      boardUpdateData.anonyYn = isAnony.value ? 'Y' : 'N';
      boardUpdateData.contents = textController.text;
      ResData res = await repo.updateBoard(boardUpdateData);
      if (res.code == '00') {
        Utils.alert('수정 되었습니다.');
        Map<String, dynamic> returnMap = <String, dynamic>{};
        returnMap['contents'] = textController.text;
        returnMap['hideYn'] = isHide.value ? 'Y' : 'N';
        returnMap['boardId'] = widget.boardId;

        Navigator.pop(context, returnMap);
      } else {
        Utils.alert('수정 중 에러가 발생했습니다.${res.msg}');
      }
    } catch (e) {
      Utils.alert('저장시 에러가 발생했습니다.');
    }
  }

  int value = 0;
  int? nullableValue;
  bool positive = false;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(100)),
                  ),
                  Container(
                    height: 40,
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.hideYn == 'Y'
                            ? const Row(
                                children: [
                                  Icon(Icons.lock, color: Colors.red, size: 20),
                                  Text(
                                    '숨기기 게시물',
                                    style: TextStyle(color: Colors.red, fontSize: 1),
                                  ),
                                ],
                              )
                            : const Text(
                                '게시물 관리',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                        const Spacer(),
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close, color: Colors.white, size: 25),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.white.withOpacity(0.2),
                    height: 1,
                  ),
                  const Gap(10),
                  HashTagTextField(
                    controller: textController,
                    focusNode: currentTextNode,
                    basicStyle: const TextStyle(fontSize: 15, color: Colors.white, decorationThickness: 0),
                    decoratedStyle: const TextStyle(fontSize: 15, color: Colors.blue),
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                      hintText: "내용을 입력해주세요! \n#태그1 #태그2 #태그3",
                      hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 59, 104, 81), width: 1.0)),
                    ),
                    onChanged: (text) {
                      _checkModification();
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: isDelete,
                    builder: (context, value, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '게시물 숨기기',
                              style: TextStyle(color: value ? Colors.grey : Colors.white, fontSize: 14),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: isHide,
                              builder: (context, value, child) {
                                bool thisValue = value;
                                return Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: thisValue,
                                    activeColor: CupertinoColors.activeOrange,
                                    trackColor: Colors.white.withOpacity(0.5),
                                    onChanged: (bool value) {
                                      isHide.value = value;

                                      _checkModification();
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<bool>(
                      valueListenable: isDelete,
                      builder: (context, value, child) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '게시물 익명처리',
                                style: TextStyle(color: value ? Colors.grey : Colors.white, fontSize: 14),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: isAnony,
                                builder: (context, value1, child) {
                                  bool thisValue = value1;
                                  return Transform.scale(
                                    scale: 0.8,
                                    child: CupertinoSwitch(
                                      value: thisValue,
                                      activeColor: CupertinoColors.activeOrange,
                                      trackColor: Colors.white.withOpacity(0.5),
                                      onChanged: (bool value) {
                                        isAnony.value = value;

                                        _checkModification();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          '게시물 삭제',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: isDelete,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: value,
                                activeColor: Colors.red,
                                trackColor: Colors.white.withOpacity(0.5),
                                onChanged: (bool value) {
                                  isDelete.value = value;
                                  if (value) {
                                    isHide.value = false;
                                    isAnony.value = false;
                                  }
                                  _checkModification();
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Gap(5),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final currentText = textController.text;
                          final TextSelection selection = textController.selection;
                          final int cursorPosition = selection.base.offset;

                          String newText;
                          int newCursorPosition;

                          if (cursorPosition >= 0 && cursorPosition <= currentText.length) {
                            // 커서 위치가 유효한 경우
                            // 커서 앞에 공백이 없으면 공백을 추가
                            if (cursorPosition == 0 || currentText[cursorPosition - 1] != ' ') {
                              newText = currentText.replaceRange(cursorPosition, cursorPosition, ' #');
                              newCursorPosition = cursorPosition + 2; // 공백과 # 다음으로 커서 이동
                            } else {
                              newText = currentText.replaceRange(cursorPosition, cursorPosition, '#');
                              newCursorPosition = cursorPosition + 1; // # 다음으로 커서 이동
                            }
                          } else {
                            // 커서 위치가 유효하지 않은 경우 (선택되지 않은 경우)
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
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          elevation: 1.5,
                          minimumSize: const Size(0, 0),
                          backgroundColor: Colors.grey[200],
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text('# 태그추가'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: Colors.black,
          child: SafeArea(
            child: ValueListenableBuilder<bool>(
                valueListenable: isModify,
                builder: (context, value, child) {
                  return CustomButton(
                    text: ' 수정 완료 ',
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
}
