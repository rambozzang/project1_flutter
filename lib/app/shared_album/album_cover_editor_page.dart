import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/app/shared_album/widget/sa_album_card.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/utils/utils.dart';

/// 대문 편집(1f) — 홈 카드 실시간 미리보기 + 대표 미디어 순서/제목/소개/테마 컬러/표시 옵션.
/// 편집은 임시 상태로만 반영되다가 저장 시 일괄 커밋(취소 시 롤백 없음 = 서버 미변경).
class AlbumCoverEditorPage extends StatefulWidget {
  const AlbumCoverEditorPage({super.key});

  @override
  State<AlbumCoverEditorPage> createState() => _AlbumCoverEditorPageState();
}

class _AlbumCoverEditorPageState extends State<AlbumCoverEditorPage> {
  final CommunityRepo _repo = CommunityRepo();

  late final CommunityData _origin;
  late final List<BoardWeatherListData> _media;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String _themeColor = ''; // ''=자동(앨범 id 순환)
  List<int> _selectedIds = []; // 대표 미디어 boardId(탭 순서 = 겹침 순서, 최대 3)
  static const List<String> _optKeys = ['member', 'media', 'avatars', 'new'];
  static const Map<String, String> _optLabels = {
    'member': '회원 수',
    'media': '총 미디어 수',
    'avatars': '멤버 썸네일',
    'new': '새 콘텐츠 뱃지',
  };
  late Set<String> _opts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _origin = args['community'] as CommunityData;
    _media = (args['items'] as List<BoardWeatherListData>?) ?? [];
    _nameCtrl = TextEditingController(text: _origin.name);
    _descCtrl = TextEditingController(text: _origin.description ?? '');
    _themeColor = _origin.themeColor ?? '';
    _selectedIds = List.of(_origin.coverMediaIds);
    _opts = _origin.cardOptions != null ? Set.of(_origin.cardOptions!) : Set.of(_optKeys);
    _nameCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// 편집 상태가 반영된 미리보기용 카드 데이터
  SaAlbumCardData get _previewData {
    final edited = _origin.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? _origin.name : _nameCtrl.text.trim(),
      description: _descCtrl.text,
      themeColor: _themeColor, // ''이면 copyWith에서 유지되지 않도록 아래에서 처리
      coverMediaIds: _selectedIds,
      cardOptions: _opts.length == _optKeys.length ? null : _opts,
    );
    // themeColor ''(자동)은 null로 — copyWith가 ??라 별도 재생성 대신 showOpt/gradient에서 ''를 자동 취급하지 않으므로 여기서 보정
    final card = SaAlbumCardData(
        community: _themeColor.isEmpty && (_origin.themeColor ?? '').isNotEmpty
            ? edited.copyWith(themeColor: '')
            : edited);
    card.thumbs = _thumbsForPreview();
    if (edited.mediaCnt > 0) card.mediaCount = edited.mediaCnt;
    card.newCount = edited.newCnt;
    return card;
  }

  List<String> _thumbsForPreview() {
    final byId = {for (final it in _media) it.boardId: it};
    final picked = _selectedIds.map((id) => byId[id]).whereType<BoardWeatherListData>().toList();
    final rest = _media.where((it) => !_selectedIds.contains(it.boardId));
    return [...picked, ...rest]
        .map((e) => e.thumbnailPath ?? '')
        .where((p) => p.isNotEmpty)
        .take(3)
        .toList();
  }

  void _toggleMedia(BoardWeatherListData item) {
    final int? id = item.boardId;
    if (id == null) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 3) _selectedIds.removeAt(0); // 가장 먼저 고른 것부터 밀어냄
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final (ok, msg) = await _repo.updateFront(
        _origin.communityId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text,
        themeColor: _themeColor, // ''=자동(해제)
        coverMediaIds: _selectedIds.join(','),
        // 전체 선택이면 미설정(null=전체 표시)으로 저장
        cardOptions: _opts.length == _optKeys.length ? '' : _opts.join(','),
      );
      if (!ok) {
        Utils.alert(msg.isEmpty ? '저장에 실패했습니다.' : msg);
        return;
      }
      BotToast.showText(text: '대문이 저장되었습니다.');
      Get.back(result: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: [
                    _sectionLabel('PREVIEW'),
                    // teal 링 강조 + 미리보기는 조작 차단
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: SaColors.accentTeal.withOpacity(0.6), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: IgnorePointer(child: SaAlbumCard(data: _previewData, onTap: () {})),
                    ),
                    const SizedBox(height: 22),
                    _sectionLabel('대표 이미지 · 겹침 순서'),
                    _buildMediaStrip(),
                    const SizedBox(height: 22),
                    _sectionLabel('제목'),
                    _buildInput(_nameCtrl, hint: '앨범 이름', maxLines: 1),
                    const SizedBox(height: 14),
                    _sectionLabel('소개'),
                    _buildInput(_descCtrl, hint: '앨범을 소개해보세요', maxLines: 3),
                    const SizedBox(height: 22),
                    _sectionLabel('테마 컬러'),
                    _buildThemeSwatches(),
                    const SizedBox(height: 22),
                    _sectionLabel('카드에 표시할 정보'),
                    _buildOptionSwitches(),
                    const SizedBox(height: 22),
                    _buildMembersRow(),
                  ],
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
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('취소', style: SaText.bodyMedium.copyWith(color: SaColors.textSecondary)),
          ),
          Expanded(child: Center(child: Text('대문 편집', style: SaText.titleS))),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))
                : Text('저장', style: SaText.bodyMedium.copyWith(color: SaColors.accentTeal, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(text, style: SaText.mono(fontSize: 11, color: SaColors.accentTeal)),
    );
  }

  // 앨범 미디어 가로 스트립 — 탭 순서가 겹침 순서(1/2/3), 재탭 시 해제
  Widget _buildMediaStrip() {
    if (_media.isEmpty) {
      return Text('아직 미디어가 없어 대표 이미지를 고를 수 없어요.', style: SaText.body.copyWith(fontSize: 12.5));
    }
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _media.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _media[index];
          final int order = item.boardId == null ? -1 : _selectedIds.indexOf(item.boardId!);
          final bool selected = order >= 0;
          return GestureDetector(
            onTap: () => _toggleMedia(item),
            child: Stack(
              children: [
                Container(
                  width: 68,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? SaColors.accentTeal : SaColors.borderStrong,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (item.thumbnailPath ?? '').isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.thumbnailPath!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => ColoredBox(color: SaColors.surfaceElevated),
                          errorWidget: (_, __, ___) => ColoredBox(color: SaColors.surfaceElevated),
                        )
                      : ColoredBox(color: SaColors.surfaceElevated),
                ),
                if (selected)
                  Positioned(
                    left: 5,
                    top: 5,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: SaColors.accentTeal, shape: BoxShape.circle),
                      child: Text('${order + 1}',
                          style: SaText.mono(fontSize: 10, fontWeight: FontWeight.w800, color: SaColors.onAccent)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, {required String hint, required int maxLines}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: SaText.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }

  // 테마 스와치: '자동' + weather gradient 8종
  Widget _buildThemeSwatches() {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _swatch(key: '', label: '자동', gradient: null),
          for (final k in SaWeatherGradients.keys)
            _swatch(key: k, label: k, gradient: SaWeatherGradients.byKey[k]),
        ],
      ),
    );
  }

  Widget _swatch({required String key, required String label, LinearGradient? gradient}) {
    final bool selected = _themeColor == key;
    return GestureDetector(
      onTap: () => setState(() => _themeColor = key),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null ? SaColors.surfaceElevated : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? SaColors.accentTeal : SaColors.borderStrong,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: gradient == null
                  ? Icon(Icons.auto_awesome, size: 16, color: SaColors.textSecondary)
                  : null,
            ),
            const SizedBox(height: 5),
            Text(label, style: SaText.mono(fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSwitches() {
    return Container(
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _optKeys.length; i++) ...[
            if (i > 0) Divider(height: 1, color: SaColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(_optLabels[_optKeys[i]]!, style: SaText.bodyMedium.copyWith(fontSize: 13.5))),
                  Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      value: _opts.contains(_optKeys[i]),
                      activeTrackColor: SaColors.accentTeal,
                      onChanged: (v) => setState(() {
                        v ? _opts.add(_optKeys[i]) : _opts.remove(_optKeys[i]);
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersRow() {
    return Container(
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaColors.border),
      ),
      child: ListTile(
        leading: PhosphorIcon(PhosphorIconsFill.usersThree, size: 20, color: SaColors.textPrimary),
        title: Text('멤버 관리', style: SaText.bodyMedium.copyWith(fontSize: 13.5)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_origin.memberCnt}명', style: SaText.mono(fontSize: 11)),
            const SizedBox(width: 6),
            PhosphorIcon(PhosphorIconsBold.caretRight, size: 13, color: SaColors.textTertiary),
          ],
        ),
        onTap: () => Get.toNamed('/CommunityMembersPage', arguments: {'communityId': _origin.communityId}),
      ),
    );
  }
}
