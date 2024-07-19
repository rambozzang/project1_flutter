import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/common/code_data.dart';
import 'package:project1/repo/common/comm_repo.dart';
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
    String crtCustId,
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

          child: SizedBox(
              height: 290,
              child: SigoPage(
                contextParent: context,
                boardId: boardId,
                crtCustId: crtCustId,
              )),
        );
      },
    );
  }
}

class SigoPage extends StatefulWidget {
  const SigoPage({super.key, required this.contextParent, required this.boardId, required this.crtCustId});
  final BuildContext contextParent;
  final String boardId;
  final String crtCustId;

  @override
  State<SigoPage> createState() => _SigoPageState();
}

class _SigoPageState extends State<SigoPage> {
  final StreamController<ResStream<List<BoardCommentResData>>> listCtrl = StreamController.broadcast();

  // 댓글 입력창
  TextEditingController replyController = TextEditingController();
  FocusNode replyFocusNode = FocusNode();
  final StreamController<ResStream<List<CodeRes>>> streamController = StreamController();

  int pageNum = 0;
  int pageSize = 500;
  late List<BoardCommentResData> list = [];

  ValueNotifier<bool> isSend = ValueNotifier<bool>(false);
  bool isFirst = true;

  String dropdownValue = '01';

  @override
  void initState() {
    super.initState();
    searchCode();
    replyController.clear();
    // 루트페이지 바텀바 숨김
    RootCntr.to.bottomBarStreamController.sink.add(false);
  }

  Future<void> searchCode() async {
    try {
      streamController.sink.add(ResStream.loading());
      CommRepo repo = CommRepo();
      CodeReq reqData = CodeReq();
      reqData.pageNum = 0;
      reqData.pageSize = 100;
      reqData.grpCd = 'SINGGO';
      reqData.code = '';
      reqData.useYn = 'Y';
      ResData res = await repo.searchCode(reqData);

      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      List<CodeRes> list = (res.data as List)!.map<CodeRes>((e) => CodeRes.fromMap(e)).toList();

      // alramlist.value = list.map((e) => e.codeNm!).toList();
      streamController.sink.add(ResStream.completed(list));

      lo.g('searchRecomWord : ${res.data}');
    } catch (e) {
      lo.g('error searchRecomWord : $e');
    }
  }

  Future<void> saveSigo() async {
    try {
      BoardRepo repo = BoardRepo();

      String reasonCd = '${dropdownValue}';
      String reason = '${replyController.text}';

      String boardId = widget.boardId.toString();

      // dropdownValue 07 이면 사용자신고(거절) 이므로 boardID 대신 상대방 custId를 넘긴다.
      boardId = dropdownValue == '07' ? widget.crtCustId : boardId;

      ResData res = await repo.saveSingo(boardId, dropdownValue, reason);
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
              Text(
                dropdownValue == '08' ? '사용자 차단 처리' : '불법영상 신고 하기',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
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
              dropdownValue == '08'
                  ? SizedBox.shrink()
                  : const Row(
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
              StreamBuilder<ResStream<List<CodeRes>>>(
                  stream: streamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.data != null) {
                      var list = snapshot.data!.data as List<CodeRes>;
                      return DropdownButton<String>(
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
                        items: list.map<DropdownMenuItem<String>>((CodeRes value) {
                          return DropdownMenuItem<String>(
                            value: value.code,
                            child: Text(
                              value.codeNm.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          );
                        }).toList(),
                      );
                    }
                    return const SizedBox(width: 30, height: 30, child: CircularProgressIndicator());
                  }),
            ],
          ),
          const Gap(5),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dropdownValue == '08' ? ' 게시물만 차단' : '신고 사유 입력(선택)',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              dropdownValue == '07'
                  ? const Text(
                      ' 게시물 차단',
                      style: TextStyle(color: Colors.yellow, fontSize: 13),
                    )
                  : const SizedBox.shrink()
            ],
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
