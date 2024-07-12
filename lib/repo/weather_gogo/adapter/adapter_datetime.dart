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
    // 45분 이전이면 현재 시보다 1시간 전 `base_time`을 요청한다.
    if (now.minute <= 45) {
      // 단, 00:45이면 `baseDate`는 전날이고 `baseTime`은 23:30이다.
      if (now.hour == 0) {
        return nowDate(day: now.day - 1, hour: 23, minute: 30);
      }

      return nowDate(hour: now.hour - 1, minute: 30);
    }

    //45분 이후면 현재 시와 같은 `base_time`을 요청한다.
    return nowDate(minute: 30);
  }

  /// 초단기 실황 DateTime
  DateTime getSuperNctDate(DateTime now) {
    // 40분 이전이면 현재 시보다 1시간 전 `base_time`을 요청한다.
    if (now.minute <= 40) {
      // 단. 0시 40분 이면 `baseDate`는 전날이고 `baseTime`은 23:00이다.
      if (now.hour == 0) return _hour23(now);

      return nowDate(hour: now.hour - 1, minute: 00);
    }

    //40분 이후면 현재 시와 같은 `base_time`을 요청한다.
    return nowDate(minute: 00);
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
    final fctList = [
      _hour23(now),
      _hour(2),
      _hour(5),
      _hour(8),
      _hour(11),
      _hour(14),
      _hour(17),
      _hour(20),
    ];

    if (now.hour == 23) return _hour(23);

    return fctList[_dateHour(now)];
  }

  int _dateHour(DateTime now) => (((now.hour + 1) % 24) / 3).floor();

  DateTime _hour23(DateTime now) {
    return nowDate(day: now.day - 1, hour: 23, minute: 00);
  }

  DateTime _hour(int hour) => nowDate(hour: hour, minute: 00);
}
