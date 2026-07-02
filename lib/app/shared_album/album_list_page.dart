import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/widget/sa_album_card.dart';
import 'package:project1/app/shared_album/widget/sa_album_mosaic_card.dart';
import 'package:project1/app/shared_album/widget/sa_gradient_button.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 공유앨범 홈 — 1a 스택 피드.
/// 내가 속한 앨범을 큰 카드 리스트로 보여준다. 카드 상단 겹침 스택은 앨범 최근 미디어
/// 썸네일 3장, 스탯 행은 멤버 아바타/수/최근 업데이트.
/// 데이터: 기존 /community/my + 앨범별 feed(3건)·members 병렬 조회로 조립.
/// (총 미디어 수·NEW 수는 백엔드 확장 후 연결 — 현재 칩/뱃지 자동 숨김)
class AlbumListPage extends StatefulWidget {
  const AlbumListPage({super.key});

  @override
  State<AlbumListPage> createState() => _AlbumListPageState();
}

class _AlbumListPageState extends State<AlbumListPage> {
  final CommunityRepo _repo = CommunityRepo();

  // 보기 방식(1a 스택 피드 ↔ 1c 모자이크 그리드) — 마지막 선택 유지
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const String _kViewModeKey = 'SA_HOME_VIEW_MODE';
  bool _mosaic = false;

  bool _loading = true;
  List<SaAlbumCardData> _cards = [];

  @override
  void initState() {
    super.initState();
    _restoreViewMode();
    _load();
  }

  Future<void> _restoreViewMode() async {
    final v = await _storage.read(key: _kViewModeKey);
    if (mounted && v == 'mosaic') setState(() => _mosaic = true);
  }

  void _toggleViewMode() {
    setState(() => _mosaic = !_mosaic);
    _storage.write(key: _kViewModeKey, value: _mosaic ? 'mosaic' : 'stack');
  }

  Future<void> _load() async {
    try {
      final communities = await _repo.getMyCommunities();
      final cards = communities.map((c) {
        final card = SaAlbumCardData(community: c);
        // 백엔드가 계산해주는 영상+사진 합계(0이면 칩 숨김 유지)
        if (c.mediaCnt > 0) card.mediaCount = c.mediaCnt;
        // NEW 뱃지: 마지막 열람 이후 남이 올린 미디어 수(0이면 자동 숨김)
        card.newCount = c.newCnt;
        return card;
      }).toList();
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
      });
      // 카드별 부가 데이터(썸네일 3장·멤버 아바타·최근 업데이트)는 병렬로 지연 로드.
      await Future.wait(cards.map(_fillCard));
      if (mounted) setState(() {});
    } catch (e) {
      lo.g('앨범 목록 조회 실패: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      Utils.alert('앨범 목록을 불러오지 못했습니다.');
    }
  }

  Future<void> _fillCard(SaAlbumCardData card) async {
    final int id = card.community.communityId;
    try {
      final results = await Future.wait([
        _repo.getFeedRes(id, 0, 3),
        _repo.getMembers(id),
      ]);
      final feedRes = results[0] as dynamic;
      if (feedRes.code == '00' && feedRes.data is List) {
        final items = (feedRes.data as List).map((e) => BoardWeatherListData.fromMap(e)).toList();
        card.thumbs = items
            .map((e) => e.thumbnailPath ?? '')
            .where((p) => p.isNotEmpty)
            .take(3)
            .toList();
        if (items.isNotEmpty && items.first.crtDtm != null) {
          card.lastUpdated = Utils.timeage(items.first.crtDtm!);
        }
      }
      final members = results[1] as List;
      card.avatars = members
          .map((m) => (m as dynamic).profilePath?.toString() ?? '')
          .where((p) => p.isNotEmpty)
          .take(3)
          .toList()
          .cast<String>();
    } catch (e) {
      lo.g('앨범($id) 카드 데이터 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SaColors.bgBase,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('우리의 앨범', style: SaText.titleL),
                const SizedBox(height: 2),
                Text('${_cards.length} ALBUMS', style: SaText.mono(fontSize: 11, color: SaColors.accentTeal)),
              ],
            ),
          ),
          _circleButton(
            icon: PhosphorIconsBold.magnifyingGlass,
            onTap: () => BotToast.showText(text: '앨범 검색은 다음 단계에서 연결됩니다.'),
          ),
          const SizedBox(width: 10),
          // 보기 방식 토글: 1a 스택 피드 ↔ 1c 모자이크 그리드
          _circleButton(
            icon: _mosaic ? PhosphorIconsBold.rows : PhosphorIconsBold.squaresFour,
            onTap: _toggleViewMode,
          ),
          const SizedBox(width: 10),
          SaGradientButton(
            label: '만들기',
            icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 14, color: SaColors.onAccent),
            onTap: () => Get.toNamed('/CommunityCreatePage')?.then((_) => _reload()),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SaColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: SaColors.borderStrong),
        ),
        child: PhosphorIcon(icon, size: 17, color: SaColors.textPrimary),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal),
      );
    }
    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhosphorIcon(PhosphorIconsFill.images, size: 44, color: SaColors.textTertiary),
            const SizedBox(height: 14),
            Text('아직 함께 모으는 앨범이 없어요', style: SaText.titleS),
            const SizedBox(height: 6),
            Text('앨범을 만들어 친구를 초대하고\n하늘 순간들을 같이 모아보세요.',
                textAlign: TextAlign.center, style: SaText.body.copyWith(fontSize: 13)),
            const SizedBox(height: 20),
            SaGradientButton(
              label: '첫 앨범 만들기',
              height: 46,
              glow: true,
              onTap: () => Get.toNamed('/CommunityCreatePage')?.then((_) => _reload()),
            ),
            const SizedBox(height: 60),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: SaColors.accentTeal,
      backgroundColor: SaColors.surface,
      onRefresh: _reload,
      child: _mosaic ? _buildMosaicGrid() : _buildStackFeed(),
    );
  }

  // 1a — 스택 피드(기본)
  Widget _buildStackFeed() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return SaAlbumCard(
          data: card,
          onTap: () => _openDetail(card),
        );
      },
    );
  }

  // 1c — 모자이크 그리드(밀도 높음, 앨범 많은 사용자용)
  Widget _buildMosaicGrid() {
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        // tall/short 교차로 스태거드 리듬 형성 (0,3,4,7... = tall)
        final bool tall = index % 4 == 0 || index % 4 == 3;
        return SaAlbumMosaicCard(
          data: card,
          tall: tall,
          onTap: () => _openDetail(card),
        );
      },
    );
  }

  void _openDetail(SaAlbumCardData card) {
    Get.toNamed('/AlbumDetailPage',
        arguments: {'communityId': card.community.communityId})?.then((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await _load();
  }
}
