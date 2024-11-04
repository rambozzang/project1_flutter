// import 'package:flutter/material.dart';
// import 'package:rich_text_view/rich_text_view.dart';

// import 'package:url_launcher/url_launcher.dart';

// class YouTubeParser extends ParsedType {
//   final Function(String)? onTap;

//   YouTubeParser({this.onTap});

//   @override
//   InlineSpan getSpan(String text) {
//     final videoId = YoutubePlayer.convertUrlToId(text);
//     if (videoId == null) return TextSpan(text: text);

//     return WidgetSpan(
//       child: YouTubePlayerWidget(videoId: videoId),
//     );
//   }

//   @override
//   bool hasMatch(String text) {
//     return YoutubePlayer.convertUrlToId(text) != null;
//   }
// }

// class YouTubePlayerWidget extends StatelessWidget {
//   final String videoId;

//   YouTubePlayerWidget({required this.videoId});

//   @override
//   Widget build(BuildContext context) {
//     return YoutubePlayer(
//       controller: YoutubePlayerController(
//         initialVideoId: videoId,
//         flags: YoutubePlayerFlags(
//           autoPlay: false,
//           mute: false,
//         ),
//       ),
//       showVideoProgressIndicator: true,
//     );
//   }
// }
