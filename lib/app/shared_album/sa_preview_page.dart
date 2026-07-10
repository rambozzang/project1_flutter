import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/app/shared_album/widget/sa_glass_chip.dart';
import 'package:project1/app/shared_album/widget/sa_gradient_button.dart';
import 'package:project1/app/shared_album/widget/sa_member_avatar_stack.dart';
import 'package:project1/app/shared_album/widget/sa_new_badge.dart';
import 'package:project1/app/shared_album/widget/sa_overlap_image_stack.dart';

/// 공유앨범 테마·공용 위젯 미리보기 (디버그 전용 — 설정 > 개발 메뉴에서 진입).
/// 화면 구현(1a~) 전에 디자인 토큰과 위젯 룩을 검수하기 위한 페이지.
class SaPreviewPage extends StatelessWidget {
  const SaPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    SaColors.syncWith(context); // 시스템 밝기에 맞춰 다크/라이트 팔레트 동기화
    return Scaffold(
      backgroundColor: SaColors.bgBase,
      appBar: AppBar(
        backgroundColor: SaColors.bgBase,
        elevation: 0,
        iconTheme: IconThemeData(color: SaColors.textPrimary),
        title: Text('공유앨범 위젯 미리보기', style: SaText.titleS),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Typography'),
          Text('우리의 앨범', style: SaText.titleL),
          const SizedBox(height: 4),
          Text('장마의 기록', style: SaText.titleM),
          const SizedBox(height: 4),
          Text('비 오는 날마다 한 컷씩 모으는 우리 동네 하늘', style: SaText.body),
          const SizedBox(height: 4),
          Text('3 ALBUMS · 132 CLIPS', style: SaText.mono(fontSize: 11)),
          const SizedBox(height: 24),

          _section('Weather Gradients'),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: SaWeatherGradients.keys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final key = SaWeatherGradients.keys[i];
                return Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: SaWeatherGradients.byKey[key],
                        shape: BoxShape.circle,
                        border: Border.all(color: SaColors.borderStrong),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(key, style: SaText.mono(fontSize: 9)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          _section('Overlap Image Stack + Overlay (1a 카드 상단)'),
          SaOverlapImageStack(
            gradientKey: 'rain',
            overlay: Stack(
              children: [
                Positioned(
                  left: 10,
                  top: 10,
                  child: SaGlassChip(
                    label: '비 24°',
                    icon: PhosphorIcon(PhosphorIconsFill.cloudRain, size: 13, color: SaColors.textPrimary),
                  ),
                ),
                const Positioned(right: 10, top: 10, child: SaGlassChip(label: '+124', mono: true)),
                Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                      border: Border.all(color: SaColors.borderStrong),
                    ),
                    child: PhosphorIcon(PhosphorIconsFill.play, size: 22, color: SaColors.textPrimary),
                  ),
                ),
                const Positioned(left: 12, bottom: 12, child: SaNewBadge(count: 6)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _section('Member Avatar Stack / New Dot'),
          Row(
            children: [
              const SaMemberAvatarStack(
                avatarUrls: ['', '', ''],
                extraCount: 5,
              ),
              const SizedBox(width: 10),
              Text('멤버 8', style: SaText.caption),
              const SizedBox(width: 14),
              const SaNewDot(),
              const SizedBox(width: 6),
              Text('안 본 콘텐츠', style: SaText.caption),
            ],
          ),
          const SizedBox(height: 24),

          _section('Gradient Buttons'),
          Row(
            children: [
              SaGradientButton(
                label: '앨범 만들기',
                icon: PhosphorIcon(PhosphorIconsBold.plus, size: 15, color: SaColors.onAccent),
                onTap: () {},
              ),
              const SizedBox(width: 12),
              SaGradientButton(
                label: '＋ 올리기',
                height: 52,
                glow: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          SaGradientButton(label: '4개 업로드', height: 52, expand: true, onTap: () {}),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: SaText.mono(fontSize: 11, color: SaColors.accentTeal)),
    );
  }
}
