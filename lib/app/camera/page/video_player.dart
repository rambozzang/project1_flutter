import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key, required this.videoFile});
  final File videoFile;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoController;

  final _stringTagController = StringTagController();

  @override
  void initState() {
    _videoController = VideoPlayerController.file(widget.videoFile);
    initializeVideo();
    super.initState();
  }

  void initializeVideo() async {
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.play();
  }

  @override
  void dispose() {
    _videoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: Colors.white,
      //resizeToAvoidBottomInset: false,
      appBar: AppBar(
        //    backgroundColor: Colors.white,
        title: const Text(""),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  const Gap(10),
                  Container(
                    height: 300,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  ),
                  // Transform.scale(
                  //   scale: 0.5,
                  //   child: Flexible(
                  //     child: AspectRatio(
                  //       aspectRatio: 9 / 16,
                  //       child: Container(
                  //         color: Colors.black,
                  //         child: VideoPlayer(_videoController),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const Gap(20),
                  const Text('제목을 입력해주세요!'),
                  const TextField(
                    decoration: InputDecoration(
                        hintStyle: TextStyle(color: Colors.grey),
                        hintText: "제목을 입력해주세요!"),
                  ),
                  const Gap(20),
                  const Text('Tag을 입력해주세요!'),
                  TextFieldTags<String>(
                      textfieldTagsController: _stringTagController,
                      initialTags: ['python', 'java'],
                      textSeparators: const [' ', ','],
                      validator: (String tag) {
                        if (tag == 'php') {
                          return 'Php not allowed';
                        }
                        return null;
                      },
                      inputFieldBuilder: (context, inputFieldValues) {
                        return TextField(
                          controller: inputFieldValues.textEditingController,
                          focusNode: inputFieldValues.focusNode,
                        );
                      }),
                  const Gap(200),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
