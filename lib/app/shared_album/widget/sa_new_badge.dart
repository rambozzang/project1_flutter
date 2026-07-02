import 'package:flutter/material.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';

/// "안 본 새 콘텐츠" 뱃지 — pink 필 + 2.4s 무한 확산 pulse 링.
/// count가 0 이하이면 아무것도 그리지 않는다(열람 처리 시 자연 소멸).
class SaNewBadge extends StatefulWidget {
  const SaNewBadge({super.key, required this.count});

  final int count;

  @override
  State<SaNewBadge> createState() => _SaNewBadgeState();
}

class _SaNewBadgeState extends State<SaNewBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 확산 링: 스케일 1→1.6, 불투명도 0.55→0 (ease-in-out)
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final double t = Curves.easeInOut.transform(_pulse.value);
            return Transform.scale(
              scale: 1.0 + 0.6 * t,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SaColors.accentPink.withOpacity(0.55 * (1 - t)),
                    width: 1.5,
                  ),
                ),
                // 링 크기의 기준이 되도록 본체와 같은 텍스트를 투명하게 깔아둔다
                child: Opacity(
                  opacity: 0,
                  child: Text('NEW ${widget.count}', style: SaText.mono(fontSize: 10)),
                ),
              ),
            );
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: SaColors.accentPink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'NEW ${widget.count}',
            style: SaText.mono(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// 제목 옆 등에 붙는 미니 "안 봄" 점 (1b MORE ALBUMS 행 등)
class SaNewDot extends StatelessWidget {
  const SaNewDot({super.key, this.size = 7});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SaColors.accentPink,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: SaColors.accentPink.withOpacity(0.45), blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );
  }
}
