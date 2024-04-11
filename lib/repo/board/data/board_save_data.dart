// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:project1/repo/board/data/board_save_main_data.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';

class BoardSaveData {
  BoardSaveMainData? boardMastInVo;
  BoardSaveWeatherData? boardWeatherVo;
  BoardSaveData({
    this.boardMastInVo,
    this.boardWeatherVo,
  });

  BoardSaveData copyWith({
    BoardSaveMainData? boardMastInVo,
    BoardSaveWeatherData? boardWeatherVo,
  }) {
    return BoardSaveData(
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

  factory BoardSaveData.fromMap(Map<String, dynamic> map) {
    return BoardSaveData(
      boardMastInVo: map['boardMastInVo'] != null ? BoardSaveMainData.fromMap(map['boardMastInVo'] as Map<String, dynamic>) : null,
      boardWeatherVo: map['boardWeatherVo'] != null ? BoardSaveWeatherData.fromMap(map['boardWeatherVo'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardSaveData.fromJson(String source) => BoardSaveData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'BoardSaveData(boardMastInVo: $boardMastInVo, boardWeatherVo: $boardWeatherVo)';

  @override
  bool operator ==(covariant BoardSaveData other) {
    if (identical(this, other)) return true;

    return other.boardMastInVo == boardMastInVo && other.boardWeatherVo == boardWeatherVo;
  }

  @override
  int get hashCode => boardMastInVo.hashCode ^ boardWeatherVo.hashCode;
}
