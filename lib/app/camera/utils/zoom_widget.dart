//Zoomer this will be a seprate widget
import 'dart:async';

import 'package:flutter/material.dart';

class ZoomableWidget extends StatefulWidget {
  final Widget? child;
  final Function? onZoom;
  final Function? onTapUp;

  const ZoomableWidget({super.key, this.child, this.onZoom, this.onTapUp});

  @override
  _ZoomableWidgetState createState() => _ZoomableWidgetState();
}

class _ZoomableWidgetState extends State<ZoomableWidget> {
  Matrix4 matrix = Matrix4.identity();
  double zoom = 1;
  double prevZoom = 1;
  bool showZoom = false;
  Timer? t1;

  bool handleZoom(newZoom) {
    if (newZoom >= 1) {
      if (newZoom > 10) {
        return false;
      }
      setState(() {
        showZoom = true;
        zoom = newZoom;
      });

      if (t1 != null) {
        t1!.cancel();
      }

      t1 = Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          showZoom = false;
        });
      });
    }
    widget.onZoom!(zoom);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onScaleStart: (scaleDetails) {
          print('scalStart');
          setState(() => prevZoom = zoom);
          //print(scaleDetails);
        },
        onScaleUpdate: (ScaleUpdateDetails scaleDetails) {
          var newZoom = (prevZoom * scaleDetails.scale);

          handleZoom(newZoom);
        },
        onScaleEnd: (scaleDetails) {
          print('end');
          //print(scaleDetails);
        },
        onTapUp: (TapUpDetails det) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final Offset localPoint = box.globalToLocal(det.globalPosition);
          final Offset scaledPoint = localPoint.scale(1 / box.size.width, 1 / box.size.height);
        },
        child: Stack(children: [
          Column(
            children: <Widget>[
              Expanded(
                child: widget.child!,
              ),
            ],
          ),
          // Visibility(
          //   visible: showZoom, //Default is true,
          //   child: Positioned.fill(
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.end,
          //       mainAxisSize: MainAxisSize.max,
          //       mainAxisAlignment: MainAxisAlignment.end,
          //       children: <Widget>[
          //         Align(
          //           alignment: Alignment.bottomCenter,
          //           child: SliderTheme(
          //             data: SliderTheme.of(context).copyWith(
          //               valueIndicatorTextStyle: const TextStyle(color: Colors.amber, letterSpacing: 1.0, fontSize: 15),
          //               valueIndicatorColor: Colors.blue,
          //               // This is what you are asking for
          //               inactiveTrackColor: const Color(0xFF8D8E98),
          //               // Custom Gray Color
          //               activeTrackColor: Colors.white,
          //               thumbColor: Colors.red,
          //               overlayColor: const Color(0x29EB1555),
          //               // Custom Thumb overlay Color
          //               thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          //               overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
          //             ),
          //             child: Slider(
          //               value: zoom,
          //               onChanged: (double newValue) {
          //                 handleZoom(newValue);
          //               },
          //               label: "$zoom",
          //               min: 1,
          //               max: 10,
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          //   //maintainSize: bool. When true this is equivalent to invisible;
          //   //replacement: Widget. Defaults to Sizedbox.shrink, 0x0
          // )
        ]));
  }
}
