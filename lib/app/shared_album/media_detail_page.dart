import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/app/videocomment/comment_item_widget.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_comment_data.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/board/data/board_comment_update_req_data.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/bbs/comment_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/media/media_interaction_repo.dart';
import 'package:project1/utils/utils.dart';

/// 2b · 미디어 상세 — 미디어 + 촬영일시·날씨칩 + 캡션 + 이모지 반응 + 관람 이력 + 댓글.
/// 댓글 리스트는 페이지에 인라인으로 표시하고 하단 입력 바에서 바로 작성한다(시트 미사용).
/// 영상은 탭 시 몰입뷰로 재생.
class MediaDetailPage extends StatefulWidget {
  const MediaDetailPage({super.key});

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  final MediaInteractionRepo _repo = MediaInteractionRepo();

  late final BoardWeatherListData _item;
  late final int _communityId;
  late final String _albumName;
  List<BoardWeatherListData> _items = [];
  int _index = 0;

  Map<String, int> _counts = {};
  List<String> _mine = [];
  List<Map<String, dynamic>> _viewers = [];
  bool _loading = true;

  // 댓글(인라인) — 페이지 내에서 바로 보고 쓴다(시트 미사용).
  List<BoardCommentResData> _comments = [];
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _sending = false;
  // 답글(대댓글) 작성 대상 — null이면 새 원댓글, 있으면 그 댓글의 대댓글로 저장.
  BoardCommentResData? _replyTarget;
  // 댓글 수정 대상 — null이 아니면 전송 시 새 저장 대신 수정(update)으로 처리.
  // 수정과 답글은 상호배타 — 한쪽을 켜면 다른쪽은 해제한다.
  BoardCommentResData? _editTarget;

  static const List<String> _emojiPalette = ['❤️', '😍', '👏', '🥹', '😂', '🔥'];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _item = args['item'] as BoardWeatherListData;
    _communityId = (args['communityId'] as num?)?.toInt() ?? 0;
    _albumName = args['albumName']?.toString() ?? '앨범';
    _items = (args['items'] as List<BoardWeatherListData>?) ?? [_item];
    _index = (args['index'] as num?)?.toInt() ?? 0;
    _repo.recordView(_item.boardId ?? 0); // 관람 기록(누가 봤나)
    _load();
    _loadComments();
  }

  Future<void> _load() async {
    final bid = _item.boardId ?? 0;
    final results = await Future.wait([_repo.reactions(bid), _repo.viewers(bid)]);
    if (!mounted) return;
    final r = results[0] as Map<String, dynamic>;
    setState(() {
      _counts = Map<String, int>.from((r['counts'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {});
      _mine = List<String>.from((r['mine'] as List?)?.map((e) => e.toString()) ?? []);
      _viewers = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  Future<void> _toggle(String emoji) async {
    // 낙관적 갱신
    setState(() {
      if (_mine.contains(emoji)) {
        _mine.remove(emoji);
        _counts[emoji] = ((_counts[emoji] ?? 1) - 1).clamp(0, 1 << 30);
        if (_counts[emoji] == 0) _counts.remove(emoji);
      } else {
        _mine.add(emoji);
        _counts[emoji] = (_counts[emoji] ?? 0) + 1;
      }
    });
    final res = await _repo.toggle(_item.boardId ?? 0, emoji);
    if (res != null && mounted) {
      setState(() {
        _counts = Map<String, int>.from((res['counts'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {});
        _mine = List<String>.from((res['mine'] as List?)?.map((e) => e.toString()) ?? []);
      });
    }
  }

  bool get _isVideo => _item.typeDtCd == 'V';

  // 멀티 이미지 현재 페이지(상세 히어로 가로 스와이프)
  int _heroIndex = 0;

  String get _mainImage {
    if (_isVideo) {
      String t = _item.thumbnailPath ?? '';
      if (t.endsWith('thumbnail.gif')) t = t.replaceAll('thumbnail.gif', 'thumbnail.jpg');
      return t;
    }
    if (_item.imageUrls?.isNotEmpty ?? false) return _item.imageUrls!.first;
    return _item.thumbnailPath ?? '';
  }

  void _openImmersive() {
    Get.toNamed('/AlbumImmersivePage', arguments: {
      'communityId': _communityId,
      'albumName': _albumName,
      'items': _items,
      'initialIndex': _index,
    });
  }

  Future<void> _loadComments() async {
    try {
      final ResData res = await BoardRepo().searchComment((_item.boardId ?? 0).toString(), 0, 500);
      if (res.code != '00') return;
      final List<BoardCommentResData> list =
          ((res.data) as List).map((d) => BoardCommentResData.fromMap(d)).toList();
      if (!mounted) return;
      // 백엔드가 이미 스레드 순서(원댓글 바로 뒤에 대댓글)로 정렬해 주므로 클라이언트 재정렬 금지.
      setState(() => _comments = list);
    } catch (_) {
      // 무시 — 재시도 가능(새로고침 등)
    }
  }

  // 답글 작성 시작 — 부모 댓글을 설정하고 입력창에 '@닉네임 '을 채운 뒤 포커스.
  void _startReply(BoardCommentResData parent) {
    setState(() {
      _editTarget = null; // 답글 시작 시 수정 모드 해제
      _replyTarget = parent;
      _replyController.text = '@${parent.nickNm ?? ''} ';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 직전 전송에서 키보드만 숨고 포커스가 입력창에 남아있으면 requestFocus가 no-op이라
      // 키보드가 안 올라온다 → 이미 포커스면 키보드를 명시적으로 다시 띄운다.
      if (_replyFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } else {
        _replyFocusNode.requestFocus();
      }
      _replyController.selection =
          TextSelection.fromPosition(TextPosition(offset: _replyController.text.length));
    });
  }

  void _cancelReply() {
    setState(() {
      _replyTarget = null;
      _replyController.clear();
    });
  }

  // 댓글 수정 시작 — 입력창에 기존 내용을 채우고 수정 모드로 전환한다.
  void _startEdit(BoardCommentResData c) {
    setState(() {
      _replyTarget = null; // 수정 시작 시 답글 모드 해제
      _editTarget = c;
      _replyController.text = c.contents ?? '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_replyFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } else {
        _replyFocusNode.requestFocus();
      }
      _replyController.selection =
          TextSelection.fromPosition(TextPosition(offset: _replyController.text.length));
    });
  }

  void _cancelEdit() {
    setState(() {
      _editTarget = null;
      _replyController.clear();
    });
    _replyFocusNode.unfocus();
  }

  // 댓글 삭제 — 확인 후 백엔드 삭제(스카이라운지와 동일 엔드포인트) → 목록 새로고침.
  Future<void> _deleteComment(BoardCommentResData c) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('댓글 삭제', style: SaText.titleS),
        content: Text('이 댓글을 삭제할까요?', style: SaText.body.copyWith(color: SaColors.textSecondary)),
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
      final ResData res = await CommentRepo().deleteComment((c.boardId ?? 0).toString());
      if (res.code == '00') {
        // 수정 중이던 댓글을 삭제하면 수정 모드 해제
        if (_editTarget?.boardId == c.boardId) _cancelEdit();
        await _loadComments();
      } else if (mounted) {
        Utils.alert(res.msg.toString());
      }
    } catch (_) {
      if (mounted) Utils.alert('댓글 삭제 중 오류가 발생했습니다.');
    }
  }

  Future<void> _sendComment() async {
    final String text = _replyController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      // 수정 모드 — 저장 대신 update(스카이라운지와 동일 엔드포인트). 앨범 댓글은 이미지가 없어 fileListData는 비움.
      if (_editTarget != null) {
        final BoardCommentUpdateReqData data = BoardCommentUpdateReqData()
          ..boardId = (_editTarget!.boardId ?? 0).toString()
          ..contents = text
          ..delYn = 'N'
          ..hideYn = 'N'
          ..fileListData = [];
        final ResData res = await CommentRepo().update(data);
        if (res.code == '00') {
          _replyController.clear();
          _editTarget = null;
          setState(() {}); // 수정 배너 즉시 제거
          _replyFocusNode.unfocus();
          await _loadComments();
        } else if (mounted) {
          Utils.alert(res.msg.toString());
        }
        return;
      }

      final String typeCd = _item.typeDtCd ?? 'V';
      final int bid = _item.boardId ?? 0;
      // 답글이면 부모 댓글의 depthNo/sortNo/boardId를 넘긴다 — 백엔드가 자식 정렬값을 다시 계산.
      // (스카이라운지 bbs_comments_cntr 와 동일 방식. 원댓글은 0/0.)
      int depthNo = 0;
      int sortNo = 0;
      int parentId = bid;
      if (_replyTarget != null) {
        depthNo = _replyTarget!.depthNo ?? 0;
        sortNo = _replyTarget!.sortNo ?? 0;
        parentId = _replyTarget!.boardId ?? bid;
      }
      final BoardCommentData data = BoardCommentData()
        ..custId = AuthCntr.to.resLoginData.value.custId.toString()
        ..parentId = parentId
        ..rootId = bid
        ..contents = text
        ..depthNo = depthNo // 백에서 다시 계산
        ..sortNo = sortNo // 백에서 다시 계산
        ..typeCd = typeCd
        ..typeDtCd = typeCd
        ..fileListData = [];
      final ResData res = await CommentRepo().saveComment(data);
      if (res.code == '00') {
        _replyController.clear();
        _replyTarget = null;
        setState(() {}); // 답글 배너 즉시 제거
        // 키보드 내리기 — hide만 하면 포커스가 남아 다음 답글 탭에서 키보드가 안 뜬다.
        _replyFocusNode.unfocus();
        await _loadComments();
      } else if (mounted) {
        Utils.alert(res.msg.toString());
      }
    } catch (_) {
      if (mounted) Utils.alert('다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  String _capturedLabel() {
    final dt = DateTime.tryParse((_item.crtDtm ?? '').replaceFirst(' ', 'T'));
    if (dt == null) return '';
    const wd = ['월', '화', '수', '목', '금', '토', '일'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}월 ${dt.day}일 ${wd[dt.weekday - 1]} $h:$m';
  }

  String _weatherLine() {
    final parts = [
      if ((_item.location ?? _item.city ?? '').isNotEmpty) (_item.location ?? _item.city)!,
      if ((_item.weatherInfo ?? '').isNotEmpty) '${_item.weatherInfo!.split('.').first} ${_item.currentTemp ?? ''}°',
      if ((_item.humidity ?? '').isNotEmpty) '습도 ${_item.humidity}%',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    SaColors.syncWith(context);
    final pad = MediaQuery.of(context).viewPadding;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: SaColors.isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: SaColors.isLight ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SaColors.bgBase,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 24 + pad.bottom),
                children: [
                  _buildMedia(pad.top),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((_item.contents ?? '').isNotEmpty) ...[
                          Text(_item.contents!, style: SaText.body.copyWith(fontSize: 15, height: 1.6, color: SaColors.textPrimary)),
                          const SizedBox(height: 16),
                        ],
                        _buildReactionBar(),
                        const SizedBox(height: 16),
                        _buildViewedBy(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  _buildCommentSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_replyTarget != null) _buildReplyBanner(),
            if (_editTarget != null) _buildEditBanner(),
            _buildCommentBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(double topPad) {
    return SizedBox(
      height: 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 사진 게시물 멀티 이미지: 가로 스와이프(첫 장만 보이던 버그 수정)
          if (!_isVideo && (_item.imageUrls?.length ?? 0) > 1)
            PageView.builder(
              itemCount: _item.imageUrls!.length,
              onPageChanged: (i) => setState(() => _heroIndex = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: _item.imageUrls![i],
                memCacheWidth: 1080,
                fit: BoxFit.cover,
                placeholder: (_, __) => DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of('night'))),
                errorWidget: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of('night'))),
              ),
            )
          else if (_mainImage.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _mainImage,
              memCacheWidth: 1080,
              fit: BoxFit.cover,
              placeholder: (_, __) => DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of('night'))),
              errorWidget: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of('night'))),
            )
          else
            DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of('night'))),

          // 멀티 이미지 n/N 카운터
          if (!_isVideo && (_item.imageUrls?.length ?? 0) > 1)
            Positioned(
              top: topPad + 10,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(999)),
                child: Text('${_heroIndex + 1}/${_item.imageUrls!.length}',
                    style: SaText.mono(fontSize: 11, color: Colors.white)),
              ),
            ),

          // 상/하 스크림
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent, Color(0x99000000)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 상단 미디어 어디를 눌러도 재생/열람(중앙 버튼 외 전체 영역)
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _openImmersive),
          ),

          // 영상 재생 버튼
          if (_isVideo)
            Center(
              child: GestureDetector(
                onTap: _openImmersive,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5))),
                  child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                ),
              ),
            ),

          // 상단 back
          Positioned(
            left: 14,
            top: topPad + 8,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                child: const PhosphorIcon(PhosphorIconsBold.caretLeft, size: 16, color: Colors.white),
              ),
            ),
          ),

          // 하단 업로더 + 촬영일시 + 날씨/위치
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: (_item.profilePath ?? '').isNotEmpty
                          ? CachedNetworkImage(imageUrl: _item.profilePath!, width: 30, height: 30, fit: BoxFit.cover)
                          : Container(width: 30, height: 30, color: Colors.white24, child: const Icon(Icons.person, size: 16, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Text(_item.nickNm ?? _item.custNm ?? '',
                        style: SaText.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(_capturedLabel(), style: SaText.mono(fontSize: 10, color: Colors.white70)),
                  ],
                ),
                if (_weatherLine().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PhosphorIcon(PhosphorIconsFill.mapPin, size: 11, color: Colors.white),
                        const SizedBox(width: 5),
                        Flexible(child: Text(_weatherLine(), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: SaText.mono(fontSize: 10, color: Colors.white))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final e in _counts.entries)
          GestureDetector(
            onTap: () => _toggle(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: _mine.contains(e.key) ? SaColors.accentTeal.withOpacity(0.16) : SaColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _mine.contains(e.key) ? SaColors.accentTeal : SaColors.border),
              ),
              child: Text('${e.key} ${e.value}', style: SaText.bodyMedium.copyWith(fontSize: 13)),
            ),
          ),
        // 반응 추가
        GestureDetector(
          onTap: _showEmojiPicker,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: SaColors.surface, shape: BoxShape.circle, border: Border.all(color: SaColors.border)),
            child: PhosphorIcon(PhosphorIconsBold.smiley, size: 17, color: SaColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              for (final e in _emojiPalette)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _toggle(e);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewedBy() {
    final int n = _viewers.length;
    return GestureDetector(
      onTap: n == 0 ? null : _showViewers,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SaColors.border),
        ),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsFill.eye, size: 18, color: SaColors.textSecondary),
            const SizedBox(width: 10),
            if (n > 0) _viewerAvatars(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(n == 0 ? '아직 아무도 안 봤어요' : '멤버 $n명이 봤어요',
                  style: SaText.bodyMedium.copyWith(fontSize: 13)),
            ),
            if (n > 0) PhosphorIcon(PhosphorIconsBold.caretRight, size: 14, color: SaColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _viewerAvatars() {
    final show = _viewers.take(4).toList();
    return SizedBox(
      width: 26.0 + (show.length - 1) * 18,
      height: 26,
      child: Stack(
        children: [
          for (int i = 0; i < show.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: SaColors.surface,
                    border: Border.all(color: SaColors.surface, width: 2)),
                child: ClipOval(
                  child: (show[i]['profilePath']?.toString() ?? '').isNotEmpty
                      ? CachedNetworkImage(imageUrl: show[i]['profilePath'].toString(), fit: BoxFit.cover)
                      : Container(color: SaColors.surfaceElevated, child: Icon(Icons.person, size: 13, color: SaColors.textTertiary)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showViewers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('본 사람 ${_viewers.length}', style: SaText.titleS)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final v in _viewers)
                    ListTile(
                      leading: ClipOval(
                        child: (v['profilePath']?.toString() ?? '').isNotEmpty
                            ? CachedNetworkImage(imageUrl: v['profilePath'].toString(), width: 40, height: 40, fit: BoxFit.cover)
                            : Container(width: 40, height: 40, color: SaColors.surfaceElevated, child: Icon(Icons.person, color: SaColors.textTertiary)),
                      ),
                      title: Text(v['nickNm']?.toString() ?? '', style: SaText.bodyMedium),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    final int n = _comments.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
          child: Row(
            children: [
              Text('댓글', style: SaText.titleS),
              const SizedBox(width: 6),
              Text('$n', style: SaText.bodyMedium.copyWith(color: SaColors.textSecondary)),
            ],
          ),
        ),
        if (n == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Text('첫 댓글을 남겨보세요',
                style: SaText.bodyMedium.copyWith(color: SaColors.textTertiary)),
          )
        else
          for (final c in _comments)
            CommentItemWidget(
              boardCommentData: c,
              controller: _replyController,
              focus: _replyFocusNode,
              isDarkTheme: !SaColors.isLight,
              onReply: _startReply,
              onEdit: _startEdit,
              onDelete: _deleteComment,
            ),
      ],
    );
  }

  // 답글 작성 중 표시 바 — 누구에게 답글 중인지 보여주고 취소할 수 있다.
  Widget _buildReplyBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      decoration: BoxDecoration(
        color: SaColors.surface,
        border: Border(top: BorderSide(color: SaColors.border)),
      ),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsRegular.arrowBendUpLeft, size: 14, color: SaColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_replyTarget?.nickNm ?? ''}님에게 답글 작성 중',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SaText.body.copyWith(fontSize: 12.5, color: SaColors.textTertiary),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _cancelReply,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: PhosphorIcon(PhosphorIconsFill.x, size: 14, color: SaColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  // 댓글 수정 중 표시 바 — 수정 모드임을 알리고 취소할 수 있다.
  Widget _buildEditBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      decoration: BoxDecoration(
        color: SaColors.surface,
        border: Border(top: BorderSide(color: SaColors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 14, color: SaColors.accentTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '댓글 수정 중',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SaText.body.copyWith(fontSize: 12.5, color: SaColors.textTertiary),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _cancelEdit,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: PhosphorIcon(PhosphorIconsFill.x, size: 14, color: SaColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentBar() {
    // 시스템 내비게이션 바(3버튼/제스처) 위로 입력창을 올린다.
    // 키보드가 열리면 Scaffold가 body를 줄여 자동으로 밀어올리므로 그때는 추가 여백 없음.
    final double navInset =
        MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + navInset),
      decoration: BoxDecoration(
        color: SaColors.surface,
        border: Border(top: BorderSide(color: SaColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              focusNode: _replyFocusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
              cursorColor: SaColors.accentTeal,
              style: SaText.body.copyWith(fontSize: 14.5, color: SaColors.textPrimary),
              decoration: InputDecoration(
                hintText: _editTarget != null ? '댓글을 수정하세요' : '따뜻한 댓글을 남겨보세요',
                hintStyle: SaText.body.copyWith(fontSize: 14, color: SaColors.textTertiary),
                filled: true,
                fillColor: SaColors.surfaceElevated,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: SaColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: SaColors.accentTeal, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _replyController,
            builder: (context, value, _) {
              final bool hasText = value.text.trim().isNotEmpty;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: (hasText && !_sending) ? _sendComment : null,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasText ? SaColors.accentTeal : SaColors.surfaceElevated,
                    border: Border.all(color: hasText ? SaColors.accentTeal : SaColors.border),
                  ),
                  child: _sending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.onAccent))
                      : (_editTarget != null
                          ? Icon(Icons.check_rounded, size: 20, color: hasText ? SaColors.onAccent : SaColors.textTertiary)
                          : PhosphorIcon(PhosphorIconsFill.paperPlaneTilt,
                              size: 18, color: hasText ? SaColors.onAccent : SaColors.textTertiary)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
