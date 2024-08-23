import 'dart:math' as math;

class RainDrop {
  late double x;
  late double y;
  late double length;
  late double speed;

  RainDrop() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble() * 400;
    y = math.Random().nextDouble() * 1200 - 1200;
    length = math.Random().nextDouble() * 10 + 10;
    speed = math.Random().nextDouble() * 10 + 5;
  }

  void fall(double height) {
    y += speed;
    if (y > height) {
      reset();
    }
  }
}
