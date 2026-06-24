import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/achievement/cntr/achievement_cntr.dart';

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AchievementCntr>(
      init: AchievementCntr(),
      builder: (cntr) => Scaffold(
        appBar: AppBar(
          title: const Text('내 업적'),
          centerTitle: true,
        ),
        body: Obx(() {
          if (cntr.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = cntr.myData.value;
          if (data == null) {
            return const Center(child: Text('데이터 없음'));
          }

          return Column(
            children: [
              // 달성률 헤더
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF1A237E),
                child: Column(
                  children: [
                    Text(
                      '${data.achievedCount} / ${data.totalCount}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '업적 달성',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: data.progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ],
                ),
              ),
              // 카테고리 탭
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: cntr.categories.map((cat) {
                    return Obx(() {
                      final isSelected = cntr.selectedCategory.value == cat['code'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat['name']!),
                          selected: isSelected,
                          onSelected: (_) =>
                              cntr.selectedCategory.value = cat['code']!,
                        ),
                      );
                    });
                  }).toList(),
                ),
              ),
              // 업적 그리드
              Expanded(
                child: Obx(() => GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: cntr.filteredAchievements.length,
                      itemBuilder: (ctx, i) {
                        final ach = cntr.filteredAchievements[i];
                        return Opacity(
                          opacity: ach.achieved ? 1.0 : 0.35,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ach.achieved
                                  ? const Color(0xFFFFF9C4)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ach.achieved
                                    ? Colors.amber
                                    : Colors.grey[300]!,
                                width: ach.achieved ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ach.achievementIcon,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ach.achievementNm,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (ach.achieved && ach.totalAchievers > 0)
                                  Text(
                                    '${ach.totalAchievers}명 달성',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
              ),
            ],
          );
        }),
      ),
    );
  }
}
