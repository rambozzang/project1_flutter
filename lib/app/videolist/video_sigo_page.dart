import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/root/cntr/root_cntr.dart';

import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';

class SigoPageSheet {
  Future<dynamic> open(
    BuildContext context,
    String boardId,
  ) async {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      useSafeArea: true,
      backgroundColor: Colors.black, //.withOpacity(0.8),
      builder: (BuildContext context) {
        return Padding(
          // padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          padding: MediaQuery.of(context).viewInsets,

          child: SizedBox(height: 290, child: SigoPage(contextParent: context, boardId: boardId)),
        );
      },
    );
  }
}

class SigoPage extends StatefulWidget {
  const SigoPage({super.key, required this.contextParent, required this.boardId});
  final BuildContext contextParent;
  final String boardId;

  @override
  State<SigoPage> createState() => _SigoPageState();
}

class _SigoPageState extends State<SigoPage> {
  final StreamController<ResStream<List<BoardCommentResData>>> listCtrl = StreamController.broadcast();

  // 댓글 입력창
  TextEditingController replyController = TextEditingController();
  FocusNode replyFocusNode = FocusNode();

  int pageNum = 0;
  int pageSize = 500;
  late List<BoardCommentResData> list = [];

  ValueNotifier<bool> isSend = ValueNotifier<bool>(false);
  bool isFirst = true;

  String dropdownValue = '신고 사유 선택';

  @override
  void initState() {
    super.initState();
    replyController.clear();
    // 루트페이지 바텀바 숨김
    RootCntr.to.bottomBarStreamController.sink.add(false);
  }

  Future<void> saveSigo() async {
    if (dropdownValue == '신고 사유 선택') {
      Utils.alert('신고 사유를 선택해주세요.');
      return;
    }

    try {
      BoardRepo repo = BoardRepo();
      String reason = '($dropdownValue)${replyController.text}';
      ResData res = await repo.saveSingo(widget.boardId.toString(), reason);
      if (res.code == '00') {
        Utils.alert('신고가 완료되었습니다.');
        Navigator.pop(widget.contextParent);
      } else {
        Utils.alert('다시 시도해주세요.');
        Navigator.pop(widget.contextParent);
      }
    } catch (e) {
      Lo.g('saveReply() error : $e');
      Utils.alert("다시 시도해주세요.");
      Navigator.pop(widget.contextParent);
    }
  }

  void onClose(bool didPop) {
    if (didPop) {
      Lo.g('PopScope 2 didPop');
      return;
    } else {
      Lo.g('PopScope 3 not didPop');
      return;
    }
  }

  @override
  void dispose() {
    replyController.dispose();

    RootCntr.to.bottomBarStreamController.sink.add(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Lo.g('SigoPage2 build');
    //  padding: MediaQuery.of(context).viewInsets, // EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(100)),
            ),
          ),
          const Gap(10),
          Row(
            children: [
              const Text(
                '불법영상 신고 하기',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(widget.contextParent),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 25,
                  ),
                  const Gap(10),
                  Text(
                    '신고 사유 선택',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              DropdownButton<String>(
                value: dropdownValue,
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 35,
                elevation: 16,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                // underline: Container(
                //   height: 2,
                //   color: Colors.deepPurpleAccent,
                // ),
                isExpanded: false,
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
                dropdownColor: Colors.black,
                items: <String>['신고 사유 선택', '욕설', '음란물', '폭력', '혐오', '정치', '거짓선동', '기타'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const Gap(5),
          const Text(
            '신고 사유 입력(선택)',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const Gap(5),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: replyController,
              focusNode: replyFocusNode,
              style: const TextStyle(color: Colors.black, fontSize: 14, decorationThickness: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(left: 10),
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.95,
              height: 48,
              child: CustomButton(text: '신고 완료', type: 'L', onPressed: () => saveSigo()),
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}
