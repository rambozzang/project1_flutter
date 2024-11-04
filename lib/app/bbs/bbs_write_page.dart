import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/bbs/cntr/bbs_list_cntr.dart';
import 'package:project1/app/bbs/cntr/bbs_write_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:rich_text_view/rich_text_view.dart';

class BbsWritePage extends StatefulWidget {
  const BbsWritePage({super.key});

  @override
  State<BbsWritePage> createState() => _BbsWritePageState();
}

class _BbsWritePageState extends State<BbsWritePage> {
  final cntr = Get.find<BbsWriteController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop) Navigator.of(context).pop();
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: _buildAppBar(),
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: false,
            body: _buildBody(),
            bottomNavigationBar: _buildBottomBar(context),
          ),
          _buildSavingIndicator(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: true,
      forceMaterialTransparency: true,
      actions: [
        ElevatedButton(
          style: _appBarButtonStyle(),
          onPressed: _handleSubmit,
          child: const Text('등록', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBbsType(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Colors.grey.shade300, height: 1),
          ),
          _buildTitleField(),
          _buildContentField(),
          _buildImageList(),
        ],
      ),
    );
  }

  Widget _buildBbsType() {
    return Container(
        alignment: Alignment.centerLeft,
        child: Obx(() => Wrap(
              children: [
                ...Get.find<BbsListController>().bbsTypeList.map((e) {
                  if (e.code.toString() == 'ALL') {
                    return const SizedBox.shrink();
                  }
                  return buildButtonDetail(e.codeNm.toString(), e.code.toString());
                }),
              ],
            )));
  }

  Widget _buildTitleField() {
    return SizedBox(
      height: 45,
      child: TextFormField(
        controller: cntr.titleController,
        focusNode: cntr.titleFocus,
        autofocus: true,
        maxLines: 1,
        style: const TextStyle(decorationThickness: 0),
        decoration: _inputDecoration('제목을 입력하세요.'),
        onChanged: _handleTitleChange,
      ),
    );
  }

  Widget _buildContentField() {
    return Expanded(
      child: TextFormField(
        controller: cntr.contentController,
        focusNode: cntr.contentsFocus,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(decorationThickness: 0),
        decoration: _inputDecorationContents(),
        onChanged: _handleContentChange,
      ),
    );
  }

  Widget _buildImageList() {
    return SizedBox(
      height: 80,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var image in cntr.imageList)
                  ImageItem(
                    key: ValueKey(image.fileName),
                    image: image.obs,
                    onRemove: () => cntr.removeImage(image),
                  ),
              ],
            )),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 63,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildBottomBarButton(Icons.tag, '태그', () => cntr.contentController.text += ' #'),
            const SizedBox(width: 10),
            _buildBottomBarButton(Icons.link_sharp, '이미지링크', () => cntr.contentController.text += '<img src="여기다 URL입력">'),
            const SizedBox(width: 10),
            _buildBottomBarButton(Icons.image_outlined, '이미지', () => cntr.pickImage()),
            const SizedBox(width: 10),
            _buildBottomBarButton(Icons.image_not_supported_outlined, '전체삭제', () => cntr.removeAllImages()),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarButton(IconData icon, String text, Function() onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        maximumSize: const Size(52, 52),
        minimumSize: const Size(52, 52),
        elevation: 3,
        side: const BorderSide(color: Colors.black, width: 0.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 25),
          Text(text, style: const TextStyle(color: Colors.black, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildSavingIndicator() {
    return Obx(() {
      if (cntr.isSaving.value) {
        return CustomIndicatorOffstage(isLoading: !cntr.isSaving.value, color: const Color(0xFFEA3799), opacity: 0.5);
      }
      return const SizedBox.shrink();
    });
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.bold),
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }

  InputDecoration _inputDecorationContents() {
    // '여기에 내용을 입력하세요. \n -#태그 #태그2\n -비디오영상은 Youtube링크만 가능\n'
    return InputDecoration(
      hintText: "",
      hintStyle: const TextStyle(color: Colors.black38),
      label: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: '여기에 내용을 입력하세요.\n',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '-#태그1 #태그2\n-비디오영상은 Youtube링크만 가능\n-이미지링크는 한글이 포함된 URL은 지원하지 않습니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }

  ButtonStyle _appBarButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 0,
      side: const BorderSide(color: Colors.white, width: 0.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }

  void _handlePopScope(bool didPop, bool result) async {
    if (didPop) return;
    final bool shouldPop = await _onWillPop();
    if (shouldPop) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSubmit() async {
    bool success = await cntr.submitPost();
    if (success) {
      Get.back(result: true);
    }
  }

  void _handleTitleChange(String value) {
    if (value.length > 40) {
      Utils.alert('40자 이하로 입력해주세요.');
      cntr.titleController.text = value.substring(0, 50);
    }
  }

  void _handleContentChange(String value) {
    if (value.length > 500) {
      Utils.alert('500자 이하로 입력해주세요.');
      cntr.titleController.text = value.substring(0, 50);
    }
  }

  Future<bool> _onWillPop() async {
    if (cntr.contentController.text.isNotEmpty || cntr.imageList.isNotEmpty) {
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.amber,
                    size: 23,
                  ),
                  const SizedBox(width: 10),
                  Text('안  내', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text('작성 중인 내용이 있습니다.\n\n정말로 나가시겠습니까?'),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소', style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('확인', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ) ??
          false;

      if (confirm && cntr.imageList.isNotEmpty) {
        cntr.isSaving.value = true;
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        await cntr.removeAllImages();
      }
      return confirm;
    }
    return true;
  }

  Widget buildButtonDetail(String title, String type) {
    return Obx(() => Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
              child: SizedBox(
                height: 27,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: cntr.typeDtCd.value == type ? Colors.black : Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                        color: cntr.typeDtCd.value == type ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    cntr.typeDtCd.value = type;
                  },
                ),
              ),
            ),
            cntr.typeDtCd.value == type
                ? Positioned(
                    top: -2,
                    right: 0,
                    child: Icon(Icons.check_circle, color: Colors.amber[600], size: 15),
                  )
                : const SizedBox.shrink(),
          ],
        ));
  }
}

class ImageItem extends StatefulWidget {
  final Rx<ImageData> image;
  final VoidCallback onRemove;

  const ImageItem({super.key, required this.image, required this.onRemove});

  @override
  _ImageItemState createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              _buildImage(),
              if (!widget.image.value.isDeleting) _buildRemoveButton(),
              if (!widget.image.value.isUploaded) _buildUploadingIndicator(),
              if (widget.image.value.isDeleting) _buildDeletingOverlay(),
            ],
          ),
        ));
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: widget.image.value.file != null
          ? FadeInImage(
              placeholder: const AssetImage('assets/transparent.png'),
              image: FileImage(File(widget.image.value.file!.path)),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            )
          : FadeInImage.assetNetwork(
              placeholder: 'assets/transparent.png',
              image: widget.image.value.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildRemoveButton() {
    return Positioned(
      right: -3,
      top: -3,
      child: CircleAvatar(
        backgroundColor: Colors.black,
        radius: 12,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            final cntr = Get.find<BbsWriteController>();
            cntr.removeImage(widget.image.value);
          },
          icon: const Icon(Icons.close, size: 12, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return Positioned(
      left: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(2),
        color: Colors.black.withOpacity(0.5),
        child: const Text(
          '업로드 중...',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildDeletingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
