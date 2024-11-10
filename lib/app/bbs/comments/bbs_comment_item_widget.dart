import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/bbs/YouTubeTextExtractor.dart';
import 'package:project1/app/bbs/bbs_view_page.dart';
import 'package:project1/app/bbs/comments/cntr/bbs_comments_cntr.dart';
import 'package:project1/app/bbs/image/image_list_preview.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:rich_text_view/rich_text_view.dart';
import 'package:url_launcher/url_launcher.dart';

typedef OnWhatToDoCallback = Function(BbsListData value);

class BBsCommentItemWidget extends StatefulWidget {
  const BBsCommentItemWidget({
    super.key,
    required this.tagNm,
    required this.callback,
    required this.bbsListData,
    required this.controller,
    required this.isDarkTheme,
  });
  final String tagNm;
  final OnWhatToDoCallback callback;
  final BbsListData bbsListData;
  final TextEditingController? controller;
  final bool isDarkTheme;

  @override
  State<BBsCommentItemWidget> createState() => _BBsCommentItemWidgetState();
}

class _BBsCommentItemWidgetState extends State<BBsCommentItemWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 스타일 상수들
  static const double _avatarSize = 22.0;
  static const double _nickNmFontSize = 12.0;
  static const double _iconSize = 15.0;
  static const double _fontSize = 12.0;
  static const double _contentsFontSize = 15.0;

  final TextStyle _defaultTextStyle =
      const TextStyle(fontSize: _nickNmFontSize, height: 1.0, fontWeight: FontWeight.w500, color: Colors.black54);

  ValueNotifier<int> likeCnt = ValueNotifier<int>(0);
  ValueNotifier<String> likeYn = ValueNotifier<String>('N');

  @override
  void initState() {
    super.initState();
    likeCnt.value = widget.bbsListData.likeCnt!;
  }

  // 좋아요 관련 메소드들...
  Future<void> like() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.like(widget.bbsListData.boardId.toString(), AuthCntr.to.resLoginData.value.custId.toString(), "N");
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      // Utils.alert('좋아요! 저장되었습니다.');
      likeCnt.value = likeCnt.value + 1;
      likeYn.value = 'Y';
      // widget.bbsListData.likeYn = 'Y';
    } catch (e) {
      // Utils.alert('좋아요 실패! 다시 시도해주세요');
    }
  }

  Future<void> likeCancle() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.likeCancle(widget.bbsListData.boardId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      // Utils.alert('좋아요! 취소 되었습니다.');
      likeCnt.value = likeCnt.value - 1;
      likeYn.value = 'N';
      // widget.bbsListData.likeYn = 'N';
    } catch (e) {
      // Utils.alert('좋아요 취소 실패! 다시 시도해주세요');
    }
  }

  // UI 테마 색상 getter
  ThemeColors _getThemeColors() {
    return ThemeColors(
      background: widget.isDarkTheme ? Colors.black : Colors.white,
      textMain: widget.isDarkTheme ? Colors.white : Colors.black,
      textSub: widget.isDarkTheme ? Colors.white54 : Colors.black54,
      icon: widget.isDarkTheme ? Colors.white54 : Colors.black54,
    );
  }

  // 프로필 아바타 위젯
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () => Get.toNamed('/OtherInfoPage/${widget.bbsListData.crtCustId}'),
      child: widget.bbsListData.profilePath!.isNotEmpty ? _buildProfileImage() : _buildDefaultAvatar(),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      height: _avatarSize,
      width: _avatarSize,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey, width: 0.5),
        image: DecorationImage(
          image: CachedNetworkImageProvider(cacheKey: widget.bbsListData.profilePath.toString(), widget.bbsListData.profilePath.toString()),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      height: _avatarSize,
      width: _avatarSize,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          widget.bbsListData.nickNm.toString().substring(0, 1),
          style: const TextStyle(fontSize: _nickNmFontSize, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 댓글 내용 위젯
  Widget _buildCommentContent() {
    return MixedContent(
      key: UniqueKey(),
      content: widget.bbsListData.contents.toString(),
      videoHeight: 200,
      delYn: widget.bbsListData.delYn.toString(),
    );
  }

  List<ParserType> _getSupportedTextTypes() {
    return [
      EmailParser(onTap: (email) => print('${email.value} clicked')),
      MentionParser(
          enableID: true,
          pattern: r'@[가-힣a-zA-Z0-9!@#$%^&*(),.?":{}|<>_-]+(?=\s|$)',
          style: TextStyle(backgroundColor: Colors.grey[200], fontSize: 14, color: Colors.indigo, fontWeight: FontWeight.w600),
          onTap: (mention) => print('${mention.value} clicked')),
      UrlParser(onTap: (url) => launchUrl(Uri.parse(url.value!))),
      BoldParser(),
      HashTagParser(onTap: (hashtag) => print('is ${hashtag.value} trending?'))
    ];
  }

  // 이미지 미리보기 위젯
  Widget _buildImagePreview() {
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
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ImageViewer(imageUrl: widget.bbsListData.fileList!.first.filePath.toString(), nickNm: '미리보기'),
    //   ),
    // );
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ImageListPreview(imageUrls: [widget.bbsListData.fileList!.first.filePath.toString()]),
    //   ),
    // );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageListPreview(imageUrls: widget.bbsListData.fileList!.map((e) => e.filePath.toString()).toList(), initialIndex: 0),
      ),
    );
  }

  // 좋아요/댓글 액션 버튼
  Widget _buildActionButtons(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildLikeButton(colors),
        const Gap(3),
        _buildLikeCount(colors),
        const Gap(15),
        _buildCommentButton(colors),
        const Gap(10),
      ],
    );
  }

  // 기존 build 메소드...
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = _getThemeColors();

    return Material(
      color: colors.background,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 0, bottom: 5, left: 10, right: 10),
        child: Column(
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.23),
            ),
            const Gap(5),
            _buildCommentLayout(colors),
          ],
        ),
      ),
    );
  }

  // 수정 SElectbox
  Widget modifyWindow(BbsListData bbsListData) {
    return SizedBox(
      height: 20,
      width: 20,
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
              // onEdit();
              Get.find<BbsCommentsController>(tag: widget.tagNm).modifySetting(bbsListData);

              break;
            case 'delete':
              // onDelete();
              Get.find<BbsCommentsController>(tag: widget.tagNm).deleteComment(bbsListData);
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
                    SizedBox(
                      width: 3,
                    ),
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
                    const SizedBox(
                      width: 3,
                    ),
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
                  const SizedBox(
                    width: 3,
                  ),
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

  // 좋아요 버튼 위젯
  Widget _buildLikeButton(ThemeColors colors) {
    return SizedBox(
      height: _iconSize,
      width: _iconSize,
      child: ValueListenableBuilder<String>(
          valueListenable: likeYn,
          builder: (context, value, child) {
            return IconButton(
              padding: EdgeInsets.zero,
              iconSize: _iconSize,
              icon: value == 'Y'
                  ? const Icon(Icons.favorite, color: Colors.red)
                  : const Icon(Icons.favorite_border_outlined, color: Colors.grey),
              onPressed: () => value == 'Y' ? likeCancle() : like(),
            );
          }),
    );
  }

  // 좋아요 카운트 위젯
  Widget _buildLikeCount(ThemeColors colors) {
    return ValueListenableBuilder<int>(
        valueListenable: likeCnt,
        builder: (context, value, child) {
          return Text(
            value.toString(),
            style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w400, color: colors.textSub),
          );
        });
  }

  // 댓글 버튼 위젯
  Widget _buildCommentButton(ThemeColors colors) {
    return SizedBox(
      height: 13,
      width: 13,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: _iconSize,
        icon: Icon(Icons.comment_outlined, color: colors.icon),
        onPressed: () {
          widget.callback(widget.bbsListData);
        },
      ),
    );
  }

  // 전체 댓글 레이아웃
  Widget _buildCommentLayout(ThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (widget.bbsListData.depthNo != '1') ...[
          const SizedBox(
            width: 25,
            height: 20,
            child: Icon(Icons.subdirectory_arrow_right_outlined, color: Colors.grey, size: 14),
          ),
        ],
        Expanded(
          child: InkWell(
            onTap: () => widget.callback(widget.bbsListData),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.bbsListData.typeDtCd != "ANON") ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 0, right: 5),
                        child: _buildAvatar(),
                      ),
                      Text(
                        widget.bbsListData.nickNm.toString(),
                        style: _defaultTextStyle,
                      ),
                    ] else ...[
                      Utils.buildRanDomProfile(widget.bbsListData.crtCustId ?? '', 22, 12, Colors.black54)
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Text(
                        '·',
                        style: TextStyle(color: colors.textSub, fontSize: 16),
                      ),
                    ),
                    Text(
                      Utils.timeage(widget.bbsListData.crtDtm!),
                      style: _defaultTextStyle,
                    ),
                    const Spacer(),
                    _buildActionButtons(colors),
                    const Gap(5),
                    modifyWindow(widget.bbsListData),
                  ],
                ),
                _buildImagePreview(),
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 1, left: 2),
                  child: _buildCommentContent(),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

// 테마 색상을 관리하기 위한 클래스
class ThemeColors {
  final Color background;
  final Color textMain;
  final Color textSub;
  final Color icon;

  ThemeColors({
    required this.background,
    required this.textMain,
    required this.textSub,
    required this.icon,
  });
}
