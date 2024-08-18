import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class VideoController {
  
  late VideoPlayerController controller;
  final ValueNotifier<bool> initialized = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

 // VideoPlayerController를 반환하는 메서드
  VideoPlayerController get getController => this.controller;

  Future<void> initialize(String url, Map<String, String> headers, VideoFormat format) async {
    controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: headers,
      formatHint: format,
    );

    await controller.initialize();
    controller.addListener(_videoListener);
    initialized.value = true;
  }

  void _videoListener() {
    isPlaying.value = controller.value.isPlaying;
    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration != Duration.zero) {
      progress.value = (position.inSeconds / duration.inSeconds * 100).clamp(0.0, 100.0);
    }
  }

  void play() => controller.play();
  void pause() => controller.pause();
  Future<void> seekTo(Duration position) => controller.seekTo(position);
  void setVolume(double volume) => controller.setVolume(volume);
  void setLooping(bool looping) => controller.setLooping(looping);

  VideoPlayerValue get value => controller.value;

  void dispose() {
    controller.removeListener(_videoListener);
    controller.dispose();
  }

}