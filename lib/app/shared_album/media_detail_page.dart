import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/app/videocomment/comment_page.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/media/media_interaction_repo.dart';

/// 2b · 미디어 상세 — 미디어 + 촬영일시·날씨칩 + 캡션 + 이모지 반응 + 관람 이력 + 댓글.
/// v1: 영상은 탭 시 몰입뷰로 재생, 댓글은 기존 CommentPage(시트) 재사용.
class MediaDetailPage extends StatefulWidget {
  const MediaDetailPage({super.key});

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  final MediaInteractionRepo _repo = MediaInteractionRepo();

  late final BoardWeatherListData _item;
  late final int _communityId;
  late final String _albumName;
  List<BoardWeatherListData> _items = [];
  int _index = 0;

  Map<String, int> _counts = {};
  List<String> _mine = [];
  List<Map<String, dynamic>> _viewers = [];
  bool _loading = true;

  static const List<String> _emojiPalette = ['❤️', '😍', '👏', '🥹', '😂', '🔥'];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _item = args['item'] as BoardWeatherListData;
    _communityId = (args['communityId'] as num?)?.toInt() ?? 0;
    _albumName = args['albumName']?.toString() ?? '앨범';
    _items = (args['items'] as List<BoardWeatherListData>?) ?? [_item];
    _index = (args['index'] as num?)?.toInt() ?? 0;
    _repo.recordView(_item.boardId ?? 0); // 관람 기록(누가 봤나)
    _load();
  }

  Future<void> _load() async {
    final bid = _item.boardId ?? 0;
    final results = await Future.wait([_repo.reactions(bid), _repo.viewers(bid)]);
    if (!mounted) return;
    final r = results[0] as Map<String, dynamic>;
    setState(() {
      _counts = Map<String, int>.from((r['counts'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {});
      _mine = List<String>.from((r['mine'] as List?)?.map((e) => e.toString()) ?? []);
      _viewers = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  Future<void> _toggle(String emoji) async {
    // 낙관적 갱신
    setState(() {
      if (_mine.contains(emoji)) {
        _mine.remove(emoji);
        _counts[emoji] = ((_counts[emoji] ?? 1) - 1).clamp(0, 1 << 30);
        if (_counts[emoji] == 0) _counts.remove(emoji);
      } else {
        _mine.add(emoji);
        _counts[emoji] = (_counts[emoji] ?? 0) + 1;
      }
    });
    final res = await _repo.toggle(_item.boardId ?? 0, emoji);
    if (res != null && mounted) {
      setState(() {
        _counts = Map<String, int>.from((res['counts'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {});
        _mine = List<String>.from((res['mine'] as List?)?.map((e) => e.toString()) ?? []);
      });
    }
  }

  bool get _isVideo => _item.typeDtCd == 'V';

  String get _mainImage {
    if (_isVideo) {
      String t = _item.thumbnailPath ?? '';
      if (t.endsWith('thumbnail.gif')) t = t.replaceAll('thumbnail.gif', 'thumbnail.jpg');
      return t;
    }
    if (_item.imageUrls?.isNotEmpty ?? false) return _item.imageUrls!.first;
    return _item.thumbnailPath ?? '';
  }

  void _openImmersive() {
    Get.toNamed('/AlbumImmersivePage', arguments: {
      'communityId': _communityId,
      'albumName': _albumName,
      'items': _items,
      'initialIndex': _index,
    });
  }

  void _openComments() {
    // 전역과 동일한 다크 댓글 바텀시트 사용(앨범 라이트여도 댓글창은 기존 그대로).
    CommentPage().open(context, (_item.boardId ?? 0).toString());
  }

  String _capturedLabel() {
    final dt = DateTime.tryParse((_item.crtDtm ?? '').replaceFirst(' ', 'T'));
    if (dt == null) return '';
    const wd = ['월', '화', '수', '목', '금', '토', '일'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}월 ${dt.day}일 ${wd[dt.weekday - 1]} $h:$m';
  }

  String _weatherLine() {
    final parts = [
      if ((_item.location ?? _item.city ?? '').isNotEmpty) (_item.location ?? _item.city)!,
      if ((_item.weatherInfo ?? '').isNotEmpty) '${_item.weatherInfo!.split('.').first} ${_item.currentTemp ?? ''}°',
      if ((_item.humidity ?? '').isNotEmpty) '습도 ${_item.humidity}%',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    SaColors.syncWith(context);
    final pad = MediaQuery.of(context).viewPadding;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: SaColors.isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: SaColors.isLight ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SaColors.bgBase,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 20 + pad.bottom),
                children: [
                  _buildMedia(pad.top),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((_item.contents ?? '').isNotEmpty) ...[
                          Text(_item.contents!, style: SaText.body.copyWith(fontSize: 15, height: 1.6, color: SaColors.textPrimary)),
                          const SizedBox(height: 16),
                        ],
                        _buildReactionBar(),
                        const SizedBox(height: 16),
                        _buildViewedBy(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildCommentBar(pad.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(double topPad) {
    return SizedBox(
      height: 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_mainImage.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _mainImage,
              fit: BoxFit.cover,
              placeholder: (_, __) => DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of('night'))),
              errorWidget: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of('night'))),
            )
          else
            DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of('night'))),

          // 상/하 스크림
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent, Color(0x99000000)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 상단 미디어 어디를 눌러도 재생/열람(중앙 버튼 외 전체 영역)
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _openImmersive),
          ),

          // 영상 재생 버튼
          if (_isVideo)
            Center(
              child: GestureDetector(
                onTap: _openImmersive,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5))),
                  child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                ),
              ),
            ),

          // 상단 back
          Positioned(
            left: 14,
            top: topPad + 8,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                child: const PhosphorIcon(PhosphorIconsBold.caretLeft, size: 16, color: Colors.white),
              ),
            ),
          ),

          // 하단 업로더 + 촬영일시 + 날씨/위치
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: (_item.profilePath ?? '').isNotEmpty
                          ? CachedNetworkImage(imageUrl: _item.profilePath!, width: 30, height: 30, fit: BoxFit.cover)
                          : Container(width: 30, height: 30, color: Colors.white24, child: const Icon(Icons.person, size: 16, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Text(_item.nickNm ?? _item.custNm ?? '',
                        style: SaText.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(_capturedLabel(), style: SaText.mono(fontSize: 10, color: Colors.white70)),
                  ],
                ),
                if (_weatherLine().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PhosphorIcon(PhosphorIconsFill.mapPin, size: 11, color: Colors.white),
                        const SizedBox(width: 5),
                        Flexible(child: Text(_weatherLine(), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: SaText.mono(fontSize: 10, color: Colors.white))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final e in _counts.entries)
          GestureDetector(
            onTap: () => _toggle(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: _mine.contains(e.key) ? SaColors.accentTeal.withOpacity(0.16) : SaColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _mine.contains(e.key) ? SaColors.accentTeal : SaColors.border),
              ),
              child: Text('${e.key} ${e.value}', style: SaText.bodyMedium.copyWith(fontSize: 13)),
            ),
          ),
        // 반응 추가
        GestureDetector(
          onTap: _showEmojiPicker,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: SaColors.surface, shape: BoxShape.circle, border: Border.all(color: SaColors.border)),
            child: PhosphorIcon(PhosphorIconsBold.smiley, size: 17, color: SaColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              for (final e in _emojiPalette)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _toggle(e);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewedBy() {
    final int n = _viewers.length;
    return GestureDetector(
      onTap: n == 0 ? null : _showViewers,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SaColors.border),
        ),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsFill.eye, size: 18, color: SaColors.textSecondary),
            const SizedBox(width: 10),
            if (n > 0) _viewerAvatars(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(n == 0 ? '아직 아무도 안 봤어요' : '멤버 $n명이 봤어요',
                  style: SaText.bodyMedium.copyWith(fontSize: 13)),
            ),
            if (n > 0) PhosphorIcon(PhosphorIconsBold.caretRight, size: 14, color: SaColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _viewerAvatars() {
    final show = _viewers.take(4).toList();
    return SizedBox(
      width: 26.0 + (show.length - 1) * 18,
      height: 26,
      child: Stack(
        children: [
          for (int i = 0; i < show.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: SaColors.surface,
                    border: Border.all(color: SaColors.surface, width: 2)),
                child: ClipOval(
                  child: (show[i]['profilePath']?.toString() ?? '').isNotEmpty
                      ? CachedNetworkImage(imageUrl: show[i]['profilePath'].toString(), fit: BoxFit.cover)
                      : Container(color: SaColors.surfaceElevated, child: Icon(Icons.person, size: 13, color: SaColors.textTertiary)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showViewers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('본 사람 ${_viewers.length}', style: SaText.titleS)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final v in _viewers)
                    ListTile(
                      leading: ClipOval(
                        child: (v['profilePath']?.toString() ?? '').isNotEmpty
                            ? CachedNetworkImage(imageUrl: v['profilePath'].toString(), width: 40, height: 40, fit: BoxFit.cover)
                            : Container(width: 40, height: 40, color: SaColors.surfaceElevated, child: Icon(Icons.person, color: SaColors.textTertiary)),
                      ),
                      title: Text(v['nickNm']?.toString() ?? '', style: SaText.bodyMedium),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentBar(double bottomPad) {
    return GestureDetector(
      onTap: _openComments,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
        decoration: BoxDecoration(
          color: SaColors.surface,
          border: Border(top: BorderSide(color: SaColors.border)),
        ),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsFill.chatCircle, size: 18, color: SaColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (_item.replyCnt ?? 0) > 0 ? '댓글 ${_item.replyCnt}개 보기' : '따뜻한 댓글을 남겨보세요…',
                style: SaText.body.copyWith(fontSize: 13.5),
              ),
            ),
            PhosphorIcon(PhosphorIconsBold.caretRight, size: 14, color: SaColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
