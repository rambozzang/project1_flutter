import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/app/achievement/cntr/achievement_cntr.dart';
import 'package:project1/app/achievement/widgets/achievement_unlock_dialog.dart';
import 'package:project1/app/common/widgets/animated_list_item.dart';
import 'package:project1/config/app_color.dart';
import 'package:project1/repo/achievement/data/achievement_data.dart';
import 'package:project1/utils/utils.dart';

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AchievementCntr>(
      init: AchievementCntr(),
      builder: (cntr) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColor.primaryColor),
          title: const Text(
            '내 업적',
            style: TextStyle(
              color: AppColor.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Obx(() {
          if (cntr.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: AppColor.primaryColor));
          }
          final data = cntr.myData.value;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 14),
                  Text(
                    cntr.hasError.value ? '업적을 불러오지 못했어요' : '표시할 업적이 없어요',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: cntr.fetchAchievements,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(data),
              _buildCategoryChips(cntr),
              Expanded(
                child: Obx(() => _buildAchievementGrid(cntr)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(MyAchievementsData data) {
    final progress = data.progress;
    final achievedCount = data.achievedCount;
    final totalCount = data.totalCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.primaryColor, AppColor.containerColorLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 46,
            lineWidth: 8,
            percent: progress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$achievedCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/ $totalCount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            progressColor: Colors.amber,
            backgroundColor: Colors.white.withOpacity(0.2),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '업적 달성',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '전체 $totalCount개 중 $achievedCount개 달성',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(AchievementCntr cntr) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cntr.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = cntr.categories[index];
          return Obx(() {
            final isSelected = cntr.selectedCategory.value == cat['code'];
            return AnimatedListItem(
              index: index,
              duration: const Duration(milliseconds: 300),
              staggerDelay: const Duration(milliseconds: 40),
              child: _CategoryChip(
                label: cat['name']!,
                isSelected: isSelected,
                onTap: () => cntr.selectedCategory.value = cat['code']!,
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildAchievementGrid(AchievementCntr cntr) {
    final items = cntr.filteredAchievements;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '해당 카테고리의 업적이 없습니다.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColor.primaryColor,
      onRefresh: cntr.fetchAchievements,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final ach = items[i];
          return _AchievementCard(
            achievement: ach,
            onTap: () => _onAchievementTap(ach),
          );
        },
      ),
    );
  }

  void _onAchievementTap(AchievementData ach) {
    if (ach.achieved) {
      AchievementUnlockDialog.show(
        icon: ach.achievementIcon,
        name: ach.achievementNm,
        message: ach.achievementDesc,
      );
    } else {
      Utils.alertIcon(
        ach.achievementDesc.isNotEmpty
            ? ach.achievementDesc
            : '아직 해금되지 않은 업적입니다.',
        icontype: 'I',
      );
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColor.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementData achievement;
  final VoidCallback onTap;

  const _AchievementCard({
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final achieved = achievement.achieved;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: achieved
              ? const LinearGradient(
                  colors: [Color(0xFFFFF9E6), Color(0xFFFFF3CD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: achieved ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: achieved ? Colors.amber.shade300 : Colors.grey.shade200,
            width: achieved ? 2 : 1,
          ),
          boxShadow: achieved
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: achieved ? 1.0 : 0.45,
                    child: Text(
                      achievement.achievementIcon,
                      style: const TextStyle(fontSize: 38),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Opacity(
                      opacity: achieved ? 1.0 : 0.55,
                      child: Text(
                        achievement.achievementNm,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: achieved
                              ? AppColor.primaryColor
                              : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (achieved && achievement.totalAchievers > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${achievement.totalAchievers}명 달성',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (achieved)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '달성',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
