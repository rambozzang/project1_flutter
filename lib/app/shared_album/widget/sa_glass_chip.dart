import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';

/// 글래스(반투명 블러) 칩 — 썸네일 위 날씨/위치/미디어수 표기용.
/// 예: [☔ 비 24°] [+124] [서울 강남 · 비 24° · 습도 88%]
class SaGlassChip extends StatelessWidget {
  const SaGlassChip({
    super.key,
    required this.label,
    this.icon,
    this.mono = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final String label;

  /// PhosphorIcon 등 아무 위젯. 크기는 호출부에서 12~14 권장.
  final Widget? icon;

  /// true면 Space Mono(수치·태그), false면 Pretendard caption.
  final bool mono;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // 사진 위 다크 글래스 — 라이트 모드와 무관하게 흰 텍스트/화이트 보더 고정
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: SaColorsDark.borderStrong, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: mono
                    ? SaText.mono(fontSize: 11, color: Colors.white)
                    : SaText.caption.copyWith(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
