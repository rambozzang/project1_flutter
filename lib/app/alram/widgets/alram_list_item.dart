import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:gap/gap.dart';
import 'package:project1/repo/alram/data/alram_res_data.dart';
import 'package:project1/route/app_route.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

class AlramListItem extends StatelessWidget {
  final AlramResData data;

  const AlramListItem({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      clipBehavior: Clip.none,
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.transparent,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        backgroundColor: Colors.transparent,
      ),
      onPressed: () => _handleItemTap(),
      child: _buildItemContent(),
    );
  }

  Widget _buildProfileImage() {
    if (!StringUtils.isEmpty(data.profilePath)) {
      return Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: CachedNetworkImageProvider(cacheKey: data.profilePath.toString(), data.profilePath.toString()),
              fit: BoxFit.cover,
            ),
          ));
    }

    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Text(
          (data.senderNickNm == null ? data.senderCustNm.toString() : data.senderNickNm.toString()).substring(0, 1),
          style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(),
        _buildContents(),
        _buildFooter(),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          data.alramTitle.toString(),
          softWrap: true,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildContents() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            data.alramContents.toString(),
            overflow: TextOverflow.clip,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          ),
        ),
        const Gap(5),
        if (data.boardId != null) _buildBoardLink() else const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildBoardLink() {
    return SizedBox(
      width: 20,
      height: 25,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
        ),
        onPressed: () {
          AppPages.goRoute(data.alramCd.toString(), AuthCntr.to.resLoginData.value.custId.toString(), data.boardId.toString());
        },
        child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
      ),
    );
  }

  Widget _buildFooter() {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            data.senderNickNm == null ? data.senderCustNm.toString() : data.senderNickNm.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.0,
              color: Colors.black54,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              '·',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
          Text(
            Utils.timeage(data.crtDtm.toString()),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _handleItemTap() {
    if (data.boardId != null) {
      Get.toNamed('/VideoMyinfoListPage',
          arguments: {'datatype': 'ONE', 'custId': AuthCntr.to.resLoginData.value.custId, 'boardId': data.boardId.toString()});
    } else {
      Get.toNamed('/OtherInfoPage/${data.senderCustId}');
    }
  }

  Widget _buildItemContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileImage(),
        const Gap(10),
        Expanded(
          child: _buildMessageContent(),
        ),
      ],
    );
  }
}
