import 'package:flutter/material.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:video_player/video_player.dart';

class CctvPage2 extends StatefulWidget {
  const CctvPage2({super.key, required this.cctvResData});
  final CctvResData cctvResData;

  @override
  State<CctvPage2> createState() => _CctvPage2State();
}

class _CctvPage2State extends State<CctvPage2> {
  late CctvResData cctvResData;

  @override
  void initState() {
    super.initState();
    cctvResData = widget.cctvResData;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Cctv Page2'),
          SizedBox(
            width: MediaQuery.of(context).size.width - 5,
            height: 320,
          ),
        ],
      ),
    ));
  }
}
