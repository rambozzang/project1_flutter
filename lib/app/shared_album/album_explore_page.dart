import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/community/widget/cover_template.dart' show coverImageUrl;
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';

/// 앨범 탐색 — 공개 앨범 검색(추천=멤버 많은 순) + 초대 코드로 참여.
/// 구 라운지 허브의 검색/코드참여 기능을 다크 테마로 이관.
/// 가입(또는 신청)이 발생하면 pop(true)로 홈에 알려 목록을 갱신한다.
class AlbumExplorePage extends StatefulWidget {
  const AlbumExplorePage({super.key});

  @override
  State<AlbumExplorePage> createState() => _AlbumExplorePageState();
}

class _AlbumExplorePageState extends State<AlbumExplorePage> {
  final CommunityRepo _repo = CommunityRepo();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _debounce;
  bool _loading = true;
  bool _joinedAny = false; // 홈 갱신 필요 여부
  List<CommunityData> _results = [];
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String keyword) async {
    setState(() => _loading = true);
    final list = await _repo.search(keyword);
    if (!mounted) return;
    setState(() {
      _results = list;
      _loading = false;
    });
  }

  Future<void> _join(CommunityData c) async {
    if (_busy.contains(c.communityId)) return;
    setState(() => _busy.add(c.communityId));
    final (ok, msg, status) = await _repo.join(c.communityId);
    if (!mounted) return;
    setState(() => _busy.remove(c.communityId));
    if (ok) {
      _joinedAny = true;
      BotToast.showText(text: status == 'PENDING' ? '가입 신청을 보냈어요. 승인을 기다려주세요.' : '[${c.name}] 앨범에 참여했어요!');
      _search(_searchCtrl.text.trim()); // myStatus 갱신
    } else {
      BotToast.showText(text: msg.isEmpty ? '참여에 실패했습니다.' : msg);
    }
  }

  Future<void> _showJoinByCodeDialog() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('코드로 참여', style: SaText.titleS),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('전달받은 초대 코드를 입력하세요.', style: SaText.body.copyWith(fontSize: 12.5)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: SaText.mono(fontSize: 14, color: SaColors.textPrimary),
              decoration: InputDecoration(
                hintText: '예) A1B2C3',
                hintStyle: SaText.mono(fontSize: 13, color: SaColors.textTertiary),
                filled: true,
                fillColor: SaColors.bgBase,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SaColors.borderStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SaColors.accentTeal),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: SaText.caption.copyWith(color: SaColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text('참여', style: SaText.caption.copyWith(color: SaColors.accentTeal, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    final (ok, msg, community) = await _repo.joinByCode(code);
    if (!mounted) return;
    BotToast.showText(
        text: ok ? '[${community?.name ?? '앨범'}]에 참여했어요!' : (msg.isEmpty ? '코드 참여에 실패했습니다.' : msg));
    if (ok) {
      _joinedAny = true;
      _search(_searchCtrl.text.trim());
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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Get.back(result: _joinedAny);
        },
        child: Scaffold(
          backgroundColor: SaColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchField(),
                _buildJoinByCodeRow(),
                Expanded(child: _buildResults()),
              ],
            ),
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
            onTap: () => Get.back(result: _joinedAny),
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
          Text('앨범 탐색', style: SaText.titleS),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onQueryChanged,
        textInputAction: TextInputAction.search,
        style: SaText.bodyMedium,
        decoration: InputDecoration(
          hintText: '앨범 이름으로 검색 (비우면 인기순 추천)',
          hintStyle: SaText.body.copyWith(fontSize: 13, color: SaColors.textTertiary),
          prefixIcon: Padding(
            padding: EdgeInsets.all(12),
            child: PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 16, color: SaColors.textSecondary),
          ),
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
    );
  }

  Widget _buildJoinByCodeRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: GestureDetector(
        onTap: _showJoinByCodeDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: SaColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SaColors.border),
          ),
          child: Row(
            children: [
              PhosphorIcon(PhosphorIconsBold.keyhole, size: 15, color: SaColors.accentTeal),
              const SizedBox(width: 10),
              Text('초대 코드로 참여하기', style: SaText.bodyMedium.copyWith(fontSize: 13)),
              const Spacer(),
              PhosphorIcon(PhosphorIconsBold.caretRight, size: 13, color: SaColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal));
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 40, color: SaColors.textTertiary),
            const SizedBox(height: 12),
            Text('검색 결과가 없어요', style: SaText.titleS.copyWith(fontSize: 14.5)),
            const SizedBox(height: 4),
            Text('다른 이름으로 검색하거나\n초대 코드로 참여해보세요.',
                textAlign: TextAlign.center, style: SaText.body.copyWith(fontSize: 12.5)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      itemCount: _results.length,
      itemBuilder: (context, index) => _resultRow(_results[index]),
    );
  }

  Widget _resultRow(CommunityData c) {
    final bool busy = _busy.contains(c.communityId);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: SaWeatherGradients.of(_gradientKey(c)),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: (c.imageUrl ?? '').isNotEmpty
                ? Image.network(coverImageUrl(c.imageUrl!, width: 200), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: SaText.bodyMedium.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('멤버 ${c.memberCnt} · ${c.isApproval ? '승인제' : '바로 참여'}',
                    style: SaText.mono(fontSize: 9.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _joinButton(c, busy),
        ],
      ),
    );
  }

  Widget _joinButton(CommunityData c, bool busy) {
    if (busy) {
      return SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal));
    }
    if (c.isJoined) return Text('멤버', style: SaText.mono(fontSize: 10));
    if (c.isPending) return Text('신청됨', style: SaText.mono(fontSize: 10, color: SaColors.warn));
    return GestureDetector(
      onTap: () => _join(c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(color: SaColors.accentTeal, borderRadius: BorderRadius.circular(999)),
        child: Text(c.isApproval ? '신청' : '참여',
            style: SaText.caption.copyWith(fontSize: 11.5, color: SaColors.onAccent, fontWeight: FontWeight.w800)),
      ),
    );
  }

  String _gradientKey(CommunityData c) {
    if ((c.themeColor ?? '').isNotEmpty) return c.themeColor!;
    const keys = ['rain', 'sunset', 'storm', 'night', 'aurora', 'golden', 'fog', 'snow'];
    return keys[c.communityId % keys.length];
  }
}
