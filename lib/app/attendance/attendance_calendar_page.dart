import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/attendance/cntr/attendance_cntr.dart';

class AttendanceCalendarPage extends StatelessWidget {
  const AttendanceCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AttendanceCntr>()) {
      Get.put(AttendanceCntr());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '출석 달력',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final attendance = AttendanceCntr.to.myAttendance.value;
        final attendanceDates = attendance?.attendanceDates ?? [];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: '연속 출석',
                      value: '${attendance?.consecutiveDays ?? 0}일',
                      color: Colors.orange,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _buildStatCard(
                      label: '이번달 출석',
                      value: '${attendance?.monthCount ?? 0}일',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const Gap(24),
              const Text(
                '최근 30일',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Gap(16),
              Expanded(
                child: _buildCalendarGrid(attendanceDates),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> attendanceDates) {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 29));
    final dates = List.generate(30, (index) => startDate.add(Duration(days: index)));

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final isAttended = attendanceDates.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

        return Container(
          decoration: BoxDecoration(
            color: isAttended
                ? Colors.greenAccent.withOpacity(0.2)
                : isToday
                    ? const Color(0xFF5B6DC0).withOpacity(0.3)
                    : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: isToday
                ? Border.all(color: const Color(0xFF5B6DC0), width: 1.5)
                : Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  color: isToday ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Gap(4),
              if (isAttended)
                const Icon(Icons.check, color: Colors.greenAccent, size: 16)
              else
                const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
