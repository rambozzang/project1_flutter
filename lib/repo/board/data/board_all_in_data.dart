// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:project1/repo/board/data/board_mast_in_data.dart';
import 'package:project1/repo/board/data/board_weather_data.dart';

class BoardAllInData {
  BoardMastInData? boardMastInVo;
  BoardWeatherData? boardWeatherVo;
  BoardAllInData({
    this.boardMastInVo,
    this.boardWeatherVo,
  });

  BoardAllInData copyWith({
    BoardMastInData? boardMastInVo,
    BoardWeatherData? boardWeatherVo,
  }) {
    return BoardAllInData(
      boardMastInVo: boardMastInVo ?? this.boardMastInVo,
      boardWeatherVo: boardWeatherVo ?? this.boardWeatherVo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'boardMastInVo': boardMastInVo?.toMap(),
      'boardWeatherVo': boardWeatherVo?.toMap(),
    };
  }

  factory BoardAllInData.fromMap(Map<String, dynamic> map) {
    return BoardAllInData(
      boardMastInVo: map['boardMastInVo'] != null ? BoardMastInData.fromMap(map['boardMastInVo'] as Map<String, dynamic>) : null,
      boardWeatherVo: map['boardWeatherVo'] != null ? BoardWeatherData.fromMap(map['boardWeatherVo'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardAllInData.fromJson(String source) => BoardAllInData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'BoardAllInData(boardMastInVo: $boardMastInVo, boardWeatherVo: $boardWeatherVo)';

  @override
  bool operator ==(covariant BoardAllInData other) {
    if (identical(this, other)) return true;

    return other.boardMastInVo == boardMastInVo && other.boardWeatherVo == boardWeatherVo;
  }

  @override
  int get hashCode => boardMastInVo.hashCode ^ boardWeatherVo.hashCode;
}
