import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_save_main_data.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';

/// 사진(다중) 등록 화면.
/// 카메라 사진 모드에서 촬영/선택한 사진들을 가로 캐러셀로 미리보고 캡션과 함께 게시한다.
/// (Phase 2: 캐러셀 + 캡션 기본형 / Phase 3: feel·정책 등 정교화 / Phase 4: 업로드 연결)
class PhotoRegPage extends StatefulWidget {
  final List<File> photoFiles;
  const PhotoRegPage({super.key, required this.photoFiles});

  @override
  State<PhotoRegPage> createState() => _PhotoRegPageState();
}

class _PhotoRegPageState extends State<PhotoRegPage> {
  // 다크 팔레트(영상 등록 화면과 통일감)
  static const Color _bg = Color(0xFF14161C);
  static const Color _surface = Color(0xFF20242E);
  static const Color _surfaceBorder = Color(0xFF2C313D);
  static const Color _accent = Color(0xFF4A90E2);
  static const Color _textHi = Color(0xFFF1F4F9);
  static const Color _textLo = Color(0xFF9AA3B2);

  final PageController _pageController = PageController();
  final TextEditingController _captionController = TextEditingController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photoFiles;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _textHi),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('새 게시물', style: TextStyle(color: _textHi, fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildCarousel(photos)),
            _buildCaptionField(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCarousel(List<File> photos) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, i) {
            return Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: Image.file(photos[i], fit: BoxFit.contain),
            );
          },
        ),
        // 페이지 인디케이터(점)
        if (photos.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) {
                final bool active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 9 : 6,
                  height: active ? 9 : 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        // 장수 배지(우상단)
        Positioned(
          top: 12,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
            child: Text('${_currentPage + 1}/${photos.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceBorder),
      ),
      child: TextField(
        controller: _captionController,
        maxLines: 3,
        minLines: 1,
        style: const TextStyle(color: _textHi, fontSize: 14),
        decoration: const InputDecoration(
          hintText: '문구와 해시태그를 입력하세요…',
          hintStyle: TextStyle(color: _textLo, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _surfaceBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: GestureDetector(
            onTap: _onPublish,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('게시하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }

  void _onPublish() {
    if (widget.photoFiles.isEmpty) return;

    // 본문(typeDtCd='I') + 체감태그만 담는다. 날씨 본체/이미지URL은
    // RootCntr.uploadPhotos가 업로드 후 저장 직전에 합친다.
    final boardSaveData = BoardSaveData()
      ..boardMastInVo = (BoardSaveMainData()
        ..contents = _captionController.text
        ..depthNo = '0'
        ..notiEdAt = ''
        ..notiStAt = ''
        ..subject = ''
        ..typeCd = 'V'
        ..typeDtCd = 'I' // ★ 사진 게시물
        ..anonyYn = 'N'
        ..hideYn = 'N')
      ..boardWeatherVo = (BoardSaveWeatherData()..feelCd = null);

    // 백그라운드 업로드 시작(영상과 동일하게 isFileUploading 전역 표시)
    Get.find<RootCntr>().goTimerPhotos(List<File>.from(widget.photoFiles), boardSaveData);

    Utils.alert('업로드중 입니다! 잠시후 정상 게시됩니다!');

    // 사진 등록 + 카메라 화면을 닫고 피드로 복귀
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
