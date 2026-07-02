import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/app/shared_album/widget/sa_album_card.dart';
import 'package:project1/app/shared_album/widget/sa_new_badge.dart';

/// 홈(1c) — 모자이크 그리드용 컴팩트 카드.
/// 이미지(tall 150 / short 106) + 제목(700/14) + 멤버/미디어 아이콘 스탯.
/// 앨범이 많은 파워유저용 밀도 높은 보기 방식.
class SaAlbumMosaicCard extends StatelessWidget {
  const SaAlbumMosaicCard({
    super.key,
    required this.data,
    required this.tall,
    required this.onTap,
  });

  final SaAlbumCardData data;

  /// true=이미지 150, false=106 (스태거드 리듬용)
  final bool tall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = data.community;
    final String? thumb = data.thumbs.isNotEmpty ? data.thumbs.first : c.imageUrl;
    final double imageH = tall ? 150 : 106;
    return Container(
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SaColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageH,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb != null && thumb.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => DecoratedBox(
                          decoration: BoxDecoration(gradient: SaWeatherGradients.of(_gradientKey(c.communityId)))),
                      errorWidget: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(gradient: SaWeatherGradients.of(_gradientKey(c.communityId)))),
                    )
                  else
                    DecoratedBox(
                        decoration: BoxDecoration(gradient: SaWeatherGradients.of(_gradientKey(c.communityId)))),
                  if (data.newCount > 0)
                    Positioned(left: 8, top: 8, child: SaNewBadge(count: data.newCount)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SaText.titleS.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const PhosphorIcon(PhosphorIconsFill.users, size: 12, color: SaColors.textTertiary),
                      const SizedBox(width: 4),
                      Text('${c.memberCnt}', style: SaText.mono(fontSize: 10)),
                      const SizedBox(width: 10),
                      const PhosphorIcon(PhosphorIconsFill.play, size: 11, color: SaColors.textTertiary),
                      const SizedBox(width: 4),
                      Text('${c.mediaCnt}', style: SaText.mono(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _gradientKey(int id) {
    const keys = ['rain', 'sunset', 'storm', 'night', 'aurora', 'golden', 'fog', 'snow'];
    return keys[id % keys.length];
  }
}
