class DailyForecast {
  final DateTime date;
  final double minTemperature;
  final double maxTemperature;
  final int dayIcon;
  final String dayIconPhrase;
  final int nightIcon;
  final String nightIconPhrase;

  DailyForecast({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.dayIcon,
    required this.dayIconPhrase,
    required this.nightIcon,
    required this.nightIconPhrase,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minTemperature': minTemperature,
        'maxTemperature': maxTemperature,
        'dayIcon': dayIcon,
        'dayIconPhrase': dayIconPhrase,
        'nightIcon': nightIcon,
        'nightIconPhrase': nightIconPhrase,
      };

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: DateTime.parse(json['date']),
        minTemperature: json['minTemperature'],
        maxTemperature: json['maxTemperature'],
        dayIcon: json['dayIcon'],
        dayIconPhrase: json['dayIconPhrase'],
        nightIcon: json['nightIcon'],
        nightIconPhrase: json['nightIconPhrase'],
      );
}
