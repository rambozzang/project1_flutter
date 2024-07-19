import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:project1/repo/cctv/data/cctv_seoul_res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:video_player/video_player.dart';

class CctvSeoulPageBottomSheet {
  Future<void> open(
    BuildContext context,
    CctvSeoulResData cctvSeoulResData,
  ) async {
    var result = await showModalBottomSheet(
      isScrollControlled: true,
      // showDragHandle: true,
      backgroundColor: Colors.yellow,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))),
      context: context,
      builder: (BuildContext context) {
        return CctvPage(cctvSeoulResData: cctvSeoulResData);
      },
    );
    return result;
  }
}

class CctvPage extends StatefulWidget {
  const CctvPage({super.key, required this.cctvSeoulResData});
  final CctvSeoulResData cctvSeoulResData;

  @override
  State<CctvPage> createState() => _CctvPageState();
}

class _CctvPageState extends State<CctvPage> {
  InAppWebViewController? webViewController;
  InAppWebViewSettings webViewSettings = InAppWebViewSettings(
    userAgent:
        'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.152 Mobile Safari/537.36',
  );

  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  late VideoPlayerController _controller;

  late CctvSeoulResData cctvSeoulResData;

  String seoulUrl = "http://www.utic.go.kr/view/map/cctvStream.jsp";
// http://www.utic.go.kr/view/map/cctvStream.jsp?cctvid=L010183&cctvname=%EC%8B%A0%EC%B4%8C&kind=EE&cctvip=8750

// http://www.utic.go.kr/view/map/cctvStream.jsp?cctvid=L902594&cctvname=%25ED%258F%25AC%25EC%259D%25BC%25EB%25A1%259C%25EC%2582%25BC%25EA%25B1%25B0%25EB%25A6%25AC&kind=EE&cctvip=6668&cctvch=null&id=null&cctvpasswd=null&cctvport=null&minX=126.86868197592773&minY=37.30479809395467&maxX=127.12307218775577&maxY=37.4373460514048

  // String seoulUrl =
  //     "https://www.utic.go.kr/view/map/openDataCctvStream.jsp?key=VI6l9pfWdIclwcZP3Go7orBQKYcp2jKs3AtbfXuAOsQOZ3bZmgpdQ9AJ0AM4fEfmJKYyLlSmhLFLWRRrIwg&cctvName=%25EA%25B0%2595%25EC%259B%2590%2520%25EA%25B0%2595%25EB%25A6%2589%2520%25EC%25A3%25BC%25EB%25AC%25B8%25EC%25A7%2584%25EB%25B0%25A9%25ED%258C%258C%25EC%25A0%259C&kind=KB&cctvip=9995&cctvch=null&id=null&cctvpasswd=null&cctvport=null&cctvid=";

  @override
  void initState() {
    super.initState();
    cctvSeoulResData = widget.cctvSeoulResData;
    // seoulUrl = seoulUrl + cctvSeoulResData.cctvid.toString();

    seoulUrl = "$seoulUrl?cctvid=${cctvSeoulResData.cctvid.toString()}&";
    seoulUrl = "${seoulUrl}cctvname=${Uri.encodeComponent(cctvSeoulResData.cctvname.toString())}&";
    seoulUrl = "${seoulUrl}kind=EE&";
    seoulUrl = "${seoulUrl}cctvip=${cctvSeoulResData.seq.toString()}&";
    seoulUrl = "${seoulUrl}cctvch=null&id=null&cctvpasswd=null&cctvport=null&";
    // seoulUrl = "${seoulUrl}minX=126.86868197592773&";
    // seoulUrl = "${seoulUrl}minY=37.30479809395467&";
    // seoulUrl = "${seoulUrl}maxX=127.12307218775577&";
    // seoulUrl = "${seoulUrl}maxY=37.4373460514048";

    // Lo.g('element.cctvurl.toString() : ${cctvSeoulResData.cctvid.toString()}');
    androidCheck();
  }

  Future<void> androidCheck() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 아래 실제 url 이고 비디오플레이어로는 플레이가 안됨!!!
    // seoulUrl =
    //     "http://www.utic.go.kr/view/map/cctvStream.jsp?cctvid=L902594&cctvname=%25ED%258F%25AC%25EC%259D%25BC%25EB%25A1%259C%25EC%2582%25BC%25EA%25B1%25B0%25EB%25A6%25AC&kind=EE&cctvip=6668&cctvch=null&id=null&cctvpasswd=null&cctvport=null&minX=126.86868197592773&minY=37.30479809395467&maxX=127.12307218775577&maxY=37.4373460514048";
    lo.g(seoulUrl);
    lo.g(Uri.parse(seoulUrl).toString());

    _controller = VideoPlayerController.networkUrl(Uri.parse(seoulUrl), formatHint: VideoFormat.ss)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.setLooping(true);
            _controller.play();
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SizedBox(
        height: 410,
        child: Column(children: [
          Container(
            ///height: 45,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(cctvSeoulResData.cctvname.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.black)),
                    const SizedBox(width: 10),
                  ],
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 5,
                  height: 320,
                  // child: InAppWebView(
                  //   key: GlobalKey(),
                  //   initialUrlRequest: URLRequest(url: WebUri(seoulUrl)),
                  //   initialSettings: settings,
                  //   onWebViewCreated: (controller) {
                  //     webViewController = controller;
                  //   },
                  //   onLoadStart: (controller, url) {
                  //     print('onLoadStart $url');
                  //     Utils.progressbar();
                  //   },
                  //   onLoadStop: (controller, url) {
                  //     print('onLoadStop $url');
                  //   },
                  //   onConsoleMessage: (controller, consoleMessage) {
                  //     print('consoleMessage $consoleMessage');
                  //   },
                  // ),
                  child: VideoPlayer(
                    _controller,
                    key: GlobalKey(),
                  ),
                ),

                const Align(alignment: Alignment.centerLeft, child: Text("『경찰청 도시교통정보센터(UTIC)』제공 "))
                //  TextButton(onPressed: () => _controller.play(), child: const Text('Play')),
              ],
            ),
          )
        ]),
      ),
    ));
  }
}
