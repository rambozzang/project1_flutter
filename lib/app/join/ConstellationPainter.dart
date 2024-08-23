import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class ConstellationPainter extends CustomPainter {
  List<Offset> constellations;
  Color color;
  Random random = Random();

  ConstellationPainter(this.constellations, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    double randomRadius = 3.0 + random.nextDouble() * 2.0;
    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    for (int i = 0; i < constellations.length - 1; i++) {
      canvas.drawCircle(
        constellations[i],
        randomRadius,
        paint..maskFilter = MaskFilter.blur(BlurStyle.normal, convertRadiusToSigma(randomRadius)),
      );
      canvas.drawCircle(
        constellations[i + 1],
        randomRadius,
        paint..maskFilter = MaskFilter.blur(BlurStyle.normal, convertRadiusToSigma(randomRadius)),
      );
      canvas.drawLine(
        constellations[i],
        constellations[i + 1],
        paint..maskFilter = MaskFilter.blur(BlurStyle.normal, convertRadiusToSigma(1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  double convertRadiusToSigma(double radius) {
    return radius;
  }
}

// class MovingConstellations {
//   double x;
//   double y;
//   List<Offset> constellations;
//   ConstellationPainter constellationPainter;
//   double rotationSpeed;
//   late double cycle;
//   late double phaseOffset;
//   late double scalePhaseOffset;
//   Random random = Random();
//   double scale = 1.0;

//   MovingConstellations(this.x, this.y, this.constellations, {required this.rotationSpeed})
//       : constellationPainter = ConstellationPainter(constellations, Colors.white) {
//     cycle = random.nextDouble() * 2 * pi;
//     phaseOffset = random.nextDouble() * 2 * pi;
//     scalePhaseOffset = random.nextDouble() * 2 * pi;
//   }

//   void move() {
//     // 회전 속도 변화
//     double rotationSpeed1 = rotationSpeed * (1 + 0.5 * sin(cycle));
//     double rotationAngle = rotationSpeed1;

//     // 크기 변화
//     scale = 1.0 + 0.2 * sin(cycle * 0.5 + scalePhaseOffset);

//     for (int i = 0; i < constellations.length; i++) {
//       // 회전 및 크기 변화 적용
//       double rotatedX = constellations[i].dx * cos(rotationAngle) - constellations[i].dy * sin(rotationAngle);
//       double rotatedY = constellations[i].dx * sin(rotationAngle) + constellations[i].dy * cos(rotationAngle);
//       constellations[i] = Offset(rotatedX * scale, rotatedY * scale);
//     }

//     // 주기 및 이동 업데이트
//     cycle += 0.02 + random.nextDouble() * 0.03;
//     if (cycle > 2 * pi) {
//       cycle -= 2 * pi;
//     }

//     // 불규칙한 이동 패턴
//     x += sin(cycle + phaseOffset) * (2 + random.nextDouble() * 3);
//     y += cos(cycle * 1.3 + phaseOffset) * (2 + random.nextDouble() * 3);

//     // 색상 변화
//     double hue = (cycle / (2 * pi) * 360) % 360;
//     constellationPainter.color = HSVColor.fromAHSV(1.0, hue, 0.2, 1.0).toColor();
//   }

//   void draw(Canvas canvas) {
//     canvas.save();
//     canvas.translate(x, y);
//     constellationPainter.paint(canvas, Size.infinite);
//     canvas.restore();
//   }
// }

class MovingConstellations {
  double x;
  double y;
  List<Offset> constellations;
  ConstellationPainter constellationPainter;
  double rotationSpeed;
  late double cycle;
  late double phaseOffset;
  late double scalePhaseOffset;
  Random random = Random();
  double scale = 1.0;

  MovingConstellations(this.x, this.y, this.constellations, {required this.rotationSpeed})
      : constellationPainter = ConstellationPainter(constellations, Colors.white) {
    cycle = random.nextDouble() * 2 * pi;
    phaseOffset = random.nextDouble() * 2 * pi;
    scalePhaseOffset = random.nextDouble() * 2 * pi;
  }

  void move() {
    // 회전 속도 변화
    double rotationSpeed1 = rotationSpeed * (1 + 0.5 * sin(cycle));
    double rotationAngle = rotationSpeed1;

    // 크기 변화
    scale = 1.0 + 0.2 * sin(cycle * 0.5 + scalePhaseOffset);

    List<Offset> newConstellations = [];
    for (int i = 0; i < constellations.length; i++) {
      // 회전 및 크기 변화 적용
      double rotatedX = constellations[i].dx * cos(rotationAngle) - constellations[i].dy * sin(rotationAngle);
      double rotatedY = constellations[i].dx * sin(rotationAngle) + constellations[i].dy * cos(rotationAngle);

      // NaN 체크 및 처리
      if (rotatedX.isFinite && rotatedY.isFinite) {
        newConstellations.add(Offset(rotatedX * scale, rotatedY * scale));
      } else {
        // NaN이 발생한 경우, 원래 좌표를 유지
        newConstellations.add(constellations[i]);
      }
    }
    constellations = newConstellations;

    // 주기 및 이동 업데이트
    cycle += 0.02 + random.nextDouble() * 0.03;
    if (cycle > 2 * pi) {
      cycle -= 2 * pi;
    }

    // 불규칙한 이동 패턴
    double dx = sin(cycle + phaseOffset) * (2 + random.nextDouble() * 3);
    double dy = cos(cycle * 1.3 + phaseOffset) * (2 + random.nextDouble() * 3);

    // NaN 체크 및 처리
    if (dx.isFinite) x += dx;
    if (dy.isFinite) y += dy;

    // 색상 변화
    double hue = (cycle / (2 * pi) * 360) % 360;
    constellationPainter.color = HSVColor.fromAHSV(1.0, hue, 0.2, 1.0).toColor();

    // ConstellationPainter 업데이트
    constellationPainter = ConstellationPainter(constellations, constellationPainter.color);
  }

  void draw(Canvas canvas) {
    canvas.save();
    canvas.translate(x, y);
    constellationPainter.paint(canvas, Size.infinite);
    canvas.restore();
  }
}
