import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/widget/sa_gradient_button.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_invite_info_data.dart';
import 'package:project1/repo/community/data/community_member_data.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// 멤버 초대(1h) — 초대 링크+QR / 팔로우에서 초대 / 현재 멤버 / 대기 중(보낸 초대).
/// 초대 발송·코드 발급은 기존 백엔드(3방식) 재사용, 보낸 초대 목록만 신규 API.
class AlbumInvitePage extends StatefulWidget {
  const AlbumInvitePage({super.key});

  @override
  State<AlbumInvitePage> createState() => _AlbumInvitePageState();
}

class _AlbumInvitePageState extends State<AlbumInvitePage> {
  final CommunityRepo _repo = CommunityRepo();
  final BoardRepo _boardRepo = BoardRepo();

  late final int _communityId;
  late final String _albumName;
  late final int _memberCnt;
  late final bool _isManager;

  bool _loading = true;
  CommunityInviteInfoData? _invite;
  List<BoardWeatherListData> _people = []; // 팔로워+팔로잉(중복 제거)
  List<CommunityMemberData> _members = [];
  List<CommunityMemberData> _pendingInvites = [];
  final Set<String> _sending = {};

  String get _inviteLink => 'https://skysnap.co.kr/invite/${_invite?.inviteCode ?? ''}';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _communityId = (args['communityId'] as num?)?.toInt() ?? 0;
    _albumName = args['albumName']?.toString() ?? '앨범';
    _memberCnt = (args['memberCnt'] as num?)?.toInt() ?? 0;
    _isManager = args['isManager'] == true;
    _load();
  }

  Future<void> _load() async {
    final String myCustId = AuthCntr.to.resLoginData.value.custId.toString();
    try {
      // 하나가 실패/지연돼도 나머지(QR·링크·멤버)는 반드시 표시되도록
      // 개별 예외 흡수 + 8초 타임아웃(무한대기로 스피너가 멈추는 것 방지).
      const t = Duration(seconds: 8);
      final results = await Future.wait<dynamic>([
        _repo.getInviteInfo(_communityId).timeout(t, onTimeout: () => null).catchError((_) => null),
        _boardRepo.getFollowList(1, myCustId).timeout(t, onTimeout: () => ResData()..code = '99').catchError((_) => ResData()..code = '99'),
        _boardRepo.getFollowList(2, myCustId).timeout(t, onTimeout: () => ResData()..code = '99').catchError((_) => ResData()..code = '99'),
        _repo.getMembers(_communityId).timeout(t, onTimeout: () => <CommunityMemberData>[]).catchError((_) => <CommunityMemberData>[]),
        if (_isManager) _repo.getInvitedMembers(_communityId).timeout(t, onTimeout: () => <CommunityMemberData>[]).catchError((_) => <CommunityMemberData>[]),
      ]);
      _invite = results[0] as CommunityInviteInfoData?;
      // 팔로워(1)+팔로잉(2) 합쳐 custId 기준 중복 제거(기존 초대 화면과 동일 규칙)
      final Map<String, BoardWeatherListData> byId = {};
      for (final r in [results[1], results[2]]) {
        final res = r as dynamic;
        if (res.code == '00' && res.data != null) {
          for (final e in (res.data as List)) {
            final item = BoardWeatherListData.fromMap(e);
            final id = item.custId?.toString();
            if (id != null && id.isNotEmpty && id != myCustId) byId[id] = item;
          }
        }
      }
      _people = byId.values.toList();
      _members = results[3] as List<CommunityMemberData>;
      if (_isManager && results.length > 4) {
        _pendingInvites = results[4] as List<CommunityMemberData>;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isMember(String custId) => _members.any((m) => m.custId == custId);
  bool _isInvited(String custId) => _pendingInvites.any((m) => m.custId == custId);

  // ── 내부 사용자 닉네임 검색(팔로우 없어도 초대 가능) ──
  final TextEditingController _searchCtrl = TextEditingController();
  List<BoardWeatherListData> _searchResults = [];
  bool _searching = false;
  bool _searched = false;

  Future<void> _runSearch() async {
    final kw = _searchCtrl.text.trim();
    if (kw.length < 2) {
      BotToast.showText(text: '닉네임을 2자 이상 입력해주세요.');
      return;
    }
    setState(() => _searching = true);
    final list = await _repo.searchUsersByNick(kw);
    if (!mounted) return;
    final String myCustId = AuthCntr.to.resLoginData.value.custId.toString();
    setState(() {
      _searched = true;
      _searching = false;
      _searchResults = list
          .where((m) => m['custId']?.toString() != myCustId)
          .map((m) => BoardWeatherListData.fromMap(m))
          .toList();
    });
  }

  Future<void> _invitePerson(String custId, {bool resend = false}) async {
    if (_sending.contains(custId)) return;
    setState(() => _sending.add(custId));
    final (ok, msg) = await _repo.inviteUser(_communityId, custId);
    if (!mounted) return;
    setState(() => _sending.remove(custId));
    BotToast.showText(text: ok ? (resend ? '초대를 다시 보냈습니다.' : '초대를 보냈습니다.') : (msg.isEmpty ? '초대에 실패했습니다.' : msg));
    if (ok && !resend && _isManager) {
      final refreshed = await _repo.getInvitedMembers(_communityId);
      if (mounted) setState(() => _pendingInvites = refreshed);
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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        children: [
                          _buildInviteCards(),
                          const SizedBox(height: 12),
                          // 가장 확실한 초대 수단을 1순위 CTA로 — 팔로우가 없어도 누구나 초대 가능
                          SaGradientButton(
                            label: '카카오톡·문자로 초대장 보내기',
                            height: 50,
                            glow: true,
                            expand: true,
                            onTap: () => Share.share(_invite?.shareText ?? _inviteLink),
                          ),
                          const SizedBox(height: 24),
                          _sectionHeader('친구 찾아 초대', _searched ? _searchResults.length : _people.length),
                          const SizedBox(height: 8),
                          // 닉네임 검색 — 팔로우가 없어도 앱 사용자를 직접 찾아 초대
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onSubmitted: (_) => _runSearch(),
                                  textInputAction: TextInputAction.search,
                                  style: SaText.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: '닉네임으로 검색 (2자 이상)',
                                    hintStyle: SaText.caption,
                                    isDense: true,
                                    filled: true,
                                    fillColor: SaColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: SaColors.border)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: SaColors.accentTeal)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _runSearch,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: SaColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _searching
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 18, color: SaColors.onAccent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_searched) ...[
                            if (_searchResults.isEmpty)
                              Text('검색 결과가 없어요. 닉네임을 다시 확인해주세요.', style: SaText.body.copyWith(fontSize: 12.5))
                            else
                              for (final p in _searchResults) _personRow(p),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _searched = false;
                                  _searchResults = [];
                                  _searchCtrl.clear();
                                }),
                                child: Text('검색 지우고 팔로우 목록 보기', style: SaText.caption),
                              ),
                            ),
                          ] else ...[
                          if (_people.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: SaColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: SaColors.border),
                              ),
                              child: Text(
                                '나를 팔로우하거나 내가 팔로우한 친구가 여기에 표시돼요.\n'
                                '아직 없다면 위의 초대장 보내기나 QR로 초대해보세요 — 앱이 없어도 초대 코드로 참여할 수 있어요.',
                                style: SaText.body.copyWith(fontSize: 12.5),
                              ),
                            )
                          else
                            for (final p in _people.take(20)) _personRow(p),
                          ],
                          const SizedBox(height: 24),
                          _sectionHeader('현재 멤버', _members.length),
                          const SizedBox(height: 8),
                          for (final m in _members.take(5)) _memberRow(m),
                          if (_members.length > 5)
                            TextButton(
                              onPressed: () => Get.toNamed('/CommunityMembersPage',
                                  arguments: {'communityId': _communityId}),
                              child: Text('모두 보기',
                                  style: SaText.caption.copyWith(color: SaColors.accentTeal)),
                            ),
                          if (_isManager && _pendingInvites.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _sectionHeader('대기 중', _pendingInvites.length),
                            const SizedBox(height: 8),
                            for (final m in _pendingInvites) _pendingRow(m),
                          ],
                        ],
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
          GestureDetector(
            onTap: () => Get.back(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('멤버 초대', style: SaText.titleS),
                Text('$_albumName · 멤버 $_memberCnt', style: SaText.mono(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // QR 크게 보기 — 상대가 카메라로 스캔하기 쉽게 확대
  void _showBigQr() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_albumName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SaText.titleS.copyWith(color: const Color(0xFF17222E))),
                const SizedBox(height: 4),
                Text('QR을 스캔해 앨범에 참여하세요',
                    style: SaText.mono(fontSize: 10, color: const Color(0xFF5C6C7E))),
                const SizedBox(height: 20),
                QrImageView(
                  data: _inviteLink,
                  version: QrVersions.auto,
                  size: 240,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 18),
                Text(_invite?.inviteCode ?? '',
                    style: SaText.mono(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF17222E), letterSpacingEm: 0.18)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 초대 링크 카드 + QR 카드 나란히
  Widget _buildInviteCards() {
    // ListView(무한 높이) 안에서 Row(stretch)는 '무한 높이 강제' 크래시.
    // IntrinsicHeight는 QR(QrImageView 내부 LayoutBuilder)와 충돌 → 고정 높이 SizedBox로 확정.
    return SizedBox(
      height: 156,
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SaColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('초대 링크', style: SaText.caption),
                const SizedBox(height: 8),
                Text(
                  _inviteLink.replaceFirst('https://', ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SaText.mono(fontSize: 10.5, color: SaColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _smallAction('복사', PhosphorIconsBold.copy, () {
                      Clipboard.setData(ClipboardData(text: _inviteLink));
                      BotToast.showText(text: '초대 링크를 복사했습니다.');
                    }),
                    const SizedBox(width: 8),
                    _smallAction('공유', PhosphorIconsFill.shareFat, () {
                      Share.share(_invite?.shareText ?? _inviteLink);
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // QR 카드 — 스캔 대비를 위해 흰 배경. 탭 시 크게 보기
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _showBigQr,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: _inviteLink,
                    version: QrVersions.auto,
                    size: 92,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Text('QR 크게 보기',
                      style: SaText.mono(fontSize: 9, color: const Color(0xFF04121A))),
                ],
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _smallAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: SaColors.accentTeal,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 12, color: SaColors.onAccent),
            const SizedBox(width: 4),
            Text(label,
                style: SaText.caption.copyWith(
                    fontSize: 11.5, color: SaColors.onAccent, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: SaText.titleS.copyWith(fontSize: 14.5)),
        const SizedBox(width: 6),
        Text('$count', style: SaText.mono(fontSize: 11, color: SaColors.accentTeal)),
      ],
    );
  }

  Widget _avatar(String? url, {double size = 38, bool dashed = false}) {
    final Widget inner = ClipOval(
      child: (url ?? '').isNotEmpty
          ? CachedNetworkImage(imageUrl: url!, width: size - 4, height: size - 4, fit: BoxFit.cover)
          : SizedBox(
              width: size - 4,
              height: size - 4,
              child: ColoredBox(
                  color: SaColors.surfaceElevated,
                  child: Icon(Icons.person, size: 18, color: SaColors.textTertiary)),
            ),
    );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: dashed ? SaColors.warn.withOpacity(0.7) : SaColors.borderStrong,
          width: 1.2,
        ),
      ),
      child: inner,
    );
  }

  Widget _personRow(BoardWeatherListData p) {
    final String id = p.custId?.toString() ?? '';
    final bool member = _isMember(id);
    final bool invited = _isInvited(id);
    final bool sending = _sending.contains(id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _avatar(p.profilePath),
          const SizedBox(width: 10),
          Expanded(
            child: Text(p.nickNm ?? p.custNm ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: SaText.bodyMedium.copyWith(fontSize: 13.5)),
          ),
          if (member)
            Text('멤버', style: SaText.mono(fontSize: 10))
          else if (invited)
            Text('초대됨', style: SaText.mono(fontSize: 10, color: SaColors.warn))
          else if (sending)
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))
          else
            GestureDetector(
              onTap: () => _invitePerson(id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: SaColors.accentTeal, width: 1.2),
                ),
                child: Text('초대',
                    style: SaText.caption.copyWith(fontSize: 11.5, color: SaColors.accentTeal, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _memberRow(CommunityMemberData m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _avatar(m.profilePath),
          const SizedBox(width: 10),
          Expanded(
            child: Text(m.nickNm ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: SaText.bodyMedium.copyWith(fontSize: 13.5)),
          ),
          Text(m.isOwner ? '방장' : (m.isManager ? '매니저' : '멤버'),
              style: SaText.mono(fontSize: 10, color: m.isManager ? SaColors.accentTeal : SaColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _pendingRow(CommunityMemberData m) {
    final String id = m.custId;
    final bool sending = _sending.contains(id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _avatar(m.profilePath, dashed: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.nickNm ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: SaText.bodyMedium.copyWith(fontSize: 13.5)),
                Text('초대 보냄', style: SaText.mono(fontSize: 9.5, color: SaColors.warn)),
              ],
            ),
          ),
          sending
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal))
              : GestureDetector(
                  onTap: () => _invitePerson(id, resend: true),
                  child: Text('다시 보내기',
                      style: SaText.caption.copyWith(fontSize: 11.5, color: SaColors.textSecondary)),
                ),
        ],
      ),
    );
  }
}
