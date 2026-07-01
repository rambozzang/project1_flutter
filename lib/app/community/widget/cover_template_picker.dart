import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'cover_template.dart';

/// 표지 템플릿 그리드 + "직접 사진 선택" 카드.
/// 선택 상태 관리는 부모(Stateful) 위젯이 가지고, 이 위젯은 순수 표시 + 콜백만 담당한다.
class CoverTemplatePicker extends StatelessWidget {
  const CoverTemplatePicker({
    super.key,
    required this.selectedTemplateId,
    required this.isCustomPhotoSelected,
    required this.onSelectTemplate,
    required this.onPickCustomPhoto,
  });

  /// 현재 선택된 템플릿 id (커스텀 사진을 선택했으면 null)
  final String? selectedTemplateId;
  final bool isCustomPhotoSelected;
  final ValueChanged<String> onSelectTemplate;
  final VoidCallback onPickCustomPhoto;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: [
        ...kCoverTemplates.map((t) => _templateCard(t)),
        _customPhotoCard(),
      ],
    );
  }

  Widget _templateCard(CoverTemplate t) {
    final selected = !isCustomPhotoSelected && selectedTemplateId == t.id;
    return GestureDetector(
      onTap: () => onSelectTemplate(t.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFF3B6FE0) : Colors.transparent, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: '${t.imageUrl}?w=200',
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: const Color(0xFFE6E8EF)),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 6, right: 6, bottom: 6,
              child: Text(t.label,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            if (selected)
              const Positioned(
                top: 6, right: 6,
                child: Icon(Icons.check_circle, color: Color(0xFF3B6FE0), size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _customPhotoCard() {
    return GestureDetector(
      onTap: onPickCustomPhoto,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF1F3F8),
          border: Border.all(color: isCustomPhotoSelected ? const Color(0xFF3B6FE0) : const Color(0xFFE6E8EF), width: isCustomPhotoSelected ? 3 : 1),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: isCustomPhotoSelected ? const Color(0xFF3B6FE0) : const Color(0xFF7A8291), size: 26),
            const SizedBox(height: 4),
            Text('직접 사진 선택', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCustomPhotoSelected ? const Color(0xFF3B6FE0) : const Color(0xFF7A8291))),
          ],
        ),
      ),
    );
  }
}
