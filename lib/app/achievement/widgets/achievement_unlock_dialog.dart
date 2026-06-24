import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AchievementUnlockDialog extends StatelessWidget {
  final String icon;
  final String name;
  final String message;

  const AchievementUnlockDialog({
    super.key,
    required this.icon,
    required this.name,
    required this.message,
  });

  static void show({
    required String icon,
    required String name,
    required String message,
  }) {
    Get.dialog(
      AchievementUnlockDialog(icon: icon, name: name, message: message),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              '업적 달성!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: Get.back,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
