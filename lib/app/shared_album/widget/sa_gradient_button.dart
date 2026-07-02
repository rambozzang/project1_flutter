import 'package:flutter/material.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';

/// teal→blue 그라디언트 pill 버튼 (주요 액션·FAB).
/// glow=true면 teal 글로우 그림자(1d "＋ 올리기" FAB 등).
class SaGradientButton extends StatelessWidget {
  const SaGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 40,
    this.glow = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;

  /// PhosphorIcon 등 아무 위젯(색은 SaColors.onAccent 권장, 크기 16~18).
  final Widget? icon;
  final double height;
  final bool glow;

  /// true면 부모 폭에 맞춤(하단 CTA), false면 내용 크기(pill).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height * 0.55),
        decoration: BoxDecoration(
          gradient: SaColors.primaryGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: SaColors.accentTeal.withOpacity(0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: SaText.titleS.copyWith(
                fontSize: height >= 48 ? 15.5 : 14,
                color: SaColors.onAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
