import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/special_weather/data/special_weather_data.dart';
import 'package:project1/app/special_weather/special_weather_detail_page.dart';
import 'package:project1/app/special_weather/special_weather_repo.dart';

/// 기상 특보 리스트 페이지.
class SpecialWeatherListPage extends StatefulWidget {
  const SpecialWeatherListPage({super.key});

  @override
  State<SpecialWeatherListPage> createState() => _SpecialWeatherListPageState();
}

class _SpecialWeatherListPageState extends State<SpecialWeatherListPage> {
  final SpecialWeatherRepo _repo = SpecialWeatherRepo();
  late Future<List<SpecialWeatherData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('기상 특보', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: FutureBuilder<List<SpecialWeatherData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text('발효 중인 특보가 없습니다.', style: TextStyle(color: Colors.black54, fontSize: 15)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _repo.fetchList());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ReportCard(data: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final SpecialWeatherData data;

  const _ReportCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isActive = data.isActive;
    final color = _categoryColor(data.category);

    return GestureDetector(
      onTap: () => Get.to(() => SpecialWeatherDetailPage(data: data)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    data.title,
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFFE5E5) : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? '발효 중' : '해제',
                    style: TextStyle(
                      color: isActive ? const Color(0xFFE53935) : const Color(0xFF757575),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.region,
              style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              data.content,
              style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.45),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              '발효: ${_format(data.issuedAt)}${data.liftedAt != null ? '  ·  해제: ${_format(data.liftedAt)}' : ''}',
              style: const TextStyle(color: Colors.black38, fontSize: 12),
            ),
          ],
        ),
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
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
