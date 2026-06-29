import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/attendance/cntr/attendance_cntr.dart';
import 'package:project1/app/challenge/cntr/challenge_cntr.dart';
import 'package:project1/app/common/widgets/animated_list_item.dart';
import 'package:project1/config/app_color.dart';
import 'package:project1/repo/challenge/data/challenge_complete_data.dart';
import 'package:project1/utils/utils.dart';

class ChallengeMainPage extends StatefulWidget {
  const ChallengeMainPage({super.key});

  @override
  State<ChallengeMainPage> createState() => _ChallengeMainPageState();
}

class _ChallengeMainPageState extends State<ChallengeMainPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrateController;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _celebrateController.dispose();
    super.dispose();
  }

  void _triggerCelebration() {
    setState(() => _showCelebration = true);
    _celebrateController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ChallengeCntr>()) {
      Get.put(ChallengeCntr());
    }
    if (!Get.isRegistered<AttendanceCntr>()) {
      Get.put(AttendanceCntr());
    }
    final challengeCntr = Get.find<ChallengeCntr>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColor.primaryColor),
        title: const Text(
          '챌린지',
          style: TextStyle(
            color: AppColor.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (challengeCntr.isLoading.value &&
            challengeCntr.todayChallenge.value == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedListItem(
                index: 0,
                child: _buildTodayChallengeCard(),
              ),
              const Gap(24),
              AnimatedListItem(
                index: 1,
                child: _buildAttendanceSection(),
              ),
              const Gap(24),
              AnimatedListItem(
                index: 2,
                child: _buildMyChallengeSection(),
              ),
              const Gap(24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTodayChallengeCard() {
    return Obx(() {
      final challenge = ChallengeCntr.to.todayChallenge.value;
      if (challenge == null) {
        return _buildInfoCard(
          title: '오늘의 챌린지',
          child: const Text(
            '오늘 진행 중인 챌린지가 없습니다.',
            style: TextStyle(color: Colors.black54),
          ),
        );
      }

      final isComplete = challenge.completeYn == 'Y';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
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
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department,
                              color: Colors.amber, size: 14),
                          Gap(4),
                          Text(
                            'DAILY',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.greenAccent, size: 16),
                            Gap(4),
                            Text(
                              '완료',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Gap(18),
                Text(
                  challenge.challengeNm ?? '오늘의 챌린지',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const Gap(10),
                Text(
                  challenge.challengeDesc ?? '챌린지 설명',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const Gap(18),
                _buildChallengeMetaRow(
                  icon: Icons.card_giftcard,
                  iconColor: Colors.amber,
                  text: challenge.rewardDesc ?? '보상 설명',
                ),
                const Gap(10),
                _buildChallengeMetaRow(
                  icon: Icons.people_alt_outlined,
                  iconColor: Colors.white54,
                  text: '오늘 ${challenge.todayParticipantCount ?? 0}명 참여',
                ),
                const Gap(22),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isComplete
                        ? Container(
                            key: const ValueKey('completed'),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, color: Colors.greenAccent),
                                Gap(8),
                                Text(
                                  '오늘 챌린지 완료!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            key: const ValueKey('action'),
                            onPressed: () async {
                              final result =
                                  await ChallengeCntr.to.completeChallenge();
                              if (result != null) {
                                _triggerCelebration();
                                _showCompleteDialog(result);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColor.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flash_on, size: 18),
                                Gap(6),
                                Text(
                                  '챌린지 완료하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (_showCelebration)
              AnimatedBuilder(
                animation: _celebrateController,
                builder: (context, child) {
                  return _CelebrationOverlay(
                      progress: _celebrateController.value);
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _buildChallengeMetaRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const Gap(8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: iconColor == Colors.amber
                  ? Colors.amber.shade100
                  : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    return Obx(() {
      final attendance = AttendanceCntr.to.myAttendance.value;
      final todayCheck = AttendanceCntr.to.todayCheck.value;

      return _buildInfoCard(
        title: '출석 현황',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    label: '연속 출석',
                    value: '${attendance?.consecutiveDays ?? 0}일',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    iconBgColor: Colors.orange.withOpacity(0.1),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildStatBox(
                    label: '이번달 출석',
                    value: '${attendance?.monthCount ?? 0}일',
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    iconBgColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const Gap(20),
            _buildWeeklyAttendance(attendance?.attendanceDates ?? []),
            if (todayCheck?.message != null) ...[
              const Gap(14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        todayCheck!.message!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMyChallengeSection() {
    return Obx(() {
      final status = ChallengeCntr.to.myChallengeStatus.value;
      if (status == null) return const SizedBox.shrink();

      final monthCount = status.monthCompleteCount ?? 0;
      String message;
      if (monthCount >= 20) {
        message = '이번 달도 최고예요! 🏆';
      } else if (monthCount >= 10) {
        message = '꾸준함이 돋보여요! ✨';
      } else if (monthCount >= 1) {
        message = '좋은 시작이에요! 💪';
      } else {
        message = '오늘의 챌린지로 시작해 보세요! 🚀';
      }

      return _buildInfoCard(
        title: '내 챌린지',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    label: '이번달 완료',
                    value: '${status.monthCompleteCount}회',
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber.shade700,
                    iconBgColor: Colors.amber.withOpacity(0.1),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildStatBox(
                    label: '총 완료',
                    value: '${status.totalCompleteCount}회',
                    icon: Icons.military_tech,
                    iconColor: Colors.purple,
                    iconBgColor: Colors.purple.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const Gap(14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColor.primaryColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColor.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const Gap(12),
          Text(
            value,
            style: const TextStyle(
              color: AppColor.primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAttendance(List<DateTime> attendanceDates) {
    final today = DateTime.now();
    final dates =
        List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dates.asMap().entries.map((entry) {
        final index = entry.key;
        final date = entry.value;
        final isAttended = attendanceDates.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

        return AnimatedListItem(
          index: index,
          duration: const Duration(milliseconds: 350),
          staggerDelay: const Duration(milliseconds: 40),
          child: Column(
            children: [
              Text(
                weekdayLabels[date.weekday % 7],
                style: TextStyle(
                  color: isToday ? AppColor.primaryColor : Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Gap(8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isAttended
                      ? Colors.green.withOpacity(0.12)
                      : isToday
                          ? AppColor.primaryColor.withOpacity(0.08)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(19),
                  border: isToday
                      ? Border.all(
                          color: AppColor.primaryColor.withOpacity(0.4),
                          width: 1.5)
                      : isAttended
                          ? Border.all(color: Colors.green.withOpacity(0.3))
                          : null,
                ),
                child: Center(
                  child: isAttended
                      ? const Icon(Icons.check, color: Colors.green, size: 20)
                      : Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isToday
                                ? AppColor.primaryColor
                                : Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showCompleteDialog(ChallengeCompleteData result) {
    final message = result.message ?? '챌린지 완료!';
    Utils.alertIcon(
      message,
      icontype: 'S',
      duration: const Duration(seconds: 3),
    );
  }
}

class _CelebrationOverlay extends StatelessWidget {
  final double progress;

  const _CelebrationOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final particles = [
      _ParticleData(
          icon: Icons.star,
          color: Colors.amber,
          start: 0.0,
          end: 1.0,
          left: 0.15,
          top: 0.2),
      _ParticleData(
          icon: Icons.circle,
          color: Colors.greenAccent,
          start: 0.1,
          end: 1.1,
          left: 0.75,
          top: 0.15),
      _ParticleData(
          icon: Icons.favorite,
          color: Colors.pinkAccent,
          start: 0.2,
          end: 1.2,
          left: 0.5,
          top: 0.1),
      _ParticleData(
          icon: Icons.star,
          color: Colors.lightBlueAccent,
          start: 0.05,
          end: 1.05,
          left: 0.85,
          top: 0.35),
      _ParticleData(
          icon: Icons.circle,
          color: Colors.orangeAccent,
          start: 0.15,
          end: 1.15,
          left: 0.1,
          top: 0.4),
      _ParticleData(
          icon: Icons.star,
          color: Colors.purpleAccent,
          start: 0.25,
          end: 1.25,
          left: 0.6,
          top: 0.25),
    ];

    return IgnorePointer(
      child: SizedBox(
        width: size.width,
        height: 360,
        child: Stack(
          children: particles.map((p) {
            final localProgress =
                ((progress - p.start) / (p.end - p.start)).clamp(0.0, 1.0);
            final opacity =
                localProgress < 0.8 ? 1.0 : 1.0 - ((localProgress - 0.8) / 0.2);
            final scale = 0.4 + localProgress * 0.9;
            final offsetY = localProgress * -80.0;

            return Positioned(
              left: size.width * p.left,
              top: 100 + size.width * p.top + offsetY,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Icon(p.icon, color: p.color, size: 28),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ParticleData {
  final IconData icon;
  final Color color;
  final double start;
  final double end;
  final double left;
  final double top;

  _ParticleData({
    required this.icon,
    required this.color,
    required this.start,
    required this.end,
    required this.left,
    required this.top,
  });
}
