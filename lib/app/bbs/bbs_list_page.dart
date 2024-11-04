import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/bbs/YouTubeTextExtractor.dart';
import 'package:project1/app/bbs/ani_button.dart';
import 'package:project1/app/bbs/cntr/bbs_list_cntr.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:intl/intl.dart';

class BbsListPage extends StatefulWidget {
  const BbsListPage({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<BbsListPage> createState() => _BbsListPageState();
}

class _BbsListPageState extends State<BbsListPage> with AutomaticKeepAliveClientMixin {
  final formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  final cntr = Get.put(BbsListController());
  double appbarBottomHeight = Platform.isIOS ? 110 : 80;

  @override
  bool get wantKeepAlive => true;

  TextStyle getStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54);

  @override
  void initState() {
    super.initState();
    init();
    _loadAd();
  }

  Future<void> init() async {
    cntr.onInitScrollCtrl(widget.scrollController);
    await cntr.getData(1);
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('BbsList1');
    isAdLoading.value = true;
  }

  @override
  void dispose() {
    AdManager().disposeBannerAd('BbsList1');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: _buildBody(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async => await cntr.getData(1, searchType: cntr.typeDtCd.value),
      child: ListView(
        controller: cntr.scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        children: [
          Gap(appbarBottomHeight),
          ValueListenableBuilder<bool>(
              valueListenable: isAdLoading,
              builder: (context, value, child) {
                if (!value) return const SizedBox.shrink();
                return const SizedBox(width: double.infinity, child: Center(child: BannerAdWidget(screenName: 'BbsList1')));
              }),
          const Gap(10),
          Container(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...cntr.bbsTypeList.map((e) {
                          return buildButtonDetail(e.codeNm.toString(), e.code.toString());
                        }),
                      ],
                    )),
              )),
          const Gap(10),
          Utils.commonStreamList<BbsListData>(cntr.listCtrl, _buildList, cntr.getDataInit),
          _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget buildButtonDetail(String title, String type) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: SizedBox(
            height: 30,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),

                backgroundColor: cntr.typeDtCd.value == type ? Colors.black : Colors.grey[200],
                // backgroundColor: val == type ? const Color.fromARGB(255, 54, 81, 50) : const Color.fromARGB(255, 80, 118, 75),
                //   color: const Color.fromARGB(255, 80, 118, 75).withOpacity(0.7),
                // padding: const EdgeInsets.symmetric(horizontal: 4),
                // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                      color: cntr.typeDtCd.value == type ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              onPressed: () async {
                cntr.typeDtCd.value = type;
                cntr.getData(1, searchType: type);
              },
            ),
          ),
        ),
        cntr.typeDtCd.value == type
            ? Positioned(
                top: -2,
                right: 0,
                child: Icon(Icons.check_circle, color: Colors.amber[600], size: 15),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: cntr.isMoreLoading,
      builder: (context, val, snapshot) {
        return val ? SizedBox(height: 60, child: Utils.progressbar()) : const SizedBox(height: 60);
      },
    );
  }

  Widget _buildFloatingActionButton() {
    double kFloatingActionButtonMargin = Platform.isAndroid ? 65.0 : 50.0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom) +
          EdgeInsets.only(right: 5, bottom: kFloatingActionButtonMargin),
      child: AnimatedFloatingButton(
        onPressed: () async {
          final result = await Get.toNamed(
            '/BbsWritePage',
          );
          if (result) {
            cntr.getData(1, searchType: cntr.typeDtCd.value);
          }
        },
        text: '글쓰기',
        icon: Icons.edit_square,
      ),
    );
  }

  Widget _buildList(List<BbsListData> list) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.length,
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      padding: const EdgeInsets.all(0),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return _buildItem(list[index]);
      },
    );
  }

  Widget _buildItem(BbsListData data) {
    return InkWell(
      onTap: () async {
        var result = await Get.toNamed('/BbsViewPage', arguments: {'boardId': data.boardId.toString(), 'tag': 'list'});
        lo.g("resultresultresult : $result");
        if (result) {
          await cntr.getData(1, searchType: cntr.typeDtCd.value);
          return;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Divider(
              height: 1,
              thickness: 0.5,
            ),
            const Gap(5),
            _buildItemHeader(data),
            const Gap(7),
            _buildItemContent(data),
            // const Gap(4),
            _buildItemFooter(data),
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader(BbsListData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildProfileImage(data),
        const Gap(4),
        _buildUserInfo(data),
        const Spacer(),
        cntr.typeDtCd.value == 'ALL' ? _buildBbsType(data.typeDtNm.toString()) : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildBbsType(String title) {
    return title == 'null'
        ? const SizedBox.shrink()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            // margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              // color: Colors.brown[400],
              // color: const Color.fromARGB(255, 114, 137, 120),
              color: Colors.deepPurple[300],
              // color: Colors.black54,
              // color: const Color(0xff93C90F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(title,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
          );
  }

  Widget _buildProfileImage(BbsListData data) {
    return GestureDetector(
      onTap: () => Get.toNamed('/OtherInfoPage/${data.crtCustId.toString()}'),
      child: data.profilePath != ''
          ? Container(
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey, width: 0.9),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(cacheKey: data.profilePath.toString(), data.profilePath.toString()),
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
                  data.nickNm.toString().substring(0, 1),
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
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
        Row(
          children: [
            Text(data.nickNm.toString(), style: getStyle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                '·',
                style: getStyle,
              ),
            ),
            Text(Utils.timeage(data.crtDtm.toString()), style: getStyle),
          ],
        ),
        // Text(intl.DateFormat('yyyy.MM.dd(EE) HH:MM:ss', 'ko').format(DateTime.parse(data.crtDtm.toString())), style: getStyle),
      ],
    );
  }

  Widget _buildItemContent(BbsListData data) {
    List<ContentPart> contentParts = MixedContentParser.parseContent(data.contents!);

    bool isYoutube = false;
    bool isImg = false;

    late String imageUrl;
    // YouTube 컨트롤러 초기화
    for (var part in contentParts) {
      if (part is YoutubePart) {
        if (isYoutube) continue;
        isYoutube = true;
      } else if (part is ImagePart) {
        if (isImg) continue;
        isImg = true;
        imageUrl = part.imageUrl;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                data.subject.toString(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: data.delYn == 'Y' ? Colors.grey : Colors.black),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                data.contents!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
              // const SizedBox(height: 5),
            ],
          ),
        ),
        if (isYoutube) ...[
          const Gap(5),
          const Icon(Icons.video_collection, size: 18, color: Colors.red),
        ],
        if (isImg) ...[
          const Gap(5),
          if (!(data.fileList == null || data.fileList!.isEmpty)) ...[
            const Icon(Icons.image, size: 18, color: Colors.purple),
          ],
          if (data.fileList == null || data.fileList!.isEmpty) ...[
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 65,
                width: 65,
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
        _buildThumbnail(data),
      ],
    );
  }

  Widget _buildThumbnail(BbsListData data) {
    if (data.fileList == null || data.fileList!.isEmpty) return const SizedBox();
    return Flexible(
      flex: 1,
      child: Container(
        color: Colors.grey[200],
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: CachedNetworkImage(
                imageUrl: data.fileList!.first.filePath.toString(),
                height: 65,
                width: 65,
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(5)),
                ),
                child: Text(
                  data.fileList!.length.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemFooter(BbsListData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Gap(2),
          if (data.likeYn == 'Y') ...[
            const Icon(Icons.favorite, size: 13, color: Colors.red),
          ],
          if (data.likeYn == 'N') ...[
            const Icon(Icons.favorite_border_outlined, size: 13, color: Colors.black87),
          ],
          const Gap(4),
          Text(data.likeCnt.toString(), style: TextStyle(fontSize: 13, color: data.likeYn == 'Y' ? Colors.redAccent : Colors.black87)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(' '),
          ),
          const Icon(Icons.chat, size: 13, color: Colors.black87),
          const Gap(4),
          Text(data.replyCnt.toString(), style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
          // const Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 5.0),
          //   child: Text(' · '),
          // ),
          const Spacer(),
          Text('조회수', style: getStyle),
          const Gap(3),
          Text(data.viewCnt.toString(), style: getStyle),
        ],
      ),
    );
  }

  Widget _buildModifyWindow(BbsListData bbsListData) {
    return SizedBox(
      height: 20,
      child: PopupMenuButton<String>(
        padding: const EdgeInsets.all(0),
        icon: const Icon(Icons.more_vert, size: 18),
        color: Colors.white,
        onSelected: (String result) {
          switch (result) {
            case 'edit':
              // onEdit();
              break;
            case 'delete':
              // onDelete();
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'edit', child: Text('수정')),
          const PopupMenuItem<String>(value: 'delete', child: Text('삭제')),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else {
      return DateFormat('yyyy년 MM월 dd일').format(date);
    }
  }
}
