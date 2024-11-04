import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project1/app/bbs/comments/cntr/bbs_comments_cntr.dart';

class BbsCommentsBottomPage extends StatelessWidget {
  final String tagNm;
  BbsCommentsBottomPage({super.key, required this.tagNm});

  late var commentsController;

  @override
  Widget build(BuildContext context) {
    commentsController = Get.find<BbsCommentsController>(tag: tagNm);
    return Obx(() => _buildAnimatedSlide(context));
  }

  Widget _buildAnimatedSlide(BuildContext context) {
    return AnimatedSlide(
      curve: Curves.easeIn,
      offset: commentsController.isCommentsHidden.value ? const Offset(0, 2) : Offset.zero,
      duration: const Duration(milliseconds: 125),
      child: commentsController.isCommentsHidden.value ? const SizedBox.shrink() : _buildBottomNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 0,
        right: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCommentImagePreview(),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentImagePreview() {
    return Obx(() {
      if (commentsController.commentImage.value == null) {
        return const SizedBox.shrink();
      }
      return Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 224, 224, 223),
          border: Border(
            top: BorderSide(color: Colors.grey, width: 0.5),
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            _buildImagePreview(),
            if (!commentsController.isSending.value) _buildRemoveImageButton(),
          ],
        ),
      );
    });
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: _getImageWidget(),
        ),
        if (commentsController.isSending.value) _buildUploadingOverlay(),
      ],
    );
  }

  Widget _getImageWidget() {
    final imagePath = commentsController.commentImage.value!.path.toString();
    return !imagePath.contains('http')
        ? Image.file(File(imagePath), fit: BoxFit.cover)
        : Image.network(
            imagePath,
            height: 240,
            width: 240,
            fit: BoxFit.cover,
          );
  }

  Widget _buildUploadingOverlay() {
    return const Positioned.fill(
      child: Center(
        child: Text(
          'Uploading...',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRemoveImageButton() {
    return Positioned(
      top: 0,
      right: 0,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: () => commentsController.removeCommentImage(),
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Obx(() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64.0 + (commentsController.visibleLines.value - 1) * 24.0,
        decoration: _buildInputFieldDecoration(),
        child: Container(
          color: Colors.white24,
          height: 64,
          padding: const EdgeInsets.only(left: 0, right: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAddPhotoButton(),
              _buildTextField(),
              const Gap(5),
              _buildSendButton(),
            ],
          ),
        ),
      );
    });
  }

  BoxDecoration _buildInputFieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, -1),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return IconButton(
      padding: const EdgeInsets.only(bottom: 18),
      icon: const Icon(
        Icons.add_photo_alternate_outlined,
        color: Colors.black,
        size: 25,
      ),
      onPressed: commentsController.pickImage,
    );
  }

  Widget _buildTextField() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          controller: commentsController.replyTextFeildScrollController,
          child: TextField(
            keyboardType: TextInputType.multiline,
            controller: commentsController.replyTextController,
            focusNode: commentsController.replyFocusNode,
            autofocus: false,
            maxLines: 3,
            minLines: 1,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(color: Colors.black, decorationThickness: 0),
            onSubmitted: (_) => _handleSubmit(),
            onTapOutside: (_) => commentsController.replyFocusNode.unfocus(),
            onChanged: (val) => commentsController.setCommentActive(val.isNotEmpty),
            decoration: _buildTextFieldDecoration(),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildTextFieldDecoration() {
    return InputDecoration(
      hintText: '댓글 달기...',
      hintStyle: const TextStyle(color: Colors.black45, fontSize: 15),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  void _handleSubmit() {
    if (commentsController.isModifyMode.value) {
      commentsController.updataComment();
    } else {
      commentsController.saveComment();
    }
  }

  Widget _buildSendButton() {
    if (!commentsController.isCommentActive.value) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        _buildSendIconButton(),
        if (commentsController.isModifyMode.value && !commentsController.isSending.value) _buildCancelModifyButton(),
      ],
    );
  }

  Widget _buildSendIconButton() {
    return ElevatedButton(
      style: _buildSendButtonStyle(),
      onPressed: () => _handleSubmit(),
      child: !commentsController.isSending.value
          ? const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 17,
              ),
            )
          : LoadingAnimationWidget.fourRotatingDots(
              color: Colors.pink,
              size: 30,
            ),
    );
  }

  ButtonStyle _buildSendButtonStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildCancelModifyButton() {
    return CircleAvatar(
      backgroundColor: Colors.grey,
      child: IconButton(
        onPressed: () => commentsController.cancleModifySetting(),
        icon: const Icon(
          Icons.close,
          size: 17,
          color: Colors.white,
        ),
      ),
    );
  }
}
