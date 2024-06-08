// import 'dart:async';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cached_video_player_plus/cached_video_player_plus.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:project1/app/list/cntr/video_list_cntr.dart';
// import 'package:project1/repo/board/data/board_weather_list_data.dart';
// import 'package:video_player/video_player.dart';
// import 'package:visibility_detector/visibility_detector.dart';

// class VideoItem extends StatefulWidget {
//   final BoardWeatherListData data;

//   VideoItem({super.key, required this.data});

//   @override
//   _VideoItemState createState() => _VideoItemState();
// }

// class _VideoItemState extends State<VideoItem> {
//   // ChewieController _chewieController;
//   // VideoPlayerController _controller;
//   // Future<void> _initializeVideoPlayerFuture;
//   late CachedVideoPlayerPlusController? _videoController;
//   Completer videoPlayerInitialized = Completer();
//   UniqueKey stickyKey = UniqueKey();
//   bool readycontroller = false;
//   bool play = false;

//   @override
//   void initstate() {
//     super.initState();
//   }

//   @override
//   void dispose() async {
//     // Ensure disposing of the VideoPlayerController to free up resources.
//     // _chewieController.dispose();
//     // _controller.pause();
//     // _controller.seekTo(Duration(seconds: 0));
//     // await _controller.dispose();
//     // setState(() {
//     //   _controller = null;
//     // });
//     await _videoController?.dispose().then((_) {
//       readycontroller = false;
//       _videoController = null;
//       videoPlayerInitialized = Completer(); // resets the Completer
//     });
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         // width: 200,
//         // height: 200,
//         child: VisibilityDetector(
//       key: stickyKey,
//       onVisibilityChanged: (VisibilityInfo info) {
//         print("meri jung one man army");
//         print(info.visibleFraction);

//         if (info.visibleFraction > 0.70) {
//           play = Get.find<VideoListCntr>().playAtFirst == 2;
//           if (play) {
//             Get.find<VideoListCntr>().playAtFirst = 1;
//           }
//           // if (_videoController == null) {
//           if (readycontroller == false) {
//             _videoController = CachedVideoPlayerPlusController.networkUrl(
//               Uri.parse(widget.data.videoPath.toString()),
//             );
//             _videoController?.initialize().then((_) {
//               videoPlayerInitialized.complete(true);
//               setState(() {
//                 readycontroller = true;
//               });
//               _videoController?.setLooping(true);
//               if (play) {
//                 _videoController?.play();
//               }
//             });
//           }
//         } else if (info.visibleFraction < 0.30) {
//           setState(() {
//             readycontroller = false;
//           });
//           if (Get.find<VideoListCntr>().playAtFirst == 1) {
//             Get.find<VideoListCntr>().playAtFirst = 2;
//           }
//           _videoController?.pause();
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _videoController?.dispose().then((_) {
//               setState(() {
//                 _videoController = null;
//                 videoPlayerInitialized = Completer(); // resets the Completer
//               });
//             });
//           });
//         }
//       },
//       child: FutureBuilder(
//         future: videoPlayerInitialized.future,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done && _videoController != null && readycontroller) {
//             // should also check that the video has not been disposed
//             return GestureDetector(
//                 onTap: () {
//                   // setState(() {
//                   if (_videoController!.value.isPlaying) {
//                     _videoController?.pause();
//                     setState(() {
//                       print("google stole my data");
//                       play = false;
//                     });
//                     Get.find<VideoListCntr>().playAtFirst = 0;
//                   } else {
//                     _videoController?.play();
//                     Get.find<VideoListCntr>().playAtFirst = 1;
//                     setState(() {
//                       print("being played now");
//                       play = true;
//                     });
//                   }
//                   // });
//                 },
//                 child: Stack(
//                   alignment: AlignmentDirectional.center,
//                   children: [
//                     CachedVideoPlayerPlus(_videoController!),
//                     !play
//                         ? const Icon(
//                             CupertinoIcons.paw_solid,
//                             color: Colors.white70,
//                             size: 126,
//                           )
//                         : const Text("")
//                   ],
//                 )); // display the video
//           }

//           return videoBurrow(context, thumbUrl: widget.data.thumbnailPath!);
//         },
//       ),
//     ));
//   }
// }

// Widget videoBurrow(BuildContext context, {String thumbUrl = ""}) {
//   return SizedBox(
//     height: MediaQuery.of(context).size.height,
//     child: Container(
//       color: Colors.black,
//       child: Stack(
//         alignment: AlignmentDirectional.center,
//         children: [
//           thumbUrl != ""
//               ? CachedNetworkImage(
//                   imageUrl: thumbUrl,
//                   imageBuilder: (context, imageProvider) => SizedBox(
//                     child: Image(
//                       image: imageProvider,
//                       fit: BoxFit.cover,
//                       // height: 126,
//                     ),
//                   ),
//                   errorWidget: (context, url, error) => Container(
//                     decoration: const BoxDecoration(color: Colors.black87),
//                   ),
//                   placeholder: (context, url) => Container(
//                     decoration: const BoxDecoration(color: Colors.black87),
//                   ),
//                 )
//               : Container(decoration: const BoxDecoration(color: Colors.black87)),
//           const Positioned(
//             child: Icon(
//               CupertinoIcons.play_arrow_solid,
//               color: Colors.white70,
//               size: 126,
//             ),
//           )
//         ],
//       ),
//     ),
//   );
// }
