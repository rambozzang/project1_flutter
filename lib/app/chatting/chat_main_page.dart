import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
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
        //   child: CircleAvatar(
        //     backgroundColor: hasImage ? Colors.transparent : color,
        //     backgroundImage: hasImage ? CachedNetworkImageProvider(room.imageUrl!) : null,
        //     radius: 20,
        //     child: !hasImage
        //         ? Text(
        //             name.isEmpty ? '' : name[0].toUpperCase(),
        //             style: const TextStyle(color: Colors.white),
        //           )
        //         : null,
        //   ),
        // );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // _userController.stream.listen((event) {
    //   lo.g(' ._userController() > event : $event');
    // });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          initSupaBaseSession();
        },
        child: Column(
          children: [
            const Gap(10),
            // StreamBuilder<User>(
            //     stream: _userController.stream,
            //     builder: (context, snapshot) {
            //       if (snapshot.hasError) {
            //         return const Padding(
            //           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.end,
            //             children: [
            //               Positioned(child: Text("Error", style: TextStyle(color: Colors.green, fontSize: 12))),
            //               Divider(
            //                 height: 3,
            //                 thickness: 3,
            //                 color: Colors.red,
            //               ),
            //             ],
            //           ),
            //         );
            //       }

            //       if (!snapshot.hasData) {
            //         return Container(
            //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //           child: const Text('Loading...'),
            //         );
            //       }
            //       // return const SizedBox(height: 16);
            //       return const Padding(
            //         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.end,
            //           children: [
            //             Positioned(child: Text("Online", style: TextStyle(color: Colors.green, fontSize: 12))),
            //             Divider(
            //               height: 3,
            //               thickness: 3,
            //               color: Colors.green,
            //             ),
            //           ],
            //         ),
            //       );
            //       User data = snapshot.data!;
            //       // return Container(
            //       //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //       //   child: Row(
            //       //     children: [
            //       //       Text(
            //       //         data.email ?? '',
            //       //         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            //       //       ),
            //       //       const Spacer(),
            //       //       IconButton(
            //       //         icon: const Icon(
            //       //           Icons.person,
            //       //         ),
            //       //         onPressed: _user == null
            //       //             ? null
            //       //             : () {
            //       //                 Navigator.of(context).push(
            //       //                   MaterialPageRoute(
            //       //                     fullscreenDialog: true,
            //       //                     builder: (context) => const UsersPage(),
            //       //                   ),
            //       //                 );
            //       //               },
            //       //       ),
            //       //       TextButton(
            //       //         onPressed: () => initSupaBaseSession(),
            //       //         child: const Icon(
            //       //           Icons.refresh,
            //       //           color: Colors.black,
            //       //         ),
            //       //       ),
            //       //     ],
            //       //   ),
            //       // );
            //     }),
            Expanded(
              child: StreamBuilder<List<types.Room>>(
                stream: SupabaseChatCore.instance.rooms(orderByUpdatedAt: false),
                // initialData: const [],
                builder: (context, snapshot) {
                  lo.g('SupabaseChatCore.instance.rooms() > snapshot.data : ${snapshot.data}');
                  lo.g('SupabaseChatCore.instance.rooms() > snapshot.data : ${snapshot.connectionState}');
                  // if (snapshot.connectionState == ConnectionState.waiting) {
                  //   return Container(
                  //     alignment: Alignment.center,
                  //     margin: const EdgeInsets.only(
                  //       bottom: 200,
                  //     ),
                  //     child: Utils.progressbar(),
                  //   );
                  // }
                  if (!snapshot.hasData) {
                    return Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(
                        bottom: 200,
                      ),
                      child: const Text('대화 내용이 없습니다.'),
                    );
                  }
                  if (snapshot.data!.isEmpty) {
                    return Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(
                        bottom: 200,
                      ),
                      child: const Text('대화 내용이 없습니다.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    controller: RootCntr.to.hideButtonController4,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final room = snapshot.data![index];
                      // room.name이 null이면 대화방만 만들어 대화를 안한상태로 가비지 처리 해야함.
                      if (room.name == null) {
                        SupabaseChatCore.instance.deleteRoom(room.id);
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

      // Container(
      //       alignment: Alignment.center,
      //       margin: const EdgeInsets.only(
      //         bottom: 200,
      //       ),
      //       child: Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: [
      //           const Text('메시지 서버 재접속이 필요합니다.'),
      //           TextButton(
      //             onPressed: () => initializeFlutterFire(),
      //             child: const Text('Refresh'),
      //           ),
      //         ],
      //       ),
      //     )
    );
  }

  buildItem(types.Room room) {
    // 메세지가 있으면 마지막 메세지를 보여준다.
    // if (room.lastMessages!.first != null) {
    //   Utils.alert("DM : ${(room.lastMessages!.first as types.TextMessage).text}");

    //   lo.g('room.lastMessages!.first : ${(room.lastMessages!.first as types.TextMessage).text}');
    // }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(room),
          const Gap(10),
          Expanded(
            child: ElevatedButton(
              clipBehavior: Clip.none,
              style: ElevatedButton.styleFrom(
                shadowColor: Colors.transparent,
                // fixedSize: Size(0, 0),
                // minimumSize: Size.zero, // Set this
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
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     fullscreenDialog: true,
                //     builder: (context) => ChatPage(room: room),
                //   ),
                // );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name.toString(),
                    softWrap: true,
                    // overflow: TextOverflow.fade,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  Text(
                    room.lastMessages != null && room.lastMessages!.isNotEmpty && room.lastMessages!.first is types.TextMessage
                        ? (room.lastMessages!.first as types.TextMessage).text
                        : '',
                    softWrap: true,
                    // overflow: TextOverflow.fade,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          // const Spacer(),
          const Gap(10),
          Text(
            timeago.format(DateTime.now().subtract(Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - (room.updatedAt ?? 0))),
                locale: 'ko_short'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
