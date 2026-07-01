import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';

/// 모임 홈. 헤더(가입/탈퇴/멤버) + 앨범 그리드 피드.
/// 앨범 탭 → 풀스크린 틱톡 뷰어(VideoMyinfoListPage, datatype=COMMUNITY) 재사용.
class CommunityHomePage extends StatefulWidget {
  const CommunityHomePage({super.key});

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> {
  final CommunityRepo _repo = CommunityRepo();
  final ScrollController _scrollCtrl = ScrollController();

  late final int _communityId;
  CommunityData? _community;
  final List<BoardWeatherListData> _feed = [];
  bool _loading = true;
  bool _feedLoading = false;
  bool _lastPage = false;
  int _pageNum = 0;
  final int _pageSize = 12;

  @override
  void initState() {
    super.initState();
    _communityId = (Get.arguments?['communityId'] as num).toInt();
    _init();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300) {
        _loadFeed();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final detail = await _repo.getDetail(_communityId);
    if (!mounted) return;
    setState(() {
      _community = detail;
      _loading = false;
    });
    if (_canViewFeed) _loadFeed(reset: true);
  }

  bool get _canViewFeed {
    final c = _community;
    if (c == null) return false;
    return !c.isPrivate || c.isJoined; // 공개거나, 비공개+멤버
  }

  Future<void> _loadFeed({bool reset = false}) async {
    if (_feedLoading) return;
    if (reset) {
      _pageNum = 0;
      _lastPage = false;
      _feed.clear();
    }
    if (_lastPage) return;
    setState(() => _feedLoading = true);
    final res = await _repo.getFeedRes(_communityId, _pageNum, _pageSize);
    if (!mounted) return;
    if (res.code == '00' && res.data != null) {
      final list = (res.data as List).map((e) => BoardWeatherListData.fromMap(e)).toList();
      if (list.length < _pageSize) _lastPage = true;
      _feed.addAll(list);
      _pageNum++;
    } else {
      _lastPage = true;
    }
    setState(() => _feedLoading = false);
  }

  Future<void> _refresh() async {
    final detail = await _repo.getDetail(_communityId);
    if (!mounted) return;
    setState(() => _community = detail);
    if (_canViewFeed) await _loadFeed(reset: true);
  }

  Future<void> _join() async {
    final (ok, status, msg) = await _repo.join(_communityId);
    Utils.alert(msg.isEmpty ? (ok ? '처리되었습니다.' : '실패했습니다.') : msg);
    if (ok) _refresh();
  }

  Future<void> _leave() async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('모임 탈퇴'),
      content: Text('${_community?.name ?? '이 모임'}에서 탈퇴하시겠어요?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('취소')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('탈퇴', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirmed != true) return;
    final (ok, msg) = await _repo.leave(_communityId);
    Utils.alert(msg.isEmpty ? (ok ? '탈퇴했습니다.' : '실패했습니다.') : msg);
    if (ok) _refresh();
  }

  bool get _canPost {
    final c = _community;
    return c != null && (c.isJoined || c.isOwner);
  }

  Future<void> _openCamera() async {
    // 카메라 진입 전 대상 모임 지정 → 촬영 후 등록 시 이 모임에 소속되어 저장됨.
    RootCntr.to.pendingCommunityId = _communityId;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraAwesomePage()));
    RootCntr.to.pendingCommunityId = null; // 복귀 시 초기화(누수 방지)
    if (mounted && _canViewFeed) {
      // 업로드는 백그라운드로 진행되므로 약간의 지연 후 새로고침
      await Future.delayed(const Duration(milliseconds: 800));
      _loadFeed(reset: true);
    }
  }

  void _openViewer(BoardWeatherListData item) {
    Get.toNamed('/VideoMyinfoListPage', arguments: {
      'datatype': 'COMMUNITY',
      'custId': '',
      'boardId': item.boardId.toString(),
      'searchWord': '',
      'communityId': _communityId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: _canPost
          ? FloatingActionButton.extended(
              onPressed: _openCamera,
              backgroundColor: const Color(0xFF3B6FE0),
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              label: const Text('글 올리기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      appBar: AppBar(
        forceMaterialTransparency: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(_community?.name ?? '모임', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_community != null)
            IconButton(
              icon: const Icon(Icons.people_alt_outlined, color: Colors.black87),
              tooltip: '멤버',
              onPressed: () => Get.toNamed('/CommunityMembersPage', arguments: {
                'communityId': _communityId,
                'isOwner': _community!.isOwner,
                'isApproval': _community!.isApproval,
              }),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _community == null
              ? const Center(child: Text('모임을 찾을 수 없습니다.', style: TextStyle(color: Color(0xFF7A8291))))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollCtrl,
                    slivers: [
                      SliverToBoxAdapter(child: _header()),
                      if (!_canViewFeed)
                        SliverFillRemaining(hasScrollBody: false, child: _privateGate())
                      else ...[
                        if (_feed.isEmpty && !_feedLoading)
                          SliverFillRemaining(hasScrollBody: false, child: _emptyFeed())
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 0.62, mainAxisSpacing: 10, crossAxisSpacing: 10),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _feedCard(_feed[i]),
                                childCount: _feed.length,
                              ),
                            ),
                          ),
                        if (_feedLoading)
                          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _header() {
    final c = _community!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFECEEF3))),
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
                        Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),
          _actionButton(c),
        ],
      ),
    );
  }

  Widget _actionButton(CommunityData c) {
    if (c.isOwner) {
      return _outlineButton('방장 · 멤버 관리', Icons.manage_accounts_outlined, () => Get.toNamed('/CommunityMembersPage', arguments: {
            'communityId': _communityId, 'isOwner': true, 'isApproval': c.isApproval,
          }));
    }
    if (c.isJoined) {
      return _outlineButton('가입중 · 탈퇴하기', Icons.logout, _leave, color: const Color(0xFF9AA3B2));
    }
    if (c.isPending) {
      return _outlineButton('승인 대기중', Icons.hourglass_empty, null, color: const Color(0xFF9AA3B2));
    }
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B6FE0), elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: Text(c.isApproval ? '가입 신청' : '가입하기', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        onPressed: _join,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Color(0xFF9AA3B2)),
            const SizedBox(height: 12),
            const Text('비공개 모임입니다', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 6),
            const Text('가입 후 멤버가 되면\n게시물을 볼 수 있어요.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF7A8291), height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _emptyFeed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.photo_library_outlined, size: 46, color: Color(0xFF9AA3B2)),
            SizedBox(height: 12),
            Text('아직 게시물이 없어요', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 4),
            Text('첫 게시물을 올려보세요!', style: TextStyle(fontSize: 12.5, color: Color(0xFF7A8291))),
          ],
        ),
      ),
    );
  }

  Widget _feedCard(BoardWeatherListData item) {
    return GestureDetector(
      onTap: () => _openViewer(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.thumbnailPath != null && item.thumbnailPath!.isNotEmpty)
              CachedNetworkImage(imageUrl: item.thumbnailPath!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: const Color(0xFFE6E8EF)))
            else
              Container(color: const Color(0xFFE6E8EF)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 8, right: 8, bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${item.nickNm ?? item.custNm ?? ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
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
    if (c.imageUrl != null && c.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(imageUrl: c.imageUrl!, width: size, height: size, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _thumbFallback(c, size, radius)),
      );
    }
    return _thumbFallback(c, size, radius);
  }

  Widget _thumbFallback(CommunityData c, double size, BorderRadius radius) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(colors: [Color(0xFF5B8DEF), Color(0xFF3B6FE0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(c.name.isNotEmpty ? c.name.characters.first : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
    );
  }
}
