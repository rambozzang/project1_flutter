import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:project1/app/bbs/ani_button.dart';
import 'package:project1/app/bbs/cntr/bbs_search_list_cntr.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:intl/intl.dart';

class BbsSearchListPage extends StatefulWidget {
  const BbsSearchListPage({super.key});

  @override
  State<BbsSearchListPage> createState() => _BbsSearchListPageState();
}

class _BbsSearchListPageState extends State<BbsSearchListPage> with AutomaticKeepAliveClientMixin {
  final formKey = GlobalKey<FormState>();
  final cntr = Get.put(BbsSearchListController());

  @override
  bool get wantKeepAlive => true;

  TextStyle getStyle = const TextStyle(fontSize: 12, height: 1.0, fontWeight: FontWeight.w500, color: Colors.black54);

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await cntr.getData(1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async => await cntr.getData(1),
      child: ListView(
        controller: cntr.scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        children: [
          const Gap(40),
          Utils.commonStreamList<BbsListData>(cntr.listCtrl, _buildList, cntr.getDataInit),
          _buildLoadingIndicator(),
        ],
      ),
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
          EdgeInsets.only(right: 10, bottom: kFloatingActionButtonMargin),
      child: AnimatedFloatingButton(
        onPressed: () async {
          final result = await Get.toNamed('/BbsWritePage');
          if (result) {
            cntr.getData(1);
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
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return _buildItem(list[index]);
      },
    );
  }

  Widget _buildItem(BbsListData data) {
    return InkWell(
      onTap: () async {
        final result = await Get.toNamed('/BbsViewPage', arguments: {'boardId': data.boardId.toString()});
        if (result) {
          cntr.getData(1);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 0.5),
            const Gap(5),
            _buildItemHeader(data),
            const Gap(10),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildProfileImage(data),
        const Gap(4),
        _buildUserInfo(data),
        const Spacer(),
        // if (data.crtCustId == AuthCntr.to.custId.value) _buildModifyWindow(data),
      ],
    );
  }

  Widget _buildProfileImage(BbsListData data) {
    return GestureDetector(
      onTap: () => Get.toNamed('/OtherInfoPage/${data.crtCustId.toString()}'),
      child: data.profilePath != ''
          ? Container(
              height: 29,
              width: 29,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey, width: 0.9),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(cacheKey: data.profilePath.toString(), data.profilePath.toString()),
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Container(
              height: 29,
              width: 29,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0),
              child: Text('·'),
            ),
            Text(Utils.timeage(data.crtDtm.toString()), style: getStyle),
          ],
        ),
        Text(intl.DateFormat('yyyy.MM.dd(EE) HH:MM:ss', 'ko').format(DateTime.parse(data.crtDtm.toString())), style: getStyle),
      ],
    );
  }

  Widget _buildItemContent(BbsListData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.subject.toString(),
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: data.subject.toString() == '[삭제된 ]' ? Colors.grey : Colors.black),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                data.contents!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
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
                height: 80,
                width: 80,
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
    return Row(
      children: [
        Text('좋아요', style: getStyle),
        const Gap(4),
        if (data.likeYn == 'Y') ...[const Icon(Icons.favorite, size: 12, color: Colors.red), const Gap(3)],
        Text(data.likeCnt.toString(), style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
        const Text(' · '),
        Text('댓글', style: getStyle),
        const Gap(4),
        Text(data.replyCnt.toString(), style: const TextStyle(fontSize: 12, color: Colors.deepPurpleAccent)),
        const Spacer(),
        Text('조회', style: getStyle),
        const Gap(4),
        Text(data.viewCnt.toString(), style: getStyle),
      ],
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
