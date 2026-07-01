import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';

/// 스카이라운지(모임 허브). 하단탭 '라운지' 확장.
/// - 내가 가입한 모임 + 추천/검색 모임 + [모임 만들기]
class CommunityHubPage extends StatefulWidget {
  const CommunityHubPage({super.key});

  @override
  State<CommunityHubPage> createState() => _CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final CommunityRepo _repo = CommunityRepo();
  final TextEditingController _searchCtrl = TextEditingController();

  List<CommunityData> _my = [];
  List<CommunityData> _discover = [];
  bool _loading = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repo.getMyCommunities(),
      _repo.search(_keyword),
    ]);
    if (!mounted) return;
    setState(() {
      _my = results[0];
      _discover = results[1];
      _loading = false;
    });
  }

  Future<void> _search(String kw) async {
    _keyword = kw.trim();
    final list = await _repo.search(_keyword);
    if (!mounted) return;
    setState(() => _discover = list);
  }

  void _openHome(CommunityData c) {
    Get.toNamed('/CommunityHomePage', arguments: {'communityId': c.communityId})?.then((_) => _load());
  }

  void _openCreate() {
    Get.toNamed('/CommunityCreatePage')?.then((created) {
      if (created == true) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        title: const Text('스카이라운지', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: TextButton.icon(
              onPressed: _openCreate,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEAF0FE),
                foregroundColor: const Color(0xFF3B6FE0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('새 모임', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            tooltip: '알림',
            onPressed: () => Get.toNamed('/AlramPage'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _sectionTitle('내 모임', _my.length),
                  const SizedBox(height: 8),
                  if (_my.isEmpty)
                    _emptyMy()
                  else
                    ..._my.map((c) => _myCard(c)),
                  const SizedBox(height: 24),
                  _sectionTitle('모임 찾기', null),
                  const SizedBox(height: 10),
                  _searchBox(),
                  const SizedBox(height: 12),
                  if (_discover.isEmpty)
                    _emptyDiscover()
                  else
                    ..._discover.map((c) => _discoverCard(c)),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, int? count) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text('$count', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3B6FE0))),
        ],
      ],
    );
  }

  Widget _emptyMy() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EF)),
      ),
      child: Column(
        children: [
          const Icon(Icons.groups_2_outlined, size: 40, color: Color(0xFF9AA3B2)),
          const SizedBox(height: 10),
          const Text('아직 가입한 모임이 없어요', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('아래에서 관심 모임을 찾아 가입하거나\n직접 모임을 만들어보세요.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Color(0xFF7A8291), height: 1.4)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _openCreate,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B6FE0),
              side: const BorderSide(color: Color(0xFF3B6FE0)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('모임 만들기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  Widget _emptyDiscover() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(child: Text('검색된 모임이 없어요', style: TextStyle(color: Color(0xFF7A8291)))),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchCtrl,
      textInputAction: TextInputAction.search,
      onSubmitted: _search,
      decoration: InputDecoration(
        hintText: '모임 이름으로 검색',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA3B2)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward, color: Color(0xFF3B6FE0)),
          onPressed: () => _search(_searchCtrl.text),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E8EF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E8EF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B6FE0), width: 1.5)),
      ),
    );
  }

  Widget _thumb(CommunityData c, double size) {
    final radius = BorderRadius.circular(14);
    if (c.imageUrl != null && c.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: c.imageUrl!, width: size, height: size, fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _thumbFallback(c, size, radius),
        ),
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
        gradient: const LinearGradient(colors: [Color(0xFF5B8DEF), Color(0xFF3B6FE0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(
        c.name.isNotEmpty ? c.name.characters.first : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
      ),
    );
  }

  Widget _myCard(CommunityData c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openHome(c),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _thumb(c, 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Colors.black87))),
                          if (c.isPrivate) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.lock, size: 14, color: Color(0xFF9AA3B2)),
                          ],
                          if (c.isOwner) ...[
                            const SizedBox(width: 5),
                            _tag('방장', const Color(0xFFEC8B00)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (c.description == null || c.description!.isEmpty) ? '멤버 ${c.memberCnt}명' : c.description!,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A8291)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFB6BCC8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _discoverCard(CommunityData c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEEF3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _thumb(c, 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87))),
                      if (c.isApproval) ...[
                        const SizedBox(width: 5),
                        _tag('승인', const Color(0xFF6B7280)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('멤버 ${c.memberCnt}명',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7A8291))),
                ],
              ),
            ),
            _joinButton(c),
          ],
        ),
      ),
    );
  }

  Widget _joinButton(CommunityData c) {
    if (c.isJoined) {
      return TextButton(
        onPressed: () => _openHome(c),
        child: const Text('입장', style: TextStyle(color: Color(0xFF3B6FE0), fontWeight: FontWeight.bold)),
      );
    }
    if (c.isPending) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('승인대기', style: TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B6FE0),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 36),
      ),
      onPressed: () => _join(c),
      child: const Text('가입', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Future<void> _join(CommunityData c) async {
    final (ok, status, msg) = await _repo.join(c.communityId);
    Get.snackbar('모임', msg.isEmpty ? (ok ? '처리되었습니다.' : '실패했습니다.') : msg,
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    if (ok) {
      if (status == 'JOINED') {
        _openHome(c);
      }
      _load();
    }
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }
}
