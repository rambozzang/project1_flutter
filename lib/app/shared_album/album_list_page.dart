import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/community/widget/cover_template.dart' show albumCoverCacheUrl;
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/widget/sa_album_card.dart';
import 'package:project1/app/shared_album/widget/sa_album_mosaic_card.dart';
import 'package:project1/app/shared_album/widget/sa_gradient_button.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 받은 초대(구 허브 기능 보존) — 수락/거절 진행 중 표시
  List<CommunityData> _invites = [];
  final Set<int> _inviteBusy = {};

  @override
  void initState() {
    super.initState();
    // 저장된 앨범 테마 복원 + 설정에서 바꾸면 즉시 반영(탭에 살아있는 페이지라 직접 구독)
    SaColors.loadSavedMode();
    SaColors.themeTick.addListener(_onThemeChanged);
    _restoreViewMode();
    _load();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SaColors.themeTick.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _restoreViewMode() async {
    // SharedPreferences 사용 — 이전엔 secure storage였는데 로그아웃 시 AuthCntr.removeAll()이
    // deleteAll()로 전체를 지워 보기 방식도 함께 초기화됐다. UI 취향값이라 일반 저장소가 맞다.
    final prefs = await SharedPreferences.getInstance();
    String? v = prefs.getString(_kViewModeKey);
    if (v == null) {
      // 기존 사용자 마이그레이션: 예전 secure storage 값이 남아있으면 1회 이관.
      v = await _storage.read(key: _kViewModeKey);
      if (v != null) await prefs.setString(_kViewModeKey, v);
    }
    if (mounted && v == 'mosaic') setState(() => _mosaic = true);
  }

  void _toggleViewMode() {
    setState(() => _mosaic = !_mosaic);
    SharedPreferences.getInstance()
        .then((p) => p.setString(_kViewModeKey, _mosaic ? 'mosaic' : 'stack'));
  }

  Future<void> _createAlbum() async {
    final result = await Get.toNamed('/AlbumCreatePage');
    if (!mounted) return;
    if (result is! Map) {
      if (result == true) await _reload();
      return;
    }

    final id = int.tryParse(result['communityId']?.toString() ?? '');
    if (id == null) {
      await _reload();
      return;
    }

    // 생성 직후 목록에서 다시 찾게 하지 않고, 새 앨범으로 곧바로 이어준다.
    var community = await _repo.getDetail(id);
    // 생성 직후 상세 조회 반영이 아주 잠깐 늦는 환경을 한 번 흡수한다.
    if (community == null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      community = await _repo.getDetail(id);
    }
    if (!mounted) return;
    if (community == null) {
      await _reload();
      return;
    }
    await Get.toNamed(
      '/AlbumShellPage',
      arguments: {
        'communityId': id,
        'community': community,
      },
    );
    if (mounted) await _reload();
  }

  Future<void> _load() async {
    try {
      // 받은 초대는 실패해도 홈 로딩을 막지 않도록 별도 처리
      _repo.getMyInvites().then((list) {
        if (mounted) setState(() => _invites = list);
      }).catchError((_) {});
      final communities = await _repo.getMyCommunities();
      final cards = communities.map((c) {
        final card = SaAlbumCardData(community: c);
        // 백엔드가 계산해주는 영상+사진 합계(0이면 칩 숨김 유지)
        if (c.mediaCnt > 0) card.mediaCount = c.mediaCnt;
        // NEW 뱃지: 마지막 열람 이후 남이 올린 미디어 수(0이면 자동 숨김)
        card.newCount = c.newCnt;
        // 아바타·최근 업데이트는 목록 응답(getMyCommunities)에 이미 포함 → 첫 렌더부터 바로 표시.
        if (c.avatars.isNotEmpty) card.avatars = c.avatars.take(3).toList();
        if (c.lastMediaDtm != null && c.lastMediaDtm!.isNotEmpty) {
          card.lastUpdated = Utils.timeage(c.lastMediaDtm!);
        }
        return card;
      }).toList();
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
      });
      // 카드별 부가 데이터(썸네일 3장·멤버 아바타·최근 업데이트)는 병렬로 지연 로드.
      // 4개씩 나눠 처리 — 앨범이 많을 때 요청이 몰려(연결 경합) 전체가 느려지는 것을 막는다.
      // 첫 화면은 앨범 대문 이미지(imageUrl)로 먼저 렌더링되고, 모든 카드의 썸네일 로드가
      // 끝난 뒤 한꺼번에 교체해 리스트 렌더링을 빠르게 한다.
      const int batch = 4;
      for (int i = 0; i < cards.length; i += batch) {
        await Future.wait(cards.skip(i).take(batch).map(_fillCard));
      }
      // 모든 썸네일 로드가 끝난 뒤 한꺼번에 thumbs에 반영.
      for (final card in cards) {
        card.thumbs = card.loadedThumbs;
      }
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
    // 아바타·최근 업데이트는 목록 응답(getMyCommunities)에 이미 포함되어 _load에서 세팅됨 →
    // 개별 getMembers 콜 완전 제거. 표지 모드(대표 미디어 미지정)는 앨범 표지(imageUrl)만 쓰므로
    // 추가 미디어 조회도 불필요 → 대부분의 카드는 네트워크 콜 0.
    final List<int> coverIds = card.community.coverMediaIds;
    if (coverIds.isEmpty) {
      card.loadedThumbs = [];
      return;
    }
    try {
      // 대표 미디어 montage 모드만 실제 미디어를 조회해 지정 순서대로 썸네일을 구성한다.
      final feedRes = await _repo.getFeedRes(id, 0, 30) as dynamic;
      if (feedRes.code == '00' && feedRes.data is List) {
        final items = (feedRes.data as List).map((e) => BoardWeatherListData.fromMap(e)).toList();
        final byId = {for (final it in items) it.boardId: it};
        final picked = coverIds.map((cid) => byId[cid]).whereType<BoardWeatherListData>().toList();
        // 지정 미디어 우선 + 부족분은 최근 미디어로 채움
        final ordered = [...picked, ...items.where((it) => !coverIds.contains(it.boardId))];
        card.loadedThumbs = ordered
            .map((e) => e.thumbnailPath ?? '')
            .where((p) => p.isNotEmpty)
            .take(3)
            .toList();
        // 목록 응답에서 최근 시각을 못 받은 경우에만 보정
        if ((card.community.lastMediaDtm == null || card.community.lastMediaDtm!.isEmpty) &&
            items.isNotEmpty &&
            items.first.crtDtm != null) {
          card.lastUpdated = Utils.timeage(items.first.crtDtm!);
        }
      }
    } catch (e) {
      lo.g('앨범($id) 카드 데이터 로드 실패: $e');
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
          bottom: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (_invites.isNotEmpty) _buildInvitesSection(),
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
          // 앨범 탐색(공개 앨범 검색 + 코드로 참여)
          _circleButton(
            icon: PhosphorIconsBold.magnifyingGlass,
            tooltip: '앨범 찾기 또는 참여',
            onTap: () => Get.toNamed('/AlbumExplorePage')?.then((joined) {
              if (joined == true) _reload();
            }),
          ),
          const SizedBox(width: 8),
          // 보기 방식 토글: 1a 스택 피드 ↔ 1c 모자이크 그리드
          _circleButton(
            icon: _mosaic ? PhosphorIconsBold.rows : PhosphorIconsBold.squaresFour,
            tooltip: _mosaic ? '목록으로 보기' : '모자이크로 보기',
            onTap: _toggleViewMode,
          ),
          const SizedBox(width: 8),
          // 앨범 만들기(teal 그라디언트 원형)
          Tooltip(
            message: '새 앨범 만들기',
            child: Semantics(
              button: true,
              label: '새 앨범 만들기',
              child: GestureDetector(
                onTap: _createAlbum,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(gradient: SaColors.primaryGradient, shape: BoxShape.circle),
                  child: PhosphorIcon(PhosphorIconsBold.plus, size: 17, color: SaColors.onAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
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
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal),
      );
    }
    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(PhosphorIconsFill.images, size: 44, color: SaColors.textTertiary),
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
              onTap: _createAlbum,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 152),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 152),
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
    // 앨범 메인 = 셸(하단 메뉴바). community를 함께 넘겨 즉시 렌더(스피너 최소화).
    Get.toNamed('/AlbumShellPage',
        arguments: {'communityId': card.community.communityId, 'community': card.community})?.then((r) {
      // 상세에서 삭제·나가기 등 변경(result==true)이 있을 때만 목록 새로고침.
      // 일반 뒤로가기는 리스트를 그대로 유지(불필요한 리프레시·스크롤 초기화 방지).
      if (r == true) _reload();
    });
  }

  // ── 받은 초대(구 허브 기능 보존) ──────────────────────────

  Future<void> _acceptInvite(CommunityData c) async {
    if (_inviteBusy.contains(c.communityId)) return;
    setState(() => _inviteBusy.add(c.communityId));
    final (ok, msg) = await _repo.acceptInvite(c.communityId);
    if (!mounted) return;
    setState(() => _inviteBusy.remove(c.communityId));
    BotToast.showText(text: ok ? '[${c.name}] 앨범에 참여했어요!' : (msg.isEmpty ? '수락에 실패했습니다.' : msg));
    if (ok) _reload();
  }

  Future<void> _declineInvite(CommunityData c) async {
    if (_inviteBusy.contains(c.communityId)) return;
    setState(() => _inviteBusy.add(c.communityId));
    final (ok, msg) = await _repo.declineInvite(c.communityId);
    if (!mounted) return;
    setState(() {
      _inviteBusy.remove(c.communityId);
      if (ok) _invites.removeWhere((e) => e.communityId == c.communityId);
    });
    if (!ok) BotToast.showText(text: msg.isEmpty ? '거절에 실패했습니다.' : msg);
  }

  Widget _buildInvitesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(PhosphorIconsFill.envelopeSimple, size: 13, color: SaColors.warn),
              const SizedBox(width: 6),
              Text('받은 초대', style: SaText.caption.copyWith(color: SaColors.warn)),
              const SizedBox(width: 6),
              Text('${_invites.length}', style: SaText.mono(fontSize: 10, color: SaColors.warn)),
            ],
          ),
          const SizedBox(height: 8),
          for (final c in _invites) _inviteRow(c),
        ],
      ),
    );
  }

  Widget _inviteRow(CommunityData c) {
    final bool busy = _inviteBusy.contains(c.communityId);
    // 제목이 비어 오는 경우에도 최소한 식별되도록 폴백.
    final String title = c.name.trim().isEmpty ? '이름 없는 앨범' : c.name;
    final String? dateText = _inviteDateText(c.crtDtm);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaColors.warn.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          // 앨범 표지 썸네일 — 어떤 앨범인지 시각적으로 식별.
          _inviteThumb(c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 앨범 제목 — 어떤 앨범의 초대인지 한눈에.
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: SaText.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('멤버 ${c.memberCnt}${dateText != null ? ' · $dateText' : ''}',
                    style: SaText.mono(fontSize: 9.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))
          else ...[
            GestureDetector(
              onTap: () => _acceptInvite(c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: SaColors.accentTeal, borderRadius: BorderRadius.circular(999)),
                child: Text('수락',
                    style: SaText.caption.copyWith(fontSize: 11.5, color: SaColors.onAccent, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _declineInvite(c),
              child: Text('거절', style: SaText.caption.copyWith(fontSize: 11.5, color: SaColors.textTertiary)),
            ),
          ],
        ],
      ),
    );
  }

  // 앨범 생성일자 — 'yyyy.MM.dd'. 빈값/형식 미달이면 null(표시 생략).
  String? _inviteDateText(String? dtm) {
    if (dtm == null || dtm.length < 10) return null;
    return dtm.substring(0, 10).replaceAll('-', '.');
  }

  // 앨범 표지 썸네일(없으면 이름 첫 글자 그라디언트).
  Widget _inviteThumb(CommunityData c) {
    const double size = 42;
    final radius = BorderRadius.circular(12);
    final coverUrl = c.coverDisplayUrl;
    if (coverUrl != null) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: albumCoverCacheUrl(coverUrl),
          memCacheWidth: 160,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _inviteThumbFallback(c, size, radius),
        ),
      );
    }
    return _inviteThumbFallback(c, size, radius);
  }

  Widget _inviteThumbFallback(CommunityData c, double size, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(borderRadius: radius, gradient: SaColors.primaryGradient),
      alignment: Alignment.center,
      child: Text(c.name.trim().isNotEmpty ? c.name.characters.first : '?',
          style: SaText.titleS.copyWith(color: SaColors.onAccent)),
    );
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await _load();
  }
}
