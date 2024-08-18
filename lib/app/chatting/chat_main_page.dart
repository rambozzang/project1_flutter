import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/chatting/lib/flutter_supabase_chat_core.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'chat_room_page.dart';
import 'util.dart';

class ChatMainApp extends StatefulWidget {
  const ChatMainApp({super.key});

  @override
  State<ChatMainApp> createState() => ChatMainAppState();
}

class ChatMainAppState extends State<ChatMainApp> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  StreamController<User> _userController = StreamController<User>.broadcast();

  User? _user;
  ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  List<String> roomlist = [];
  @override
  void initState() {
    super.initState();
    initSupaBaseSession();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _userController.add(_user!);
      }
    });
    _loadAd();
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('AlramPage2');
    isAdLoading.value = true;
  }

  Future<void> initSupaBaseSession() async {
    setState(
      () {},
    );
    try {
      // 1.세션이 존재하는지 체크 한다.
      _user = Supabase.instance.client.auth.currentUser;
      lo.g('Supabase 세션에 회원 체크 : _user : $_user');

      if (_user != null) {
        await updateUserInfo(_user!.id);
        _userController.add(_user!);
        return;
      }

      // 2.없으면 로그인을 시도한다.
      lo.g("로그인 시도 1: ${Get.find<AuthCntr>().resLoginData.value.email} / ${Get.find<AuthCntr>().resLoginData.value.custId}");
      AuthResponse authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: Get.find<AuthCntr>().resLoginData.value.email,
        password: Get.find<AuthCntr>().resLoginData.value.custId!,
      );
      _user = authRes.session?.user;
      lo.g("로그인 시도 결과 : $_user");

      if (_user != null) {
        await updateUserInfo(_user!.id);
        _userController.add(_user!);
        return;
      }

      // 4.로그인이 안되면 회원가입을 시도한다.
      signUp();

      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        lo.g('Supabase onAuthStateChange : ${data.session}');
        lo.g('Supabase onAuthStateChange: $_user');

        _user = data.session?.user;
        Utils.alertIcon('Supabase 세션에 회원 체크 : _user : $_user', icontype: 'W');
      });
    } catch (e) {
      lo.g('initSupaBaseSession() error : $e');
      signUp();
    }
  }

  Future<User> signUp() async {
    lo.g("회원 가입 시도");

    try {
      var resLoginData = Get.find<AuthCntr>().resLoginData.value;

      final response = await Supabase.instance.client.auth.signUp(
        email: resLoginData.email,
        password: resLoginData.custId!,
      );
      await updateUserInfo(response.user!.id);
      return response.user!;
    } catch (e) {
      lo.g('error : $e');
      lo.g('error : ${Get.find<AuthCntr>().resLoginData.value.email}');
      lo.g('error : ${Get.find<AuthCntr>().resLoginData.value.custId}');
      AuthResponse authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: Get.find<AuthCntr>().resLoginData.value.email,
        password: Get.find<AuthCntr>().resLoginData.value.custId!,
      );

      _user = authRes.session?.user;
      _userController.add(_user!);
      return _user!;
    }
  }

  Future<void> updateUserInfo(String chatUid) async {
    try {
      var resLoginData = Get.find<AuthCntr>().resLoginData.value;

      String name = resLoginData.nickNm ?? '';
      if (resLoginData.nickNm == 'null' || resLoginData.nickNm == null || resLoginData.nickNm == '') {
        name = resLoginData.custNm!;
      }

      Map<String, dynamic> metadata = {
        'email': resLoginData.email ?? '',
        'custId': resLoginData.custId ?? '',
        'nickNm': resLoginData.nickNm ?? '',
        'custNm': resLoginData.custNm ?? '',
        'selfId': resLoginData.custData?.selfId ?? '',
      };
      // supabase chat 서버에 회원정보 업데이트
      await SupabaseChatCore.instance
          .updateUser(types.User(id: chatUid, firstName: name, lastName: "", imageUrl: resLoginData.profilePath, metadata: metadata));
      _user = Supabase.instance.client.auth.currentUser;

      // 우리 서버 ChatId 업데이트 처리
      // CustRepo repo = CustRepo();
      // repo.updateChatId(resLoginData.custId!, chatUid);

      if (_user != null) {
        _userController.add(_user!);
        return;
      }
    } catch (e) {
      lo.g('updateUserInfo() error : $e');
    }
  }

  void logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  Widget _buildAvatar(types.Room room) {
    var color = Colors.transparent;
    types.User? otherUser;

    if (room.type == types.RoomType.direct) {
      try {
        otherUser = room.users.firstWhere(
          (u) => u.id != _user!.id,
        );

        color = getUserAvatarNameColor(otherUser);
      } catch (e) {
        // Do nothing if the other user is not found.
      }
    }

    bool hasImage = room.imageUrl != null;
    final name = room.name ?? '';

    final Widget child = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          shape: BoxShape.circle,
        ),
        child: Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: hasImage ? Colors.transparent : color,
            // color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            image: hasImage
                ? DecorationImage(
                    image: CachedNetworkImageProvider(room.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasImage
              ? Center(
                  child: Text(
                    name.isEmpty ? '' : name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        ));

    if (otherUser == null) {
      return Container(
        margin: const EdgeInsets.only(right: 2),
        child: child,
      );
    }

    // Se `otherUser` non è null, la stanza è diretta e possiamo mostrare l'indicatore di stato online.
    return GestureDetector(
      onTap: () {
        if (otherUser?.metadata?['custId'] == null) {
          Utils.alert('ID 정보가 누락되었습니다. ');
        } else {
          Get.toNamed('/OtherInfoPage/${otherUser?.metadata?['custId'] ?? ''}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 0),
        child: UserOnlineStatusWidget(
          uid: otherUser.id,
          builder: (status) => Stack(
            alignment: Alignment.bottomRight,
            children: [
              child,
              if (status == UserOnlineStatus.online) // Assumendo che `status` indichi lo stato online
                Container(
                  width: 15,
                  height: 15,
                  margin: const EdgeInsets.only(right: 1, bottom: 1),
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
      ),
    );
  }

  @override
  void dispose() {
    _userController.close();

    AdManager().disposeBannerAd('AlramPage2');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          initSupaBaseSession();
        },
        child: Column(
          children: [
            const Gap(10),
            ValueListenableBuilder<bool>(
                valueListenable: isAdLoading,
                builder: (context, value, child) {
                  if (!value) return const SizedBox.shrink();
                  return const SizedBox(width: double.infinity, child: Center(child: BannerAdWidget(screenName: 'AlramPage2')));
                }),
            const Gap(10),
            Expanded(
              child: StreamBuilder<List<types.Room>>(
                stream: SupabaseChatCore.instance.rooms(orderByUpdatedAt: false),
                builder: (context, snapshot) {
                  lo.g('StreamBuilder state: ${snapshot.connectionState}');
                  lo.g('StreamBuilder data: ${snapshot.data}');
                  lo.g('StreamBuilder error: ${snapshot.error}');

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Utils.progressbar());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 200),
                      child: const Text('대화 내용이 없습니다.'),
                    );
                  }

                  final rooms = snapshot.data!.where((room) => room.name != null && room.lastMessages != null).toList();

                  if (rooms.isEmpty) {
                    return Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 200),
                      child: const Text('대화방이 없습니다.'),
                    );
                  }

                  roomlist.clear();
                  return ListView.builder(
                    itemCount: rooms.length,
                    controller: RootCntr.to.hideButtonController4,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      // room.name이 null이면 대화방만 만들어 대화를 안한상태로 가비지 처리 해야함.
                      if (room.name == null || room.lastMessages == null) {
                        //   SupabaseChatCore.instance.deleteRoom(room.id);
                        return const SizedBox.shrink();
                      }
                      return buildItem(room);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildItem(types.Room room) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(room),
          const Gap(10),
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                _showRoomOptions(room);
              },
              child: ElevatedButton(
                clipBehavior: Clip.none,
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  backgroundColor: Colors.transparent,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () {
                  Get.to(ChatPage(room: room));
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name.toString(),
                      softWrap: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    Text(
                      room.lastMessages!.isNotEmpty ? (room.lastMessages!.first as types.TextMessage).text : '',
                      softWrap: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeago.format(
                    DateTime.now().subtract(Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - (room.updatedAt ?? 0))),
                    locale: 'ko_short'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const Gap(5),
              (room.lastMessages?.first.author.id != _user?.id && room.metadata!['unreadCount'] != 0)
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${room.metadata!['unreadCount']}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    )
                  : const SizedBox.shrink(),
              const Gap(10),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoomOptions(types.Room room) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('채팅방 옵션'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('방 나가기'),
                onTap: () {
                  Navigator.pop(context);
                  _leaveRoom(room);
                },
              ),
              ListTile(
                title: Text('차단하기'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(room);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _leaveRoom(types.Room room) async {
    // 방 나가기 로직 구현
    try {
      await SupabaseChatCore.instance.leaveRoom(room.id);
      Utils.alert('채팅방에서 나왔습니다.');
      setState(() {}); // 리스트 갱신
    } catch (e) {
      Utils.alert('방 나가기 실패: $e');
    }
  }

  void _blockUser(types.Room room) async {
    String otherCustId = '';
    // 차단하기 로직 구현
    // 이 부분은 실제 차단 기능 구현에 따라 달라질 수 있습니다.
    for (var user in room.users) {
      lo.g("user.id : ${user.id}");
      if (user.id != AuthCntr.to.resLoginData.value.chatId) {
        otherCustId = user?.metadata?['custId'] ?? '';
      }
    }
    BoardRepo repo = BoardRepo();
    String reason = '채팅방목록에서 차단';
    String boardId = '';
    // dropdownValue 07 이면 사용자신고(거절) 이므로 boardID 대신 상대방 custId를 넘긴다.
    // boardId = dropdownValue == '07' ? widget.crtCustId : boardId;
    await repo.saveSingo(boardId, otherCustId, otherCustId, reason);
    Utils.alert('차단이 완료되었습니다.');

    setState(() {}); // 리스트 갱신
  }

  Widget buildUserState() {
    return const SizedBox.shrink();
  }
}
