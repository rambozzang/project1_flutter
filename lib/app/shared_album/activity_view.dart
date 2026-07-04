import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/repo/media/activity_repo.dart';
import 'package:project1/utils/utils.dart';

/// 2d · 활동 피드 — 업로드·댓글·반응·가입 소식(시간 그룹: 오늘/이번 주/이전).
class ActivityView extends StatefulWidget {
  const ActivityView({super.key, required this.communityId, required this.onOpenBoard});

  final int communityId;
  final void Function(int boardId) onOpenBoard;

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  final ActivityRepo _repo = ActivityRepo();
  List<Map<String, dynamic>> _acts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.feed(widget.communityId);
    if (mounted) setState(() {
      _acts = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.accentTeal));
    }
    if (_acts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('아직 소식이 없어요.\n멤버가 사진을 올리거나 반응하면 여기에 모여요.',
              textAlign: TextAlign.center, style: SaText.body),
        ),
      );
    }

    // 시간 그룹핑
    final now = DateTime.now();
    final today = <Map<String, dynamic>>[];
    final week = <Map<String, dynamic>>[];
    final older = <Map<String, dynamic>>[];
    for (final a in _acts) {
      final dt = DateTime.tryParse((a['crtDtm'] ?? '').toString().replaceFirst(' ', 'T'));
      if (dt == null) {
        older.add(a);
        continue;
      }
      final diff = now.difference(dt);
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        today.add(a);
      } else if (diff.inDays < 7) {
        week.add(a);
      } else {
        older.add(a);
      }
    }

    return RefreshIndicator(
      color: SaColors.accentTeal,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (today.isNotEmpty) ...[_groupHeader('오늘'), ...today.map(_row)],
          if (week.isNotEmpty) ...[_groupHeader('이번 주'), ...week.map(_row)],
          if (older.isNotEmpty) ...[_groupHeader('이전'), ...older.map(_row)],
        ],
      ),
    );
  }

  Widget _groupHeader(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
        child: Text(t, style: SaText.mono(fontSize: 12, color: SaColors.textSecondary, letterSpacingEm: 0.1)),
      );

  Widget _row(Map<String, dynamic> a) {
    final String type = a['type']?.toString() ?? '';
    final String nick = a['actorNick']?.toString() ?? '';
    final String profile = a['actorProfile']?.toString() ?? '';
    final String thumb = a['thumbnail']?.toString() ?? '';
    final String extra = a['extra']?.toString() ?? '';
    final int? boardId = (a['boardId'] as num?)?.toInt();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: boardId != null ? () => widget.onOpenBoard(boardId) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatarWithBadge(profile, type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RichLine(nick: nick, action: _actionText(type)),
                  if (type == 'comment' && extra.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('"$extra"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SaText.body.copyWith(fontSize: 12.5, fontStyle: FontStyle.italic, color: SaColors.textSecondary)),
                  ],
                  const SizedBox(height: 3),
                  Text(Utils.timeage((a['crtDtm'] ?? '').toString()), style: SaText.mono(fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (thumb.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: thumb.endsWith('thumbnail.gif') ? thumb.replaceAll('thumbnail.gif', 'thumbnail.jpg') : thumb,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(width: 44, height: 44, color: SaColors.surfaceElevated),
                  errorWidget: (_, __, ___) => Container(width: 44, height: 44, color: SaColors.surfaceElevated),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatarWithBadge(String profile, String type) {
    final (IconData icon, Color color) = _badge(type);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          ClipOval(
            child: profile.isNotEmpty
                ? CachedNetworkImage(imageUrl: profile, width: 42, height: 42, fit: BoxFit.cover)
                : Container(width: 42, height: 42, color: SaColors.surfaceElevated, child: Icon(Icons.person, size: 20, color: SaColors.textTertiary)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: SaColors.bgBase, width: 2)),
              child: PhosphorIcon(icon, size: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _badge(String type) {
    switch (type) {
      case 'upload':
        return (PhosphorIconsBold.arrowUp, SaColors.accentTeal);
      case 'comment':
        return (PhosphorIconsFill.chatCircle, SaColorsDark.accentBlue);
      case 'like':
        return (PhosphorIconsFill.heart, SaColorsDark.accentPink);
      case 'join':
        return (PhosphorIconsBold.userPlus, const Color(0xFF8B5CF6));
      default:
        return (PhosphorIconsFill.sparkle, SaColors.accentTeal);
    }
  }

  String _actionText(String type) {
    switch (type) {
      case 'upload':
        return '님이 새 사진·영상을 올렸어요';
      case 'comment':
        return '님이 댓글을 남겼어요';
      case 'like':
        return '님이 반응을 남겼어요';
      case 'join':
        return '님이 앨범에 참여했어요 🎉';
      default:
        return '님의 소식';
    }
  }
}

class _RichLine extends StatelessWidget {
  const _RichLine({required this.nick, required this.action});
  final String nick;
  final String action;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: nick, style: SaText.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800)),
          TextSpan(text: action, style: SaText.body.copyWith(fontSize: 13.5)),
        ],
      ),
    );
  }
}
