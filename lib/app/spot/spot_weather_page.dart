import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/spot/spot_admin_page.dart';
import 'package:project1/app/spot/spot_my_page.dart';
import 'package:project1/app/spot/spot_submit_page.dart';
import 'package:project1/app/spot/spot_weather_body.dart';
import 'package:project1/repo/spot/spot_repo.dart';

/// "스팟별 날씨" — 캠핑·낚시·골프 스팟을 현재 날씨와 함께 둘러보고,
/// 스팟을 탭하면 그곳 커뮤니티 영상으로 "지금 거기 어때?"를 확인한다.
/// (백엔드 /api/spot/* 준비 시 자동 연동 — WEATHER_ACTIVATION_API_CONTRACT.md)
class SpotWeatherPage extends StatelessWidget {
  const SpotWeatherPage({super.key});

  static const Color _bg = Color(0xFFF8F9FB);
  static const Color _textHi = Colors.black;
  static const Color _accent = Color(0xFF8C83DD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('스팟별 날씨', style: TextStyle(color: _textHi, fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textHi, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: const [_SpotMenu()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        onPressed: () => Get.to(() => const SpotSubmitPage()),
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('스팟 제보', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: const SpotWeatherBody(),
    );
  }
}

/// AppBar 우측 메뉴: 내 제보 / (운영자) 스팟 승인.
/// 운영자 여부는 진입 시 1회 조회해 메뉴를 노출한다.
class _SpotMenu extends StatefulWidget {
  const _SpotMenu();

  @override
  State<_SpotMenu> createState() => _SpotMenuState();
}

class _SpotMenuState extends State<_SpotMenu> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    SpotRepo().getIsAdmin().then((v) {
      if (mounted && v) setState(() => _isAdmin = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black),
      onSelected: (v) {
        if (v == 'my') Get.to(() => const SpotMyPage());
        if (v == 'admin') Get.to(() => const SpotAdminPage());
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'my', child: Text('내 제보 목록')),
        if (_isAdmin) const PopupMenuItem(value: 'admin', child: Text('🛠 스팟 승인 관리')),
      ],
    );
  }
}
