import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/widget/sa_gradient_button.dart';
import 'package:project1/app/shared_album/widget/sa_member_avatar_stack.dart';
import 'package:project1/app/shared_album/widget/sa_new_badge.dart';
import 'package:project1/app/shared_album/widget/sa_overlap_image_stack.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 앨범 상세 — 1d 갤러리 뷰.
/// 커버 스트립(미니 겹침스택+멤버/스탯) + 필터 칩(전체/영상 N/사진 N) + 뷰 전환 세그먼트
/// + 3열 미디어 그리드(무한 스크롤) + '＋ 올리기' FAB.
/// 몰입 뷰(1e) 구현 전까지 세그먼트/셀 탭은 기존 COMMUNITY 풀스크린 피드로 연결.
class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

enum _MediaFilter { all, video, photo }

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final CommunityRepo _repo = CommunityRepo();
  final ScrollController _scroll = ScrollController();

  late final int _communityId;
  CommunityData? _community;
  List<String> _memberAvatars = [];

  /// 진입 시점의 마지막 열람 시각 — 셀 pink 점(안 본 것) 판단 기준.
  /// detail 조회로 이전 값을 확보한 뒤 markSeen으로 갱신하므로 이번 세션 동안 점이 유지된다.
  DateTime? _lastSeen;

  final List<BoardWeatherListData> _items = [];
  static const int _pageSize = 30;
  int _pageNum = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  _MediaFilter _filter = _MediaFilter.all;

  bool get _canPost {
    final c = _community;
    return c != null && (c.isJoined || c.isOwner);
  }

  List<BoardWeatherListData> get _visibleItems {
    switch (_filter) {
      case _MediaFilter.video:
        return _items.where((e) => e.typeDtCd == 'V').toList();
      case _MediaFilter.photo:
        return _items.where((e) => e.typeDtCd == 'I').toList();
      case _MediaFilter.all:
        return _items;
    }
  }

  @override
  void initState() {
    super.initState();
    _communityId = (Get.arguments?['communityId'] as num?)?.toInt() ?? 0;
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
      _loadFeed();
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.getDetail(_communityId),
        _repo.getMembers(_communityId),
      ]);
      _community = results[0] as CommunityData?;
      // pink 점 기준: 갱신 전의 마지막 열람 시각 확보 → 이후 열람 처리로 갱신
      _lastSeen = DateTime.tryParse(_community?.lastSeenDtm ?? '');
      _repo.markSeen(_communityId); // fire-and-forget — 홈 복귀 시 NEW 뱃지 해소
      final members = results[1] as List;
      _memberAvatars = members
          .map((m) => (m as dynamic).profilePath?.toString() ?? '')
          .where((p) => p.isNotEmpty)
          .take(3)
          .toList()
          .cast<String>();
      await _loadFeed(reset: true);
    } catch (e) {
      lo.g('앨범 상세 조회 실패: $e');
      Utils.alert('앨범 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFeed({bool reset = false}) async {
    if (reset) {
      _pageNum = 0;
      _hasMore = true;
      _items.clear();
    }
    if (!_hasMore) return;
    _loadingMore = true;
    try {
      final res = await _repo.getFeedRes(_communityId, _pageNum, _pageSize);
      if (res.code == '00' && res.data is List) {
        final list = (res.data as List).map((e) => BoardWeatherListData.fromMap(e)).toList();
        _items.addAll(list);
        _hasMore = list.length >= _pageSize;
        _pageNum++;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      lo.g('앨범 피드 조회 실패: $e');
      _hasMore = false;
    } finally {
      _loadingMore = false;
      if (mounted) setState(() {});
    }
  }

  /// 몰입 뷰(1e)로 진입 — 현재 필터 기준 목록과 시작 인덱스를 넘긴다.
  /// 아이템 객체를 공유하므로 몰입 뷰에서 바뀐 좋아요 상태가 복귀 시 그대로 반영된다.
  void _openImmersive({int initialIndex = 0}) {
    if (_visibleItems.isEmpty) return;
    Get.toNamed('/AlbumImmersivePage', arguments: {
      'communityId': _communityId,
      'albumName': _community?.name ?? '앨범',
      'items': _visibleItems,
      'initialIndex': initialIndex,
    })?.then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openCamera() async {
    // 카메라 진입 전 대상 앨범 지정 → 촬영 후 등록 시 이 앨범 소속으로 저장
    RootCntr.to.pendingCommunityId = _communityId;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraAwesomePage()));
    RootCntr.to.pendingCommunityId = null;
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      _loadFeed(reset: true);
    }
  }

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _sheetItem(PhosphorIconsFill.users, '멤버 보기', () {
              Get.back();
              Get.toNamed('/CommunityMembersPage', arguments: {'communityId': _communityId});
            }),
            if (_canPost)
              _sheetItem(PhosphorIconsBold.userPlus, '멤버 초대', () {
                Get.back();
                Get.toNamed('/CommunityInvitePage', arguments: {'communityId': _communityId})
                    ?.then((_) => _load());
              }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: PhosphorIcon(icon, size: 20, color: SaColors.textPrimary),
      title: Text(label, style: SaText.bodyMedium),
      onTap: onTap,
    );
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _canPost
            ? SaGradientButton(
                label: '＋ 올리기',
                height: 50,
                glow: true,
                onTap: _openCamera,
              )
            : null,
        body: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))
              : Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: RefreshIndicator(
                        color: SaColors.accentTeal,
                        backgroundColor: SaColors.surface,
                        onRefresh: () => _loadFeed(reset: true),
                        child: CustomScrollView(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(child: _buildCoverStrip()),
                            SliverToBoxAdapter(child: _buildControlRow()),
                            _buildGrid(),
                            const SliverToBoxAdapter(child: SizedBox(height: 90)),
                          ],
                        ),
                      ),
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
          _circleButton(PhosphorIconsBold.caretLeft, () => Get.back()),
          Expanded(
            child: Center(
              child: Text(_community?.name ?? '앨범',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: SaText.titleS),
            ),
          ),
          _circleButton(PhosphorIconsBold.dotsThree, _showMoreSheet),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: SaColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: SaColors.borderStrong),
        ),
        child: PhosphorIcon(icon, size: 16, color: SaColors.textPrimary),
      ),
    );
  }

  // 커버 스트립: 미니 겹침스택 + 멤버/스탯 + mono 메타
  Widget _buildCoverStrip() {
    final c = _community;
    final thumbs = _items.map((e) => e.thumbnailPath ?? '').where((p) => p.isNotEmpty).take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: SaOverlapImageStack(
              height: 64,
              leadHeight: 60,
              leadUrl: thumbs.isNotEmpty ? thumbs[0] : c?.imageUrl,
              leftUrl: thumbs.length > 1 ? thumbs[1] : null,
              rightUrl: thumbs.length > 2 ? thumbs[2] : null,
              gradientKey: _gradientKey(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SaMemberAvatarStack(
                      avatarUrls: _memberAvatars,
                      extraCount: ((c?.memberCnt ?? 0) - _memberAvatars.length).clamp(0, 999),
                      size: 24,
                      overlap: 8,
                      ringColor: SaColors.bgBase,
                    ),
                    const SizedBox(width: 8),
                    Text('멤버 ${c?.memberCnt ?? 0}', style: SaText.caption),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'VIDEO ${c?.videoCnt ?? 0} · PHOTO ${c?.photoCnt ?? 0}${c?.crtDtm != null ? ' · ${Utils.timeage(c!.crtDtm!)}' : ''}',
                  style: SaText.mono(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _gradientKey() {
    const keys = ['rain', 'sunset', 'storm', 'night', 'aurora', 'golden', 'fog', 'snow'];
    return keys[_communityId % keys.length];
  }

  // 필터 칩(전체/영상 N/사진 N) + 뷰 전환 세그먼트(그리드|몰입)
  Widget _buildControlRow() {
    final c = _community;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          _filterChip('전체', _MediaFilter.all),
          const SizedBox(width: 6),
          _filterChip('영상 ${c?.videoCnt ?? 0}', _MediaFilter.video),
          const SizedBox(width: 6),
          _filterChip('사진 ${c?.photoCnt ?? 0}', _MediaFilter.photo),
          const Spacer(),
          _viewSegment(),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _MediaFilter value) {
    final bool active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? SaColors.accentTeal : SaColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? SaColors.accentTeal : SaColors.borderStrong),
        ),
        child: Text(
          label,
          style: SaText.caption.copyWith(
            fontSize: 12,
            color: active ? SaColors.onAccent : SaColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _viewSegment() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SaColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: SaColors.accentTeal,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const PhosphorIcon(PhosphorIconsFill.squaresFour, size: 13, color: SaColors.onAccent),
          ),
          GestureDetector(
            onTap: () => _openImmersive(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: PhosphorIcon(PhosphorIconsBold.frameCorners, size: 13, color: SaColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final items = _visibleItems;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              const PhosphorIcon(PhosphorIconsFill.images, size: 40, color: SaColors.textTertiary),
              const SizedBox(height: 12),
              Text(
                _canPost ? '아직 미디어가 없어요.\n첫 순간을 올려보세요!' : '아직 미디어가 없어요.',
                textAlign: TextAlign.center,
                style: SaText.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1 / 1.12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _gridCell(items[index], index),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _gridCell(BoardWeatherListData item, int index) {
    final bool isVideo = item.typeDtCd == 'V';
    return GestureDetector(
      onTap: () => _openImmersive(initialIndex: index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if ((item.thumbnailPath ?? '').isNotEmpty)
              CachedNetworkImage(
                imageUrl: item.thumbnailPath!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: SaColors.surfaceElevated),
                errorWidget: (_, __, ___) => const ColoredBox(color: SaColors.surfaceElevated),
              )
            else
              const ColoredBox(color: SaColors.surfaceElevated),
            Positioned(
              right: 6,
              bottom: 6,
              child: PhosphorIcon(
                isVideo ? PhosphorIconsFill.playCircle : PhosphorIconsFill.image,
                size: 15,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            // 안 본 콘텐츠 pink 점(마지막 열람 이후 올라온 것)
            if (_isNew(item)) const Positioned(left: 6, top: 6, child: SaNewDot(size: 7)),
          ],
        ),
      ),
    );
  }

  bool _isNew(BoardWeatherListData item) {
    if (_lastSeen == null) return false;
    final dt = DateTime.tryParse(item.crtDtm ?? '');
    return dt != null && dt.isAfter(_lastSeen!);
  }
}
