import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/bbs/YouTubeTextExtractor.dart';

import 'package:project1/app/bbs/cntr/bbs_view_cntr.dart';
import 'package:project1/app/bbs/comments/bbs_comments_bottom_page.dart';
import 'package:project1/app/bbs/comments/bbs_comments_page.dart';
import 'package:project1/app/bbs/comments/cntr/bbs_comments_cntr.dart';
import 'package:project1/app/bbs/image/image_list_preview.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

class BbsViewPage extends StatefulWidget {
  const BbsViewPage({
    super.key,
  });

  @override
  State<BbsViewPage> createState() => _BbsViewPageState();
}

class _BbsViewPageState extends State<BbsViewPage> {
  // final cntr = Get.find<BbsViewController>();

  late BbsViewController cntr;

  late String _boardId;
  late String _tagNm; // 컨트롤러 태그명
  late String _admobId;
  bool isDisplayMyListPage = true;
  final ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    _tagNm = Get.arguments['tag'] + Get.arguments['boardId'];
    _admobId = Get.arguments['tag'] == 'list' ? 'BbsView1' : 'BbsView2';
    _loadAd(_admobId);

    cntr = Get.put(BbsViewController(), tag: _tagNm);
    Get.put(BbsCommentsController(), tag: _tagNm);

    super.initState();
    _initializeBoardId();
  }

  Future<void> _loadAd(String admobId) async {
    await AdManager().loadBannerAd(admobId);
    isAdLoading.value = true;
  }

  void _initializeBoardId() {
    _boardId = Get.arguments['boardId'] ?? '0';
    isDisplayMyListPage = Get.arguments['isDisplayMyListPage'] ?? true;

    if (_boardId == '0') {
      Utils.alertIcon('비정상적인 접근입니다.', icontype: 'E');
      Get.back();
      return;
    }
    cntr.fetchDataInit(_boardId.toString());
  }

  void fetchDataInit() => cntr.fetchDataInit(_boardId);
  void _handleLikePress(bool isLiked) {
    if (cntr.bbsViewData.delYn == 'Y') {
      Utils.alertIcon('삭제된 게시글입니다..', icontype: 'E');
      return;
    }
    if (isLiked) {
      cntr.likeCancel();
      cntr.isCount.value--;
    } else {
      cntr.like();
      cntr.isCount.value++;
    }
    cntr.isLike.value = !isLiked;
  }

  @override
  void dispose() {
    // AdManager().disposeBannerAd('BbsView1');
    cntr.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _buildAppBar(),
          backgroundColor: Colors.white,
          body: _buildBody(),
          bottomNavigationBar: BbsCommentsBottomPage(
            tagNm: _tagNm,
          ),
        ),
        Obx(() {
          if (cntr.isLoading.value) {
            return CustomIndicatorOffstage(isLoading: !cntr.isLoading.value, color: const Color(0xFFEA3799), opacity: 0.5);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      forceMaterialTransparency: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      elevation: 0,
      actions: [
        _buildLikeButton(),
        _buildModifyWindow(),
      ],
    );
  }

  Widget _buildLikeButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: cntr.isLike,
      builder: (context, val, snapshot) {
        lo.g('val : $val');
        return IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () => _handleLikePress(val),
          color: val ? Colors.red : Colors.grey,
        );
      },
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async => await cntr.fetchData(_boardId),
      child: SingleChildScrollView(
        controller: cntr.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Utils.commonStreamBody<BbsListData>(cntr.dataStreamController, _buildContent, fetchDataInit),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BbsListData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(data),
        _buildDivider(),
        const Gap(5),
        _buildSubject(data),
        _buildMainContent(data),
        const Gap(5),
        ValueListenableBuilder<bool>(
            valueListenable: isAdLoading,
            builder: (context, value, child) {
              if (!value) return const SizedBox.shrink();
              return SizedBox(width: double.infinity, child: Center(child: BannerAdWidget(screenName: _admobId)));
            }),
        BbsCommentsPage(
          tagNm: _tagNm,
          mainScrollController: cntr.scrollController,
          bbsListData: data,
        ),
      ],
    );
  }

  Widget _buildSubject(BbsListData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        '${data.subject}',
        style: TextStyle(fontSize: 18, color: data.delYn == 'Y' ? Colors.grey : Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTitle(BbsListData data) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          data.typeDtNm == 'null' || data.typeDtNm == null ? const SizedBox.shrink() : _buildBbsType(data.typeDtNm.toString()),
          Row(
            children: [
              _buildProfileImage(data),
              const Gap(5),
              _buildUserInfo(data),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(BbsListData data) {
    return GestureDetector(
      onTap: () => Get.toNamed('/OtherInfoPage/${data.crtCustId.toString()}'),
      child: data.profilePath != ''
          ? Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green, width: 0.5),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(cacheKey: data.profilePath.toString(), data.profilePath.toString()),
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  data.nickNm.toString().substring(0, 1),
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfo(BbsListData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(data.nickNm.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
        Row(
          children: [
            Text(
              intl.DateFormat('yyyy/MM/dd(EE) HH:MM:ss', 'ko').format(DateTime.parse(data.crtDtm.toString())),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black54),
            ),
            const Gap(10),
            _buildLikeCount(),
            const Gap(5),
            _buildViewCount(data),
          ],
        ),
      ],
    );
  }

  Widget _buildLikeCount() {
    return ValueListenableBuilder<int>(
      valueListenable: cntr.isCount,
      builder: (context, val, snapshot) {
        return RichText(
          text: TextSpan(
            text: "좋아요:",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            children: [
              TextSpan(
                text: ' ${val.toString()}',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewCount(BbsListData data) {
    return RichText(
      text: TextSpan(
        text: "조회수:",
        style: const TextStyle(fontSize: 12, color: Colors.black54),
        children: [
          TextSpan(
            text: ' ${data.viewCnt}',
            style: const TextStyle(fontSize: 12, color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildMainContent(BbsListData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(10),
          MixedContent(
            content: data.contents.toString(),
            videoHeight: 200,
            delYn: data.delYn.toString(),
          ),
          _buildImageList(data),
          const Gap(15),
          isDisplayMyListPage ? _buildMyListPageButton(data) : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildMyListPageButton(BbsListData data) {
    return InkWell(
      onTap: () async {
        final result = await Get.toNamed('/BbsMyListPage/${data.crtCustId.toString()}');
        cntr.fetchDataInit(_boardId);
      },
      child: Container(
        alignment: Alignment.centerRight,
        // color: Colors.grey.withOpacity(0.1),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${data.nickNm.toString()}님 글 보기',
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
            const Gap(3),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black54,
              size: 10,
            ),
          ],
        ),
      ),
    );
  }

  // 회원정보카드
  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green, width: 0.5),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(cacheKey: 'data.profilePath.toString()', 'data.profilePath.toString()'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Gap(5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('data.nickNm.toString()', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
                  Text('data.crtDtm.toString()', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black54)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
          const Gap(10),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildImageList(BbsListData data) {
    if (data.fileList!.isEmpty) return const SizedBox();

    return Column(
      children: data.fileList!.map((fileData) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: GestureDetector(
            // onTap: () => _openImageViewer(fileData.filePath.toString()),
            onTap: () {
              lo.g('data.fileList : ${data.fileList!.map((e) => e.filePath.toString()).toList()}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageListPreview(
                      imageUrls: data.fileList!.map((e) => e.filePath.toString()).toList(), initialIndex: data.fileList!.indexOf(fileData)),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Hero(
                tag: fileData.filePath.toString(),
                child: CachedNetworkImage(
                  cacheKey: fileData.filePath.toString(),
                  imageUrl: fileData.filePath.toString(),
                  fit: BoxFit.cover,
                  // width: double.infinity,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModifyWindow() {
    return SizedBox(
      height: 18,
      child: PopupMenuButton<String>(
        padding: const EdgeInsets.all(0),
        icon: const Icon(Icons.more_vert, size: 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.white,
        onSelected: (String result) => _handleModifyAction(result, cntr.bbsViewData),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          if (Get.find<AuthCntr>().custId.value == cntr.bbsViewData.crtCustId.toString()) ...[
            const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_square, color: Colors.blue, size: 21),
                    const SizedBox(
                      width: 3,
                    ),
                    Text('수정'),
                  ],
                )),
            const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 21,
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Text(
                      '삭제',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
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

  Widget _buildBbsType(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 3, bottom: 3),
      // alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(right: 5, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.deepPurple[300],
        // color: Colors.deepPurple[300],
        // color: Colors.black54,
        borderRadius: BorderRadius.circular(7),
      ),
      child:
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  void _handleModifyAction(String action, BbsListData bbsListData) {
    if (cntr.bbsViewData.delYn == 'Y') {
      Utils.alertIcon('삭제된 게시글입니다..', icontype: 'E');
      return;
    }

    switch (action) {
      case 'edit':
        onEdit(bbsListData.boardId.toString());
        break;
      case 'delete':
        onDelete(bbsListData.boardId.toString());
        break;
      case 'singo':
        SigoPageSheet().open(context, bbsListData.boardId.toString(), bbsListData.crtCustId.toString(), callBackFunction: null);
        break;
    }
  }

  void onEdit(String boardId) async {
    var result = await Get.toNamed('/BBsModifyPage/$boardId');
    lo.g("result : $result");
    if (result == true || result == 'true') {
      Get.back(result: true);
    } else {
      //현재 페이지를 리로드
      fetchDataInit();
    }
  }

  void onDelete(String boardId) {
    String title = "삭제 하시겠습니까?";
    Utils.showConfirmDialog("확인", title, BackButtonBehavior.none, confirm: () async {
      await cntr.delete(boardId).then((onValue) => Get.back(result: true));
    }, cancel: () async {
      Lo.g('cancel');
    }, backgroundReturn: () {});
  }
}

class ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String nickNm;

  const ImageViewer({super.key, required this.imageUrl, required this.nickNm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        centerTitle: false,
        title: Text(nickNm, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: InteractiveViewer(
        child: Padding(
          padding: const EdgeInsets.only(left: 2.0, right: 2.0, top: 0.0),
          child: Center(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fadeInDuration: const Duration(milliseconds: 100),
              fadeOutDuration: const Duration(milliseconds: 100),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}
