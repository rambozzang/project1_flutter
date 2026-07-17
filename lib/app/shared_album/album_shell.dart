import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/app/community/community_home_body.dart';
import 'package:project1/app/shared_album/activity_view.dart';
import 'package:project1/app/shared_album/recap_view.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_update_data.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';
import 'package:project1/repo/community/data/community_tag_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 앨범 진입 셸 — 하단 탭바(타임라인 · 회고 · ＋ · 활동 · 멤버)로 개별 화면을 묶는다.
/// v1: 타임라인(2a) 완성 + 회고/활동 준비중 플레이스홀더 + 멤버(멤버 관리/초대 재사용).
class AlbumShellPage extends StatefulWidget {
  const AlbumShellPage({super.key});

  @override
  State<AlbumShellPage> createState() => _AlbumShellPageState();
}

class _AlbumShellPageState extends State<AlbumShellPage> {
  final CommunityRepo _repo = CommunityRepo();

  late final int _communityId;
  CommunityData? _community;

  final List<BoardWeatherListData> _items = [];
  static const int _pageSize = 30;
  int _pageNum = 0;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _feedLoaded = false; // 첫 피드 로딩 완료 여부(빈 상태 vs 로딩 구분용)
  bool _changed = false; // 업로드·수정·삭제·표지변경 등 목록에 영향 주는 변경 발생 → 뒤로갈 때 리스트에 신호

  // 홈 탭(첫 탭 = CommunityHomePage 디자인) — 인기 태그 필터 & 무한 스크롤 컨트롤러
  List<CommunityTagData> _tags = [];
  String? _activeTag; // 선택된 인기 태그(탭하면 이미 로드된 피드에서 클라이언트 필터링)
  bool _onlyMine = false; // '내 사진만' 필터 — 내가 올린 미디어만 표시
  final ScrollController _homeScrollCtrl = ScrollController();

  int _tab = 0; // 0 홈 / 1 회고 / 2 활동 (멤버는 별도 화면으로 바로 진입)

  bool get _canPost {
    final c = _community;
    return c != null && (c.isJoined || c.isOwner);
  }

  @override
  void initState() {
    super.initState();
    // int/num/String(FCM·딥링크 유입) 어떤 타입이 와도 안전하게 파싱 — 캐스팅 크래시 방지.
    _communityId = int.tryParse('${Get.arguments?['communityId'] ?? 0}') ?? 0;
    // 리스트에서 넘겨준 앨범 정보가 있으면 즉시 셸을 그린다(없으면(딥링크 등) _load 완료까지 스피너).
    _community = Get.arguments?['community'] as CommunityData?;
    // 홈 탭 무한 스크롤 — 하단 근처에서 다음 페이지 로드.
    _homeScrollCtrl.addListener(() {
      if (_homeScrollCtrl.position.pixels >= _homeScrollCtrl.position.maxScrollExtent - 300) {
        _loadFeed();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _homeScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // 피드도 병렬로 시작 — 상세 완료를 기다리지 않아 표시가 빨라진다.
      final feedFuture = _loadFeed(reset: true);
      final detail = await _repo.getDetail(_communityId);
      // getDetail이 null이면 리스트에서 넘겨받은 값을 유지.
      _community = detail ?? _community;
      _repo.markSeen(_communityId); // 홈 복귀 시 NEW 뱃지 해소
      if (_canViewFeed) _loadTags(); // 홈 탭 인기 태그(피드 조회 가능할 때만)
      await feedFuture;
    } catch (e) {
      lo.g('앨범 셸 조회 실패: $e');
      // 넘겨받은 정보가 전혀 없을 때만 알럿(정보가 있으면 화면은 유지).
      if (_community == null) Utils.alert('앨범 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() {}); // 최종 데이터(상세·멤버·피드) 반영
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
      _feedLoaded = true; // 첫 피드 로딩(성공/실패 무관) 완료 → 이후 빈 상태 판단
      if (mounted) setState(() {});
    }
  }

  void _openMedia(int feedIndex) {
    // 타일 탭 → 몰입 상세(틱톡형). 댓글·좋아요·관람이력·소유자 편집(문구/위치/삭제)을 모두 지원.
    Get.toNamed('/AlbumImmersivePage', arguments: {
      'communityId': _communityId,
      'albumName': _community?.name ?? '앨범',
      'items': _items,
      'initialIndex': feedIndex,
    })?.then((r) {
      if (!mounted) return;
      if (r == true) {
        _changed = true; // 삭제/이동 → 목록에도 반영 신호
        _loadFeed(reset: true); // 삭제/이동 등 변경 → 피드 새로고침
      } else {
        setState(() {}); // 문구 수정 등 in-place 반영
      }
    });
  }

  /// 회고 컬렉션(테마별 큐레이션 목록)을 몰입뷰로 순차 재생.
  void _playCollection(List<BoardWeatherListData> collection, int index) {
    if (collection.isEmpty) return;
    Get.toNamed('/AlbumImmersivePage', arguments: {
      'communityId': _communityId,
      'albumName': _community?.name ?? '앨범',
      'items': collection,
      'initialIndex': index,
    })?.then((r) {
      // 몰입뷰에서 삭제/이동이 있었으면 피드 새로고침(회고 재생 경로도 동일하게 반영).
      if (mounted && r == true) {
        _changed = true;
        _loadFeed(reset: true);
      }
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
      _changed = true; // 촬영·업로드 진입 → 목록(미디어 수)도 갱신되게 신호
      await Future.delayed(const Duration(milliseconds: 800));
      _loadFeed(reset: true);
    }
  }

  // ── 홈 탭(그리드 홈) 지원 ────────────────────────────────
  bool get _canViewFeed {
    final c = _community;
    if (c == null) return false;
    return !c.isPrivate || c.isJoined || c.isOwner; // 공개거나, 비공개+멤버/방장
  }

  // 태그·'내 사진만' 필터가 적용된 피드(이미 로드된 피드에서 클라이언트 필터링).
  List<BoardWeatherListData> get _visibleFeed {
    Iterable<BoardWeatherListData> feed = _items;
    if (_onlyMine) feed = feed.where(_isMine);
    final tag = _activeTag;
    if (tag != null) feed = feed.where((e) => (e.contents ?? '').contains(tag));
    return feed.toList();
  }

  // 로그인 사용자 ID — 내가 올린 미디어 판별용.
  String get _myCustId => AuthCntr.to.resLoginData.value.custId?.toString() ?? '';

  // 본인 게시물 여부 — custId 일치(몰입뷰와 동일 기준).
  bool _isMine(BoardWeatherListData item) => _myCustId.isNotEmpty && _myCustId == item.custId;

  // 내가 올린 미디어 롱프레스 → 수정·삭제 바텀시트(몰입뷰 진입 없이 그리드에서 바로 관리).
  void _onLongPressMedia(BoardWeatherListData item) {
    if (!_isMine(item)) return;
    HapticFeedback.mediumImpact();
    _showMyMediaSheet(item);
  }

  void _showMyMediaSheet(BoardWeatherListData item) {
    final bool isVideo = item.typeDtCd == 'V';
    showModalBottomSheet(
      context: context,
      backgroundColor: SaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // 어떤 항목인지 컨텍스트 — 종류(영상/사진) + 올린 시점.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  Icon(isVideo ? Icons.videocam_outlined : Icons.photo_outlined,
                      size: 16, color: SaColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('내가 올린 ${isVideo ? '영상' : '사진'}',
                      style: SaText.bodyMedium.copyWith(color: SaColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  if ((item.crtDtm ?? '').isNotEmpty)
                    Text(Utils.timeage(item.crtDtm!), style: SaText.mono(fontSize: 10, color: SaColors.textTertiary)),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit_outlined, size: 22, color: SaColors.textPrimary),
              title: Text('문구 수정', style: SaText.bodyMedium),
              onTap: () {
                Navigator.of(ctx).pop();
                _editMyCaption(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, size: 22, color: Colors.red),
              title: Text('삭제', style: SaText.bodyMedium.copyWith(color: Colors.red)),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteMyMedia(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 문구(캡션) 수정 — /board/updateBoard contents 갱신 후 즉시 반영(몰입뷰와 동일 API).
  Future<void> _editMyCaption(BoardWeatherListData item) async {
    final TextEditingController ctrl = TextEditingController(text: item.contents ?? '');
    final String? result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('문구 수정', style: SaText.titleS),
        content: TextField(
          controller: ctrl,
          minLines: 1,
          maxLines: 5,
          style: SaText.body.copyWith(color: SaColors.textPrimary),
          decoration: InputDecoration(
            hintText: '문구를 입력하세요',
            hintStyle: SaText.body.copyWith(color: SaColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소', style: SaText.bodyMedium.copyWith(color: SaColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text('저장', style: SaText.bodyMedium.copyWith(color: SaColors.accentTeal)),
          ),
        ],
      ),
    );
    if (result == null) return; // 취소
    try {
      final ResData res = await BoardRepo().updateBoard(
        BoardUpdateData(boardId: (item.boardId ?? 0).toString(), contents: result),
      );
      if (res.code == '00') {
        item.contents = result;
        _changed = true; // 뒤로 갈 때 앨범 목록에도 반영 신호
        if (mounted) setState(() {});
      } else if (mounted) {
        Utils.alert(res.msg.toString());
      }
    } catch (_) {
      if (mounted) Utils.alert('문구 수정 중 오류가 발생했습니다.');
    }
  }

  // 게시물 삭제 — del_yn='Y' 후 피드 재조회(몰입뷰와 동일 API).
  Future<void> _deleteMyMedia(BoardWeatherListData item) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('게시물 삭제', style: SaText.titleS),
        content: Text('이 게시물을 삭제할까요? 되돌릴 수 없습니다.',
            style: SaText.body.copyWith(color: SaColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('취소', style: SaText.bodyMedium.copyWith(color: SaColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('삭제', style: SaText.bodyMedium.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final ResData res = await BoardRepo().updateBoard(
        BoardUpdateData(boardId: (item.boardId ?? 0).toString(), delYn: 'Y'),
      );
      if (res.code == '00') {
        _changed = true; // 앨범 목록(미디어 수)에도 반영 신호
        _loadFeed(reset: true); // 서버 기준으로 피드 재조회
      } else if (mounted) {
        Utils.alert(res.msg.toString());
      }
    } catch (_) {
      if (mounted) Utils.alert('삭제 중 오류가 발생했습니다.');
    }
  }

  Future<void> _loadTags() async {
    final tags = await _repo.getTags(_communityId);
    if (!mounted) return;
    setState(() => _tags = tags);
  }

  // 태그 탭 → 선택 토글. 이미 로드된 피드 안에서 클라이언트 필터링(과설계 방지).
  void _onTagTap(String tag) {
    setState(() => _activeTag = _activeTag == tag ? null : tag);
  }

  Future<void> _join() async {
    final (ok, _, msg) = await _repo.join(_communityId);
    Utils.alert(msg.isEmpty ? (ok ? '처리되었습니다.' : '실패했습니다.') : msg);
    if (ok) _load();
  }

  Future<void> _openMembersPage() async {
    final wasJoined = _community?.isJoined == true;
    final wasOwner = _community?.isOwner == true;
    final changed = await Get.toNamed('/CommunityMembersPage', arguments: {
      'communityId': _communityId,
      'communityName': _community?.name,
      'isOwner': _community?.isOwner == true,
      'isApproval': _community?.isApproval == true,
    });
    if (!mounted || changed != true) return;
    final updated = await _repo.getDetail(_communityId);
    if (!mounted) return;
    if (wasJoined && !wasOwner && updated?.isJoined != true) {
      Get.back(result: true);
      return;
    }
    await _load();
  }

  void _openInvite() {
    final c = _community;
    Get.toNamed('/AlbumInvitePage', arguments: {
      'communityId': _communityId,
      'albumName': c?.name ?? '앨범',
      'memberCnt': c?.memberCnt ?? 0,
      'isManager': c?.canEditCover == true,
    })?.then((_) => _load());
  }

  // 홈 그리드 타일 탭 → 몰입 상세. 태그 필터가 적용된 목록 기준으로 인덱스 계산.
  void _openHomeItem(BoardWeatherListData item) {
    final list = _visibleFeed;
    final idx = list.indexWhere((e) => e.boardId == item.boardId);
    Get.toNamed('/AlbumImmersivePage', arguments: {
      'communityId': _communityId,
      'albumName': _community?.name ?? '앨범',
      'items': list,
      'initialIndex': idx < 0 ? 0 : idx,
    })?.then((r) {
      if (!mounted) return;
      if (r == true) {
        _changed = true; // 삭제/이동 → 목록에도 반영 신호
        _loadFeed(reset: true);
      } else {
        setState(() {}); // 문구 수정 등 in-place 반영
      }
    });
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
      child: PopScope<bool>(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, bool? result) {
          if (didPop) return;
          Get.back(result: _changed); // 시스템/제스처 뒤로가기도 변경신호(있을 때만 목록 새로고침)
        },
        child: Scaffold(
        backgroundColor: SaColors.bgBase,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          // 넘겨받은 앨범 정보가 있으면 셸을 즉시 렌더(피드는 백그라운드 로드). 없을 때만 스피너.
          child: _community == null
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))
              : Column(
                  children: [
                    _buildAppBar(),
                    Expanded(child: _buildTabBody()),
                  ],
                ),
        ),
        bottomNavigationBar: _community == null ? null : _buildBottomBar(),
      ),
      ),
    );
  }

  // 대문(표지) 편집 — 여러 곳에서 재사용.
  void _openCoverEditor() {
    Get.toNamed('/AlbumCoverEditorPage', arguments: {'community': _community, 'items': _items})?.then((saved) {
      if (saved == true) {
        _changed = true; // 표지 변경 → 목록 카드 표지도 갱신
        _load();
      }
    });
  }

  // 방장이 아닌 가입 멤버의 앨범 나가기(탈퇴). 백엔드 /community/leave (방장은 서버가 거부).
  Future<void> _leaveAlbum() async {
    final bool? ok = await Get.dialog<bool>(AlertDialog(
      backgroundColor: SaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('앨범 나가기', style: SaText.titleS),
      content: Text('${_community?.name ?? '이 앨범'}에서 나가시겠어요?',
          style: SaText.body.copyWith(color: SaColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('취소', style: SaText.bodyMedium.copyWith(color: SaColors.textTertiary)),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text('나가기', style: SaText.bodyMedium.copyWith(color: Colors.red)),
        ),
      ],
    ));
    if (ok != true) return;
    final (bool success, String msg) = await _repo.leave(_communityId);
    if (success) {
      Utils.alert('앨범에서 나갔습니다.');
      Get.back(result: true); // 목록으로 복귀하며 새로고침 신호
    } else {
      Utils.alert(msg.isEmpty ? '나가기에 실패했습니다.' : msg);
    }
  }

  // 방장의 앨범 삭제. 백엔드 /community/delete (소프트삭제 — 목록/조회에서 제외). 성공 시 셸 닫고 목록으로.
  Future<void> _deleteAlbum() async {
    final bool? ok = await Get.dialog<bool>(AlertDialog(
      backgroundColor: SaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('앨범 삭제', style: SaText.titleS),
      content: Text("'${_community?.name ?? '이 앨범'}'을(를) 삭제하면 되돌릴 수 없어요.\n담긴 사진·영상도 더 이상 보이지 않습니다.",
          style: SaText.body.copyWith(color: SaColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('취소', style: SaText.bodyMedium.copyWith(color: SaColors.textTertiary)),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text('삭제', style: SaText.bodyMedium.copyWith(color: Colors.red)),
        ),
      ],
    ));
    if (ok != true) return;
    final (bool success, String msg) = await _repo.deleteAlbum(_communityId);
    if (success) {
      Utils.alert(msg.isEmpty ? '앨범을 삭제했습니다.' : msg);
      Get.back(result: true); // 목록으로 복귀하며 새로고침 신호
    } else {
      Utils.alert(msg.isEmpty ? '삭제에 실패했습니다.' : msg);
    }
  }

  Widget _buildAppBar() {
    final c = _community;
    final int mediaCnt = (c?.videoCnt ?? 0) + (c?.photoCnt ?? 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          _circle(PhosphorIconsBold.caretLeft, () => Get.back(result: _changed)),
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
          // 관리자면 표지 편집을 앱바 우측에 노출 — 멤버 탭에 묻혀 안 보이던 문제 해결.
          if (c?.canEditCover == true) ...[
            // 하단 '회고' 탭(sparkle)과 겹치지 않게 대문편집은 붓 아이콘 사용.
            _circle(PhosphorIconsFill.paintBrush, _openCoverEditor),
            const SizedBox(width: 8),
          ],
          if (_canPost || c?.isOwner == true) _buildMoreMenu(),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_tab) {
      case 0:
        // 홈 탭 = CommunityHomePage 그리드 홈 디자인(공용 위젯). 데이터·페이징은 셸이 소유.
        // 배경은 CommunityHomePage 원본 톤(#F6F7FB) 유지 — 셸 SaColors 톤이 카드 여백에 비치지 않게.
        return ColoredBox(
          color: const Color(0xFFF6F7FB),
          child: CommunityHomeBody(
            community: _community!,
            visibleFeed: _visibleFeed,
            tags: _tags,
            activeTag: _activeTag,
            feedLoading: !_feedLoaded || _loadingMore, // 첫 로딩/추가 로딩 중엔 스피너(빈 메시지 번쩍임 방지)
            canViewFeed: _canViewFeed,
            controller: _homeScrollCtrl,
            onRefresh: () => _load(), // 당겨서 새로고침 — 상세·멤버·피드·태그 재조회
            onTagTap: _onTagTap,
            onTapItem: _openHomeItem,
            // 내가 올린 미디어 — MY 배지 · '내 사진만' 필터 · 롱프레스 수정/삭제(로그인 시에만).
            myCustId: _myCustId,
            onlyMine: _onlyMine,
            onToggleOnlyMine: _myCustId.isEmpty ? null : () => setState(() => _onlyMine = !_onlyMine),
            onLongPressItem: _onLongPressMedia,
            onJoin: _join,
            onOpenMembers: _openMembersPage,
            onOpenCoverEditor: _openCoverEditor,
            onCreatePost: _canPost ? _openUpload : null,
            showCoverEditAction: false,
            showMemberAction: false,
            bottomPadding: 100, // 셸 하단 바(82) 아래 여유
          ),
        );
      case 1:
        return RecapView(
          items: _items,
          communityId: _communityId,
          albumName: _community?.name ?? '앨범',
          onPlay: _playCollection,
        );
      case 2:
        return ActivityView(
          communityId: _communityId,
          onOpenBoard: (boardId) {
            final idx = _items.indexWhere((e) => e.boardId == boardId);
            if (idx >= 0) _openMedia(idx);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMoreMenu() {
    final c = _community;
    return PopupMenuButton<String>(
      tooltip: '앨범 관리',
      color: SaColors.surface,
      onSelected: (value) {
        if (value == 'invite') _openInvite();
        if (value == 'leave') _leaveAlbum();
        if (value == 'delete') _deleteAlbum();
      },
      itemBuilder: (_) => [
        if (_canPost)
          PopupMenuItem(
            value: 'invite',
            child: Row(children: [
              PhosphorIcon(PhosphorIconsBold.userPlus, size: 18, color: SaColors.textPrimary),
              const SizedBox(width: 10),
              Text('멤버 초대', style: SaText.bodyMedium),
            ]),
          ),
        if (c?.isJoined == true && c?.isOwner != true)
          PopupMenuItem(
            value: 'leave',
            child: Row(children: [
              const PhosphorIcon(PhosphorIconsBold.signOut, size: 18, color: Colors.red),
              const SizedBox(width: 10),
              Text('앨범 나가기', style: SaText.bodyMedium.copyWith(color: Colors.red)),
            ]),
          ),
        if (c?.isOwner == true)
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              const PhosphorIcon(PhosphorIconsBold.trash, size: 18, color: Colors.red),
              const SizedBox(width: 10),
              Text('앨범 삭제', style: SaText.bodyMedium.copyWith(color: Colors.red)),
            ]),
          ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: SaColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: SaColors.borderStrong),
        ),
        child: PhosphorIcon(PhosphorIconsBold.dotsThree, size: 18, color: SaColors.textPrimary),
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
              _tabItem(0, PhosphorIconsFill.house, PhosphorIconsBold.house, '홈'),
              _tabItem(1, PhosphorIconsFill.sparkle, PhosphorIconsBold.sparkle, '회고'),
              _centerButton(),
              _tabItem(2, PhosphorIconsFill.bell, PhosphorIconsBold.bell, '활동'),
              _actionTabItem(PhosphorIconsBold.usersThree, '멤버', _openMembersPage),
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

  Widget _actionTabItem(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(icon, size: 23, color: SaColors.textTertiary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: SaColors.textTertiary,
              ),
            ),
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
