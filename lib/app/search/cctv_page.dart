import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:video_player/video_player.dart';

// 서울 시내
class CctvPageBottomSheet {
  Future<void> open(
    BuildContext context,
    CctvResData cctvResData,
  ) async {
    var result = await showModalBottomSheet(
      isScrollControlled: true,
      // showDragHandle: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))),
      context: context,
      builder: (BuildContext context) {
        return CctvPage(cctvResData: cctvResData);
      },
    );
    return result;
  }
}

class CctvPage extends StatefulWidget {
  const CctvPage({super.key, required this.cctvResData});
  final CctvResData cctvResData;

  @override
  State<CctvPage> createState() => _CctvPageState();
}

class _CctvPageState extends State<CctvPage> {
  VideoPlayerController? _controller;

  /// 재생 실패 안내(null 이면 정상).
  String? _error;

  late CctvResData cctvResData;

  @override
  void initState() {
    super.initState();
    cctvResData = widget.cctvResData;

    Lo.g('element.cctvurl.toString() : ${cctvResData.cctvurl.toString()}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies 는 여러 번 불릴 수 있다. 예전엔 부를 때마다 플레이어를 새로
    // 만들어 앞 것이 해제되지 않고 남았다 — 한 번만 시작한다.
    if (_controller == null && _error == null) _start();
  }

  /// 국가교통정보센터 CCTV 주소는 확장자 없는 짧은 주소이고, 열면 302 로 실제 재생목록
  /// (https://…:8082/…/playlist.m3u8?wmsAuthSign=…)으로 넘겨준다. iOS 플레이어는 이
  /// 넘겨받기를 처리하지 못하고 "Failed to load video" 로 끝났다(2026-10-13 시뮬레이터).
  /// 재생 전에 최종 주소를 직접 풀어서 넘긴다. 서명은 120분 유효라 열 때마다 새로 푼다.
  Future<void> _start() async {
    final raw = cctvResData.cctvurl.toString();
    final url = await _resolve(raw.replaceFirst('http://', 'https://')) ?? await _resolve(raw) ?? raw;
    lo.g('CCTV 재생 주소: $url');
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = c;
    try {
      await c.initialize();
      if (!mounted) return;
      await c.setLooping(true);
      await c.play();
      setState(() {});
    } catch (e) {
      lo.g('CCTV 재생 실패: $e');
      if (mounted) setState(() => _error = '지금 이 CCTV 영상을 불러올 수 없어요');
    }
  }

  /// 넘겨주기(3xx)를 따라가 최종 주소를 돌려준다. 실패하면 null.
  static Future<String?> _resolve(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      var current = Uri.parse(url);
      for (var hop = 0; hop < 4; hop++) {
        final req = await client.getUrl(current);
        req.followRedirects = false;
        final res = await req.close().timeout(const Duration(seconds: 8));
        await res.drain<void>();
        final loc = res.headers.value(HttpHeaders.locationHeader);
        if (res.isRedirect && loc != null) {
          current = current.resolve(loc);
          continue;
        }
        return res.statusCode < 400 ? current.toString() : null;
      }
      return current.toString();
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SizedBox(
        height: 430,
        child: Column(children: [
          Container(
            ///height: 45,
            padding: const EdgeInsets.only(left: 5, bottom: 10, right: 5),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(cctvResData.cctvname.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.black)),
                    const SizedBox(width: 10),
                  ],
                ),
                SizedBox(
                    width: MediaQuery.of(context).size.width - 5,
                    height: 320,
                    child: _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: Colors.black54)))
                        : (_controller?.value.isInitialized ?? false)
                            ? VideoPlayer(_controller!)
                            : const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                const Align(alignment: Alignment.centerLeft, child: Text("『국가교통정보센터(UTIC)』제공 "))
                //  TextButton(onPressed: () => _controller.play(), child: const Text('Play')),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
