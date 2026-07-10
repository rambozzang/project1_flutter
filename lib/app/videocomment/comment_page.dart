import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/videocomment/comment_header_widget.dart';
import 'package:project1/app/videocomment/comment_item_widget.dart';
import 'package:project1/repo/bbs/comment_repo.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/board/data/board_comment_data.dart';
import 'package:project1/repo/board/data/board_comment_update_req_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/root/cntr/root_cntr.dart';

import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/error_page.dart';

class CommentPage {
  Future<dynamic> open(
    BuildContext context,
    String boardId, {
    bool isDark = true, // 앨범 라이트모드에서 밝게 표시(기본=다크, 쇼츠 피드 등 영상 위는 다크 유지)
    bool autoFocus = false, // 앨범 상세 등 '입력창'을 눌러 열 때: 열자마자 키보드 포커스(재탭 제거)
  }) async {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      builder: (BuildContext context) {
        return SizedBox(height: MediaQuery.of(context).size.height * 0.65, child: CommentsPage(contextParent: context, boardId: boardId, isDark: isDark, autoFocus: autoFocus));
      },
    );
  }
}

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.contextParent, required this.boardId, this.isDark = true, this.autoFocus = false});
  final BuildContext contextParent;
  final String boardId;
  final bool isDark;
  final bool autoFocus;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  ScrollController scrollController = ScrollController();
  // final CommentSheetController commentSheetController = CommentSheetController();

  final StreamController<ResStream<List<BoardCommentResData>>> listCtrl = StreamController.broadcast();

  // 댓글 입력창
  TextEditingController replyController = TextEditingController();
  FocusNode replyFocusNode = FocusNode();

  int pageNum = 0;
  int pageSize = 500;
  late List<BoardCommentResData> list = [];

  ValueNotifier<bool> isSend = ValueNotifier<bool>(false);
  bool isFirst = true;

  bool isDarkTheme = true;

  // 답글(대댓글) 작성 대상 — null이면 새 원댓글, 있으면 그 댓글의 대댓글로 저장.
  BoardCommentResData? _replyTarget;
  // 댓글 수정 대상 — null이 아니면 전송 시 새 저장 대신 수정(update). 답글과 상호배타.
  BoardCommentResData? _editTarget;

  @override
  void initState() {
    isDarkTheme = widget.isDark;
    replyController.clear();
    super.initState();
    // 루트페이지 바텀바 숨김
    RootCntr.to.bottomBarStreamController.sink.add(false);
    getData(widget.boardId);
    // 앨범 상세의 '댓글 입력창'을 눌러 열었을 때: 시트가 뜨자마자 입력창에 포커스를 줘
    // 사용자가 한 번 더 입력창을 탭하지 않고 바로 작성할 수 있게 한다.
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) replyFocusNode.requestFocus();
        });
      });
    }
  }

  Future<void> getFakeData() async {
    isFirst = true;
    getData(widget.boardId);
  }

  Future<void> getData(boardId) async {
    try {
      if (isFirst) {
        listCtrl.sink.add(ResStream.loading());
      }
      isFirst = false;
      ResData resListData = await BoardRepo().searchComment(boardId, pageNum, pageSize);
      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }
      list = ((resListData.data) as List).map((data) => BoardCommentResData.fromMap(data)).toList();
      // 백엔드가 이미 스레드 순서(원댓글 바로 뒤에 대댓글)로 정렬해 주므로 클라이언트 재정렬 금지.
      //listCtrl.sink.add(ResStream.completed([]));
      listCtrl.sink.add(ResStream.completed(list));
    } catch (e) {
      Lo.g('getDate() error : $e');
      listCtrl.sink.add(ResStream.error(e.toString()));
    }
  }

  // 답글 작성 시작 — 부모 댓글을 설정하고 입력창에 '@닉네임 '을 채운 뒤 포커스.
  void startReply(BoardCommentResData parent) {
    setState(() {
      _editTarget = null; // 답글 시작 시 수정 모드 해제
      _replyTarget = parent;
      replyController.text = '@${parent.nickNm ?? ''} ';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 직전 전송에서 키보드만 숨고 포커스가 입력창에 남아있으면 requestFocus가 no-op이라
      // 키보드가 안 올라온다 → 이미 포커스면 키보드를 명시적으로 다시 띄운다.
      if (replyFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } else {
        replyFocusNode.requestFocus();
      }
      replyController.selection =
          TextSelection.fromPosition(TextPosition(offset: replyController.text.length));
    });
  }

  void cancelReply() {
    setState(() {
      _replyTarget = null;
      replyController.clear();
    });
  }

  // 댓글 수정 시작 — 입력창에 기존 내용을 채우고 수정 모드로 전환.
  void _startEdit(BoardCommentResData c) {
    setState(() {
      _replyTarget = null; // 수정 시작 시 답글 모드 해제
      _editTarget = c;
      replyController.text = c.contents ?? '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (replyFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } else {
        replyFocusNode.requestFocus();
      }
      replyController.selection =
          TextSelection.fromPosition(TextPosition(offset: replyController.text.length));
    });
  }

  void _cancelEdit() {
    setState(() {
      _editTarget = null;
      replyController.clear();
    });
    replyFocusNode.unfocus();
  }

  // 댓글 삭제 — 확인 후 백엔드 삭제(스카이라운지/앨범과 동일 엔드포인트) → 목록 새로고침.
  Future<void> _deleteComment(BoardCommentResData c) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final ResData res = await CommentRepo().deleteComment((c.boardId ?? 0).toString());
      if (res.code == '00') {
        if (_editTarget?.boardId == c.boardId) _cancelEdit();
        await getData(widget.boardId);
      } else {
        Utils.alert(res.msg.toString());
      }
    } catch (_) {
      Utils.alert('댓글 삭제 중 오류가 발생했습니다.');
    }
  }

  Future<void> saveComment() async {
    try {
      if (replyController.text == "") return;

      isSend.value = true;

      // 수정 모드 — 저장 대신 update(스카이라운지/앨범과 동일 엔드포인트).
      if (_editTarget != null) {
        final BoardCommentUpdateReqData data = BoardCommentUpdateReqData()
          ..boardId = (_editTarget!.boardId ?? 0).toString()
          ..contents = replyController.text
          ..delYn = 'N'
          ..hideYn = 'N'
          ..fileListData = [];
        final ResData res = await CommentRepo().update(data);
        if (res.code == '00') {
          replyFocusNode.unfocus();
          replyController.clear();
          _editTarget = null;
          setState(() {});
          await getData(widget.boardId);
        } else {
          Utils.alert(res.msg.toString());
        }
        isSend.value = false;
        return;
      }

      final int bid = int.parse(widget.boardId);
      // 답글이면 부모 댓글의 depthNo/sortNo/boardId를 넘긴다 — 백엔드가 자식 정렬값을 다시 계산.
      // (스카이라운지 bbs_comments_cntr 와 동일 방식. 원댓글은 0/0.)
      int depthNo = 0;
      int sortNo = 0;
      int parentId = bid;
      if (_replyTarget != null) {
        depthNo = _replyTarget!.depthNo ?? 0;
        sortNo = _replyTarget!.sortNo ?? 0;
        parentId = _replyTarget!.boardId ?? bid;
      }
      CommentRepo repo = CommentRepo();
      BoardCommentData replyData = BoardCommentData();
      replyData.custId = AuthCntr.to.resLoginData.value.custId.toString();
      replyData.parentId = parentId;
      replyData.rootId = bid;
      replyData.contents = replyController.text;
      replyData.depthNo = depthNo; // 백에서 다시 계산
      replyData.sortNo = sortNo; // 백에서 다시 계산
      replyData.typeCd = 'V';
      replyData.typeDtCd = 'V';
      replyData.fileListData = [];

      await repo.saveComment(replyData).then((value) async {
        if (value.code == '00') {
          // Utils.alert("댓글이 등록되었습니다.");

          // 키보드 내리기 — hide만 하면 포커스가 남아 다음 답글 탭에서 키보드가 안 뜬다.
          replyFocusNode.unfocus();

          replyController.clear();
          _replyTarget = null;
          setState(() {}); // 답글 배너 즉시 제거
          await getData(widget.boardId);

          // 리스트가 다시 그려진 뒤 최신 댓글로 스크롤(클라이언트 없을 때 예외 방지).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.jumpTo(scrollController.position.maxScrollExtent);
            }
          });
        } else {
          Utils.alert(value.msg.toString());
        }
      });
      isSend.value = false;
    } catch (e) {
      Lo.g('saveReply() error : $e');
      Utils.alert("다시 시도해주세요.");

      isSend.value = false;
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

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
  }

  @override
  void dispose() {
    replyController.dispose();
    scrollController.dispose();
    RootCntr.to.bottomBarStreamController.sink.add(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Lo.g('CommentsPage2 build');
    Color backgroundColor = isDarkTheme ? Colors.black : Colors.white;
    Color textColor = isDarkTheme ? Colors.white : Colors.black;
    return Theme(
      data: ThemeData(
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        // 다른 테마 속성들도 여기에 추가할 수 있습니다.
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            StreamBuilder<ResStream<List<BoardCommentResData>>>(
                stream: listCtrl.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data?.status == Status.COMPLETED) {
                      var list = snapshot.data!.data;
                      return CommentHeaderWidget(
                        listLength: list!.length,
                        getData: () => getFakeData(),
                        isDarkTheme: isDarkTheme,
                      );
                    }
                  }
                  return CommentHeaderWidget(
                    listLength: 0,
                    getData: () => getFakeData(),
                    isDarkTheme: isDarkTheme,
                  );
                }),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: StreamBuilder<ResStream<List<BoardCommentResData>>>(
                  stream: listCtrl.stream,
                  builder: (BuildContext context, AsyncSnapshot<ResStream<List<BoardCommentResData>>> snapshot) {
                    if (snapshot.hasData) {
                      switch (snapshot.data?.status) {
                        case Status.LOADING:
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(68.0),
                              child: Utils.progressbar(),
                            ),
                          );
                        case Status.COMPLETED:
                          List list = snapshot.data!.data as List<BoardCommentResData>;
                          return ListView.builder(
                            shrinkWrap: true,
                            // physics: const AlwaysScrollableScrollPhysics(),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.isEmpty ? 1 : list.length,
                            itemBuilder: (BuildContext context, int index) {
                              return list.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(68.0),
                                        child: Text(
                                          '댓글 없습니다.',
                                          style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black54, fontSize: 13),
                                        ),
                                      ),
                                    )
                                  : CommentItemWidget(
                                      focus: replyFocusNode,
                                      boardCommentData: list[index],
                                      controller: replyController,
                                      isDarkTheme: isDarkTheme, // 추가된 부분
                                      onReply: startReply,
                                      onEdit: _startEdit,
                                      onDelete: _deleteComment,
                                    );
                            },
                          );
                        case Status.ERROR:
                          return ErrorPage(
                            errorMessage: snapshot.data!.message ?? '',
                            onRetryPressed: () => getData(widget.boardId),
                          );
                        case null:
                          return const SizedBox(
                            width: 200,
                            height: 300,
                            child: Text("조회 중 오류가 발생했습니다."),
                          );
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Utils.progressbar(),
                    );
                  },
                ),
              ),
            ),
            if (_replyTarget != null) _buildReplyBanner(),
            if (_editTarget != null) _buildEditBanner(),
            buildBottomWidget(),
          ],
        ),
      ),
    );
  }

  // 답글 작성 중 표시 바 — 누구에게 답글 중인지 보여주고 취소할 수 있다.
  Widget _buildReplyBanner() {
    final Color sub = isDarkTheme ? Colors.white54 : Colors.black54;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      color: isDarkTheme ? Colors.grey[900] : Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.reply, size: 14, color: sub),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_replyTarget?.nickNm ?? ''}님에게 답글 작성 중',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: sub, fontSize: 12.5),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: cancelReply,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, size: 14, color: sub),
            ),
          ),
        ],
      ),
    );
  }

  // 댓글 수정 중 표시 바
  Widget _buildEditBanner() {
    final Color sub = isDarkTheme ? Colors.white54 : Colors.black54;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      color: isDarkTheme ? Colors.grey[900] : Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 14, color: sub),
          const SizedBox(width: 8),
          Expanded(
            child: Text('댓글 수정 중', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 12.5)),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _cancelEdit,
            child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close, size: 14, color: sub)),
          ),
        ],
      ),
    );
  }

  // 댓글 입력창
  Widget buildBottomWidget() {
    // 시스템 내비게이션 바(3버튼/제스처) 위로 입력창을 올린다.
    // 키보드가 열리면 상위 Padding(viewInsets)이 이미 밀어올리므로 그때는 추가 여백 없음.
    final double navInset = MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : MediaQuery.of(context).viewPadding.bottom;
    return Container(
      color: isDarkTheme ? Colors.grey[900] : Colors.grey[100],
      height: 64 + navInset,
      padding: EdgeInsets.only(left: 5, right: 5, bottom: navInset),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: const Color(0xff7c94b6),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                      cacheKey: AuthCntr.to.resLoginData.value.profilePath!, AuthCntr.to.resLoginData.value.profilePath!),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                border: Border.all(
                  color: Colors.green,
                  width: 0.4,
                ),
              ),
            ),
            // child: Icon(
            //   Icons.emoji_emotions_outlined,
            //   color: Colors.white,
            // ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: TextField(
                keyboardType: TextInputType.text,
                controller: replyController,
                focusNode: replyFocusNode,
                // cursorHeight: 5,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black, decorationThickness: 0),
                onSubmitted: (value) => saveComment(),
                decoration: InputDecoration(
                  hintText: _editTarget != null ? '댓글 수정...' : '댓글 ...',
                  hintStyle: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
                  prefixIconConstraints: const BoxConstraints(minWidth: 27, maxHeight: 27),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkTheme ? Colors.grey : Colors.grey.shade300, width: 0.4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkTheme ? Colors.white : Colors.black, width: 1.0),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(left: 10, bottom: 5, top: 15),
                ),
              ),
            ),
          ),
          ElevatedButton(
            clipBehavior: Clip.none,
            style: ElevatedButton.styleFrom(
              //  shadowColor: Colors.transparent,
              // fixedSize: Size(0, 0),
              minimumSize: Size.zero, // Set this
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              backgroundColor: Colors.transparent,
            ),
            onPressed: () => saveComment(),
            child: ValueListenableBuilder<bool>(
                valueListenable: isSend,
                builder: (context, value, snapshot) {
                  return Transform.scale(
                    scale: value ? 0.8 : 1.0,
                    child: Opacity(
                      opacity: value ? 0.5 : 1.0,
                      child: !value
                          ? Icon(
                              Icons.send,
                              color: isDarkTheme ? Colors.white : Colors.black87,
                            )
                          : LoadingAnimationWidget.fourRotatingDots(
                              color: Colors.pink,
                              size: 30,
                            ),
                      // : const Icon(
                      //     Icons.close,
                      //     color: Colors.grey,
                      //   ),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
