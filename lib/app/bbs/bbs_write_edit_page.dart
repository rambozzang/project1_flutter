// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_quill_delta_from_html/parser/html_to_delta.dart';
// import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
// import 'dart:io' as io show Directory, File;
// import 'package:get/get.dart';
// import 'package:project1/app/bbs/cntr/bbs_cntr3.dart';
// import 'package:project1/app/bbs/embeds/timestamp_embed.dart';
// import 'package:project1/app/bbs/quill/my_quill_toolbar.dart';
// import 'package:project1/utils/log_utils.dart';
// import 'package:project1/utils/utils.dart';
// import 'package:project1/widget/custom_indicator_offstage.dart';
// import 'package:flutter_quill_extensions/src/editor/image/widgets/image.dart' show getImageProviderByImageSource, imageFileExtensions;
// import 'package:flutter_quill/flutter_quill.dart' as ql;
// import 'package:path/path.dart' as path;

// class BbsWriteEditPage extends StatefulWidget {
//   const BbsWriteEditPage({super.key});

//   @override
//   State<BbsWriteEditPage> createState() => _BbsWritePage3State();
// }

// class _BbsWritePage3State extends State<BbsWriteEditPage> {
//   // 업로드 파일 리스트
//   String result = '';

//   final TextEditingController videoNameController = TextEditingController();
//   final TextEditingController videoUrlController = TextEditingController();
//   final cntr = Get.find<BbsWriteController3>();

//   @override
//   void initState() {
//     super.initState();
//     // FocusScope.of(context).requestFocus(textFocus);

//     //  _controller.readOnly = _isReadOnly;
//   }

//   void _saveAsHtml() async {
//     bool result = await cntr.submitPost();
//     if (result) {
//       Get.back();
//     }
//   }

//   void _loadFromHtml() {
//     String htmlContent = "<p>Hello, <b>world</b>!</p>";
//     var delta = HtmlToDelta().convert(htmlContent);
//     lo.g("_loadFromHtml delta : $delta");
//   }

//   @override
//   void dispose() {
//     videoNameController.clear();
//     videoUrlController.clear();
//     videoNameController.dispose();
//     videoUrlController.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // cntr.htmlController.readOnly = true;
//     return Stack(
//       children: [
//         Scaffold(
//           appBar: AppBar(
//             automaticallyImplyLeading: true,
//             forceMaterialTransparency: true,
//             actions: [
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   elevation: 0,
//                   side: const BorderSide(color: Colors.white, width: 0.0),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
//                   // backgroundColor: Colors.grey.shade50,
//                 ),
//                 onPressed: () {
//                   _saveAsHtml();
//                 },
//                 child: const Text(
//                   '등록',
//                   style: TextStyle(color: Colors.black),
//                 ),
//               ),
//             ],
//           ),
//           backgroundColor: Colors.white,
//           resizeToAvoidBottomInset: true,
//           body: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(
//                   // margin: const EdgeInsets.symmetric(horizontal: 0),
//                   // padding: const EdgeInsets.only(top: 5),
//                   height: 55,
//                   child: TextFormField(
//                     controller: cntr.titleController,
//                     focusNode: cntr.titleFocus,
//                     maxLines: 1,
//                     textInputAction: TextInputAction.next,
//                     style: const TextStyle(decorationThickness: 0, fontSize: 14), // 한글밑줄제거
//                     decoration: const InputDecoration(
//                       alignLabelWithHint: true, // label 과 입력창을 같은 높이로 맞춤
//                       contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
//                       filled: true,
//                       fillColor: Colors.white,
//                       enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(
//                         color: Colors.transparent,
//                       )),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: BorderSide(
//                           color: Colors.transparent,
//                         ),
//                       ),
//                       label: Text("제목을 입력해주세요.", style: TextStyle(color: Colors.black38, fontSize: 14)),
//                       labelStyle: TextStyle(color: Colors.black38),
//                       floatingLabelBehavior: FloatingLabelBehavior.never,
//                     ),
//                     onChanged: (value) {
//                       if (value.length > 50) {
//                         Utils.alert('50자 이하로 입력해주세요.');
//                         cntr.titleController.text = value.substring(0, 50);
//                       }
//                     },
//                     onFieldSubmitted: (text) {
//                       FocusScope.of(context).nextFocus();

//                       // Perform search
//                     },
//                   ),
//                 ),
//                 Expanded(
//                   child: ql.QuillEditor.basic(
//                     focusNode: cntr.htmlFocus,
//                     controller: cntr.htmlController,
//                     scrollController: ScrollController(),
//                     configurations: ql.QuillEditorConfigurations(
//                         scrollable: true,
//                         autoFocus: false,
//                         expands: true,
//                         placeholder: '내용을 입력해 주세요.',
//                         scrollPhysics: const ScrollPhysics(),
//                         padding: const EdgeInsets.only(bottom: 70),
//                         textSelectionThemeData: TextSelectionThemeData(
//                           cursorColor: Colors.purple, // 커서 색상을 보라색으로 설정
//                           selectionColor: Colors.purple.withOpacity(0.5), // 선택 영역의 색상 설정 (필요에 따라)
//                           selectionHandleColor: Colors.purple, // 선택 핸들 색상 설정 (필요에 따라)
//                         ),
//                         sharedConfigurations: const ql.QuillSharedConfigurations(
//                           locale: Locale('ko'),
//                         ),
//                         onImagePaste: (imageBytes) async {
//                           // We will save it to system temporary files
//                           final newFileName = 'imageFile-${DateTime.now().toIso8601String()}.png';
//                           final newPath = path.join(
//                             io.Directory.systemTemp.path,
//                             newFileName,
//                           );
//                           final file = await io.File(
//                             newPath,
//                           ).writeAsBytes(imageBytes, flush: true);
//                           return file.path;
//                         },
//                         embedBuilders: [
//                           ...FlutterQuillEmbeds.editorBuilders(
//                             imageEmbedConfigurations: QuillEditorImageEmbedConfigurations(
//                               imageErrorWidgetBuilder: (context, error, stackTrace) {
//                                 return Text(
//                                   'Error while loading an image: ${error.toString()}',
//                                 );
//                               },
//                               imageProviderBuilder: (context, imageUrl) {
//                                 // cached_network_image is supported
//                                 // only for Android, iOS and web
//                                 // We will use it only if image from network
//                                 if (isHttpBasedUrl(imageUrl)) {
//                                   return CachedNetworkImageProvider(
//                                     imageUrl,
//                                   );
//                                 }
//                                 return getImageProviderByImageSource(
//                                   imageUrl,
//                                   imageProviderBuilder: null,
//                                   context: context,
//                                   assetsPrefix: QuillSharedExtensionsConfigurations.get(context: context).assetsPrefix,
//                                 );
//                               },
//                             ),
//                             videoEmbedConfigurations: QuillEditorVideoEmbedConfigurations(
//                               customVideoBuilder: (videoUrl, readOnly) {
//                                 // Example: Check for YouTube Video URL and return your
//                                 // YouTube video widget here.

//                                 // Otherwise return null to fallback to the defualt logic
//                                 return null;
//                               },
//                               ignoreYouTubeSupport: true,
//                             ),
//                           ),
//                           TimeStampEmbedBuilderWidget(),
//                         ]),
//                   ),
//                 ),
//                 MyQuillToolbar(
//                   controller: cntr.htmlController,
//                   focusNode: cntr.htmlTitleFocus,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Obx(() {
//           if (cntr.isSaving.value) {
//             return CustomIndicatorOffstage(isLoading: !cntr.isSaving.value, color: const Color(0xFFEA3799), opacity: 0.5);
//           }
//           return const SizedBox.shrink();
//         })
//       ],
//     );
//   }

//   Widget btn(String text, Function() onPressed) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.black,
//         foregroundColor: Colors.black,
//         padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
//         elevation: 3,
//         side: const BorderSide(color: Colors.white, width: 0.0),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
//         // backgroundColor: Colors.grey.shade50,
//       ),
//       onPressed: onPressed,
//       child: Text(
//         text,
//         style: const TextStyle(color: Colors.white),
//       ),
//     );
//   }
// }
