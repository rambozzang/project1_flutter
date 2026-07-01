import 'package:flutter/material.dart';
import 'package:project1/config/app_color.dart';
import 'package:project1/repo/feel/data/feel_ranking_data.dart';

class FeelSelectorWidget extends StatefulWidget {
  final String? selectedFeelCd;
  final void Function(String? feelCd) onSelected;

  /// 어두운 배경(사진 등록 화면 등) 위에 올릴 때 제목 텍스트 색을 밝게 처리한다.
  final bool dark;

  const FeelSelectorWidget({
    super.key,
    this.selectedFeelCd,
    required this.onSelected,
    this.dark = false,
  });

  @override
  State<FeelSelectorWidget> createState() => _FeelSelectorWidgetState();
}

class _FeelSelectorWidgetState extends State<FeelSelectorWidget> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedFeelCd;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '지금 날씨 어때요?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.dark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeelCode.codes.entries.map((entry) {
            final isSelected = _selected == entry.key;
            return GestureDetector(
              onTap: () {
                // 이미 선택된 태그를 다시 누르면 선택 해제(태그 없음)한다.
                final next = isSelected ? null : entry.key;
                setState(() => _selected = next);
                widget.onSelected(next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColor.primaryColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColor.primaryColor : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.value['emoji']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.value['name']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
