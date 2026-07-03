import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/widget/sa_gradient_button.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_save_main_data.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';

/// 업로드(1g) — 갤러리에서 고른 사진들을 앨범에 올리는 전용 화면.
/// 대상 앨범 칩 + 미디어 그리드(첫 항목 크게) + 캡션 + 날씨·위치 자동 태그 + N개 업로드.
/// 업로드는 기존 파이프라인(RootCntr.goTimerPhotos) 재사용 — 영상은 촬영 플로우로 안내.
class AlbumUploadPage extends StatefulWidget {
  const AlbumUploadPage({super.key, required this.community, required this.photoFiles});

  final CommunityData community;
  final List<File> photoFiles;

  @override
  State<AlbumUploadPage> createState() => _AlbumUploadPageState();
}

class _AlbumUploadPageState extends State<AlbumUploadPage> {
  final TextEditingController _captionCtrl = TextEditingController();
  late final List<File> _files;
  bool _attachWeather = true;

  @override
  void initState() {
    super.initState();
    _files = List.of(widget.photoFiles);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  // 자동 감지 태그 문구: "서울 강남구 · 비 24°" (기존 날씨앱 데이터 재사용 — 1g의 핵심 연동 포인트)
  String get _autoTagText {
    final w = Get.find<WeatherGogoCntr>();
    final String loc = w.currentLocation.value.name;
    final String temp = w.currentWeather.value.temp ?? '';
    final String desc = w.currentWeather.value.description ?? '';
    final parts = [
      if (loc.isNotEmpty && loc != '현재 위치') loc,
      if (desc.isNotEmpty) desc,
      if (temp.isNotEmpty && temp != '0.0') '$temp°',
    ];
    return parts.isEmpty ? '위치·날씨 감지 대기 중' : parts.join(' · ');
  }

  Future<void> _addMore() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
    if (picked.isEmpty || !mounted) return;
    setState(() => _files.addAll(picked.map((e) => File(e.path))));
  }

  BoardSaveWeatherData _weatherData() {
    final w = Get.find<WeatherGogoCntr>();
    final weather = w.currentWeather.value;
    return BoardSaveWeatherData()
      ..boardId = 0
      ..city = ''
      ..country = ''
      ..currentTemp = weather.temp ?? '0'
      ..humidity = weather.humidity?.toString() ?? '1'
      ..lat = w.currentLocation.value.latLng.latitude.toString()
      ..lon = w.currentLocation.value.latLng.longitude.toString()
      ..speed = weather.speed?.toString() ?? '1'
      ..sky = weather.sky?.toString() ?? '1'
      ..rain = weather.rain?.toString() ?? '0'
      ..tempMax = ''
      ..tempMin = ''
      ..location = w.currentLocation.value.name
      ..weatherInfo = weather.description ?? '맑음'
      ..mist10 = w.mistData.value.mist10Grade.toString()
      ..mist25 = w.mistData.value.mist25Grade.toString();
  }

  void _upload() {
    if (_files.isEmpty) return;
    final boardSaveData = BoardSaveData()
      ..boardMastInVo = (BoardSaveMainData()
        ..contents = _captionCtrl.text
        ..depthNo = '0'
        ..notiEdAt = ''
        ..notiStAt = ''
        ..subject = ''
        ..typeCd = 'V'
        ..typeDtCd = 'I' // 사진 게시물
        ..anonyYn = 'N'
        ..hideYn = 'N'
        ..communityId = widget.community.communityId)
      ..boardWeatherVo = (_attachWeather ? _weatherData() : BoardSaveWeatherData());

    // 기존 백그라운드 업로드 파이프라인 재사용(진행 표시는 전역 isFileUploading)
    Get.find<RootCntr>().goTimerPhotos(List<File>.from(_files), boardSaveData);
    Utils.alert('업로드중 입니다! 잠시후 정상 게시됩니다!');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    SaColors.syncWith(context); // 시스템 밝기에 맞춰 다크/라이트 팔레트 동기화
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: SaColors.isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: SaColors.isLight ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SaColors.bgBase,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _buildTargetChip(),
                    const SizedBox(height: 16),
                    _buildMediaGrid(),
                    const SizedBox(height: 18),
                    _sectionLabel('캡션'),
                    TextField(
                      controller: _captionCtrl,
                      maxLines: 3,
                      style: SaText.bodyMedium,
                      decoration: InputDecoration(
                        hintText: '이 순간을 설명해보세요 (#해시태그 가능)',
                        hintStyle: SaText.body.copyWith(color: SaColors.textTertiary),
                        filled: true,
                        fillColor: SaColors.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: SaColors.borderStrong),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: SaColors.accentTeal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildAutoTagCard(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: SaGradientButton(
                  label: '${_files.length}개 업로드',
                  height: 52,
                  glow: true,
                  expand: true,
                  onTap: _upload,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: SaText.bodyMedium.copyWith(color: SaColors.textSecondary)),
          ),
          Expanded(child: Center(child: Text('올리기', style: SaText.titleS))),
          const SizedBox(width: 48), // 좌측 취소 버튼과 균형
        ],
      ),
    );
  }

  Widget _buildTargetChip() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: SaColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: SaColors.borderStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(PhosphorIconsFill.images, size: 13, color: SaColors.accentTeal),
              const SizedBox(width: 6),
              Text(widget.community.name,
                  style: SaText.caption.copyWith(color: SaColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('앨범에 올라갑니다', style: SaText.mono(fontSize: 10)),
      ],
    );
  }

  // 선택된 미디어 그리드: 첫 항목 2x2 크게, 나머지 1x1, 끝에 + 추가 타일
  Widget _buildMediaGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 3,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (int i = 0; i < _files.length; i++)
          StaggeredGridTile.count(
            crossAxisCellCount: i == 0 ? 2 : 1,
            mainAxisCellCount: i == 0 ? 2 : 1,
            child: _mediaTile(i),
          ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: GestureDetector(
            onTap: _addMore,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SaColors.borderStrong),
                color: SaColors.surface,
              ),
              child: Center(
                child: PhosphorIcon(PhosphorIconsBold.plus, size: 20, color: SaColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mediaTile(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_files[index], fit: BoxFit.cover),
        ),
        Positioned(
          right: 5,
          top: 5,
          child: GestureDetector(
            onTap: () => setState(() => _files.removeAt(index)),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: SaText.mono(fontSize: 11, color: SaColors.accentTeal)),
    );
  }

  // GPS+날씨 자동 감지 카드 — 기존 날씨앱 데이터 연동 포인트
  Widget _buildAutoTagCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaColors.border),
      ),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsFill.mapPin, size: 16, color: SaColors.accentTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('날씨·위치 자동 태그', style: SaText.bodyMedium.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(_autoTagText, style: SaText.mono(fontSize: 10)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: _attachWeather,
              activeTrackColor: SaColors.accentTeal,
              onChanged: (v) => setState(() => _attachWeather = v),
            ),
          ),
        ],
      ),
    );
  }
}
