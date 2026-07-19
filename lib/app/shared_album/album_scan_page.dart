import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/utils/utils.dart';

/// 근접 QR 초대 스캔 — 상대의 앨범 초대 QR(예: https://skysnap.co.kr/invite/CODE)을 읽어
/// 기존 joinByCode로 바로 가입하고 앨범 셸로 진입한다.
/// "폰을 가까이 대는" 경험을 QR 스캔 한 번으로 재현(NameDrop은 애플 전용이라 대체).
class AlbumScanPage extends StatefulWidget {
  const AlbumScanPage({super.key});

  @override
  State<AlbumScanPage> createState() => _AlbumScanPageState();
}

class _AlbumScanPageState extends State<AlbumScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final CommunityRepo _repo = CommunityRepo();
  bool _handling = false; // 코드 1건 처리 중엔 추가 감지 무시

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 스캔 문자열에서 초대 코드를 추출한다.
  /// 지원: https://skysnap.co.kr/invite/CODE, .../invite?code=CODE,
  ///       skysnap://invite?code=CODE, skysnap://invite/CODE, 그리고 원시 코드.
  String? _extractCode(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final uri = Uri.tryParse(s);
    if (uri != null && (uri.scheme == 'skysnap' || uri.host.contains('skysnap.co.kr'))) {
      final q = uri.queryParameters['code'];
      if (q != null && q.trim().isNotEmpty) return q.trim();
      final segs = uri.pathSegments;
      final i = segs.indexOf('invite');
      if (i >= 0 && i + 1 < segs.length) return segs[i + 1].trim();
      if (uri.host == 'invite' && segs.isNotEmpty) return segs.first.trim();
      return null;
    }
    // URL 형식이 아니면 코드 자체로 간주(영숫자 4~20자).
    if (RegExp(r'^[A-Za-z0-9]{4,20}$').hasMatch(s)) return s;
    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final String? raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (raw == null) return;
    final String? code = _extractCode(raw);
    if (code == null) return; // 우리 초대 QR이 아님 → 계속 스캔

    _handling = true;
    if (mounted) setState(() {});
    await _controller.stop();

    final (ok, msg, community) = await _repo.joinByCode(code);
    if (!mounted) return;
    Utils.alert(msg.isEmpty ? (ok ? '참여했습니다.' : '가입에 실패했습니다.') : msg);

    if (ok && community != null) {
      // 가입 완료 → 앨범 셸(메인)로 대체 이동(스캔 화면은 스택에서 제거).
      Get.offNamed('/AlbumShellPage', arguments: {
        'communityId': community.communityId,
        'community': community,
      });
    } else {
      // 실패 → 다시 스캔 가능하도록 복구.
      _handling = false;
      if (mounted) setState(() {});
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('초대 QR 스캔', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            tooltip: '플래시',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text('카메라를 열 수 없습니다.\n권한을 확인해 주세요.\n(${error.errorCode.name})',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              ),
            ),
          ),
          // 스캔 가이드 프레임
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_handling) ...[
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('가입 처리 중…',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ] else
                  const Text('상대의 앨범 초대 QR을 사각형 안에 맞춰주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
