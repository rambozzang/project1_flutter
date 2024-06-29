// import 'dart:async';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
// import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
// import 'package:gap/gap.dart';
// import 'package:get/get.dart';
// import 'package:project1/utils/log_utils.dart';
// import 'package:project1/utils/utils.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:timeago/timeago.dart' as timeago;

// import 'auth.dart';
// import 'chat.dart';
// import 'users.dart';
// import 'util.dart';

// class RoomsPage extends StatefulWidget {
//   const RoomsPage({super.key});

//   @override
//   State<RoomsPage> createState() => _RoomsPageState();
// }

// class _RoomsPageState extends State<RoomsPage> with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   bool _error = false;
//   bool _initialized = false;
//   User? _user;

//   StreamController<AuthState> _sessionController = StreamController<AuthState>.broadcast();
//   StreamController<List<types.Room>> _roomsController = StreamController<List<types.Room>>.broadcast();

//   @override
//   void initState() {
//     initializeFlutterFire();
//     super.initState();
//   }

//   void initializeFlutterFire() async {
//     try {
//       _user = Supabase.instance.client.auth.currentUser;

//       if (_user != null) {
//         setState(() {
//           _initialized = true;
//         });
//         return;
//       }

//       Supabase.instance.client.auth.onAuthStateChange.listen((data) {
//         lo.g('Supabase : ' + data.session.toString());
//         setState(() {
//           _user = data.session?.user;
//         });
//       });
//       setState(() {
//         _initialized = true;
//       });
//     } catch (e) {
//       setState(() {
//         _error = true;
//       });
//     }
//   }

//   void logout() async {
//     await Supabase.instance.client.auth.signOut();
//   }

//   Widget _buildAvatar(types.Room room) {
//     var color = Colors.transparent;
//     types.User? otherUser;

//     if (room.type == types.RoomType.direct) {
//       try {
//         otherUser = room.users.firstWhere(
//           (u) => u.id != _user!.id,
//         );

//         color = getUserAvatarNameColor(otherUser);
//       } catch (e) {
//         // Do nothing if the other user is not found.
//       }
//     }

//     final hasImage = room.imageUrl != null;
//     final name = room.name ?? '';
//     final Widget child = Container(
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: Colors.grey.shade300,
//         ),
//         shape: BoxShape.circle,
//       ),
//       child: CircleAvatar(
//         backgroundColor: hasImage ? Colors.transparent : color,
//         backgroundImage: hasImage ? CachedNetworkImageProvider(room.imageUrl!) : null,
//         radius: 20,
//         child: !hasImage
//             ? Text(
//                 name.isEmpty ? '' : name[0].toUpperCase(),
//                 style: const TextStyle(color: Colors.white),
//               )
//             : null,
//       ),
//     );

//     if (otherUser == null) {
//       return Container(
//         margin: const EdgeInsets.only(right: 2),
//         child: child,
//       );
//     }

//     // Se `otherUser` non è null, la stanza è diretta e possiamo mostrare l'indicatore di stato online.
//     return Container(
//       margin: const EdgeInsets.only(right: 0),
//       child: UserOnlineStatusWidget(
//         uid: otherUser.id,
//         builder: (status) => Stack(
//           alignment: Alignment.bottomRight,
//           children: [
//             child,
//             if (status == UserOnlineStatus.online) // Assumendo che `status` indichi lo stato online
//               Container(
//                 width: 15,
//                 height: 15,
//                 margin: const EdgeInsets.only(right: 1, bottom: 1),
//                 decoration: BoxDecoration(
//                   color: Colors.green,
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: Colors.white,
//                     width: 2,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_error) {
//       return Container();
//     }

//     if (!_initialized) {
//       return Utils.progressbar();
//     }

//     return Scaffold(
//       body: _user == null
//           ? Container(
//               alignment: Alignment.center,
//               margin: const EdgeInsets.only(
//                 bottom: 200,
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text('Not authenticated'),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).push(
//                         MaterialPageRoute(
//                           fullscreenDialog: true,
//                           builder: (context) => const AuthScreen(),
//                         ),
//                       );
//                     },
//                     child: const Text('Login'),
//                   ),
//                 ],
//               ),
//             )
//           : RefreshIndicator(
//               onRefresh: () async {
//                 initializeFlutterFire();
//               },
//               child: Column(
//                 children: [
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: IconButton(
//                       icon: const Icon(
//                         Icons.add,
//                       ),
//                       onPressed: _user == null
//                           ? null
//                           : () {
//                               Navigator.of(context).push(
//                                 MaterialPageRoute(
//                                   fullscreenDialog: true,
//                                   builder: (context) => const UsersPage(),
//                                 ),
//                               );
//                             },
//                     ),
//                   ),
//                   Expanded(
//                     child: StreamBuilder<List<types.Room>>(
//                       stream: SupabaseChatCore.instance.rooms(),
//                       // initialData: const [],
//                       builder: (context, snapshot) {
//                         lo.g(' snapshot.data : ${snapshot.data}');
//                         if (!snapshot.hasData) {
//                           return Container(
//                             alignment: Alignment.center,
//                             margin: const EdgeInsets.only(
//                               bottom: 200,
//                             ),
//                             child: Utils.progressbar(),
//                           );
//                         }
//                         if (snapshot.data!.isEmpty) {
//                           return Container(
//                             alignment: Alignment.center,
//                             margin: const EdgeInsets.only(
//                               bottom: 200,
//                             ),
//                             child: const Text('대화 목록이 없습니다.'),
//                           );
//                         }
//                         return ListView.builder(
//                           itemCount: snapshot.data!.length,
//                           itemBuilder: (context, index) {
//                             final room = snapshot.data![index];
//                             return buildItem(room);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   buildItem(types.Room room) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
//       child: ElevatedButton(
//         clipBehavior: Clip.none,
//         style: ElevatedButton.styleFrom(
//           shadowColor: Colors.transparent,
//           // fixedSize: Size(0, 0),
//           minimumSize: Size.zero, // Set this
//           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
//           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//           visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
//           elevation: 3,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(5),
//           ),
//           backgroundColor: Colors.transparent,
//         ),
//         onPressed: () => Get.toNamed('/ChatPage', arguments: {'room': room}),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildAvatar(room),
//             const Gap(10),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     room.name.toString(),
//                     softWrap: true,
//                     // overflow: TextOverflow.fade,
//                     style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
//                   ),
//                   Text(
//                     room.lastMessages != null && room.lastMessages!.isNotEmpty && room.lastMessages!.first is types.TextMessage
//                         ? (room.lastMessages!.first as types.TextMessage).text
//                         : '',
//                     softWrap: true,
//                     // overflow: TextOverflow.fade,
//                     style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
//                   ),
//                 ],
//               ),
//             ),
//             // const Spacer(),
//             const Gap(10),
//             Text(
//               timeago.format(DateTime.now().subtract(Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - (room.updatedAt ?? 0))),
//                   locale: 'kr_short'),
//               style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
