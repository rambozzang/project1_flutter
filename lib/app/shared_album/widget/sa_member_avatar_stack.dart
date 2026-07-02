import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';

/// 멤버 아바타 겹침 스택 — 28px 원, -10px 겹침, 마지막에 "+N".
/// avatarUrls는 표시할 앞쪽 몇 명(3~4명 권장), extraCount는 "+N"에 들어갈 나머지 수.
class SaMemberAvatarStack extends StatelessWidget {
  const SaMemberAvatarStack({
    super.key,
    required this.avatarUrls,
    this.extraCount = 0,
    this.size = 28,
    this.overlap = 10,
    this.ringColor = SaColors.surface,
  });

  final List<String> avatarUrls;
  final int extraCount;
  final double size;
  final double overlap;

  /// 아바타 테두리(겹침 구분) 색 — 올려지는 배경(surface/카드)과 맞춘다.
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final int n = avatarUrls.length + (extraCount > 0 ? 1 : 0);
    if (n == 0) return const SizedBox.shrink();
    final double width = size + (n - 1) * (size - overlap);
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < avatarUrls.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: _circle(
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrls[i],
                    width: size - 4,
                    height: size - 4,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ColoredBox(color: SaColors.surfaceElevated),
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: SaColors.surfaceElevated,
                      child: Icon(Icons.person, size: 14, color: SaColors.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: avatarUrls.length * (size - overlap),
              child: _circle(
                child: ClipOval(
                  child: Container(
                    width: size - 4,
                    height: size - 4,
                    color: SaColors.surfaceElevated,
                    alignment: Alignment.center,
                    child: Text(
                      '+$extraCount',
                      style: SaText.mono(fontSize: 9, color: SaColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circle({required Widget child}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      alignment: Alignment.center,
      child: child,
    );
  }
}
