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
  late VideoPlayerController _controller;

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
    String url = cctvResData.cctvurl.toString();
    lo.g(url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        lo.g('1');
        if (mounted) {
          lo.g('2');
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
                    Text(cctvResData.cctvname.toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
