import 'package:flutter/material.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';

/// pill(999) 액션 버튼 — [SaGradientButton](주요 액션 전용, teal→blue 고정)의 짝.
///
/// 토글형 액션(팔로우/차단 등)처럼 **강조 정도가 상태에 따라 바뀌는** 버튼에 쓴다.
///   - [solid] = true  → [accent] 색 단색 채움 + 흰 글씨(지금 상태를 눈에 띄게 알림)
///   - [solid] = false → 옅은 틴트 배경 + [accent] 색 글씨·테두리(차분한 보조 상태)
/// 색만 다를 뿐 모양(pill, 높이, 그림자 없음)은 항상 같아서 두 상태를 오가도 버튼이
/// 덜컹거리지 않는다.
class SaPillButton extends StatelessWidget {
  const SaPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.solid,
    required this.onTap,
    this.accent = SaColorsLight.accentTeal, // 기본값은 const 라 SaColorsLight를 직접 참조
    this.height = 40,
  });

  final String label;
  final IconData icon;

  /// true=단색 채움(주목), false=옅은 틴트+테두리(차분).
  final bool solid;
  final VoidCallback onTap;

  /// 상태 강조색. 팔로우=accentTeal(기본), 차단처럼 위험 계열이면 SaColors.warn을 넘긴다.
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color fg = solid ? SaColors.onAccent : accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height * 0.5),
        decoration: BoxDecoration(
          color: solid ? accent : accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: solid ? null : Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: SaText.caption.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
