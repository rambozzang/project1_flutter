// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedWaterDrops extends StatefulWidget {
  const AnimatedWaterDrops({super.key});

  @override
  _AnimatedWaterDropsState createState() => _AnimatedWaterDropsState();
}

class _AnimatedWaterDropsState extends State<AnimatedWaterDrops> {
  List<AnimatedDropParam> drops = [];
  Random random = Random();

  @override
  void initState() {
    super.initState();
    // 초기 물방울 생성
    for (int i = 0; i < 10; i++) {
      drops.add(_createRandomDrop());
    }
    // 애니메이션 시작
    Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _updateDrops();
      });
    });
  }

  AnimatedDropParam _createRandomDrop() {
    return AnimatedDropParam(
      left: random.nextDouble() * 300,
      top: random.nextDouble() * 100 - 100, // 화면 위에서 시작
      width: random.nextDouble() * 30 + 20,
      height: random.nextDouble() * 40 + 30,
      speed: random.nextDouble() * 2 + 1,
    );
  }

  void _updateDrops() {
    for (var drop in drops) {
      drop.top += drop.speed;
      if (drop.top > MediaQuery.of(context).size.height) {
        // 화면 아래로 벗어나면 새로운 물방울로 교체
        drops[drops.indexOf(drop)] = _createRandomDrop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 배경
        Container(color: Colors.lightBlue[100]),
        // 물방울들
        ...drops.map((drop) => WaterDrop.single(
              left: drop.left,
              top: drop.top,
              width: drop.width,
              height: drop.height,
              key: GlobalKey(),
              child: Container(color: Colors.blue[200]),
            )),
      ],
    );
  }
}

class AnimatedDropParam extends WaterDropParam {
  double speed;

  AnimatedDropParam({
    required super.left,
    required super.top,
    required super.width,
    required super.height,
    required this.speed,
  });
}

// 여기에 제공된 WaterDrop, WaterDropParam, OvalClipper, _LightDot, _OvalShadow 클래스들을 그대로 붙여넣습니다.
// (코드 중복을 피하기 위해 여기서는 생략했습니다)

///Parameter of a single water drop
class WaterDropParam {
  ///Distance from the top of child
  double top;

  ///Distance from the left of child
  double left;

  ///Width of a water drop
  double width;

  ///Height of a water drop
  double height;

  WaterDropParam({required this.top, required this.left, required this.width, required this.height});
}

class WaterDrop extends StatelessWidget {
  final List<WaterDropParam> params;
  final Widget child;

  const WaterDrop({
    super.key,
    required this.params,
    required this.child,
  });

  ///A factory for creating a single drop
  factory WaterDrop.single(
          {required Key key,
          required double left,
          required double top,
          required double height,
          required double width,
          required Widget child}) =>
      WaterDrop(
        child: child,
        params: [
          WaterDropParam(top: top, left: left, width: width, height: height),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        ...params.map((param) => _WaterDrop(
              child: child,
              left: param.left,
              top: param.top,
              width: param.width,
              height: param.height,
            )),
      ],
    );
  }
}

class _WaterDrop extends StatefulWidget {
  final double top;
  final double left;
  final double width;
  final double height;
  final Widget child;

  const _WaterDrop({
    Key? key,
    required this.child,
    required this.top,
    required this.width,
    required this.left,
    required this.height,
  }) : super(key: key);

  @override
  __WaterDropState createState() => __WaterDropState();
}

class __WaterDropState extends State<_WaterDrop> {
  Size? totalSize;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          totalSize = context.size;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = totalSize ?? MediaQuery.of(context).size;

    final alignment = getAlignment(size);

    final alignmentModifier = Alignment(
      widget.width / size.width,
      widget.height / size.height,
    );

    Widget childWithGradient = Container(
      foregroundDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignment - alignmentModifier,
          end: alignment + alignmentModifier,
          colors: [Colors.black, Colors.white],
        ),
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: widget.child,
    );

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          _OvalShadow(
            width: widget.width,
            height: widget.height,
            top: widget.top,
            left: widget.left,
          ),
          ...List.generate(8, (i) {
            return Transform.scale(
              scale: 1 + 0.02 * i,
              alignment: alignment,
              child: ClipPath(
                clipper: OvalClipper(
                  center: center,
                  width: widget.width * (1 - 0.04 * i),
                  height: widget.height * (1 - 0.04 * i),
                ),
                clipBehavior: Clip.hardEdge,
                child: childWithGradient,
              ),
            );
          }),
          _LightDot(
            width: widget.width,
            height: widget.height,
            top: widget.top,
            left: widget.left,
          ),
        ],
      ),
    );
  }

  Offset get center => Offset(
        widget.left + widget.width / 2,
        widget.top + widget.height / 2,
      );

  Alignment getAlignment(Size size) => Alignment(
        (center.dx - size.width / 2) / (size.width / 2),
        (center.dy - size.height / 2) / (size.height / 2),
      );
}

class OvalClipper extends CustomClipper<Path> {
  final double height;
  final double width;
  final Offset center;

  OvalClipper({
    required this.height,
    required this.width,
    required this.center,
  });

  @override
  Path getClip(Size size) {
    Path path = Path()
      ..addOval(Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      ));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;

  OvalClipper copyWith({
    double? height,
    double? width,
    Offset? center,
  }) {
    return OvalClipper(
      height: height ?? this.height,
      width: width ?? this.width,
      center: center ?? this.center,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'height': height,
      'width': width,
      'centerX': center.dx,
      'centerY': center.dy,
    };
  }

  factory OvalClipper.fromMap(Map<String, dynamic> map) {
    return OvalClipper(
      height: map['height'] as double,
      width: map['width'] as double,
      center: Offset(map['centerX'] as double, map['centerY'] as double),
    );
  }

  String toJson() => json.encode(toMap());

  factory OvalClipper.fromJson(String source) => OvalClipper.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'OvalClipper(height: $height, width: $width, center: $center)';

  @override
  bool operator ==(covariant OvalClipper other) {
    if (identical(this, other)) return true;

    return other.height == height && other.width == width && other.center == center;
  }

  @override
  int get hashCode => height.hashCode ^ width.hashCode ^ center.hashCode;
}

///A white dot in top left corner
class _LightDot extends StatelessWidget {
  final double top;
  final double left;
  final double width;
  final double height;

  const _LightDot({
    Key? key,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left + width / 4,
      top: top + height / 4,
      width: width / 4,
      height: height / 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 3,
              color: Colors.white.withOpacity(0.9),
            ),
          ],
        ),
      ),
    );
  }
}

///A shadow below the drop
class _OvalShadow extends StatelessWidget {
  final double top;
  final double left;
  final double width;
  final double height;

  const _OvalShadow({
    Key? key,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.elliptical(width / 2, height / 2),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(4, 4),
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
