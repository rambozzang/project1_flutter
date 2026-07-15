import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:project1/app/community/widget/cover_template.dart' show albumCoverCacheUrl;
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/repo/community/data/community_tag_data.dart';
import 'package:project1/app/shared_album/widget/sa_album_cover_hero.dart';

/// 앨범 홈 본문(커버 배너 · 앨범정보/가입버튼 헤더 · 인기태그 · 2열 그리드 피드).
/// `/CommunityHomePage`(초대링크 가입 랜딩)와 `/AlbumShellPage` 첫 탭(앨범 메인)이 함께 사용한다.
/// 데이터·페이징·새로고침은 호스트가 소유하고, 이 위젯은 표시와 콜백만 담당한다.
class CommunityHomeBody extends StatelessWidget {
  const CommunityHomeBody({
    super.key,
    required this.community,
    required this.visibleFeed,
    required this.tags,
    required this.activeTag,
    required this.feedLoading,
    required this.canViewFeed,
    required this.onRefresh,
    required this.onTagTap,
    required this.onTapItem,
    required this.onJoin,
    required this.onOpenMembers,
    required this.onOpenCoverEditor,
    this.onCreatePost,
    this.showCoverEditAction = true,
    this.showMemberAction = true,
    this.controller,
    this.bottomPadding = 120,
  });

  final CommunityData community;
  // 태그 필터가 적용된 피드(호스트에서 계산해 전달).
  final List<BoardWeatherListData> visibleFeed;
  final List<CommunityTagData> tags;
  final String? activeTag;
  final bool feedLoading;
  final bool canViewFeed;
  final Future<void> Function() onRefresh;
  final void Function(String tag) onTagTap;
  final void Function(BoardWeatherListData item) onTapItem;
  final VoidCallback onJoin;
  final VoidCallback onOpenMembers;
  final VoidCallback onOpenCoverEditor;
  final VoidCallback? onCreatePost;
  final bool showCoverEditAction;
  final bool showMemberAction;
  // 무한 스크롤은 호스트가 이 컨트롤러에 리스너를 붙여 처리한다.
  final ScrollController? controller;
  // 하단 바/FAB에 마지막 콘텐츠가 가리지 않도록 확보할 여백.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          if (!canViewFeed)
            SliverFillRemaining(hasScrollBody: false, child: _privateGate())
          else ...[
            if (tags.isNotEmpty) SliverToBoxAdapter(child: _tagSection()),
            if (visibleFeed.isEmpty && !feedLoading)
              SliverFillRemaining(hasScrollBody: false, child: _emptyFeed())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.62, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _feedCard(visibleFeed[i]),
                    childCount: visibleFeed.length,
                  ),
                ),
              ),
            if (feedLoading)
              const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))),
          ],
          // 시스템 내비게이션 버튼/홈 인디케이터와 하단 바/FAB에 마지막 콘텐츠가 가리지 않게 한다.
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final c = community;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFECEEF3))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _coverBanner(c),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _thumb(c, 64),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                  child: Text(c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
                              if (c.isPrivate) ...[const SizedBox(width: 6), const Icon(Icons.lock, size: 15, color: Color(0xFF9AA3B2))],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 14, color: Color(0xFF9AA3B2)),
                              const SizedBox(width: 3),
                              Text('멤버 ${c.memberCnt}명', style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A8291))),
                              const SizedBox(width: 10),
                              Text(c.isApproval ? '승인제' : '자유가입', style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A8291))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (c.description != null && c.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(c.description!, style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A5162), height: 1.45)),
                ],
                if (showMemberAction || (!c.isOwner && !c.isJoined)) ...[
                  const SizedBox(height: 14),
                  _actionButton(c),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverBanner(CommunityData c) {
    final coverUrl = c.coverDisplayUrl;
    return Stack(
      children: [
        SaAlbumCoverHero(
          communityId: c.communityId,
          child: coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: albumCoverCacheUrl(coverUrl),
                  memCacheWidth: 960,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _coverFallback(c),
                )
              : _coverFallback(c),
        ),
        if (showCoverEditAction && c.canEditCover)
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onOpenCoverEditor,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _coverFallback(CommunityData c) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF5B8DEF), Color(0xFF3B6FE0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(c.name.isNotEmpty ? c.name.characters.first : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40)),
    );
  }

  Widget _actionButton(CommunityData c) {
    if (c.isOwner) {
      return _outlineButton('방장 · 멤버 관리', Icons.manage_accounts_outlined, onOpenMembers);
    }
    if (c.isJoined) {
      return _outlineButton('가입중 · 멤버 보기', Icons.people_alt_outlined, onOpenMembers, color: const Color(0xFF9AA3B2));
    }
    if (c.isPending) {
      return _outlineButton('승인 대기중', Icons.hourglass_empty, null, color: const Color(0xFF9AA3B2));
    }
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B6FE0),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label:
            Text(c.isApproval ? '가입 신청' : '가입하기', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        onPressed: onJoin,
      ),
    );
  }

  Widget _outlineButton(String text, IconData icon, VoidCallback? onTap, {Color color = const Color(0xFF3B6FE0)}) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, color: color, size: 19),
        label: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14.5)),
        onPressed: onTap,
      ),
    );
  }

  Widget _privateGate() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Color(0xFF9AA3B2)),
            SizedBox(height: 12),
            Text('비공개 앨범입니다', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            SizedBox(height: 6),
            Text('가입 후 멤버가 되면\n게시물을 볼 수 있어요.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF7A8291), height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _tagSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('인기 태그', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = tags[i];
                final selected = activeTag == t.tag;
                return GestureDetector(
                  onTap: () => onTagTap(t.tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF3B6FE0) : const Color(0xFFF1F5FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? const Color(0xFF3B6FE0) : const Color(0xFFD6E0FA)),
                    ),
                    alignment: Alignment.center,
                    child: Text('${t.tag} ${t.count}',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF3B6FE0))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyFeed() {
    final filtered = activeTag != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 46, color: Color(0xFF9AA3B2)),
            const SizedBox(height: 12),
            Text(filtered ? "'$activeTag' 태그 게시물이 없어요" : '아직 게시물이 없어요',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(filtered ? '다른 태그를 선택해보세요.' : '첫 게시물을 올려보세요!', style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A8291))),
            if (!filtered && onCreatePost != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: onCreatePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6FE0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 18),
                  label: const Text('첫 순간 올리기',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feedCard(BoardWeatherListData item) {
    return GestureDetector(
      onTap: () => onTapItem(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.thumbnailPath != null && item.thumbnailPath!.isNotEmpty)
              CachedNetworkImage(
                  imageUrl: item.thumbnailPath!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: const Color(0xFFE6E8EF)))
            else
              Container(color: const Color(0xFFE6E8EF)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${item.nickNm ?? item.custNm ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 13),
                      Text(' ${item.likeCnt ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      const SizedBox(width: 8),
                      const Icon(Icons.visibility, color: Colors.white, size: 13),
                      Text(' ${item.viewCnt ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(CommunityData c, double size) {
    final radius = BorderRadius.circular(16);
    final coverUrl = c.coverDisplayUrl;
    if (coverUrl != null) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
            imageUrl: albumCoverCacheUrl(coverUrl),
            memCacheWidth: (size * 3).round(),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _thumbFallback(c, size, radius)),
      );
    }
    return _thumbFallback(c, size, radius);
  }

  Widget _thumbFallback(CommunityData c, double size, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient:
            const LinearGradient(colors: [Color(0xFF5B8DEF), Color(0xFF3B6FE0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(c.name.isNotEmpty ? c.name.characters.first : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
    );
  }
}
