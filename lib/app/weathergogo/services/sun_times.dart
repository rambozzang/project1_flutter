import 'dart:math' as math;

/// 일출/일몰 시각(한국 표준시 KST 기준 필드값).
class SunTimes {
  final DateTime? sunrise; // 시:분 필드가 KST를 나타냄
  final DateTime? sunset;
  const SunTimes(this.sunrise, this.sunset);

  bool get hasData => sunrise != null && sunset != null;
}

double _deg2rad(double d) => d * math.pi / 180.0;
double _rad2deg(double r) => r * 180.0 / math.pi;

/// NOAA 근사 일출·일몰 계산 — 외부 API/네트워크 없이 위·경도와 날짜만으로 로컬(오프라인) 산출.
/// [date]는 대상 '날짜'(시각 무시). 한국은 서머타임 없이 UTC+9 고정.
/// 반환 DateTime의 시:분 필드가 KST 시각을 나타낸다(포맷 시 그대로 HH:mm 사용).
SunTimes computeSunTimes(double lat, double lng, DateTime date, {int tzHours = 9}) {
  // 대상 날짜의 Julian day(정오 근사 계산에 충분).
  final DateTime dayUtc = DateTime.utc(date.year, date.month, date.day);
  final double jd = dayUtc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;

  final double n = (jd - 2451545.0 + 0.0008).roundToDouble();
  final double jStar = n - lng / 360.0; // 평균 태양시
  final double m = (357.5291 + 0.98560028 * jStar) % 360.0; // 태양 평균 근점이각
  final double mRad = _deg2rad(m);
  final double c =
      1.9148 * math.sin(mRad) + 0.0200 * math.sin(2 * mRad) + 0.0003 * math.sin(3 * mRad); // 중심차
  final double lambda = (m + c + 180.0 + 102.9372) % 360.0; // 황경
  final double lambdaRad = _deg2rad(lambda);
  final double jTransit =
      2451545.0 + jStar + 0.0053 * math.sin(mRad) - 0.0069 * math.sin(2 * lambdaRad); // 태양 남중
  final double sinDec = math.sin(lambdaRad) * math.sin(_deg2rad(23.44)); // 적위 sin
  final double decRad = math.asin(sinDec);
  final double latRad = _deg2rad(lat);
  // 지평선(굴절 보정 -0.833°)에서의 시간각.
  final double cosOmega =
      (math.sin(_deg2rad(-0.833)) - math.sin(latRad) * sinDec) / (math.cos(latRad) * math.cos(decRad));
  if (cosOmega > 1.0 || cosOmega < -1.0) {
    // 극야/백야(한국에선 발생 안 함).
    return const SunTimes(null, null);
  }
  final double omega = _rad2deg(math.acos(cosOmega));
  final double jRise = jTransit - omega / 360.0;
  final double jSet = jTransit + omega / 360.0;

  DateTime jToKst(double j) {
    final int ms = ((j - 2440587.5) * 86400000.0).round();
    // UTC 시각 + tz → 시:분 필드가 KST가 되도록 이동(포맷은 필드값 그대로 사용).
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).add(Duration(hours: tzHours));
  }

  return SunTimes(jToKst(jRise), jToKst(jSet));
}
