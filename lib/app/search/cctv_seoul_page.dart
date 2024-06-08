import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
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
      backgroundColor: Colors.white,
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
  late VideoPlayerController _controller;

  late CctvSeoulResData cctvSeoulResData;

  @override
  void initState() {
    super.initState();
    cctvSeoulResData = widget.cctvSeoulResData;

    Lo.g('element.cctvurl.toString() : ${cctvSeoulResData.cctvid.toString()}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String url = cctvSeoulResData.cctvid.toString().replaceAll('http://', 'https://');
    lo.g(url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
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
        height: 380,
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
                    Text(cctvSeoulResData.cctvname.toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.black)),
                    const SizedBox(width: 10),
                  ],
                ),
                SizedBox(
                    width: MediaQuery.of(context).size.width - 5,
                    height: 320,
                    child: VideoPlayer(
                      _controller,
                      key: GlobalKey(),
                    )),
                //  TextButton(onPressed: () => _controller.play(), child: const Text('Play')),
              ],
            ),
          )
        ]),
      ),
    ));
  }
}
