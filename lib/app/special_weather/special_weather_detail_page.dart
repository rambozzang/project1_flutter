import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/special_weather/data/special_weather_data.dart';
import 'package:project1/app/special_weather/special_weather_repo.dart';

/// 기상 특보 상세 페이지.
/// 푸시 클릭 시 reportId를 arguments로 받아 해당 특보를 조회한다.
class SpecialWeatherDetailPage extends StatefulWidget {
  final SpecialWeatherData? data;

  const SpecialWeatherDetailPage({super.key, this.data});

  @override
  State<SpecialWeatherDetailPage> createState() => _SpecialWeatherDetailPageState();
}

class _SpecialWeatherDetailPageState extends State<SpecialWeatherDetailPage> {
  final SpecialWeatherRepo _repo = SpecialWeatherRepo();
  late Future<SpecialWeatherData?> _future;

  @override
  void initState() {
    super.initState();
    final reportId = Get.arguments?['reportId']?.toString();
    if (widget.data != null) {
      _future = Future.value(widget.data);
    } else if (reportId != null && reportId.isNotEmpty) {
      _future = _repo.fetchById(reportId);
    } else {
      _future = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('특보 상세', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: FutureBuilder<SpecialWeatherData?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('특보 정보를 찾을 수 없습니다.', style: TextStyle(color: Colors.black54, fontSize: 15)),
            );
          }
          return _DetailBody(data: data);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final SpecialWeatherData data;

  const _DetailBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(data.category);
    final isActive = data.isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
                child: Text(
                  data.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFE5E5) : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? '발효 중' : '해제',
                  style: TextStyle(
                    color: isActive ? const Color(0xFFE53935) : const Color(0xFF757575),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(icon: Icons.place_outlined, label: '대상 지역', value: data.region),
          const SizedBox(height: 14),
          _InfoRow(icon: Icons.access_time, label: '발효 시각', value: _format(data.issuedAt)),
          if (data.liftedAt != null) ...[
            const SizedBox(height: 14),
            _InfoRow(icon: Icons.check_circle_outline, label: '해제 시각', value: _format(data.liftedAt)),
          ],
          if (data.source != null) ...[
            const SizedBox(height: 14),
            _InfoRow(icon: Icons.apartment_outlined, label: '발표 기관', value: data.source!),
          ],
          const SizedBox(height: 28),
          const Text('특보 내용', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Text(
              data.content,
              style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.6),
            ),
          ),
          if (data.actionTip != null && data.actionTip!.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('행동 요령', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Text(
                data.actionTip!,
                style: const TextStyle(color: Color(0xFF795548), fontSize: 15, height: 1.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    return switch (category) {
      '폭염' => const Color(0xFFE53935),
      '호우' => const Color(0xFF1E88E5),
      '대설' => const Color(0xFF7E57C2),
      '강풍' => const Color(0xFF43A047),
      _ => const Color(0xFFFB8C00),
    };
  }

  String _format(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black45),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
