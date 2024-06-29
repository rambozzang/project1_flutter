import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:project1/repo/alram/alram_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.room,
  });

  final types.Room room;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isAttachmentUploading = false;
  late SupabaseChatController _chatController;
  final String buket = 'chats_assets';
  late types.Room room;

  bool _isFirst = true;

  @override
  void initState() {
    room = widget.room; // Get.arguments['room'];
    _chatController = SupabaseChatController(room: room);
    super.initState();
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 130,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleImageSelection();
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.image),
                      Text('Image'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleFileSelection();
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.attach_file),
                      Text('File'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      _setAttachmentUploading(true);

      try {
        final bytes = result.files.single.bytes;
        final name = result.files.single.name;
        final mimeType = lookupMimeType(name, headerBytes: bytes);
        final reference = await Supabase.instance.client.storage
            .from(buket)
            .uploadBinary('${room.id}/${const Uuid().v1()}-$name', bytes!, fileOptions: FileOptions(contentType: mimeType));
        final url = '${Supabase.instance.client.storage.url}/object/authenticated/$reference';
        final message = types.PartialFile(
          mimeType: mimeType,
          name: name,
          size: result.files.single.size,
          uri: url,
        );

        SupabaseChatCore.instance.sendMessage(message, room.id);
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );
    if (result != null) {
      _setAttachmentUploading(true);
      final bytes = await result.readAsBytes();
      final size = bytes.length;
      final image = await decodeImageFromList(bytes);
      final name = result.name;
      final mimeType = lookupMimeType(name, headerBytes: bytes);
      try {
        final reference = await Supabase.instance.client.storage
            .from(buket)
            .uploadBinary('${room.id}/${const Uuid().v1()}-$name', bytes, fileOptions: FileOptions(contentType: mimeType));
        final url = '${Supabase.instance.client.storage.url}/object/authenticated/$reference';
        final message = types.PartialImage(
          height: image.height.toDouble(),
          name: name,
          size: size,
          uri: url,
          width: image.width.toDouble(),
        );
        SupabaseChatCore.instance.sendMessage(
          message,
          room.id,
        );
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  Map<String, String> get storageHeaders => {
        'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
      };

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      final client = http.Client();
      final request = await client.get(Uri.parse(message.uri), headers: storageHeaders);
      final result = await FileSaver.instance.saveFile(
        name: message.uri.split('/').last,
        bytes: request.bodyBytes,
      );
      await OpenFilex.open(result);
    }
  }

  Future<void> _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) async {
    final updatedMessage = message.copyWith(previewData: previewData);

    await SupabaseChatCore.instance.updateMessage(updatedMessage, room.id);
  }

  void _handleSendPressed(types.PartialText message) async {
    SupabaseChatCore.instance.sendMessage(
      message,
      room.id,
    );
    lo.g("_handleSendPressed");

    //최초로 보내거나 이 위젯이 처음 생성될때만 푸시를 보낸다.
    // 최초 여부를 관리하는 방법이 필요함.
    // if (_isFirst) {
    room.users.forEach((element) {
      if (element.id != SupabaseChatCore.instance.supabaseUser!.id) {
        String custId = element.metadata!['custId'];
        if (custId != '') {
          AlramRepo alramRepo = AlramRepo();
          alramRepo.pushByCustId(element.metadata!['custId']);
        }
      }
    });
    _isFirst = false;
    //  }
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }

  void leaveRoom() {
    Utils.showConfirmDialog('나가기', '대화내용이 삭제됩니다. 나가겠습니까?', BackButtonBehavior.none, confirm: () async {
      Lo.g('cancel');
    }, cancel: () async {
      Lo.g('cancel');
    }, backgroundReturn: () {});

    // SupabaseChatCore.instance.deleteRoom(room.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF262B49), // Colors.black87,
          automaticallyImplyLeading: true,
          // systemOverlayStyle: SystemUiOverlayStyle.light,
          // forceMaterialTransparency: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          titleSpacing: 0,
          centerTitle: false,
          title: Text(
            room.name ?? '대화하기',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              onPressed: leaveRoom,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF262B49),
        body: StreamBuilder<List<types.Message>>(
            initialData: const [],
            stream: _chatController.messages,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Utils.progressbar());
              }

              if (!snapshot.hasData) {
                return Center(child: Utils.progressbar());
              }

              // if (snapshot.data!.isEmpty) {
              //   return Container(
              //     alignment: Alignment.center,
              //     margin: const EdgeInsets.only(
              //       bottom: 200,
              //     ),
              //     child: const Text(
              //       '메세지 내용이 없습니다.',
              //       style: TextStyle(color: Colors.white),
              //     ),
              //   );
              // }

              return Chat(
                scrollPhysics: const BouncingScrollPhysics(),
                theme: const DefaultChatTheme(
                  dateDividerMargin: EdgeInsets.only(bottom: 15, top: 15),
                  dateDividerTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  inputBackgroundColor: Colors.white,
                  inputTextColor: Colors.black,
                  primaryColor: Colors.yellow,
                  userNameTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.375,
                  ),
                  unreadHeaderTheme: UnreadHeaderTheme(
                    color: secondary,
                    textStyle: TextStyle(color: neutral2, fontSize: 12, fontWeight: FontWeight.w500, height: 1.333),
                  ),
                  secondaryColor: Color.fromARGB(255, 68, 68, 68),
                  inputPadding: EdgeInsets.fromLTRB(14, 10, 14, 10),
                  messageBorderRadius: 10,
                  messageInsetsVertical: 5,
                  messageInsetsHorizontal: 10,
                  sentMessageBodyTextStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400, height: 1.375),
                  receivedMessageBodyTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400, height: 1.375),
                  sentMessageLinkDescriptionTextStyle: TextStyle(color: neutral7, fontSize: 14, fontWeight: FontWeight.w400, height: 1.428),
                  sentMessageLinkTitleTextStyle: TextStyle(color: neutral7, fontSize: 16, fontWeight: FontWeight.w800, height: 1.375),
                  receivedEmojiMessageTextStyle: TextStyle(fontSize: 25),
                  inputBorderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  backgroundColor: const Color(0xFF262B49), // Colors.black87,
                  inputTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                ),

                dateFormat: DateFormat('yyyy/MM/dd'),
                timeFormat: DateFormat('HH:mm'),

                messageWidthRatio: 0.8,
                showUserNames: false,
                showUserAvatars: true,
                avatarBuilder: (author) => Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    backgroundImage: author.imageUrl != null ? CachedNetworkImageProvider(author.imageUrl!) : null,
                    child: author.imageUrl == null ? const Icon(Icons.person) : null,
                  ),
                ),
                isAttachmentUploading: _isAttachmentUploading,
                messages: snapshot.data ?? [],

                // customBottomWidget: Container(
                //   color: Colors.white,
                //   child: const Text('Custom bottom widget'),
                // ),
                onAttachmentPressed: _handleAttachmentPressed,
                onMessageTap: _handleMessageTap,
                onPreviewDataFetched: _handlePreviewDataFetched,
                onSendPressed: _handleSendPressed,
                hideBackgroundOnEmojiMessages: false,
                user: types.User(
                  id: SupabaseChatCore.instance.supabaseUser!.id,
                ),

                imageHeaders: storageHeaders,
                onMessageVisibilityChanged: (message, visible) async {
                  if (message.status != types.Status.seen && message.author.id != SupabaseChatCore.instance.supabaseUser!.id) {
                    await SupabaseChatCore.instance.updateMessage(message.copyWith(status: types.Status.seen), room.id);
                  }
                },
                onEndReached: _chatController.loadPreviousMessages,
                // bubbleBuilder: (child, {required message, required nextMessageInGroup}) => Bubble(
                //   child: child,
                //   message: message,
                //   nextMessageInGroup: nextMessageInGroup,
                // ),
              );
            }),
      );
}