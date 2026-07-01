import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/community/data/community_data.dart';

/// 업로드(영상/사진 등록) 화면에서 "어느 앨범에 올릴지" 고르는 셀렉터.
/// - null = 선택 안함(전체 피드)
/// - 값   = 해당 앨범(community)
class AlbumTargetSelector extends StatefulWidget {
  const AlbumTargetSelector({
    super.key,
    required this.selectedCommunityId,
    required this.onChanged,
    this.dark = false,
  });

  final int? selectedCommunityId;
  final ValueChanged<CommunityData?> onChanged;
  final bool dark; // 다크 배경(사진 등록 화면)용

  @override
  State<AlbumTargetSelector> createState() => _AlbumTargetSelectorState();
}

class _AlbumTargetSelectorState extends State<AlbumTargetSelector> {
  List<CommunityData> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final albums = await CommunityRepo().getMyCommunities();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  CommunityData? get _selected {
    final id = widget.selectedCommunityId;
    if (id == null) return null;
    for (final a in _albums) {
      if (a.communityId == id) return a;
    }
    return null;
  }

  Future<void> _pick() async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E3EA), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                const Text('어디에 올릴까요?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 14),
                _sheetTile(
                  ctx,
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFEFF1F6), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.public, color: Color(0xFF7A8291)),
                  ),
                  title: '전체 피드',
                  subtitle: '앨범 없이 모두에게 공개',
                  selected: widget.selectedCommunityId == null,
                  onTap: () => Navigator.of(ctx).pop('__none__'),
                ),
                if (_albums.isNotEmpty) const Divider(height: 20),
                if (_albums.isEmpty && !_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('참여한 앨범이 없어요. 라운지에서 앨범을 만들어보세요.',
                        textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9AA3B2), fontSize: 12.5)),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _albums.map((a) => _sheetTile(
                      ctx,
                      leading: _albumThumb(a, 44),
                      title: a.name,
                      subtitle: '멤버 ${a.memberCnt}명',
                      selected: widget.selectedCommunityId == a.communityId,
                      onTap: () => Navigator.of(ctx).pop(a),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null) return; // 그냥 닫음
    if (result == '__none__') {
      widget.onChanged(null);
    } else if (result is CommunityData) {
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    final isNone = widget.selectedCommunityId == null;
    final dark = widget.dark;

    final Color bg = dark
        ? (isNone ? const Color(0xFF20242E) : const Color(0xFF1E2A44))
        : (isNone ? Colors.white : const Color(0xFFF1F5FF));
    final Color border = dark
        ? (isNone ? const Color(0xFF2C313D) : const Color(0xFF35507F))
        : (isNone ? const Color(0xFFE6E8EF) : const Color(0xFFD6E0FA));
    final Color accent = dark ? const Color(0xFF6AA0F0) : const Color(0xFF3B6FE0);
    final Color valueColor = isNone ? (dark ? const Color(0xFFF1F4F9) : Colors.black87) : accent;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _loading ? null : _pick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(isNone ? Icons.public : Icons.photo_album, size: 20, color: isNone ? (dark ? const Color(0xFF9AA3B2) : const Color(0xFF7A8291)) : accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('올릴 앨범', style: TextStyle(fontSize: 11.5, color: Color(0xFF9AA3B2), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    _loading ? '불러오는 중…' : (isNone ? '전체 피드' : (sel?.name ?? '선택한 앨범')),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: valueColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: dark ? const Color(0xFF6B7280) : const Color(0xFFB6BCC8)),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(BuildContext ctx,
      {required Widget leading, required String title, required String subtitle, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2))),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFF3B6FE0)),
          ],
        ),
      ),
    );
  }

  Widget _albumThumb(CommunityData a, double size) {
    final radius = BorderRadius.circular(12);
    if (a.imageUrl != null && a.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(imageUrl: a.imageUrl!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(colors: [Color(0xFF5B8DEF), Color(0xFF3B6FE0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(a.name.isNotEmpty ? a.name.characters.first : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
