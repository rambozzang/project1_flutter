import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/follow_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_room_page.dart';
import 'util.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  StreamController<ResStream<List<FollowData>>> listCntr = StreamController();
  List<FollowData> followList = [];

  // late final _future ;
  @override
  void initState() {
    super.initState();
    // _future = Supabase.instance.client.schema('chat').from('users').select();
    getInitFollowList();
  }

  getInitFollowList() {
    getFollowList(1);
  }

  // followType 0: 팔로잉, 1: 팔로워
  // follow list 가져오기
  void getFollowList(int followType) async {
    try {
      listCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getFollowList(followType, AuthCntr.to.resLoginData.value.custId.toString());
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        listCntr.sink.add(ResStream.error(res.msg.toString()));
        return;
      }
      followList.clear();

      followList = ((res.data) as List).map((data) => FollowData.fromMap(data)).toList();
      listCntr.sink.add(ResStream.completed(followList));
    } catch (e) {
      Utils.alert("팔로우 리스트 가져오기 실패");
      listCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  void addAlram(String yn) async {
    try {
      BoardRepo repo = BoardRepo();
      ResData res = await repo.changeFollowAlram(AuthCntr.to.resLoginData.value.custId.toString(), yn);
      if (res.code == '00') {
        listCntr.sink.add(ResStream.completed(followList));
      }
    } catch (e) {
      Utils.alert("알람 설정 실패");
    }
  }

  Widget _buildAvatar(types.User user) {
    final color = getUserAvatarNameColor(user);
    final hasImage = user.imageUrl != null;
    final name = getUserName(user);
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: UserOnlineStatusWidget(
        uid: user.id,
        builder: (status) => Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              backgroundColor: hasImage ? Colors.transparent : color,
              backgroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
              radius: 20,
              child: !hasImage
                  ? Text(
                      name.isEmpty ? '' : name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            if (status == UserOnlineStatus.online)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 3, bottom: 3),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePressed(types.User otherUser, BuildContext context) async {
    final navigator = Navigator.of(context);
    final room = await SupabaseChatCore.instance.createRoom(otherUser);
    navigator.pop();
    Get.to(ChatPage(room: room));
    // await navigator.push(
    //   MaterialPageRoute(
    //     builder: (context) => ChatPage(
    //       room: room,
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          centerTitle: false,
          titleSpacing: -2,
          title: const Text(
            '대화 가능한 사용자 - 팔우잉',
            style: TextStyle(color: Colors.black, fontSize: 14),
          ),
        ),
        body: SingleChildScrollView(
          child: Expanded(
            child: Column(
              children: [
                Container(
                    //    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Utils.commonStreamList<FollowData>(listCntr, buildList, getInitFollowList)),
                const Divider(
                  height: 10,
                ),
                StreamBuilder<List<types.User>>(
                  stream: SupabaseChatCore.instance.users(),
                  // initialData: const [],
                  builder: (context, snapshot) {
                    log('snapshot: ${snapshot.data}');
                    if (!snapshot.hasData) {
                      return Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(
                          bottom: 200,
                        ),
                        child: Utils.progressbar(),
                      );
                    }
                    if (snapshot.data!.isEmpty) {
                      return Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(
                          bottom: 200,
                        ),
                        child: const Text('대화(팔로워) 상대가 없습니다.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final user = snapshot.data![index];
                        return ListTile(
                          leading: _buildAvatar(user),
                          title: Text(getUserName(user)),
                          onTap: () {
                            _handlePressed(user, context);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

  Widget buildList(List<FollowData> list) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: list.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return buildItem(list[index]);
        });
  }

  Widget buildItem(FollowData data) {
    return InkWell(
      onTap: () => Get.toNamed('/OtherInfoPage/${data.custId}'),
      child: Container(
        //height: 50,
        decoration: BoxDecoration(
          //  color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  // color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(data.profilePath.toString()),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white)),
            const Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${data.selfId ?? data.custNm}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${data.nickNm} ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                print('object');
              },
              child: Container(
                height: 30,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text("팔로잉", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal))),
              ),
            ),
            IconButton(
              onPressed: () => addAlram(data.alramYn.toString() == 'Y' ? 'Y' : 'N'),
              icon: Icon(Icons.alarm_add, color: data.alramYn.toString() == 'Y' ? Colors.grey.shade400 : Colors.black),
            )
          ],
        ),
      ),
    );
  }
}
