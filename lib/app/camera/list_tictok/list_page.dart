import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/list_tictok/VidoeUrl.dart';
import 'package:project1/app/camera/list_tictok/api_service.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:video_player/video_player.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late List<String> urls;
  late VideoPlayerController _videoController;
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final PreloadPageController _controller = PreloadPageController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDate();
  }

  getDate() async {
    isLoading.value = false;
    urls = await ApiService.getVideos();
    isLoading.value = true;
  }

  void goRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            return CameraBloc(
              cameraUtils: CameraUtils(),
              permissionUtils: PermissionUtils(),
            )..add(const CameraInitialize(recordingLimit: 15));
          },
          child: const CameraPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, value, child) {
                  return value
                      // ? PageView.builder(
                      //     allowImplicitScrolling: true,
                      //     controller: PageController(viewportFraction: 0.999),
                      //     itemCount: urls.length,
                      ? PreloadPageView.builder(
                          controller: _controller,
                          preloadPagesCount: 4,
                          scrollDirection: Axis.vertical,
                          itemCount: urls.length,
                          itemBuilder: (context, i) {
                            return VideoUrl(
                              videoUrl: urls[i],
                            );
                          })
                      : Utils.progressbar();
                }),
            Positioned(
              top: 20,
              right: 10,
              child: SizedBox(
                  width: 50,
                  child: CustomButton(listColors: [
                    const Color.fromARGB(255, 251, 250, 250),
                    const Color.fromARGB(255, 226, 226, 226)
                  ], text: '+', type: 'S', onPressed: () => goRecord())),
            ),
            const Positioned(
                bottom: 20,
                right: 20,
                left: 20,
                child: Row(children: [
                  CircleAvatar(),
                  Column(
                    children: [Text('이문세'), Text('2024.03.03')],
                  ),
                  Text('adsfasdfasdfasdf'),
                ]))
          ],
        ),
      ),
    );
  }
}
