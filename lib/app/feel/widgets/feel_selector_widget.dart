import 'package:flutter/material.dart';
import 'package:project1/repo/feel/data/feel_ranking_data.dart';

class FeelSelectorWidget extends StatefulWidget {
  final String? selectedFeelCd;
  final void Function(String feelCd) onSelected;

  const FeelSelectorWidget({
    super.key,
    this.selectedFeelCd,
    required this.onSelected,
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
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '지금 날씨 어때요?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeelCode.codes.entries.map((entry) {
            final isSelected = _selected == entry.key;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = entry.key);
                widget.onSelected(entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
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
