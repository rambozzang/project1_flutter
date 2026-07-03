import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/community/widget/cover_template.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/widget/sa_gradient_button.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';

/// 새 앨범 만들기 — 공유앨범 다크 디자인 버전(구 CommunityCreatePage 대체).
/// 기능 동일: 표지(템플릿 10종/커스텀 업로드) + 이름/소개 + 공개·가입 방식 + 장소 연결(prefill 지원).
/// Spot 상세("이 장소로 앨범 만들기")에서 arguments로 spotId/spotName/lat/lon을 넘기면 미리 채워진다.
class AlbumCreatePage extends StatefulWidget {
  const AlbumCreatePage({super.key});

  @override
  State<AlbumCreatePage> createState() => _AlbumCreatePageState();
}

class _AlbumCreatePageState extends State<AlbumCreatePage> {
  final CommunityRepo _repo = CommunityRepo();
  final KakaoRepo _kakao = KakaoRepo();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _spotSearchCtrl = TextEditingController();

  bool _isPublic = true;
  String _joinType = 'AUTO';
  bool _saving = false;

  // 표지: 템플릿 or 커스텀 업로드(둘 중 하나만)
  String? _coverTemplateId = kCoverTemplates.first.id;
  String? _customCoverUrl;
  bool _uploadingCover = false;

  // 장소 연결(선택)
  Timer? _debounce;
  List<Map<String, dynamic>> _spotResults = [];
  bool _spotSearching = false;
  int? _spotId; // Spot 상세에서 넘어온 경우만 채워짐
  String? _spotName;
  double? _spotLat;
  double? _spotLon;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      final spotId = args['spotId'];
      if (spotId != null) _spotId = spotId is int ? spotId : int.tryParse(spotId.toString());
      _spotName = args['spotName']?.toString();
      final lat = args['lat'];
      final lon = args['lon'];
      _spotLat = lat is double ? lat : double.tryParse(lat?.toString() ?? '');
      _spotLon = lon is double ? lon : double.tryParse(lon?.toString() ?? '');
      if ((_spotName ?? '').isNotEmpty) _spotSearchCtrl.text = _spotName!;
    }
    // 템플릿 미리보기(w=800)를 미리 받아둬 선택 즉시 전환되게 한다(총 ~1-2MB, 백그라운드).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final t in kCoverTemplates) {
        precacheImage(CachedNetworkImageProvider(coverImageUrl(t.imageUrl)), context);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _spotSearchCtrl.dispose();
    super.dispose();
  }

  String? get _previewUrl =>
      _customCoverUrl ??
      kCoverTemplates.where((t) => t.id == _coverTemplateId).map((t) => t.imageUrl).firstOrNull;

  // ── 표지 ────────────────────────────────────────────────

  void _selectTemplate(String id) {
    setState(() {
      _coverTemplateId = id;
      _customCoverUrl = null;
    });
  }

  Future<void> _pickCustomCover() async {
    setState(() => _uploadingCover = true);
    final url = await pickAndUploadCoverPhoto();
    if (!mounted) return;
    setState(() {
      _uploadingCover = false;
      if (url != null) {
        _customCoverUrl = url;
        _coverTemplateId = null;
      }
    });
  }

  // ── 장소 ────────────────────────────────────────────────

  void _onSpotSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _spotResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchSpot(q.trim()));
  }

  Future<void> _searchSpot(String q) async {
    setState(() => _spotSearching = true);
    try {
      final docs = await _kakao.getCoordinates(q);
      if (mounted) setState(() => _spotResults = docs);
    } catch (_) {
      if (mounted) setState(() => _spotResults = []);
    } finally {
      if (mounted) setState(() => _spotSearching = false);
    }
  }

  void _selectSpot(Map<String, dynamic> doc) {
    setState(() {
      _spotName = doc['place_name']?.toString() ?? '';
      _spotLat = double.tryParse(doc['y']?.toString() ?? '');
      _spotLon = double.tryParse(doc['x']?.toString() ?? '');
      _spotId = null; // 새로 검색한 장소는 기존 Spot 레코드와 무관(좌표만 저장)
      _spotResults = [];
      _spotSearchCtrl.text = _spotName!;
      FocusScope.of(context).unfocus();
    });
  }

  void _clearSpot() {
    setState(() {
      _spotId = null;
      _spotName = null;
      _spotLat = null;
      _spotLon = null;
      _spotSearchCtrl.clear();
      _spotResults = [];
    });
  }

  // ── 생성 ────────────────────────────────────────────────

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      BotToast.showText(text: '앨범 이름을 입력해주세요.');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final (ok, msg, _) = await _repo.create(
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isPublic: _isPublic ? 'Y' : 'N',
      joinType: _joinType,
      spotId: _spotId,
      lat: _spotLat,
      lon: _spotLon,
      coverTemplateId: _customCoverUrl == null ? _coverTemplateId : null,
      imageUrl: _customCoverUrl,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    BotToast.showText(text: msg.isEmpty ? (ok ? '앨범이 생성되었습니다.' : '생성에 실패했습니다.') : msg);
    if (ok) Get.back(result: true);
  }

  // ── UI ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SaColors.syncWith(context); // 시스템 밝기에 맞춰 다크/라이트 팔레트 동기화
    final bool spotSelected = _spotLat != null && _spotLon != null;
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
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _buildCoverPreview(),
                    const SizedBox(height: 10),
                    _buildTemplateStrip(),
                    const SizedBox(height: 22),
                    _sectionLabel('이름'),
                    _input(_nameCtrl, hint: '예) 장마의 기록', maxLines: 1),
                    const SizedBox(height: 14),
                    _sectionLabel('소개'),
                    _input(_descCtrl, hint: '어떤 순간을 모으는 앨범인가요?', maxLines: 3),
                    const SizedBox(height: 22),
                    _sectionLabel('공개 범위 · 가입 방식'),
                    _buildOptions(),
                    const SizedBox(height: 22),
                    _sectionLabel('장소 연결 (선택)'),
                    if (spotSelected) _buildSelectedSpot() else _buildSpotSearch(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: _saving
                    ? Center(
                        child: SizedBox(
                            width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal)))
                    : SaGradientButton(label: '앨범 만들기', height: 52, glow: true, expand: true, onTap: _submit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: SaColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: SaColors.borderStrong),
              ),
              child: PhosphorIcon(PhosphorIconsBold.caretLeft, size: 16, color: SaColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Text('새 앨범', style: SaText.titleS),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: SaText.mono(fontSize: 11, color: SaColors.accentTeal)),
    );
  }

  // 선택된 표지 큰 미리보기
  Widget _buildCoverPreview() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SaColors.border),
        color: SaColors.surfaceElevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((_previewUrl ?? '').isNotEmpty)
            CachedNetworkImage(
              // 원본 대신 w=800 경량본. 로드되는 동안엔 스트립에서 이미 캐시된
              // w=200 썸네일을 깔아 선택 즉시 바뀐 것처럼 보이게 한다.
              imageUrl: coverImageUrl(_previewUrl!),
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (_, __) => CachedNetworkImage(
                imageUrl: coverImageUrl(_previewUrl!, width: 200),
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(color: SaColors.surfaceElevated),
                errorWidget: (_, __, ___) => ColoredBox(color: SaColors.surfaceElevated),
              ),
              errorWidget: (_, __, ___) => ColoredBox(color: SaColors.surfaceElevated),
            ),
          if (_uploadingCover)
            Container(
              color: Colors.black45,
              child: Center(
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))),
            ),
        ],
      ),
    );
  }

  // 템플릿 가로 스트립 + 커스텀 업로드 타일
  Widget _buildTemplateStrip() {
    return SizedBox(
      height: 78,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 커스텀 사진 업로드 타일
          GestureDetector(
            onTap: _uploadingCover ? null : _pickCustomCover,
            child: Container(
              width: 62,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _customCoverUrl != null ? SaColors.accentTeal : SaColors.borderStrong,
                  width: _customCoverUrl != null ? 2 : 1,
                ),
                color: SaColors.surface,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(PhosphorIconsFill.camera, size: 18, color: SaColors.textSecondary),
                  const SizedBox(height: 4),
                  Text('내 사진', style: SaText.mono(fontSize: 8.5)),
                ],
              ),
            ),
          ),
          for (final t in kCoverTemplates)
            GestureDetector(
              onTap: () => _selectTemplate(t.id),
              child: Container(
                width: 62,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _coverTemplateId == t.id ? SaColors.accentTeal : SaColors.borderStrong,
                    width: _coverTemplateId == t.id ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: coverImageUrl(t.imageUrl, width: 200),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(color: SaColors.surfaceElevated),
                      errorWidget: (_, __, ___) => ColoredBox(color: SaColors.surfaceElevated),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        color: Colors.black.withOpacity(0.55),
                        child: Text(t.label,
                            textAlign: TextAlign.center,
                            style: SaText.caption.copyWith(fontSize: 9.5, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController ctrl, {required String hint, required int maxLines}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: SaText.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: SaText.body.copyWith(fontSize: 13, color: SaColors.textTertiary),
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
    );
  }

  Widget _buildOptions() {
    return Container(
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _segmentRow(
            label: '공개 범위',
            options: const [('공개', true), ('비공개', false)],
            selected: _isPublic,
            onSelect: (v) => setState(() => _isPublic = v as bool),
            hint: _isPublic ? '누구나 검색해서 참여할 수 있어요' : '초대받은 사람만 볼 수 있어요',
          ),
          const SizedBox(height: 12),
          _segmentRow(
            label: '가입 방식',
            options: const [('바로 참여', 'AUTO'), ('승인제', 'APPROVAL')],
            selected: _joinType,
            onSelect: (v) => setState(() => _joinType = v as String),
            hint: _joinType == 'AUTO' ? '신청 즉시 멤버가 돼요' : '방장/매니저 승인 후 참여돼요',
          ),
        ],
      ),
    );
  }

  Widget _segmentRow({
    required String label,
    required List<(String, Object)> options,
    required Object selected,
    required ValueChanged<Object> onSelect,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: SaText.bodyMedium.copyWith(fontSize: 13.5))),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: SaColors.bgBase,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: SaColors.borderStrong),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (text, value) in options)
                    GestureDetector(
                      onTap: () => onSelect(value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected == value ? SaColors.accentTeal : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          text,
                          style: SaText.caption.copyWith(
                            fontSize: 11.5,
                            color: selected == value ? SaColors.onAccent : SaColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(hint, style: SaText.mono(fontSize: 9.5)),
      ],
    );
  }

  Widget _buildSpotSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _spotSearchCtrl,
          onChanged: _onSpotSearchChanged,
          style: SaText.bodyMedium,
          decoration: InputDecoration(
            hintText: '장소·명소 검색 (예: 남산타워)',
            hintStyle: SaText.body.copyWith(fontSize: 13, color: SaColors.textTertiary),
            prefixIcon: Padding(
              padding: EdgeInsets.all(12),
              child: PhosphorIcon(PhosphorIconsFill.mapPin, size: 15, color: SaColors.textSecondary),
            ),
            suffixIcon: _spotSearching
                ? Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal)),
                  )
                : null,
            filled: true,
            fillColor: SaColors.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
        if (_spotResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: SaColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: SaColors.borderStrong),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _spotResults.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: SaColors.border),
              itemBuilder: (context, i) {
                final doc = _spotResults[i];
                return ListTile(
                  dense: true,
                  title: Text(doc['place_name']?.toString() ?? '',
                      style: SaText.bodyMedium.copyWith(fontSize: 13)),
                  subtitle: Text(doc['address_name']?.toString() ?? '',
                      style: SaText.body.copyWith(fontSize: 11)),
                  onTap: () => _selectSpot(doc),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedSpot() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaColors.accentTeal.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsFill.mapPin, size: 15, color: SaColors.accentTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_spotName ?? '선택된 장소',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: SaText.bodyMedium.copyWith(fontSize: 13.5)),
          ),
          GestureDetector(
            onTap: _clearSpot,
            child: PhosphorIcon(PhosphorIconsBold.x, size: 14, color: SaColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
