import 'dart:math' as math;

class Snowflake {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double angle;
  late double swingAmount;
  late double swingSpeed;
  late double opacity;
  late int pattern;
  late bool isReverse;

  Snowflake() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble() * 400;
    y = math.Random().nextDouble() * 1200 - 1200;
    size = math.Random().nextDouble() * 3 + 1;
    speed = math.Random().nextDouble() * 1.5 + 0.5;
    angle = 0;
    swingAmount = math.Random().nextDouble() * 2 + 0.5;
    swingSpeed = math.Random().nextDouble() * 0.03 + 0.01;
    opacity = math.Random().nextDouble() * 0.5 + 0.5;
    isReverse = math.Random().nextBool(); // 50% 확률로 반대 방향
    pattern = math.Random().nextInt(7); // 0-8 사이의 랜덤 패턴
  }

  void fall(double height, double width, double animationValue, double windStrength) {
    y += speed;
    angle += swingSpeed;

    double direction = isReverse ? -1 : 1;

    switch (pattern) {
      case 0: // 지그재그 패턴
        x += direction * (math.sin(angle) * swingAmount + windStrength);
        break;
      case 1: // 나선형 패턴
        x += direction * (math.cos(y / 50) * 2 + windStrength);
        break;
      case 2: // S자 패턴
        x += direction * (math.sin(y / 100) * 3 + windStrength);
        break;
      case 3: // 직선 패턴
        x += direction * windStrength;
        break;
      case 4: // 원형 패턴
        x += direction * (math.cos(angle) * swingAmount);
        y += math.sin(angle) * swingAmount + speed;
        break;
      case 5: // 지그재그 + 가속 패턴
        x += direction * (math.sin(angle) * swingAmount + windStrength);
        speed += 0.01;
        break;
      case 6: // 8자 패턴
        x += direction * (math.sin(angle * 2) * swingAmount);
        y += math.cos(angle) * swingAmount / 2 + speed;
        break;
      case 7: // 불규칙 패턴
        x += direction * (math.sin(angle) * swingAmount + math.cos(angle * 2) * swingAmount / 2 + windStrength);
        break;
      case 8: // 사인 + 코사인 복합 패턴
        x += direction * (math.sin(y / 50) * 2 + math.cos(y / 30) * 1.5 + windStrength);
        break;
    }

    if (y > height || x < -10 || x > width + 10) {
      reset();
      y = -size;
    }
  }
}
