import 'dart:math';

import 'dart:math';

class TwinklingStar {
  double x;
  double y;
  late double opacity;
  late double speed;
  late Random random;

  TwinklingStar(this.x, this.y) {
    random = Random();
    opacity = 0.3 + random.nextDouble() * 0.7;
    speed = 0.06 + random.nextDouble() * 0.03; // 속도를 줄임
  }

  void twinkle() {
    opacity += speed;
    if (opacity >= 1.0 || opacity <= 0.0) {
      speed = -speed;
    }
    opacity = opacity.clamp(0.0, 1.0); // opacity를 0.0에서 1.0 사이로 제한
  }
}
