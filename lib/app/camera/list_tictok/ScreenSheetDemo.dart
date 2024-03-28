// import 'dart:math';

// import 'package:comment_sheet/comment_sheet.dart';
// import 'package:flutter/material.dart';
// import 'package:project1/app/camera/list_tictok/test_grabin_widget.dart';
// import 'package:project1/app/camera/list_tictok/test_list_item_widget.dart';

// class ScreenSheetDemo extends StatefulWidget {
//   const ScreenSheetDemo({Key? key}) : super(key: key);

//   @override
//   State<ScreenSheetDemo> createState() => _ScreenSheetDemoState();
// }

// class _ScreenSheetDemoState extends State<ScreenSheetDemo> {
//   final scrollController = ScrollController();
//   final commentSheetController = CommentSheetController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: CommentSheet(
//         slivers: [
//           buildSliverList(),
//         ],
//         grabbingPosition: WidgetPosition.above,
//         initTopPosition: 200,
//         calculateTopPosition: calculateTopPosition,
//         onTopChanged: (top) {},
//         scrollController: scrollController,
//         grabbing: buildGrabbing(context),
//         topWidget: (info) {
//           return Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             height: max(0, info.currentTop),
//             child: const Placeholder(
//               color: Colors.red,
//             ),
//           );
//         },
//         topPosition: WidgetPosition.below,
//         bottomWidget: buildBottomWidget(),
//         onPointerUp: (
//           BuildContext context,
//           CommentSheetInfo info,
//         ) {},
//         onAnimationComplete: (
//           BuildContext context,
//           CommentSheetInfo info,
//         ) {},
//         scrollPhysics: const CommentSheetBouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
//         commentSheetController: commentSheetController,
//         child: const Placeholder(),
//         backgroundBuilder: (context) {
//           return Container(
//             color: const Color(0xFF0F0F0F),
//             margin: const EdgeInsets.only(top: 20),
//           );
//         },
//       ),
//     );
//   }

//   double calculateTopPosition(
//     CommentSheetInfo info,
//   ) {
//     final vy = info.velocity.getVelocity().pixelsPerSecond.dy;
//     final top = info.currentTop;
//     double p0 = 0;
//     double p1 = 200;
//     double p2 = info.size.maxHeight - 100;

//     if (top > p1) {
//       if (vy > 0) {
//         if (info.isAnimating && info.animatingTarget == p1 && top < p1 + 10) {
//           return p1;
//         } else {
//           return p2;
//         }
//       } else {
//         return p1;
//       }
//     } else if (top == p1) {
//       return p1;
//     } else if (top == p0) {
//       return p0;
//     } else {
//       if (vy > 0) {
//         if (info.isAnimating && info.animatingTarget == p0 && top < p0 + 10) {
//           return p0;
//         } else {
//           return p1;
//         }
//       } else {
//         return p0;
//       }
//     }
//   }

//   Container buildBottomWidget() {
//     return Container(
//       color: Colors.transparent,
//       height: 50,
//       child: const Placeholder(
//         color: Colors.blue,
//       ),
//     );
//   }

//   Widget buildGrabbing(BuildContext context) {
//     return const GrabbingWidget();
//   }

//   Widget buildSliverList() {
//     return SliverList(
//         delegate: SliverChildBuilderDelegate((context, index) {
//       return const ListItemWidget();
//     }, childCount: 15));
//   }
// }
