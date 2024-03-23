import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoUrl extends StatefulWidget {
  const VideoUrl({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<VideoUrl> createState() => _VideoUrlState();
}

class _VideoUrlState extends State<VideoUrl> {
  late VideoPlayerController _controller;
  bool initialized = false;

  initiliazeVideo() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.setLooping(true);
            _controller.pause();
            initialized = true;
          });
        }
      });
  }

  @override
  void initState() {
    initiliazeVideo();
    super.initState();
  }

  @override
  void dispose() {
    if (initialized) {
      initialized = false;
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          if (initialized) {
            _controller.play();
          }
        } else if (info.visibleFraction < 0.4) {
          if (initialized) {
            _controller.pause();
            _controller.seekTo(Duration.zero);
          }
        }
      },
      key: UniqueKey(),
      child: initialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
