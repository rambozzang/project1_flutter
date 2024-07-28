import 'package:project1/utils/log_utils.dart';

class DateTimeAdapter {
  /// 새로운 new dateTime 생성
  DateTime nowDate({int? day, int? hour, int? minute}) {
    final nowDate = DateTime.now();

    return DateTime(
      nowDate.year,
      nowDate.month,
      day ?? nowDate.day,
      hour ?? nowDate.hour,
      minute ?? nowDate.minute,
    );
  }

  /// 초단기 예보 DateTime
  DateTime getSuperFctDate(DateTime now) {
    if (now.minute < 45) {
      // 45분 이전: 한 시간 전의 발표 시각
      if (now.hour == 0) {
        // 00:00 ~ 00:44: 전날 23:45
        return DateTime(now.year, now.month, now.day - 1, 23, 45);
      } else {
        // 그 외: 1시간 전의 45분
        return DateTime(now.year, now.month, now.day, now.hour - 1, 45);
      }
    } else {
      // 45분 이후: 현재 시각의 45분
      return DateTime(now.year, now.month, now.day, now.hour, 45);
    }
  }

  /// 초단기 실황 DateTime
  // DateTime getSuperNctDate(DateTime now) {
  //   // 40분 이전이면 현재 시보다 1시간 전 `base_time`을 요청한다.
  //   if (now.minute <= 40) {
  //     // 단. 0시 40분 이면 `baseDate`는 전날이고 `baseTime`은 23:00이다.
  //     if (now.hour == 0) return _hour23(now);

  //     return nowDate(hour: now.hour - 1, minute: 00);
  //   }

  //   //40분 이후면 현재 시와 같은 `base_time`을 요청한다.
  //   return nowDate(minute: 00);
  // }
  // 초단기실황 호출시간 계산 함수
  DateTime getSuperNctDate(DateTime now) {
    if (now.minute < 30) {
      // 30분 이전: 한 시간 전의 발표 시각
      if (now.hour == 0) {
        // 0시 30분 이전: 전날 23:30
        return DateTime(now.year, now.month, now.day - 1, 23, 30);
      } else {
        // 그 외: 1시간 전의 30분
        return DateTime(now.year, now.month, now.day, now.hour - 1, 30);
      }
    } else {
      // 30분 이후: 현재 시각의 30분
      return DateTime(now.year, now.month, now.day, now.hour, 30);
    }
  }

  // /// 초단기 실황 YesterDay DateTime
  // DateTime getSuperNctYesterDayDate(DateTime now) {
  //   // 40분 이전이면 현재 시보다 1시간 전 `base_time`을 요청한다.
  //   if (now.minute <= 40) {
  //     // 단. 0시 40분 이면 `baseDate`는 전날이고 `baseTime`은 23:00이다.
  //     if (now.hour == 0) return nowDate(day: now.day - 1, hour: 24, minute: 00);

  //     return nowDate(hour: now.hour - 1, minute: 00);
  //   }

  //   //40분 이후면 현재 시와 같은 `base_time`을 요청한다.
  //   return nowDate(day: now.day - 1, minute: 00);
  // }

  /// 단기 예보 DateTime
  DateTime getFctDate(DateTime now) {
    final fctTimes = [2, 5, 8, 11, 14, 17, 20, 23];
    // 0시부터 2시 사이의 경우 처리
    if (now.hour < fctTimes.first) {
      // 전날 23시의 예보 사용
      return DateTime(now.year, now.month, now.day - 1, 23);
    }
    // 가장 최근의 예보 시간 찾기
    int targetHour = fctTimes.lastWhere((h) => now.hour > h, orElse: () => fctTimes.last);
    // 날짜 변경 처리
    if (targetHour == 23 && now.hour < 23) {
      // 23시 예보를 찾았지만 현재 23시 이전인 경우, 전날의 23시 예보를 사용
      return DateTime(now.year, now.month, now.day - 1, 23);
    }
    return DateTime(now.year, now.month, now.day, targetHour);
  }

  int _dateHour(DateTime now) => (((now.hour + 1) % 24) / 3).floor();

  DateTime _hour23(DateTime now) {
    if (now.hour == 0) {
      // 0시일 때 전날 23시로 설정
      return nowDate(day: now.day - 1, hour: 23, minute: 00);
    }
    return nowDate(hour: 23, minute: 00);
  }

  // DateTime _hour(int hour) => nowDate(hour: hour, minute: 00);

  DateTime _hour(int hour) {
    // 24시를 0시로 변환
    if (hour == 24) {
      return nowDate(day: nowDate().day + 1, hour: 0, minute: 00);
    }
    return nowDate(hour: hour, minute: 00);
  }
}
