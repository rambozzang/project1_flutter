import 'dart:math' as math;

class RainDrop {
  late double x;
  late double y;
  late double length;
  late double speed;
  late double angle;
  late double opacity;

  RainDrop() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble() * 400;
    y = math.Random().nextDouble() * 1200 - 1200;
    // length = math.Random().nextDouble() * 10 + 10;
    // speed = math.Random().nextDouble() * 10 + 5;
    length = math.Random().nextDouble() * 90; // 길이를 10-60으로 늘림
    speed = math.Random().nextDouble() * 15 + 5; // 속도를 5-20으로 늘림
    angle = math.Random().nextDouble() * 0.02; // 0.1-0.3 라디안 (약 5-17도)
    opacity = math.Random().nextDouble() * 0.5 + 0.9; // 불투명도 0.3-0.8
  }

  void fall(double height) {
    y += speed;
    x += speed * math.sin(angle); // 비가 각도를 가지고 떨어지도록 함
    if (y > height || x > 400) {
      reset();
    }
  }
}
