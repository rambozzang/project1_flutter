import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/bbs/YouTubeTextExtractor.dart';
import 'package:project1/app/bbs/bbs_view_page.dart';
import 'package:project1/app/short/comment/cntr/short_comments_cntr.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:rich_text_view/rich_text_view.dart';
import 'package:url_launcher/url_launcher.dart';

typedef OnWhatToDoCallback = Function(BbsListData value);

class ShortCommentItemWidget extends StatefulWidget {
  const ShortCommentItemWidget({
    super.key,
    required this.callback,
    required this.bbsListData,
    required this.controller,
    required this.isDarkTheme,
    required this.displayDate,
  });

  final OnWhatToDoCallback callback;
  final BbsListData bbsListData;
  final TextEditingController? controller;
  final bool isDarkTheme;
  final String? displayDate;

  @override
  State<ShortCommentItemWidget> createState() => _ShortCommentItemWidgetState();
}

class _ShortCommentItemWidgetState extends State<ShortCommentItemWidget> {
  ValueNotifier<int> likeCnt = ValueNotifier<int>(0);
  ValueNotifier<String> likeYn = ValueNotifier<String>('N');

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    likeCnt.value = widget.bbsListData.likeCnt!;
  }

  // 좋아요 관련 메서드들
  Future<void> like() async {
    try {
      final resData = await _handleLikeRequest();
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      _updateLikeState(true);
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> likeCancle() async {
    try {
      final resData = await _handleLikeCancelRequest();
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      _updateLikeState(false);
    } catch (e) {
      // 에러 처리
    }
  }

  Future<ResData> _handleLikeRequest() {
    final boardRepo = BoardRepo();
    return boardRepo.like(widget.bbsListData.boardId.toString(), AuthCntr.to.resLoginData.value.custId.toString(), "N");
  }

  Future<ResData> _handleLikeCancelRequest() {
    final boardRepo = BoardRepo();
    return boardRepo.likeCancle(widget.bbsListData.boardId.toString());
  }

  void _updateLikeState(bool isLiked) {
    likeCnt.value += isLiked ? 1 : -1;
    likeYn.value = isLiked ? 'Y' : 'N';
  }

  @override
  Widget build(BuildContext context) {
    final theme = _CommentTheme(widget.isDarkTheme);

    return RepaintBoundary(
      child: Material(
        color: theme.backgroundColor,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 0, bottom: 5, left: 10, right: 10),
          child: Column(
            children: [
              _buildDateHeader(),
              _buildCommentContent(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    if (widget.displayDate == null) return const SizedBox();

    return Container(
      height: 25,
      width: 110,
      margin: const EdgeInsets.only(bottom: 10, top: 5),
      // padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.indigo[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          widget.displayDate.toString(),
          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Widget _buildCommentContent(_CommentTheme theme) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.end,
  //     children: [
  //       if (widget.bbsListData.depthNo != '1') const SizedBox(width: 25),
  //       Expanded(
  //         child: _buildCommentCard(theme),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildCommentContent(_CommentTheme theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // color: const Color.fromARGB(255, 208, 200, 208).withOpacity(0.1),

        color: const Color.fromARGB(255, 217, 229, 222).withOpacity(0.25),
        // color: const Color.fromARGB(255, 220, 230, 241).withOpacity(0.25),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.bbsListData.depthNo != '1')
            const SizedBox(
              width: 25,
              height: 20,
              child: Icon(Icons.subdirectory_arrow_right_outlined, color: Colors.grey, size: 14),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentInfo(theme),
                _buildAttachedImage(),
                _buildCommentText(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedImage() {
    if (widget.bbsListData.fileList == null || widget.bbsListData.fileList!.isEmpty) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: () => _showImageViewer(),
      child: Container(
        color: Colors.grey[200],
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: CachedNetworkImage(
            imageUrl: widget.bbsListData.fileList!.first.filePath.toString(),
            height: 240,
            width: 240,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  void _showImageViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(imageUrl: widget.bbsListData.fileList!.first.filePath.toString(), nickNm: '미리보기'),
      ),
    );
  }

  Widget _buildCommentText() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 0, left: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MixedContent(
            key: GlobalKey(),
            content: widget.bbsListData.contents.toString(),
            videoHeight: 200,
            delYn: widget.bbsListData.delYn.toString(),
          ),
          // RichTextView(
          //   text: widget.bbsListData.contents.toString(),
          //   truncate: false,
          //   style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
          //   linkStyle: const TextStyle(color: Colors.blueAccent, fontSize: 15, fontWeight: FontWeight.w600),
          //   selectable: true,
          //   supportedTypes: [
          //     EmailParser(onTap: (email) => print('${email.value} clicked')),
          //     MentionParser(
          //         pattern: r'@[가-힣a-zA-Z0-9!@#$%^&*(),.?":{}|<>_-]+(?=\s|$)',
          //         style: TextStyle(
          //           backgroundColor: Colors.grey[200],
          //           color: Colors.indigo,
          //           fontWeight: FontWeight.bold,
          //         ),
          //         onTap: (mention) => print('${mention.value} clicked')),
          //     UrlParser(
          //       onTap: (url) => launchUrl(Uri.parse(url.value!)),
          //     ),
          //     BoldParser(),
          //     HashTagParser(onTap: (hashtag) => print('is ${hashtag.value} trending?'))
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildCommentInfo(_CommentTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildUserInfo(theme),
        const Spacer(),
        _buildLikeButton(theme),
        const Gap(5),
        _buildLikeCount(theme),
        const Gap(15),
        _buildCommentButton(theme),
        const Gap(10),
        _buildModifyWindow(widget.bbsListData) // 여기를 수정
      ],
    );
  }

  Widget _buildUserInfo(_CommentTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0, right: 4, bottom: 0),
          child: GestureDetector(
            onTap: () => Get.toNamed('/OtherInfoPage/${widget.bbsListData.crtCustId}'),
            child: _buildUserAvatar(),
          ),
        ),
        Text(
          widget.bbsListData.nickNm.toString(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            '·',
            style: TextStyle(color: theme.textColorSub, fontSize: 16),
          ),
        ),
        Text(
          Utils.timeage(widget.bbsListData.crtDtm!),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return widget.bbsListData.profilePath != ""
        ? Container(
            height: 22,
            width: 22,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey, width: 0.5),
              image: DecorationImage(
                image: CachedNetworkImageProvider(
                    cacheKey: widget.bbsListData.profilePath.toString(), widget.bbsListData.profilePath.toString()),
                fit: BoxFit.cover,
              ),
            ),
          )
        : Container(
            height: 22,
            width: 22,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                widget.bbsListData.nickNm.toString().substring(0, 1),
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
  }

  Widget _buildLikeButton(_CommentTheme theme) {
    return SizedBox(
      height: 15,
      width: 15,
      child: ValueListenableBuilder<String>(
          valueListenable: likeYn,
          builder: (context, value, child) {
            return IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: value == 'Y'
                  ? const Icon(Icons.favorite, color: Colors.red)
                  : const Icon(Icons.favorite_border_outlined, color: Colors.grey),
              onPressed: () => value == 'Y' ? likeCancle() : like(),
            );
          }),
    );
  }

  Widget _buildLikeCount(_CommentTheme theme) {
    return ValueListenableBuilder<int>(
        valueListenable: likeCnt,
        builder: (context, value, child) {
          return Text(
            value.toString(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.textColorSub),
          );
        });
  }

  Widget _buildCommentButton(_CommentTheme theme) {
    return SizedBox(
      height: 13,
      width: 15,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 15,
        icon: Icon(Icons.comment_outlined, color: theme.iconColor),
        onPressed: () {
          widget.callback(widget.bbsListData);
        },
      ),
    );
  }

  Widget _buildModifyWindow(BbsListData bbsListData) {
    return SizedBox(
      height: 25,
      width: 30,
      child: PopupMenuButton<String>(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 80,
        ),
        padding: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: const Icon(
          Icons.more_vert,
          size: 20,
        ),
        color: Colors.white,
        onSelected: (String result) {
          switch (result) {
            case 'edit':
              Get.find<ShortCommentsController>().modifySetting(bbsListData);
              break;
            case 'delete':
              Get.find<ShortCommentsController>().deleteComment(bbsListData);
              break;
            case 'singo':
              SigoPageSheet().open(context, bbsListData.boardId.toString(), bbsListData.crtCustId.toString(), callBackFunction: null);
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          if (Get.find<AuthCntr>().custId.value == bbsListData.crtCustId.toString()) ...[
            const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_square, color: Colors.blue, size: 18),
                    SizedBox(width: 3),
                    Text(
                      '수정',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                )),
            const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    SizedBox(width: 3),
                    Text(
                      '삭제',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                )),
          ],
          const PopupMenuItem<String>(
              value: 'singo',
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.black,
                    size: 21,
                  ),
                  SizedBox(width: 3),
                  Text(
                    '신고',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

// 테마 관련 클래스
class _CommentTheme {
  final bool isDarkTheme;

  _CommentTheme(this.isDarkTheme);

  Color get backgroundColor => isDarkTheme ? Colors.black : Colors.white;
  Color get textColorMain => isDarkTheme ? Colors.white : Colors.black;
  Color get textColorSub => isDarkTheme ? Colors.white54 : Colors.black54;
  Color get iconColor => isDarkTheme ? Colors.white54 : Colors.black54;
}
