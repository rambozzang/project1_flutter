import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:project1/app/short/cntr/short_list_cntr.dart';
import 'package:project1/app/short/comment/short_comments_bottom_page.dart';
import 'package:project1/app/short/short_view_page.dart';
import 'package:project1/app/short/short_write_page.dart';
import 'package:project1/app/short/widgets/image_viewer.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:intl/intl.dart';

class ShortListPage extends StatefulWidget {
  const ShortListPage({super.key});

  @override
  State<ShortListPage> createState() => _ShortListPageState();
}

class _ShortListPageState extends State<ShortListPage> with AutomaticKeepAliveClientMixin {
  final formKey = GlobalKey<FormState>();
  final cntr = Get.find<ShortListController>();

  @override
  bool get wantKeepAlive => true;

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
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      forceMaterialTransparency: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '지역 실시간 제보 공원',
        style: TextStyle(color: Colors.black, fontSize: 18),
      ),
      leadingWidth: 20,
      centerTitle: false,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async => await cntr.getData(1),
      child: SingleChildScrollView(
        controller: cntr.scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(children: [
          Utils.commonStreamList<BbsListData>(cntr.listCtrl, _buildList, cntr.getDataInit),
        ]),
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
        final result = await Get.toNamed('/ShortViewPage', arguments: {'boardId': data.boardId.toString()});
        if (result) {
          cntr.getData(1);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 0.5),
            const Gap(10),
            _buildContentPreview(data),
            const Gap(4),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BbsListData data) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.toNamed('/OtherInfoPage/${data.crtCustId.toString()}'),
          child: _buildUserAvatar(data),
        ),
        const Gap(5),
        _buildUserDetails(data),
        const Spacer(),
      ],
    );
  }

  Widget _buildUserAvatar(BbsListData data) {
    return data.profilePath != ''
        ? Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green, width: 0.9),
              image: DecorationImage(
                image: CachedNetworkImageProvider(cacheKey: data.profilePath.toString(), data.profilePath.toString()),
                fit: BoxFit.cover,
              ),
            ),
          )
        : Container(
            height: 38,
            width: 38,
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
          );
  }

  Widget _buildUserDetails(BbsListData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(data.nickNm.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Text(' · '),
            Text(Utils.timeage(data.crtDtm.toString()), style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
        Text(intl.DateFormat('yyyy.MM.dd(EE) HH:MM:ss', 'ko').format(DateTime.parse(data.crtDtm.toString())),
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _buildContentPreview(BbsListData data) {
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
                data.subject!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                data.contents!,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),

        _buildPostStats(data),
        // _buildThumbnail(data),
      ],
    );
  }

  Widget _buildPostStats(BbsListData data) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      const Text('좋아요', style: TextStyle(fontSize: 11, color: Colors.black87)),
      const Gap(4),
      Text(data.likeCnt.toString(), style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
      const Gap(14),
      const Text('조회수', style: TextStyle(fontSize: 11, color: Colors.black87)),
      const Gap(4),

      Text(data.viewCnt.toString(), style: const TextStyle(fontSize: 11, color: Colors.redAccent)),

      // const Text(' · '),
      // const Text('댓글', style: TextStyle(fontSize: 13, color: Colors.black87)),
      // const Gap(4),
      // Text(data.replyCnt.toString(), style: const TextStyle(fontSize: 13, color: Colors.deepPurpleAccent)),
      // const Spacer(),
      // const Text('조회', style: TextStyle(fontSize: 13, color: Colors.black87)),
      // const Gap(4),
      // Text(data.viewCnt.toString(), style: const TextStyle(fontSize: 13, color: Colors.black87)),
    ]);
  }
}
