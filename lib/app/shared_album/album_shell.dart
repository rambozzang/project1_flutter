import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/app/shared_album/activity_view.dart';
import 'package:project1/app/shared_album/album_timeline_page.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/widget/sa_gradient_button.dart';
import 'package:project1/app/shared_album/widget/sa_member_avatar_stack.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 앨범 진입 셸 — 하단 탭바(타임라인 · 회고 · ＋ · 활동 · 가족)로 개별 화면을 묶는다.
/// v1: 타임라인(2a) 완성 + 회고/활동 준비중 플레이스홀더 + 가족(멤버/초대 재사용).
class AlbumShellPage extends StatefulWidget {
  const AlbumShellPage({super.key});

  @override
  State<AlbumShellPage> createState() => _AlbumShellPageState();
}

class _AlbumShellPageState extends State<AlbumShellPage> {
  final CommunityRepo _repo = CommunityRepo();

  late final int _communityId;
  CommunityData? _community;
  List<String> _memberAvatars = [];
  DateTime? _lastSeen;

  final List<BoardWeatherListData> _items = [];
  static const int _pageSize = 30;
  int _pageNum = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _tab = 0; // 0 타임라인 / 1 회고 / 2 활동 / 3 가족

  bool get _canPost {
    final c = _community;
    return c != null && (c.isJoined || c.isOwner);
  }

  @override
  void initState() {
    super.initState();
    _communityId = (Get.arguments?['communityId'] as num?)?.toInt() ?? 0;
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.getDetail(_communityId),
        _repo.getMembers(_communityId),
      ]);
      _community = results[0] as CommunityData?;
      _lastSeen = DateTime.tryParse(_community?.lastSeenDtm ?? '');
      _repo.markSeen(_communityId); // 홈 복귀 시 NEW 뱃지 해소
      final members = results[1] as List;
      _memberAvatars = members
          .map((m) => (m as dynamic).profilePath?.toString() ?? '')
          .where((p) => p.isNotEmpty)
          .take(4)
          .toList()
          .cast<String>();
      await _loadFeed(reset: true);
    } catch (e) {
      lo.g('앨범 셸 조회 실패: $e');
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
    if (!_hasMore || _loadingMore) return;
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

  void _openMedia(int feedIndex) {
    // 타일 탭 → 2b 미디어 상세(댓글·반응·관람이력). 영상 재생은 상세에서 몰입뷰로 이어짐.
    Get.toNamed('/MediaDetailPage', arguments: {
      'item': _items[feedIndex],
      'items': _items,
      'index': feedIndex,
      'communityId': _communityId,
      'albumName': _community?.name ?? '앨범',
    })?.then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openUpload() async {
    if (!_canPost) {
      Utils.alert('앨범 멤버만 올릴 수 있어요.');
      return;
    }
    RootCntr.to.pendingCommunityId = _communityId;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraAwesomePage()));
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      _loadFeed(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    SaColors.syncWith(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: SaColors.isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: SaColors.isLight ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SaColors.bgBase,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: _loading
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))
              : Column(
                  children: [
                    _buildAppBar(),
                    Expanded(child: _buildTabBody()),
                  ],
                ),
        ),
        bottomNavigationBar: _loading ? null : _buildBottomBar(),
      ),
    );
  }

  Widget _buildAppBar() {
    final c = _community;
    final int mediaCnt = (c?.videoCnt ?? 0) + (c?.photoCnt ?? 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          _circle(PhosphorIconsBold.caretLeft, () => Get.back()),
          Expanded(
            child: Column(
              children: [
                Text(c?.name ?? '앨범',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: SaText.titleS),
                const SizedBox(height: 2),
                Text('${mediaCnt > 0 ? mediaCnt : _items.length} MEDIA · ${c?.memberCnt ?? 0}',
                    style: SaText.mono(fontSize: 10.5)),
              ],
            ),
          ),
          _circle(PhosphorIconsBold.magnifyingGlass, () {
            Utils.alert('검색은 곧 제공됩니다.');
          }),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_tab) {
      case 0:
        return AlbumTimelineView(
          items: _items,
          communityId: _communityId,
          lastSeen: _lastSeen,
          onTapItem: _openMedia,
          onLoadMore: () => _loadFeed(),
        );
      case 1:
        return _placeholder(PhosphorIconsFill.sparkle, '회고 영상', '모은 영상을 1초씩 이어붙인\n자동 회고를 준비하고 있어요.');
      case 2:
        return ActivityView(
          communityId: _communityId,
          onOpenBoard: (boardId) {
            final idx = _items.indexWhere((e) => e.boardId == boardId);
            if (idx >= 0) _openMedia(idx);
          },
        );
      case 3:
        return _buildFamily();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _placeholder(IconData icon, String title, String desc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 44, color: SaColors.accentTeal),
          const SizedBox(height: 14),
          Text(title, style: SaText.titleM.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: SaText.body),
        ],
      ),
    );
  }

  Widget _buildFamily() {
    final c = _community;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        Text('가족', style: SaText.titleL),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SaColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SaColors.border),
          ),
          child: Row(
            children: [
              if (_memberAvatars.isNotEmpty)
                SaMemberAvatarStack(
                  avatarUrls: _memberAvatars,
                  extraCount: ((c?.memberCnt ?? 0) - _memberAvatars.length).clamp(0, 999),
                ),
              const SizedBox(width: 12),
              Expanded(child: Text('멤버 ${c?.memberCnt ?? 0}명', style: SaText.bodyMedium)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _familyBtn(PhosphorIconsFill.users, '멤버 보기',
            () => Get.toNamed('/CommunityMembersPage', arguments: {'communityId': _communityId})),
        if (_canPost)
          _familyBtn(PhosphorIconsBold.userPlus, '멤버 초대', () {
            Get.toNamed('/AlbumInvitePage', arguments: {
              'communityId': _communityId,
              'albumName': c?.name ?? '앨범',
              'memberCnt': c?.memberCnt ?? 0,
              'isManager': c?.canEditCover == true,
            })?.then((_) => _load());
          }),
        if (c?.canEditCover == true)
          _familyBtn(PhosphorIconsFill.sparkle, '대문 편집', () {
            Get.toNamed('/AlbumCoverEditorPage', arguments: {'community': c, 'items': _items})
                ?.then((saved) {
              if (saved == true) _load();
            });
          }),
      ],
    );
  }

  Widget _familyBtn(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaColors.border),
      ),
      child: ListTile(
        leading: PhosphorIcon(icon, size: 20, color: SaColors.textPrimary),
        title: Text(label, style: SaText.bodyMedium),
        trailing: PhosphorIcon(PhosphorIconsBold.caretRight, size: 14, color: SaColors.textTertiary),
        onTap: onTap,
      ),
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) {
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

  Widget _buildBottomBar() {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomInset),
          height: 82 + bottomInset,
          decoration: BoxDecoration(
            color: SaColors.bgBase.withOpacity(0.92),
            border: Border(top: BorderSide(color: SaColors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _tabItem(0, PhosphorIconsFill.stack, PhosphorIconsBold.stack, '타임라인'),
              _tabItem(1, PhosphorIconsFill.sparkle, PhosphorIconsBold.sparkle, '회고'),
              _centerButton(),
              _tabItem(2, PhosphorIconsFill.bell, PhosphorIconsBold.bell, '활동'),
              _tabItem(3, PhosphorIconsFill.usersThree, PhosphorIconsBold.usersThree, '가족'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int index, IconData fill, IconData regular, String label) {
    final bool active = _tab == index;
    final Color color = active ? SaColors.accentTeal : SaColors.textTertiary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(active ? fill : regular, size: 23, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _centerButton() {
    return SizedBox(
      width: 64,
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -14),
          child: GestureDetector(
            onTap: _openUpload,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: SaColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: SaColors.accentTeal.withOpacity(0.4), blurRadius: 14, spreadRadius: 1),
                ],
              ),
              child: Icon(Icons.add, size: 28, color: SaColors.onAccent),
            ),
          ),
        ),
      ),
    );
  }
}
