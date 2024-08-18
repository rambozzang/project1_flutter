import 'dart:async';
import 'dart:io';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util.dart';
import 'supabase_chat_core_config.dart';
import 'user_online_status.dart';

/// Provides access to Supabase chat data. Singleton, use
/// SupabaseChatCore.instance to access methods.
class SupabaseChatCore {
  SupabaseChatCore._privateConstructor() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      supabaseUser = data.session?.user;
      _currentUserOnlineStatusChannel = supabaseUser != null ? getUserOnlineStatusChannel(supabaseUser!.id) : null;
    });
  }

  /// Config to set custom names for users, room and messages tables. Also
  /// see [SupabaseChatCoreConfig].
  SupabaseChatCoreConfig config = const SupabaseChatCoreConfig(
    'chats',
    'rooms',
    'messages',
    'users',
    'online-user-',
  );

  /// Current logged in user in Supabase. Does not update automatically.
  /// Use [Supabase.instance.client.auth.onAuthStateChange] to listen to the state changes.
  User? supabaseUser = Supabase.instance.client.auth.currentUser;

  /// Returns user online status realtime channel .
  RealtimeChannel getUserOnlineStatusChannel(String uid) => client.channel('${config.realtimeOnlineUserPrefixChannel}$uid');

  /// Returns a current user online status realtime channel .
  RealtimeChannel? _currentUserOnlineStatusChannel;

  bool _userStatusSubscribed = false;
  bool _userStatusSubscribing = false;

  // 클라이언트 측 캐시
  final Map<String, int> _unreadCountCache = {};

  Future<void> _trackUserStatus() async {
    final userStatus = {
      'uid': supabaseUser?.id,
      'online_at': DateTime.now().toIso8601String(),
    };
    await _currentUserOnlineStatusChannel?.track(userStatus);
  }

  Future<void> setPresenceStatus(UserOnlineStatus status) async {
    if (!_userStatusSubscribed && !_userStatusSubscribing) {
      _userStatusSubscribing = true;
      _currentUserOnlineStatusChannel?.subscribe(
        (status, error) async {
          if (status != RealtimeSubscribeStatus.subscribed) return;
          _userStatusSubscribed = true;
          _userStatusSubscribing = false;
          await _trackUserStatus();
        },
      );
    }

    switch (status) {
      case UserOnlineStatus.online:
        if (_userStatusSubscribed) {
          await _trackUserStatus();
        }
        break;
      case UserOnlineStatus.offline:
        if (_userStatusSubscribed) {
          await _currentUserOnlineStatusChannel?.untrack();
        }
        break;
    }
  }

  /// Singleton instance.
  static final SupabaseChatCore instance = SupabaseChatCore._privateConstructor();

  /// Gets proper [SupabaseClient] instance.
  SupabaseClient get client => Supabase.instance.client;

  /// Sets custom config to change default names for users, rooms
  /// and messages tables. Also see [SupabaseChatCoreConfig].
  void setConfig(SupabaseChatCoreConfig supabaseChatCoreConfig) {
    config = supabaseChatCoreConfig;
  }

  /// Creates a chat group room with [users]. Creator is automatically
  /// added to the group. [name] is required and will be used as
  /// a group name. Add an optional [imageUrl] that will be a group avatar
  /// and [metadata] for any additional custom data.
  Future<types.Room> createGroupRoom({
    types.Role creatorRole = types.Role.admin,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    required String name,
    required List<types.User> users,
  }) async {
    if (supabaseUser == null) return Future.error('User does not exist');

    final currentUser = await fetchUser(
      client,
      supabaseUser!.id,
      config.usersTableName,
      config.schema,
      role: creatorRole.toShortString(),
    );

    final roomUsers = [types.User.fromJson(currentUser)] + users;

    final room = await client.schema(config.schema).from(config.roomsTableName).insert({
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'name': name,
      'type': types.RoomType.group.toShortString(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'userIds': roomUsers.map((u) => u.id).toList(),
      'userRoles': roomUsers.fold<Map<String, String?>>(
        {},
        (previousValue, user) => {
          ...previousValue,
          user.id: user.role?.toShortString(),
        },
      ),
    }).select();

    return types.Room(
      id: room.first['id'].toString(),
      imageUrl: imageUrl,
      metadata: metadata,
      name: name,
      type: types.RoomType.group,
      users: roomUsers,
    );
  }

  /// Creates a direct chat for 2 people. Add [metadata] for any additional
  /// custom data.
  Future<types.Room> createRoom(
    types.User otherUser, {
    Map<String, dynamic>? metadata,
  }) async {
    final su = supabaseUser;

    if (su == null) return Future.error('User does not exist');

    // Sort two user ids array to always have the same array for both users,
    // this will make it easy to find the room if exist and make one read only.
    final userIds = [su.id, otherUser.id]..sort();

    final roomQuery = await client
        .schema(config.schema)
        .from(config.roomsTableName)
        .select()
        .eq('type', types.RoomType.direct.toShortString())
        .eq('userIds', userIds)
        .limit(1);
    // Check if room already exist.
    if (roomQuery.isNotEmpty) {
      final room = (await processRoomsRows(
        su,
        client,
        roomQuery,
        config.usersTableName,
        config.schema,
      ))
          .first;

      return room;
    }

    final currentUser = await fetchUser(
      client,
      su.id,
      config.usersTableName,
      config.schema,
    );

    final users = [types.User.fromJson(currentUser), otherUser];

    // Create new room with sorted user ids array.
    final room = await client.schema(config.schema).from(config.roomsTableName).insert({
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'imageUrl': null,
      'metadata': metadata,
      'name': null,
      'type': types.RoomType.direct.toShortString(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'userIds': userIds,
      'userRoles': null,
    }).select();
    return types.Room(
      id: room.first['id'].toString(),
      metadata: metadata,
      type: types.RoomType.direct,
      users: users,
    );
  }

  /// Update [types.User] in Supabase to store name and avatar used on
  /// rooms list.
  Future<void> updateUser(types.User user) async {
    await client.schema(config.schema).from(config.usersTableName).update({
      'firstName': user.firstName,
      'imageUrl': user.imageUrl,
      'lastName': user.lastName,
      'metadata': user.metadata,
      'role': user.role?.toShortString(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }).eq('id', user.id);
  }

  /// Removes message.
  Future<void> deleteMessage(String roomId, String messageId) async {
    await client.schema(config.schema).from(config.messagesTableName).delete().eq('roomId', roomId).eq('id', messageId);
  }

  /// Removes room.
  Future<void> deleteRoom(String roomId) async {
    await client.schema(config.schema).from(config.roomsTableName).delete().eq('id', roomId);
  }

  /// Returns a stream of messages from Supabase for a given room.
  Stream<List<types.Message>> messages(types.Room room) {
    final query = client
        .schema(config.schema)
        .from(config.messagesTableName)
        .stream(primaryKey: ['id'])
        .eq('roomId', int.parse(room.id))
        .order('createdAt', ascending: false);
    return query.map(
      (snapshot) => snapshot.fold<List<types.Message>>(
        [],
        (previousMessages, data) {
          final author = room.users.firstWhere(
            (u) => u.id == data['authorId'],
            orElse: () => types.User(id: data['authorId'] as String),
          );
          data['author'] = author.toJson();
          data['id'] = data['id'].toString();
          data['roomId'] = data['roomId'].toString();
          final newMessage = types.Message.fromJson(data);
          final index = previousMessages.indexWhere((msg) => msg.id == newMessage.id);
          if (index != -1) {
            previousMessages[index] = newMessage;
          } else {
            previousMessages.add(newMessage);
          }
          return previousMessages;
        },
      ),
    );
  }

  /// Returns a stream of changes in a room from Supabase.
  // Stream<types.Room> room(String roomId) {
  //   final fu = supabaseUser;
  //   if (fu == null) return const Stream.empty();
  //   return client.schema(config.schema).from(config.roomsTableName).stream(primaryKey: ['id']).eq('id', roomId).asyncMap(
  //         (doc) => processRoomRow(
  //           doc.first,
  //           fu,
  //           client,
  //           config.usersTableName,
  //           config.schema,
  //         ),
  //       );
  // }
  Stream<types.Room> room(String roomId) {
    final fu = supabaseUser;
    if (fu == null) return const Stream.empty();
    return client.schema(config.schema).from(config.roomsTableName).stream(primaryKey: ['id']).eq('id', roomId).asyncMap((doc) async {
          final room = await processRoomRow(
            doc.first,
            fu,
            client,
            config.usersTableName,
            config.schema,
          );

          // Check if there's a user who left the room
          final metadata = room.metadata;
          if (metadata != null && metadata['lastLeftUserId'] != null) {
            final lastLeftUserId = metadata['lastLeftUserId'];
            final lastLeftAt = metadata['lastLeftAt'] ?? DateTime.now().toIso8601String();

            // Find the user who left
            final leftUser = room.users.firstWhere(
              (user) => user.id == lastLeftUserId,
              orElse: () => types.User(id: lastLeftUserId),
            );

            lo.g('${leftUser.firstName ?? leftUser.id} left the room at $lastLeftAt');

            // You can handle this information as needed, for example:
            // Show a message in the chat that the user has left
            // Or update the UI to reflect that the user is no longer in the chat
          }

          return room;
        });
  }

  /// Returns a stream of online user state from Supabase Realtime.
  Stream<UserOnlineStatus> userOnlineStatus(String uid) {
    final controller = StreamController<UserOnlineStatus>();
    UserOnlineStatus userStatus(List<Presence> presences, String uid) =>
        presences.map((e) => e.payload['uid']).contains(uid) ? UserOnlineStatus.online : UserOnlineStatus.offline;
    getUserOnlineStatusChannel(uid).onPresenceJoin((payload) {
      controller.sink.add(userStatus(payload.newPresences, uid));
    }).onPresenceLeave((payload) {
      controller.sink.add(userStatus(payload.currentPresences, uid));
    }).subscribe();
    return controller.stream;
  }

  /// Returns a stream of rooms from Supabase. Only rooms where current
  /// logged in user exist are returned. [orderByUpdatedAt] is used in case
  /// you want to have last modified rooms on top, there are a couple
  /// of things you will need to do though:
  /// 1) Make sure `updatedAt` exists on all rooms
  /// 2) Write a Cloud Function which will update `updatedAt` of the room
  /// when the room changes or new messages come in
  /// 3) Create an Index (Firestore Database -> Indexes tab) where collection ID
  /// is `rooms`, field indexed are `userIds` (type Arrays) and `updatedAt`
  /// (type Descending), query scope is `Collection`.

  Stream<List<types.Room>> rooms({bool orderByUpdatedAt = true}) {
    lo.g('------------------------------------');
    lo.g('Executing rooms Start~!!!!!!!!');
    final fu = supabaseUser;
    if (fu == null) {
      lo.g('Error: supabaseUser is null');
      return const Stream.empty();
    }
    lo.g('Fetching rooms for user: ${fu.id}');
    // final controller = StreamController<List<types.Room>>();
    final roomsSubject = BehaviorSubject<List<types.Room>>();
    List<types.Room> currentRooms = [];
    final roomsSet = <String>{};
    Timer? debounceTimer;

    Future<void> fetchAndProcessRooms({String? specificRoomId}) async {
      try {
        var query = client
            .schema(config.schema)
            .from(config.roomsTableName)
            .select('*, messages(count)')
            .or('userIds.cs.{${fu.id}},type.eq.direct')
            .or('metadata.is.null,metadata->>lastLeftUserId.is.null,metadata->>lastLeftUserId.neq.${fu.id}');

        if (specificRoomId != null) {
          query = query.eq('id', specificRoomId);
        }

        if (orderByUpdatedAt) {
          query = query.order('updatedAt', ascending: false) as PostgrestFilterBuilder<List<Map<String, dynamic>>>;
        }

        lo.g('Executing query: $query');

        final data = await query;
        lo.g('Received room data: ${data.length} rooms');
        lo.g('Received room data: ${data.length} rooms');

        final currentRooms = roomsSubject.valueOrNull ?? [];
        final updatedRooms = <types.Room>[];

        int loopInt = 0;
        for (var val in data) {
          final roomId = val['id'].toString();
          lo.g('---------------------- : $loopInt');
          lo.g('Processing room: ${val['id']}');
          try {
            final metadata = val['metadata'] as Map<String, dynamic>?;
            lo.g('Room metadata: $metadata');

            if (metadata != null && metadata['lastLeftUserId'] == fu.id) {
              lo.g('Skipped room ${val['id']} (user left)');
              continue;
            }

            final newRoom = await processRoomRow(val, fu, client, config.usersTableName, config.schema);
            lo.g('Processed room: ${newRoom.id}, Type: ${newRoom.type}, Users: ${newRoom.users.length}, Metadata: ${newRoom.metadata}');

            final totalMessages = val['messages'][0]['count'] as int;
            final lastReadTime = val['last_read_times'][fu.id];

            // int unreadCount;
            // if (lastReadTime == null) {
            //   unreadCount = totalMessages;
            // } else {
            //   final unreadMessagesResponse = await client
            //       .schema(config.schema)
            //       .from(config.messagesTableName)
            //       .select('id')
            //       .eq('roomId', newRoom.id.toString())
            //       .gt('createdAt', int.parse(lastReadTime.toString()));
            //   unreadCount = unreadMessagesResponse.length;
            // }
            int unreadCount = await calculateUnreadCount(newRoom.id, lastReadTime, totalMessages);
            lo.g('Room unreadCount: $unreadCount');
            final updatedRoom = types.Room(
              id: newRoom.id,
              type: newRoom.type,
              users: newRoom.users,
              name: newRoom.name,
              imageUrl: newRoom.imageUrl,
              createdAt: newRoom.createdAt,
              updatedAt: newRoom.updatedAt,
              lastMessages: newRoom.lastMessages,
              metadata: {
                ...newRoom.metadata ?? {},
                'unreadCount': unreadCount,
              },
            );

            updatedRooms.add(updatedRoom);
            roomsSet.add(roomId);
            lo.g('Added room ${updatedRoom.id} to list with unreadCount: $unreadCount');
          } catch (e, stackTrace) {
            lo.g('Error processing room ${val['id']}: $e');
            lo.g('Stack trace: $stackTrace');
          }
          loopInt++;
        }
        // Remove rooms that are no longer in the fetched data
        List<types.Room> mergedRooms;
        if (specificRoomId != null) {
          // Update or add the specific room
          mergedRooms = List.from(currentRooms);
          final index = mergedRooms.indexWhere((room) => room.id == specificRoomId);
          if (index != -1) {
            mergedRooms[index] = updatedRooms.first;
          } else {
            mergedRooms.add(updatedRooms.first);
          }
        } else {
          // Full update
          final fetchedRoomIds = updatedRooms.map((room) => room.id).toSet();
          mergedRooms = [
            ...currentRooms.where((room) => !fetchedRoomIds.contains(room.id)),
            ...updatedRooms,
          ];
        }

        if (orderByUpdatedAt) {
          mergedRooms.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
        }

        lo.g('Final rooms list: ${mergedRooms.length} rooms');
        roomsSubject.add(mergedRooms);
      } catch (error, stackTrace) {
        lo.g('Error fetching rooms: $error');
        lo.g('Stack trace: $stackTrace');
        if (error is PostgrestException) {
          lo.g('Postgrest Error details: ${error.details}');
          lo.g('Postgrest Error hint: ${error.hint}');
        }
        // roomsSubject.addError(error);
      }
    }

    // 초기 데이터 로드
    fetchAndProcessRooms();

    // 실시간 업데이트 설정
    final subscription = client
        .channel('${config.schema}:${config.roomsTableName}')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: config.schema,
            table: config.roomsTableName,
            callback: (payload) async {
              lo.g('Received realtime update: $payload');
              if (payload.eventType == PostgresChangeEvent.delete) {
                if (payload.oldRecord != null && payload.oldRecord!['id'] != null) {
                  final deletedRoomId = payload.oldRecord!['id'].toString();
                  final currentRooms = roomsSubject.value;
                  currentRooms.removeWhere((room) => room.id == deletedRoomId);
                  roomsSubject.add(currentRooms);
                }
              } else if (payload.eventType == PostgresChangeEvent.insert || payload.eventType == PostgresChangeEvent.update) {
                final roomId = payload.newRecord!['id'].toString();
                debounceTimer?.cancel();
                debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  fetchAndProcessRooms(specificRoomId: roomId);
                });
              }
            })
        .subscribe();

    // 스트림 종료 시 정리
    roomsSubject.onCancel = () {
      subscription.unsubscribe();
      debounceTimer?.cancel();
      roomsSubject.close();
    };

    lo.g('------------------------------------');
    return roomsSubject.stream;
  }

  Future<int> calculateUnreadCount(String roomId, dynamic lastReadTime, int totalMessages) async {
    lo.g('lastReadTime: $lastReadTime');
    if (lastReadTime == null) {
      return totalMessages;
    }
    // final unreadMessagesResponse = await client
    //     .schema(config.schema)
    //     .from(config.messagesTableName)
    //     .select('id')
    //     .eq('roomId', roomId)
    //     .gt('createdAt', int.parse(lastReadTime.toString()))
    //     .count();
    final result = await client.schema(config.schema).rpc('get_unread_message_count', params: {
      'p_room_id': roomId,
      'p_user_id': supabaseUser!.id,
    });
    return result as int;
  }

  // 읽지 않은 메시지 수 가져오기 (캐시 사용)
  Future<int> getUnreadCount(int roomId) async {
    if (supabaseUser == null) return 0;

    final result = await client.schema(config.schema).rpc('get_unread_message_count', params: {
      'p_room_id': roomId,
      'p_user_id': supabaseUser!.id,
    });

    return result as int;
  }

  /// Sends a message to the Supabase. Accepts any partial message and a
  /// room ID. If arbitrary data is provided in the [partialMessage]
  /// does nothing.
  Future<bool> sendMessage(dynamic partialMessage, String roomId, {isOutMsg = false}) async {
    if (supabaseUser == null) return false;

    if (!await canSendMessage(roomId) && !isOutMsg) {
      Utils.alert('상대방이 방을 나갔습니다. 더이상 메세지를 보낼수 없습니다.');
      return false;
    }

    types.Message? message;

    if (partialMessage is types.PartialCustom) {
      message = types.CustomMessage.fromPartial(
        author: types.User(id: supabaseUser!.id),
        id: '',
        partialCustom: partialMessage,
      );
    } else if (partialMessage is types.PartialFile) {
      message = types.FileMessage.fromPartial(
        author: types.User(id: supabaseUser!.id),
        id: '',
        partialFile: partialMessage,
      );
    } else if (partialMessage is types.PartialImage) {
      message = types.ImageMessage.fromPartial(
        author: types.User(id: supabaseUser!.id),
        id: '',
        partialImage: partialMessage,
      );
    } else if (partialMessage is types.PartialText) {
      message = types.TextMessage.fromPartial(
        author: types.User(id: supabaseUser!.id),
        id: '',
        partialText: partialMessage,
      );
    }

    if (message != null) {
      final messageMap = message.toJson();
      messageMap.removeWhere((key, value) => key == 'author' || key == 'id');
      messageMap['roomId'] = roomId;
      messageMap['authorId'] = supabaseUser!.id;
      messageMap['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      messageMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      // await client.schema(config.schema).from(config.messagesTableName).insert(messageMap);

      // await client
      //     .schema(config.schema)
      //     .from(config.roomsTableName)
      //     .update({'updatedAt': DateTime.now().millisecondsSinceEpoch}).eq('id', roomId);
      // DB 함수를 사용하여 메시지 전송 및 방 정보 업데이트
      // await client.schema(config.schema).rpc('send_message_and_update_room', params: {
      //   'p_message': messageMap,
      //   'p_room_id': roomId,
      // });

      // 필요한 필드만 남기고 나머지는 제거
      messageMap.removeWhere((key, value) => ![
            'text',
            'type',
            'authorId', /* 다른 필요한 필드 */
          ].contains(key));

      await client.schema(config.schema).rpc('send_message_and_update_room', params: {
        'p_message': messageMap,
        'p_room_id': int.parse(roomId),
      });

      // 캐시된 읽지 않은 메시지 수 증가
      _incrementUnreadCount(int.parse(roomId));
    }
    return true;
  }

  // 캐시된 읽지 않은 메시지 수 증가
  void _incrementUnreadCount(int roomId) {
    _unreadCountCache[roomId.toString()] = (_unreadCountCache[roomId] ?? 0) + 1;
  }

  // 서버에서 읽지 않은 메시지 수 새로고침
  Future<void> _refreshUnreadCount(int roomId) async {
    if (supabaseUser == null) return;
    try {
      lo.g('roomId : $roomId');
      lo.g('supabaseUser!.id : ${supabaseUser!.id}');
      final result = await client.schema(config.schema).rpc('get_unread_message_count', params: {
        'p_room_id': roomId,
        'p_user_id': supabaseUser!.id,
      });

      _unreadCountCache[roomId.toString()] = result as int;
    } catch (e, stackTrace) {
      lo.g('Error refreshing unread count: $e');
      lo.g('Stack trace: $stackTrace');
    }
  }

  // 마지막 읽은 시간 업데이트
  Future<void> updateLastReadTime(int roomId) async {
    if (supabaseUser == null) return;
    try {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      await client.schema(config.schema).rpc('update_last_read_time', params: {
        'p_room_id': roomId,
        'p_user_id': supabaseUser!.id,
        'p_last_read_time': currentTime,
      });
      lo.g('Last read time updated successfully for room $roomId');
      _unreadCountCache.remove(roomId);
    } catch (e) {
      lo.g('Error updating last read time: $e');
    }
  }

  /// Updates a message in the Supabase. Accepts any message and a
  /// room ID. Message will probably be taken from the [messages] stream.
  Future<void> updateMessage(types.Message message, String roomId) async {
    //if (supabaseUser == null) return;
    //if (message.author.id != supabaseUser!.id) return;

    final messageMap = message.toJson();
    messageMap.removeWhere(
      (key, value) => key == 'author' || key == 'createdAt' || key == 'id',
    );
    //messageMap['authorId'] = message.author.id;
    messageMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    await client.schema(config.schema).from(config.messagesTableName).update(messageMap).eq('roomId', roomId).eq('id', message.id);
  }

  /// Updates a room in the Supabase. Accepts any room.
  /// Room will probably be taken from the [rooms] stream.
  void updateRoom(types.Room room) async {
    if (supabaseUser == null) return;

    final roomMap = room.toJson();
    roomMap.removeWhere((key, value) => key == 'createdAt' || key == 'id' || key == 'lastMessages' || key == 'users');

    if (room.type == types.RoomType.direct) {
      roomMap['imageUrl'] = null;
      roomMap['name'] = null;
    }

    roomMap['lastMessages'] = room.lastMessages?.map((m) {
      final messageMap = m.toJson();

      messageMap.removeWhere((key, value) => key == 'author' || key == 'createdAt' || key == 'id' || key == 'updatedAt');

      messageMap['authorId'] = m.author.id;

      return messageMap;
    }).toList();
    roomMap['updatedAt'] = DateTime.now();
    roomMap['userIds'] = room.users.map((u) => u.id).toList();

    await client.schema(config.schema).from(config.roomsTableName).update(roomMap).eq('id', room.id);
  }

  /// Returns a stream of all users from Supabase.
  Stream<List<types.User>> users() {
    if (supabaseUser == null) return const Stream.empty();
    return client.schema(config.schema).from(config.usersTableName).stream(primaryKey: ['id']).map(
      (snapshot) => snapshot.fold<List<types.User>>(
        [],
        (previousValue, data) {
          if (supabaseUser!.id == data['id']) return previousValue;
          return [...previousValue, types.User.fromJson(data)];
        },
      ),
    );
  }

  // 메시지 전송 가능 여부를 확인하는 새로운 메서드
  Future<bool> canSendMessage(String roomId) async {
    final roomData = await client.schema(config.schema).from(config.roomsTableName).select('metadata, userIds').eq('id', roomId).single();

    final userIds = List<String>.from(roomData['userIds']);
    if (!userIds.contains(supabaseUser!.id)) {
      return false;
    }

    final metadata = roomData['metadata'] as Map<String, dynamic>?;
    return metadata == null || metadata['lastLeftUserId'] == null;
  }

  Future<bool> leaveRoom(String roomId) async {
    if (supabaseUser == null) return Future.error('User does not exist');

    try {
      lo.g('Attempting to leave room: $roomId');
      lo.g('Current user ID: ${supabaseUser!.id}');

      // leave_room 함수 호출
      final result = await client.schema(config.schema).rpc(
        'leave_room',
        params: {
          'p_room_id': int.parse(roomId),
          'p_user_id': supabaseUser!.id,
        },
      ) as Map<String, dynamic>;

      lo.g('Leave room result: $result');

      if (result['status'] == 'error') {
        return Future.error('Failed to leave room: ${result['message']}');
      }

      if (result['message'] == 'All users left. Room deleted') {
        lo.g('Room has been deleted as all users left');
      } else {
        // "[방나감]" 메시지 전송 (방이 삭제되지 않았을 때만)
        lo.g('[방나감][방나감][방나감][방나감][방나감][방나감]');
        sendMessage(const types.PartialText(text: "💥방을 나갔습니다.💥"), roomId, isOutMsg: true);
        // sleep(const Duration(seconds: 1));
      }

      lo.g('Successfully left the room.');
      return true;
    } catch (e, stackTrace) {
      lo.g('Error leaving room: $e');
      lo.g('Stack trace: $stackTrace');
      return Future.error('Failed to leave room: $e\n$stackTrace');
    }
  }

  // 모든방에서 나가기
  Future<void> leaveAllRooms() async {
    if (supabaseUser == null) return;

    try {
      // 사용자가 속한 모든 방을 가져옵니다.
      final rooms =
          await client.schema(config.schema).from(config.roomsTableName).select('id').filter('userIds', 'cs', '{${supabaseUser!.id}}');

      // 각 방에서 순차적으로 나갑니다.
      for (var room in rooms) {
        await leaveRoom(room['id'].toString());
      }
    } catch (e) {
      print('Error leaving all rooms: $e');
      rethrow;
    }
  }
}
