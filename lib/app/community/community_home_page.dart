import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/app/community/community_home_body.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/repo/community/data/community_invite_info_data.dart';
import 'package:project1/repo/community/data/community_tag_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';

/// 앨범 홈. 헤더·멤버 관리·대문 편집과 앨범 그리드 피드를 제공한다.
/// 앨범 미디어 탭 → 편집·삭제를 지원하는 몰입형 상세 화면으로 이동한다.
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

  List<CommunityTagData> _tags = [];
  String? _activeTag; // 선택된 인기 태그 (탭하면 피드를 클라이언트에서 필터링)

  @override
  void initState() {
    super.initState();
    // int/num/String(FCM·딥링크 유입) 어떤 타입이 와도 안전하게 파싱 — 캐스팅 크래시 방지.
    _communityId = int.tryParse('${Get.arguments?['communityId'] ?? 0}') ?? 0;
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
    if (_canViewFeed) {
      _loadFeed(reset: true);
      _loadTags();
    }
  }

  bool get _canViewFeed {
    final c = _community;
    if (c == null) return false;
    return !c.isPrivate || c.isJoined; // 공개거나, 비공개+멤버
  }

  Future<void> _loadTags() async {
    final tags = await _repo.getTags(_communityId);
    if (!mounted) return;
    setState(() => _tags = tags);
  }

  /// 태그 탭 → 선택 토글. 이미 로드된 피드 안에서 해당 해시태그가 포함된 게시물만 보여준다(과설계 방지).
  void _onTagTap(String tag) {
    setState(() => _activeTag = _activeTag == tag ? null : tag);
  }

  List<BoardWeatherListData> get _visibleFeed {
    final tag = _activeTag;
    if (tag == null) return _feed;
    return _feed.where((e) => (e.contents ?? '').contains(tag)).toList();
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
    if (_canViewFeed) {
      await _loadFeed(reset: true);
      _loadTags();
    }
  }

  Future<void> _join() async {
    final (ok, status, msg) = await _repo.join(_communityId);
    Utils.alert(msg.isEmpty ? (ok ? '처리되었습니다.' : '실패했습니다.') : msg);
    if (ok) _refresh();
  }

  Future<void> _openMembers() async {
    final changed = await Get.toNamed('/CommunityMembersPage', arguments: {
      'communityId': _communityId,
      'communityName': _community?.name,
      'isOwner': _community?.isOwner == true,
      'isApproval': _community?.isApproval == true,
    });
    if (changed == true) _refresh();
  }

  bool get _canPost {
    final c = _community;
    return c != null && (c.isJoined || c.isOwner);
  }

  Future<void> _openCamera() async {
    // 카메라 진입 전 대상 앨범 지정 → 촬영 후 등록 시 이 앨범에 소속되어 저장됨.
    // 복귀 시 null 초기화 금지 — 카메라→등록 페이지 전환이 pushReplacement라 이 await가 먼저 풀려
    // 등록 페이지가 값을 읽기 전에 지워진다. 초기화는 등록 페이지가 소비 직후 수행.
    RootCntr.to.pendingCommunityId = _communityId;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraAwesomePage()));
    if (mounted && _canViewFeed) {
      // 업로드는 백그라운드로 진행되므로 약간의 지연 후 새로고침
      await Future.delayed(const Duration(milliseconds: 800));
      _loadFeed(reset: true);
    }
  }

  Future<void> _showInviteSheet() async {
    final info = await _repo.getInviteInfo(_communityId);
    if (!mounted) return;
    if (info == null) {
      Utils.alert('초대 정보를 불러오지 못했습니다.');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => _InviteSheet(
          info: info,
          onInviteFriends: () {
            Navigator.of(ctx).pop();
            Get.toNamed('/CommunityInvitePage', arguments: {'communityId': _communityId});
          }),
    );
  }

  Future<void> _openCoverEditor() async {
    final saved = await Get.toNamed('/AlbumCoverEditorPage', arguments: {
      'community': _community,
      'items': _feed,
    });
    if (saved == true) await _refresh();
  }

  Future<void> _deleteAlbum() async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('앨범 삭제'),
      content: Text("'${_community?.name ?? '이 앨범'}'을(를) 삭제하면 되돌릴 수 없어요.\n담긴 사진·영상도 더 이상 보이지 않습니다."),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('취소')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirmed != true) return;
    final (ok, msg) = await _repo.deleteAlbum(_communityId);
    Utils.alert(msg.isEmpty ? (ok ? '앨범을 삭제했습니다.' : '삭제에 실패했습니다.') : msg);
    if (ok) Get.back(result: true);
  }

  void _openViewer(BoardWeatherListData item) {
    final int initialIndex = _visibleFeed.indexWhere((e) => e.boardId == item.boardId);
    Get.toNamed('/AlbumImmersivePage', arguments: {
      'communityId': _communityId,
      'albumName': _community?.name ?? '앨범',
      'items': _visibleFeed,
      'initialIndex': initialIndex < 0 ? 0 : initialIndex,
    })?.then((changed) {
      if (changed == true) _loadFeed(reset: true);
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
        title: Text(_community?.name ?? '앨범', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_canPost)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1, color: Colors.black87),
              tooltip: '초대',
              onPressed: _showInviteSheet,
            ),
          if (_community != null)
            IconButton(
              icon: const Icon(Icons.people_alt_outlined, color: Colors.black87),
              tooltip: '멤버',
              onPressed: _openMembers,
            ),
          if (_community?.isOwner == true)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (value) {
                if (value == 'delete') _deleteAlbum();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Text('앨범 삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _community == null
              ? const Center(child: Text('앨범을 찾을 수 없습니다.', style: TextStyle(color: Color(0xFF7A8291))))
              : CommunityHomeBody(
                  community: _community!,
                  visibleFeed: _visibleFeed,
                  tags: _tags,
                  activeTag: _activeTag,
                  feedLoading: _feedLoading,
                  canViewFeed: _canViewFeed,
                  controller: _scrollCtrl,
                  onRefresh: _refresh,
                  onTagTap: _onTagTap,
                  onTapItem: _openViewer,
                  onJoin: _join,
                  onOpenMembers: _openMembers,
                  onOpenCoverEditor: _openCoverEditor,
                ),
    );
  }

}

/// 앨범 초대 바텀시트: 초대코드 + 복사/공유/친구초대
class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.info, required this.onInviteFriends});
  final CommunityInviteInfoData info;
  final VoidCallback onInviteFriends;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E3EA), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text("'${info.name}' 초대하기",
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
            const SizedBox(height: 4),
            const Text('아래 코드/링크를 공유하거나 친구를 직접 초대하세요.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Color(0xFF7A8291))),
            const SizedBox(height: 20),
            // 초대 코드 박스
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6E0FA)),
              ),
              child: Row(
                children: [
                  const Text('초대 코드', style: TextStyle(fontSize: 12.5, color: Color(0xFF7A8291), fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(info.inviteCode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3, color: Color(0xFF2C4FA0))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF3B6FE0), size: 20),
                    tooltip: '코드 복사',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: info.inviteCode));
                      Get.snackbar('복사됨', '초대 코드를 복사했어요.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B6FE0),
                      side: const BorderSide(color: Color(0xFF3B6FE0)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('공유하기', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Share.share(info.shareText),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B6FE0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.group_add, color: Colors.white, size: 18),
                    label: const Text('친구 초대', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: onInviteFriends,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
