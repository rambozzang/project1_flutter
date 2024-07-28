import 'dart:convert';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:project1/utils/log_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Extension with one [toShortString] method.
extension RoleToShortString on types.Role {
  /// Converts enum to the string equal to enum's name.
  String toShortString() => toString().split('.').last;
}

/// Extension with one [toShortString] method.
extension RoomTypeToShortString on types.RoomType {
  /// Converts enum to the string equal to enum's name.
  String toShortString() => toString().split('.').last;
}

/// Fetches user from Firebase and returns a promise.
Future<Map<String, dynamic>> fetchUser(
  SupabaseClient instance,
  String userId,
  String usersTableName,
  String schema, {
  String? role,
}) async =>
    (await instance.schema(schema).from(usersTableName).select().eq('id', userId).limit(1)).first;

/// Returns a list of [types.Room] created from Firebase query.
/// If room has 2 participants, sets correct room name and image.
Future<List<types.Room>> processRoomsRows(
  User supabaseUser,
  SupabaseClient instance,
  List<dynamic> rows,
  String usersCollectionName,
  String schema,
) async =>
    await Future.wait(rows.map(
      (doc) => processRoomRow(
        doc,
        supabaseUser,
        instance,
        usersCollectionName,
        schema,
      ),
    ));

Future<types.Room> processRoomRow(
  Map<String, dynamic> data,
  User currentUser,
  SupabaseClient client,
  String usersTableName,
  String schema,
) async {
  lo.g('Processing room row: $data');

  var imageUrl = data['imageUrl'] as String?;
  var name = data['name'] as String?;
  final type = data['type'] as String?;
  final userIds = (data['userIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
  final userRoles = data['userRoles'] as Map<String, dynamic>?;
  final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

  lo.g('Room type: $type, User IDs: $userIds');
  lo.g('Room metadata: $metadata');

  final users = await Future.wait(
    userIds.map(
      (userId) => fetchUser(
        client,
        userId,
        usersTableName,
        schema,
        role: userRoles?[userId] as String?,
      ),
    ),
  );
  lo.g('Fetched users: ${users.map((u) => u['id']).toList()}');

  if (type == types.RoomType.direct.toShortString()) {
    try {
      final otherUser = users.firstWhere(
        (u) => u['id'] != currentUser.id,
        orElse: () => {'id': 'unknown', 'firstName': 'Unknown', 'lastName': 'User'},
      );
      imageUrl = otherUser['imageUrl'] as String?;
      name = '${otherUser['firstName'] ?? ''} ${otherUser['lastName'] ?? ''}'.trim();
      lo.g('Direct chat with: $name');
    } catch (e) {
      lo.g('Error finding other user in direct chat: $e');
    }
  }

  List<types.Message>? lastMessages;

  lo.g('data[lastMessages] : ${data['lastMessages']}');
  if (data['lastMessages'] != null) {
    try {
      if (data['lastMessages'] is String) {
        // JSON 문자열로 저장된 경우
        final decodedMessages = jsonDecode(data['lastMessages']);
        if (decodedMessages is List) {
          lastMessages = decodedMessages.map((lm) => parseMessage(lm)).where((m) => m != null).cast<types.Message>().toList();
        }
      } else if (data['lastMessages'] is List) {
        // 이미 리스트 형태로 저장된 경우
        lastMessages = (data['lastMessages'] as List).map((lm) => parseMessage(lm)).where((m) => m != null).cast<types.Message>().toList();
      }
      print('Processed lastMessages: ${lastMessages?.length ?? 0}');
    } catch (e) {
      print('Error processing lastMessages: $e');
      lastMessages = null;
    }
  } else {
    print('lastMessages is null');
  }

  // if (data['lastMessages'] != null) {
  //   try {
  //     if (data['lastMessages'] is List) {
  //       lastMessages = (data['lastMessages'] as List)
  //           .map((lm) {
  //             final author = users.firstWhere(
  //               (u) => u['id'] == lm['authorId'],
  //               orElse: () => {'id': lm['authorId'] as String},
  //             );
  //             lm['author'] = author;
  //             lm['id'] = lm['id'].toString();
  //             lm['roomId'] = lm['roomId'].toString();
  //             lm['text'] = lm['text'].toString();
  //             return lm;
  //           })
  //           .whereType<types.Message>()
  //           .toList();
  //     } else {
  //       lo.g('Unexpected lastMessages format: ${data['lastMessages']}');
  //     }
  //     lo.g('Processed lastMessages: ${lastMessages?.length ?? 0}');
  //   } catch (e) {
  //     lo.g('Error processing lastMessages: $e');
  //     lo.g('Raw lastMessages data: ${data['lastMessages']}');
  //     lastMessages = null;
  //   }
  // } else {
  //   lo.g('lastMessages is null');
  // }

  final lastLeftUserId = metadata['lastLeftUserId'] as String?;

  return types.Room(
    id: data['id'].toString(),
    type: type == types.RoomType.direct.toShortString() ? types.RoomType.direct : types.RoomType.group,
    users: users.map((u) => types.User.fromJson(u)).toList(),
    name: name,
    imageUrl: imageUrl,
    updatedAt: data['updatedAt'] is int ? data['updatedAt'] : int.tryParse(data['updatedAt']?.toString() ?? '') ?? 0,
    createdAt: data['createdAt'] is int ? data['createdAt'] : int.tryParse(data['createdAt']?.toString() ?? '') ?? 0,
    lastMessages: lastMessages,
    metadata: metadata,
  );
}

types.Message? parseMessage(dynamic messageData) {
  if (messageData == null || messageData is! Map<String, dynamic>) {
    lo.g('Invalid message data: $messageData');
    return null;
  }
  try {
    return types.TextMessage(
      author: types.User(
        id: messageData['authorId']?.toString() ?? '',
        firstName: messageData['author']?['firstName']?.toString(),
        lastName: messageData['author']?['lastName']?.toString(),
      ),
      id: messageData['id']?.toString() ?? '',
      text: messageData['text']?.toString() ?? '',
      createdAt: messageData['createdAt'] is int
          ? messageData['createdAt']
          : (messageData['createdAt'] is String ? int.tryParse(messageData['createdAt']) : null) ?? 0,
      status: parseMessageStatus(messageData['status']),
    );
  } catch (e) {
    lo.g('Error parsing message: $e');
    lo.g('Problematic message data: $messageData');
    return null;
  }
}

types.Status parseMessageStatus(dynamic status) {
  if (status is String) {
    switch (status.toLowerCase()) {
      case 'sent':
        return types.Status.sent;
      case 'delivered':
        return types.Status.delivered;
      case 'seen':
        return types.Status.seen;
      default:
        return types.Status.sending;
    }
  }
  return types.Status.sending;
}
