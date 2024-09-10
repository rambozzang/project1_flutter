import 'dart:math';

class MapAdapter {
  final int x;
  final int y;

  const MapAdapter(this.x, this.y);

  factory MapAdapter.changeMap(double longitude, double latitude) {
    double deGrad = pi / 180.0;
    double re = ChangeMapParameter.re / ChangeMapParameter.grid;
    double slat1 = ChangeMapParameter.slat1 * deGrad;
    double slat2 = ChangeMapParameter.slat2 * deGrad;
    double oLon = ChangeMapParameter.oLon * deGrad;
    double oLat = ChangeMapParameter.oLat * deGrad;

    double sn = tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5);
    sn = log(cos(slat1) / cos(slat2)) / log(sn);

    double sf = tan(pi * 0.25 + slat1 * 0.5);
    sf = pow(sf, sn) * cos(slat1) / sn;

    double ro = tan(pi * 0.25 + oLat * 0.5);
    ro = re * sf / pow(ro, sn);

    double ra = tan(pi * 0.25 + latitude * deGrad * 0.5);
    ra = re * sf / pow(ra, sn);
    double theta = longitude * deGrad - oLon;

    if (theta > pi) theta -= 2.0 * pi;
    if (theta < -pi) theta += 2.0 * pi;

    theta *= sn;

    double x = ra * sin(theta) + ChangeMapParameter.nx + 1.5;
    double y = ro - ra * cos(theta) + ChangeMapParameter.ny + 1.5;

    print('x = $x, y = $y');

    return MapAdapter(x.toInt(), y.toInt());
  }
}

class ChangeMapParameter {
  static const double re = 6371.00877;
  static const double grid = 5.0;
  static const double slat1 = 30.0;
  static const double slat2 = 60.0;
  static const double oLon = 126.0;
  static const double oLat = 38.0;
  static const double nx = 210 / 5.0;
  static const double ny = 675 / 5.0;
}


// /// 동네 좌표 변환
// class MapAdapter {
//   /// [x] : 경도 (초/100)
//   final int x;

//   /// [y] : 위도 (초/100)
//   final int y;

//   const MapAdapter(this.x, this.y);

//   /// 위경도 (x, y)  -> 동네 좌표(X, Y) 변환
//   ///
//   /// [x] : 경도 (초/100) -> 격자 X
//   ///
//   /// [y] : 위도 (초/100) -> 격자 Y
//   ///
//   ///
//   /// ```dart
//   ///
//   /// // 서울특별시 위도
//   /// const double x = 126.98000833333333;
//   /// const double y = 37.56356944444444;
//   ///
//   /// final map = MapAdapter.changeMap(x, y);
//   ///
//   /// print('서울특별시 x = ${map.x}, y = ${map.y}');
//   ///
//   /// [출력 결과] 서울특별시 x = 60, y = 127
//   ///
//   /// ```
//   factory MapAdapter.changeMap(double longitude, double latitude) {
//     late double deGrad;
//     late double re;
//     late double oLon;
//     late double sn;
//     late double sf;
//     late double ro;
//     late double slat1;
//     late double slat2;
//     late double ra;
//     late double theta;

//     const map = ChangeMapParameter();

//     if (map.first == 0) {
//       late double oLat;

//       deGrad = pi / 180.0;

//       re = map.re! / map.grid!;

//       slat1 = map.slat1! * deGrad;
//       slat2 = map.slat2! * deGrad;

//       oLon = map.oLon! * deGrad;
//       oLat = map.oLat! * deGrad;

//       sn = tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5);
//       sn = log(cos(slat1) / cos(slat2)) / log(sn);

//       sf = tan(pi * 0.25 + slat1 * 0.5);
//       sf = pow(sf, sn) * cos(slat1) / sn;

//       ro = tan(pi * 0.25 + oLat * 0.5);
//       ro = re * sf / pow(ro, sn);

//       map.copyWith(first: 1);
//     }

//     ra = tan(pi * 0.25 + latitude * deGrad * 0.5);
//     ra = re * sf / pow(ra, sn);
//     theta = longitude * deGrad - oLon;

//     if (theta > pi) theta -= 2.0 * pi;
//     if (theta < -pi) theta += 2.0 * pi;

//     theta *= sn;

//     double x = (ra * sin(theta)) + map.nx!;
//     double y = (ro - ra * cos(theta)) + map.ny!;

//     x = x + 1.5;
//     y = y + 1.5;

//     return MapAdapter(x.toInt(), y.toInt());
//   }
// }

// /// 변환에 필요한 Parameter
// class ChangeMapParameter {
//   ///사용할 지구반경
//   final double? re;

//   ///격자간격
//   final double? grid;

//   ///표준위도
//   final double? slat1;

//   ///표준위도
//   final double? slat2;

//   ///기준점의 경도
//   final double? oLon;

//   ///기준점의 위도
//   final double? oLat;

//   ///기준점의 X 좌표
//   final double? nx;

//   ///기준점의 Y 좌표
//   final double? ny;

//   ///시작여부
//   final int first;

//   const ChangeMapParameter({
//     this.re = 6371.00877,
//     this.grid = 5.0,
//     this.slat1 = 30.0,
//     this.slat2 = 60.0,
//     this.oLon = 126.0,
//     this.oLat = 38.0,
//     this.nx = 43 , //210 / 5.0,
//     this.ny = 136 , // 675 / 5.0,
//     this.first = 0,
//   });

//   ChangeMapParameter copyWith({int? first}) {
//     return ChangeMapParameter(
//       first: first ?? this.first,
//     );
//   }
// }
