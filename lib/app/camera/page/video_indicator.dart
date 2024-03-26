import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

class VideoProgressIndicator2 extends StatefulWidget {
  const VideoProgressIndicator2(
    this.controller, {
    super.key,
    this.colors = const VideoProgressColors(),
    required this.allowScrubbing,
    this.padding = const EdgeInsets.only(top: 5.0),
  });

  final VideoPlayerController controller;

  final VideoProgressColors colors;

  final bool allowScrubbing;

  final EdgeInsets padding;

  @override
  State<VideoProgressIndicator> createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<VideoProgressIndicator> {
  _VideoProgressIndicatorState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  late VoidCallback listener;

  VideoPlayerController get controller => widget.controller;

  VideoProgressColors get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    Widget progressIndicator;
    if (controller.value.isInitialized) {
      final int duration = controller.value.duration.inMilliseconds;
      final int position = controller.value.position.inMilliseconds;

      int maxBuffering = 0;
      for (final DurationRange range in controller.value.buffered) {
        final int end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      progressIndicator = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: (MediaQuery.of(context).size.width - 206) *
                (maxBuffering / duration),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: colors.backgroundColor,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: (MediaQuery.of(context).size.width - 206) *
                (maxBuffering / duration),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.transparent,
            ),
          ),
          // LinearProgressIndicator(
          //   value: maxBuffering / duration,
          //   valueColor: AlwaysStoppedAnimation<Color>(colors.bufferedColor),
          //   backgroundColor: colors.backgroundColor,
          // ),
          // LinearProgressIndicator(
          //   value: position / duration,
          //   valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
          //   backgroundColor: Colors.transparent,
          // ),
        ],
      );
    } else {
      progressIndicator = LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
        backgroundColor: colors.backgroundColor,
      );
    }
    final Widget paddedProgressIndicator = Padding(
      padding: widget.padding,
      child: progressIndicator,
    );
    if (widget.allowScrubbing) {
      return VideoScrubber(
        controller: controller,
        child: paddedProgressIndicator,
      );
    } else {
      return paddedProgressIndicator;
    }
  }
}
