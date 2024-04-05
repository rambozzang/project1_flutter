// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BoardListData {
  String? nickNm;
  String? custNm;
  String? profilePath;
  String? likeYn;
  String? followYn;

  String? suject;
  String? location;
  String? country;
  String? contents;
  int? parentId;
  double? distance;
  int? boardId;
  String? lat;
  String? lon;
  String? weatherInfo;
  String? videoPath;
  String? thumbnailPath;
  String? currentTemp;
  String? feelsTemp;
  String? tempMin;
  String? tempMax;
  String? humidity;
  String? speed;
  String? city;
  String? typeCd;
  String? typeDtCd;
  int? depthNo;
  String? chgDtm;
  int? likeCnt;
  String? icon;
  BoardListData({
    this.nickNm,
    this.custNm,
    this.profilePath,
    this.likeYn,
    this.followYn,
    this.suject,
    this.location,
    this.country,
    this.contents,
    this.parentId,
    this.distance,
    this.boardId,
    this.lat,
    this.lon,
    this.weatherInfo,
    this.videoPath,
    this.thumbnailPath,
    this.currentTemp,
    this.feelsTemp,
    this.tempMin,
    this.tempMax,
    this.humidity,
    this.speed,
    this.city,
    this.typeCd,
    this.typeDtCd,
    this.depthNo,
    this.chgDtm,
    this.likeCnt,
    this.icon,
  });

  BoardListData copyWith({
    String? nickNm,
    String? custNm,
    String? profilePath,
    String? likeYn,
    String? followYn,
    String? suject,
    String? location,
    String? country,
    String? contents,
    int? parentId,
    double? distance,
    int? boardId,
    String? lat,
    String? lon,
    String? weatherInfo,
    String? videoPath,
    String? thumbnailPath,
    String? currentTemp,
    String? feelsTemp,
    String? tempMin,
    String? tempMax,
    String? humidity,
    String? speed,
    String? city,
    String? typeCd,
    String? typeDtCd,
    int? depthNo,
    String? chgDtm,
    int? likeCnt,
    String? icon,
  }) {
    return BoardListData(
      nickNm: nickNm ?? this.nickNm,
      custNm: custNm ?? this.custNm,
      profilePath: profilePath ?? this.profilePath,
      likeYn: likeYn ?? this.likeYn,
      followYn: followYn ?? this.followYn,
      suject: suject ?? this.suject,
      location: location ?? this.location,
      country: country ?? this.country,
      contents: contents ?? this.contents,
      parentId: parentId ?? this.parentId,
      distance: distance ?? this.distance,
      boardId: boardId ?? this.boardId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      weatherInfo: weatherInfo ?? this.weatherInfo,
      videoPath: videoPath ?? this.videoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      currentTemp: currentTemp ?? this.currentTemp,
      feelsTemp: feelsTemp ?? this.feelsTemp,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      humidity: humidity ?? this.humidity,
      speed: speed ?? this.speed,
      city: city ?? this.city,
      typeCd: typeCd ?? this.typeCd,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      depthNo: depthNo ?? this.depthNo,
      chgDtm: chgDtm ?? this.chgDtm,
      likeCnt: likeCnt ?? this.likeCnt,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nickNm': nickNm,
      'custNm': custNm,
      'profilePath': profilePath,
      'likeYn': likeYn,
      'followYn': followYn,
      'suject': suject,
      'location': location,
      'country': country,
      'contents': contents,
      'parentId': parentId,
      'distance': distance,
      'boardId': boardId,
      'lat': lat,
      'lon': lon,
      'weatherInfo': weatherInfo,
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'currentTemp': currentTemp,
      'feelsTemp': feelsTemp,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'humidity': humidity,
      'speed': speed,
      'city': city,
      'typeCd': typeCd,
      'typeDtCd': typeDtCd,
      'depthNo': depthNo,
      'chgDtm': chgDtm,
      'likeCnt': likeCnt,
      'icon': icon,
    };
  }

  factory BoardListData.fromMap(Map<String, dynamic> map) {
    return BoardListData(
      nickNm: map['nickNm'] != null ? map['nickNm'] as String : null,
      custNm: map['custNm'] != null ? map['custNm'] as String : null,
      profilePath: map['profilePath'] != null ? map['profilePath'] as String : null,
      likeYn: map['likeYn'] != null ? map['likeYn'] as String : null,
      followYn: map['followYn'] != null ? map['followYn'] as String : null,
      suject: map['suject'] != null ? map['suject'] as String : null,
      location: map['location'] != null ? map['location'] as String : null,
      country: map['country'] != null ? map['country'] as String : null,
      contents: map['contents'] != null ? map['contents'] as String : null,
      parentId: map['parentId'] != null ? map['parentId'] as int : null,
      distance: map['distance'] != null ? map['distance'] as double : null,
      boardId: map['boardId'] != null ? map['boardId'] as int : null,
      lat: map['lat'] != null ? map['lat'] as String : null,
      lon: map['lon'] != null ? map['lon'] as String : null,
      weatherInfo: map['weatherInfo'] != null ? map['weatherInfo'] as String : null,
      videoPath: map['videoPath'] != null ? map['videoPath'] as String : null,
      thumbnailPath: map['thumbnailPath'] != null ? map['thumbnailPath'] as String : null,
      currentTemp: map['currentTemp'] != null ? map['currentTemp'] as String : null,
      feelsTemp: map['feelsTemp'] != null ? map['feelsTemp'] as String : null,
      tempMin: map['tempMin'] != null ? map['tempMin'] as String : null,
      tempMax: map['tempMax'] != null ? map['tempMax'] as String : null,
      humidity: map['humidity'] != null ? map['humidity'] as String : null,
      speed: map['speed'] != null ? map['speed'] as String : null,
      city: map['city'] != null ? map['city'] as String : null,
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      typeDtCd: map['typeDtCd'] != null ? map['typeDtCd'] as String : null,
      depthNo: map['depthNo'] != null ? map['depthNo'] as int : null,
      chgDtm: map['chgDtm'] != null ? map['chgDtm'] as String : null,
      likeCnt: map['likeCnt'] != null ? map['likeCnt'] as int : null,
      icon: map['icon'] != null ? map['icon'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardListData.fromJson(String source) => BoardListData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardListData(nickNm: $nickNm, custNm: $custNm, profilePath: $profilePath, likeYn: $likeYn, followYn: $followYn, suject: $suject, location: $location, country: $country, contents: $contents, parentId: $parentId, distance: $distance, boardId: $boardId, lat: $lat, lon: $lon, weatherInfo: $weatherInfo, videoPath: $videoPath, thumbnailPath: $thumbnailPath, currentTemp: $currentTemp, feelsTemp: $feelsTemp, tempMin: $tempMin, tempMax: $tempMax, humidity: $humidity, speed: $speed, city: $city, typeCd: $typeCd, typeDtCd: $typeDtCd, depthNo: $depthNo, chgDtm: $chgDtm, likeCnt: $likeCnt, icon: $icon)';
  }

  @override
  bool operator ==(covariant BoardListData other) {
    if (identical(this, other)) return true;

    return other.nickNm == nickNm &&
        other.custNm == custNm &&
        other.profilePath == profilePath &&
        other.likeYn == likeYn &&
        other.followYn == followYn &&
        other.suject == suject &&
        other.location == location &&
        other.country == country &&
        other.contents == contents &&
        other.parentId == parentId &&
        other.distance == distance &&
        other.boardId == boardId &&
        other.lat == lat &&
        other.lon == lon &&
        other.weatherInfo == weatherInfo &&
        other.videoPath == videoPath &&
        other.thumbnailPath == thumbnailPath &&
        other.currentTemp == currentTemp &&
        other.feelsTemp == feelsTemp &&
        other.tempMin == tempMin &&
        other.tempMax == tempMax &&
        other.humidity == humidity &&
        other.speed == speed &&
        other.city == city &&
        other.typeCd == typeCd &&
        other.typeDtCd == typeDtCd &&
        other.depthNo == depthNo &&
        other.chgDtm == chgDtm &&
        other.likeCnt == likeCnt &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return nickNm.hashCode ^
        custNm.hashCode ^
        profilePath.hashCode ^
        likeYn.hashCode ^
        followYn.hashCode ^
        suject.hashCode ^
        location.hashCode ^
        country.hashCode ^
        contents.hashCode ^
        parentId.hashCode ^
        distance.hashCode ^
        boardId.hashCode ^
        lat.hashCode ^
        lon.hashCode ^
        weatherInfo.hashCode ^
        videoPath.hashCode ^
        thumbnailPath.hashCode ^
        currentTemp.hashCode ^
        feelsTemp.hashCode ^
        tempMin.hashCode ^
        tempMax.hashCode ^
        humidity.hashCode ^
        speed.hashCode ^
        city.hashCode ^
        typeCd.hashCode ^
        typeDtCd.hashCode ^
        depthNo.hashCode ^
        chgDtm.hashCode ^
        likeCnt.hashCode ^
        icon.hashCode;
  }
}
