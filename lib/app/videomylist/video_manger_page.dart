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
  Future<dynamic> open(BuildContext context, String boardId, String hideYn, String contents) async {
    String? returnString = await showModalBottomSheet(
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
              height: 280,
              child: VideoManagePage(
                contextParent: context,
                boardId: boardId,
                hideYn: hideYn,
                contents: contents,
              )),
        );
      },
    );
    return returnString;
  }
}

class VideoManagePage extends StatefulWidget {
  const VideoManagePage({
    super.key,
    required this.contextParent,
    required this.boardId,
    required this.hideYn,
    required this.contents,
  });
  final BuildContext contextParent;
  final String boardId;
  final String hideYn;
  final String contents;

  @override
  State<VideoManagePage> createState() => _VideoManagePageState();
}

class _VideoManagePageState extends State<VideoManagePage> {
  // 게시물 숨김 여부
  ValueNotifier<bool> isHide = ValueNotifier<bool>(false);
  ValueNotifier<bool> isDelete = ValueNotifier<bool>(false);
  ValueNotifier<bool> isModify = ValueNotifier<bool>(false);

  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isHide.value = widget.hideYn == 'Y';
    textController.text = widget.contents;
  }

  @override
  void dispose() {
    super.dispose();
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
                Navigator.pop(context);
              }
            } else {
              Utils.alert('삭제 중 에러가 발생했습니다.${res.msg}');
            }
          } catch (e) {
            lo.g('삭제 중 에러 ${e.toString()}');
            Utils.alert('삭제 중 에러가 발생했습니다.');
          }
          if (mounted) {
            // 여기서도 mounted 체크
            Navigator.pop(context);
          }
          // 삭제 Api 호출
        }, backgroundReturn: () {});
        Navigator.pop(context);
        return;
      }

      // 2 수정 Api 호출
      boardUpdateData.hideYn = isHide.value ? 'Y' : 'N';
      boardUpdateData.contents = textController.text;
      ResData res = await repo.updateBoard(boardUpdateData);
      if (res.code == '00') {
        Utils.alert('수정 되었습니다.');
        Navigator.pop(context, textController.text);
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
    return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(100)),
              ),
              Container(
                height: 60,
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    widget.hideYn == 'Y'
                        ? const Row(
                            children: [
                              Icon(Icons.lock, color: Colors.red, size: 20),
                              Text(
                                '숨기기 게시물',
                                style: TextStyle(color: Colors.red, fontSize: 15),
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
                    CustomButton(text: ' 수정 완료 ', type: 'XS', isEnable: true, onPressed: () => save())
                  ],
                ),
              ),
              Divider(
                color: Colors.white.withOpacity(0.2),
                height: 1,
              ),
              const Gap(10),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       textController.text = '${textController.text} #';
              //     },
              //     clipBehavior: Clip.none,
              //     style: ElevatedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //       elevation: 1.5,
              //       minimumSize: const Size(0, 0),
              //       backgroundColor: Colors.grey[200],
              //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(10.0),
              //       ),
              //     ),
              //     child: const Text(
              //       '# 태그추가',
              //       style: TextStyle(
              //         color: Colors.black,
              //         fontSize: 14,
              //       ),
              //     ),
              //   ),
              // ),
              // const Gap(5),
              HashTagTextField(
                controller: textController,
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
                onDetectionTyped: (text) {
                  print(text);
                },
                onDetectionFinished: () {
                  print("detection finished");
                },
              ),
              const Gap(10),
              ValueListenableBuilder<bool>(
                  valueListenable: isDelete,
                  builder: (context, value, child) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Text(
                            '게시물 숨기기',
                            style: TextStyle(color: value ? Colors.grey : Colors.white, fontSize: 15),
                          ),
                          const Spacer(),
                          ValueListenableBuilder<bool>(
                              valueListenable: isHide,
                              builder: (context, value, child) {
                                bool thisValue = value;
                                return CupertinoSwitch(
                                  value: thisValue,
                                  activeColor: CupertinoColors.activeOrange,
                                  trackColor: Colors.white.withOpacity(0.5),
                                  onChanged: (bool value) {
                                    isHide.value = value;
                                  },
                                );
                              }),
                        ],
                      ),
                    );
                  }),
              // const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const Text(
                      '게시물 삭제',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                        valueListenable: isDelete,
                        builder: (context, value, child) {
                          return CupertinoSwitch(
                            value: value,
                            activeColor: Colors.red,
                            trackColor: Colors.white.withOpacity(0.5),
                            onChanged: (bool value) {
                              isDelete.value = value;
                              if (value) {
                                isHide.value = false;
                              }
                            },
                          );
                        }),
                    // SizedBox(
                    //     height: 45,
                    //     width: 120,
                    //     child: CustomButton(
                    //         text: "완전삭제",
                    //         listColors: const [
                    //           Color.fromARGB(255, 190, 14, 1),
                    //           Color.fromARGB(255, 201, 61, 51),
                    //           Color.fromARGB(255, 179, 80, 72),
                    //         ],
                    //         type: "S",
                    //         onPressed: () => delete())),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
