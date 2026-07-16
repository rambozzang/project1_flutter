import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/subscript_service.dart';

/// 프리미엄 구독 페이월 — 광고 제거 + 프리미엄 날씨 + 프리미엄 앨범 테마 안내.
/// `arguments: {'source': 'weather'}` 로 들어오면 날씨 강조 문구를 보여준다.
class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final String source = args['source'] ?? 'general';
    final sub = SubscriptionService.instance;

    final List<_Benefit> benefits = [
      const _Benefit(PhosphorIconsFill.confetti, '광고 없이 쾌적하게', '배너·전면광고 모두 제거'),
      const _Benefit(PhosphorIconsFill.cloudSun, '프리미엄 날씨', '초단기·시간대별 상세 예보와 특보 알림'),
      const _Benefit(PhosphorIconsFill.imagesSquare, '프리미엄 앨범 테마', '골드·시네마틱 등 전용 표지 테마'),
      const _Benefit(PhosphorIconsFill.hardDrives, 'PRO 저장 용량', '앨범 미디어 보관 한도 확장'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0E1525),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('SkySnap Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Obx(() {
        final subscribed = AuthCntr.to.isPremium.value;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A5CFF), Color(0xFF00C2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('구름 없는 날씨, 광고 없는 경험',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    source == 'weather'
                        ? '프리미엄 날씨로 더 정확한 예보를 확인하세요.'
                        : '더 많은 기능을 광고 없이 누려보세요.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (subscribed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent),
                    SizedBox(width: 10),
                    Expanded(child: Text('프리미엄 구독이 활성화되어 있어요!', style: TextStyle(color: Colors.white))),
                  ],
                ),
              )
            else ...[
              ...benefits.map((b) => _benefitTile(b)),
              const SizedBox(height: 18),
              _planTile(sub, PremiumProductIds.monthly, '월간', '매월 자동 갱신'),
              const SizedBox(height: 10),
              _planTile(sub, PremiumProductIds.yearly, '연간', '월간 대비 최대 30% 절약'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() => ElevatedButton(
                      onPressed: sub.purchasing.value
                          ? null
                          : () {
                              final pid = sub.productById(PremiumProductIds.monthly) != null
                                  ? PremiumProductIds.monthly
                                  : PremiumProductIds.yearly;
                              sub.buy(pid);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A5CFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: sub.purchasing.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('프리미엄 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    )),
              ),
              const SizedBox(height: 10),
              Obx(() => TextButton(
                    onPressed: sub.restoring.value ? null : sub.restore,
                    child: sub.restoring.value
                        ? const Text('복원 중...', style: TextStyle(color: Colors.white70))
                        : const Text('이미 구매하셨나요? 구독 복원', style: TextStyle(color: Colors.white70)),
                  )),
              const SizedBox(height: 8),
              const Text(
                '구독은 언제든 해지할 수 있으며, 결제는 앱스토어/구글 플레이를 통해 처리됩니다. 가격은 매장 정책에 따릅니다.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _benefitTile(_Benefit b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          PhosphorIcon(b.icon, color: const Color(0xFF8C7CFF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
                Text(b.desc, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTile(SubscriptionService sub, String id, String label, String desc) {
    final p = sub.productById(id);
    final price = p?.price ?? (id == PremiumProductIds.yearly ? '연간' : '월간');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => sub.buy(id),
            child: Text(price, style: const TextStyle(color: Color(0xFF8C7CFF), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String desc;
  const _Benefit(this.icon, this.title, this.desc);
}
