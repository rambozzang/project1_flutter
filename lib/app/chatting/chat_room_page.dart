import 'dart:ffi';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/chatting/lib/flutter_supabase_chat_core.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/repo/alram/alram_repo.dart';
import 'package:project1/repo/alram/data/chat_req_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
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

  // final gemini = Gemini.instance;
  final TextEditingController _textController = TextEditingController();
  final ValueNotifier<String> geminiText = ValueNotifier<String>('');
  final ValueNotifier<bool> isGeminiAi = ValueNotifier<bool>(true);

  late List<types.Message> messageList;
  late String? otherChatId;
  late String? otherCustId;
  late bool isBlocked = false;

  @override
  void initState() {
    room = widget.room; // Get.arguments['room'];

    _chatController = SupabaseChatController(room: room);

    for (var user in room.users) {
      lo.g("user.id : ${user.id}");
      if (user.id != AuthCntr.to.resLoginData.value.chatId) {
        AuthCntr.to.currentChatId = user.id;
        otherChatId = user.id;
        otherCustId = user?.metadata?['custId'] ?? '';
        lo.g("otherChatId.id : ${user.id}");
        lo.g("otherCustId.id : ${otherCustId}");
        checkBlock(otherCustId!);
      }
    }

    updateLastReadTime();

    super.initState();
  }

  Future<void> checkBlock(String otherCustId) async {
    if (otherCustId == '' || otherCustId == null) return;
    try {
      CustRepo repo = CustRepo();
      ResData res = await repo.checkBlock(otherCustId);
      isBlocked = res.data;
      if (isBlocked) {
        Utils.alert('사용자가 차단했습니다.');
      }
    } catch (e) {
      lo.g('checkBlock 오류: $e');
    }
  }

  updateLastReadTime() async {
    // 사용자가 방을 읽었을 때
    await SupabaseChatCore.instance.updateLastReadTime(int.parse(widget.room.id));
  }

  // void geminiChat(List<types.Message> list) {
  //   List<String> chats = [];
  //   // list 를 chats에 파싱 해줘
  //   for (types.Message item in list) {
  //     Map<String, dynamic> jsonData = item.toJson();

  //     lo.g('item firstName : ${item.author.firstName}');
  //     lo.g('item firstName : ${jsonData['text']}');
  //     if (item.author.id == SupabaseChatCore.instance.supabaseUser!.id) {
  //       chats.add('나 : ${jsonData['text']}');
  //     } else {
  //       chats.add('상대방 :${jsonData['text']}');
  //     }
  //   }

  //   chats = chats.reversed.toList();
  //   lo.g('chats : $chats');

  //   geminiText.value = "";
  //   if (isGeminiAi.value) {
  //     gemini
  //         .streamGenerateContent(
  //             "지금 나는 채팅방에서 대화중입니다. Gemini 당신은  나의 보조이자  같은편이다.  대화 내용은 [$chats] 입니다. 내말에 대답할 필요는 없다. 최근 대화 내용 중 맨 마지막 대화 글이 상대방이면 내가 대답할 차례입니다.  재미있는 답변을 추천 해주세요. 답변만 짧고 간단하게 알려주세요?")
  //         .listen((value) {
  //       if (value.output == null) {
  //         return;
  //       }
  //       lo.g('대답 :  ${value.output.toString()}');
  //       geminiText.value = geminiText.value + value.output!;
  //     });
  //   }
  // }

  // 첨부파일 보내기
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
                      Text('이미지'),
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
                      Text('파일'),
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
    if (isBlocked) {
      Utils.alert('차단된 사용자입니다.');
      return;
    }
    bool result = await SupabaseChatCore.instance.sendMessage(
      message,
      room.id,
    );

    // 메세지 성공하면
    if (result) {
      // 최초 여부를 관리하는 방법이 필요함.
      // if (_isFirst) {
      room.users.forEach((element) {
        if (element.id != SupabaseChatCore.instance.supabaseUser!.id) {
          String custId = element.metadata!['custId'] ?? '';
          if (custId != '') {
            AlramRepo alramRepo = AlramRepo();
            ChatReqData data = ChatReqData();
            data.custId = element.metadata!['custId'];
            data.alramContents = message.text;
            data.alramCd = '07';
            alramRepo.pushByCustId(data);
          }
        }
      });
    }
    _isFirst = false;
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }

  void leaveRoom() {
    FocusManager.instance.primaryFocus?.unfocus();
    sleep(const Duration(milliseconds: 150));
    Utils.showConfirmDialog(
      '나가기',
      '대화방을 나가시겠습니까?',
      BackButtonBehavior.none,
      confirm: () async {
        try {
          bool result = await SupabaseChatCore.instance.leaveRoom(room.id);
          if (result) {
            Utils.alert('대화방에서 나왔습니다.');
            Get.back();
          }
        } catch (e) {
          lo.g('방 나가기 오류: $e');
          Utils.alert('방 나가기 중 오류가 발생했습니다.');
        }
      },
      cancel: () {
        lo.g('방 나가기 취소');
      },
    );
  }

  @override
  void dispose() {
    // _chatController.dispose();
    updateLastReadTime();
    AuthCntr.to.currentChatId = "";
    super.dispose();
  }

  void _handleCustomSendPressed() {
    if (_textController.text.isEmpty) {
      return;
    }

    types.PartialText partialText = types.PartialText(text: _textController.text, metadata: null, previewData: null, repliedMessage: null);

    _handleSendPressed(partialText);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF262B49), //
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
            // isGeminiAi
            IconButton(
              icon: const Icon(
                Icons.warning,
                color: Colors.white,
              ),
              onPressed: () => SigoPageSheet().open(
                context,
                '',
                otherChatId.toString(),
                () => {},
              ),
            ),

            IconButton(
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              onPressed: leaveRoom,
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 78, 81, 102), // const Color(0xFF262B49),
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
              messageList = snapshot.data ?? [];
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
                  backgroundColor: Color.fromARGB(255, 32, 36, 59), // const Color(0xFF262B49), // Colors.black87,
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
                emptyState: const Center(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '💥음란대화는 법적조치가 들어갑니다.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      Spacer(),
                      Text(
                        '이제 대화를 시작해보세요.',
                        style: TextStyle(color: Colors.white),
                      ),
                      Spacer(),
                      const SizedBox(
                        height: 1,
                      )
                    ],
                  ),
                ),
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
                //customBottomWidget: customTextinputWidget(),
                onAttachmentPressed: _handleAttachmentPressed,
                onMessageTap: _handleMessageTap,
                onPreviewDataFetched: _handlePreviewDataFetched,
                onSendPressed: _handleSendPressed,
                hideBackgroundOnEmojiMessages: false,
                user: types.User(
                  id: SupabaseChatCore.instance.supabaseUser!.id,
                ),
                // systemMessageBuilder: (SystemMessage) {
                //   if (snapshot.data!.first == '[상대방나감]') {
                //     return const Text('나갔씁니다.');
                //   }
                //   return const Text('상대방이 나갔습니다.');
                // },

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
  Widget customTextinputWidget() {
    return ValueListenableBuilder<bool>(
      valueListenable: isGeminiAi,
      builder: (context, value, child) {
        return Container(
          height: value ? 160 + 35 : 68 + 35,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 57, 65, 112),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 35,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Text(
                      'Gemini AI',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    FittedBox(
                      child: Switch(
                        value: isGeminiAi.value,
                        onChanged: (value) {
                          isGeminiAi.value = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              value
                  ? Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<String>(
                              valueListenable: geminiText,
                              builder: (context, value, child) {
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => _textController.text = value,
                                    child: SingleChildScrollView(
                                      child: Text(value,
                                          overflow: TextOverflow.clip,
                                          softWrap: true,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                          )),
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              Container(
                color: Colors.white,
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(0),
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _handleAttachmentPressed();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (text) => _handleCustomSendPressed(),
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: Colors.black, decorationThickness: 0), //
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          hintText: "메세지 입력",
                          border: InputBorder.none,
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          // border: OutlineInputBorder(
                          //   borderRadius: BorderRadius.circular(8.0),
                          // ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          // Handle send button press
                          _handleCustomSendPressed();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
