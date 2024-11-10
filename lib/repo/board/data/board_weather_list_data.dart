// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BoardWeatherListData {
  String? custId;
  String? custNm;
  String? nickNm;

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
  String? anonyYn;
  String? hideYn;
  String? lat;
  String? lon;
  String? sky;
  String? rain;
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
  String? crtDtm;
  int? replyCnt;
  int? likeCnt;
  int? viewCnt;
  String? icon;
  String? videoId;
  int? size1;
  String? thumbnail;
  String? preview;
  String? mp4;
  String? hls;
  double? range1;
  double? total;
  BoardWeatherListData({
    this.custId,
    this.custNm,
    this.nickNm,
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
    this.anonyYn,
    this.hideYn,
    this.lat,
    this.lon,
    this.sky,
    this.rain,
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
    this.crtDtm,
    this.replyCnt,
    this.likeCnt,
    this.viewCnt,
    this.icon,
    this.videoId,
    this.size1,
    this.thumbnail,
    this.preview,
    this.mp4,
    this.hls,
    this.range1,
    this.total,
  });

  BoardWeatherListData copyWith({
    String? custId,
    String? custNm,
    String? nickNm,
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
    String? anonyYn,
    String? hideYn,
    String? lat,
    String? lon,
    String? sky,
    String? rain,
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
    String? crtDtm,
    int? replyCnt,
    int? likeCnt,
    int? viewCnt,
    String? icon,
    String? videoId,
    int? size1,
    String? thumbnail,
    String? preview,
    String? mp4,
    String? hls,
    double? range1,
    double? total,
  }) {
    return BoardWeatherListData(
      custId: custId ?? this.custId,
      custNm: custNm ?? this.custNm,
      nickNm: nickNm ?? this.nickNm,
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
      anonyYn: anonyYn ?? this.anonyYn,
      hideYn: hideYn ?? this.hideYn,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      sky: sky ?? this.sky,
      rain: rain ?? this.rain,
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
      crtDtm: crtDtm ?? this.crtDtm,
      replyCnt: replyCnt ?? this.replyCnt,
      likeCnt: likeCnt ?? this.likeCnt,
      viewCnt: viewCnt ?? this.viewCnt,
      icon: icon ?? this.icon,
      videoId: videoId ?? this.videoId,
      size1: size1 ?? this.size1,
      thumbnail: thumbnail ?? this.thumbnail,
      preview: preview ?? this.preview,
      mp4: mp4 ?? this.mp4,
      hls: hls ?? this.hls,
      range1: range1 ?? this.range1,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'custId': custId,
      'custNm': custNm,
      'nickNm': nickNm,
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
      'anonyYn': anonyYn,
      'hideYn': hideYn,
      'lat': lat,
      'lon': lon,
      'sky': sky,
      'rain': rain,
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
      'crtDtm': crtDtm,
      'replyCnt': replyCnt,
      'likeCnt': likeCnt,
      'viewCnt': viewCnt,
      'icon': icon,
      'videoId': videoId,
      'size1': size1,
      'thumbnail': thumbnail,
      'preview': preview,
      'mp4': mp4,
      'hls': hls,
      'range1': range1,
      'total': total,
    };
  }

  factory BoardWeatherListData.fromMap(Map<String, dynamic> map) {
    return BoardWeatherListData(
      custId: map['custId'] != null ? map['custId'] as String : null,
      custNm: map['custNm'] != null ? map['custNm'] as String : null,
      nickNm: map['nickNm'] != null ? map['nickNm'] as String : null,
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
      anonyYn: map['anonyYn'] != null ? map['anonyYn'] as String : null,
      hideYn: map['hideYn'] != null ? map['hideYn'] as String : null,
      lat: map['lat'] != null ? map['lat'] as String : null,
      lon: map['lon'] != null ? map['lon'] as String : null,
      sky: map['sky'] != null ? map['sky'] as String : null,
      rain: map['rain'] != null ? map['rain'] as String : null,
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
      crtDtm: map['crtDtm'] != null ? map['crtDtm'] as String : null,
      replyCnt: map['replyCnt'] != null ? map['replyCnt'] as int : null,
      likeCnt: map['likeCnt'] != null ? map['likeCnt'] as int : null,
      viewCnt: map['viewCnt'] != null ? map['viewCnt'] as int : null,
      icon: map['icon'] != null ? map['icon'] as String : null,
      videoId: map['videoId'] != null ? map['videoId'] as String : null,
      size1: map['size1'] != null ? map['size1'] as int : null,
      thumbnail: map['thumbnail'] != null ? map['thumbnail'] as String : null,
      preview: map['preview'] != null ? map['preview'] as String : null,
      mp4: map['mp4'] != null ? map['mp4'] as String : null,
      hls: map['hls'] != null ? map['hls'] as String : null,
      range1: map['range1'] != null ? map['range1'] as double : null,
      total: map['total'] != null ? map['total'] as double : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardWeatherListData.fromJson(String source) => BoardWeatherListData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BoardWeatherListData(custId: $custId, custNm: $custNm, nickNm: $nickNm, profilePath: $profilePath, likeYn: $likeYn, followYn: $followYn, suject: $suject, location: $location, country: $country, contents: $contents, parentId: $parentId, distance: $distance, boardId: $boardId, anonyYn: $anonyYn,  hideYn: $hideYn, lat: $lat, lon: $lon, sky: $sky, rain: $rain, weatherInfo: $weatherInfo, videoPath: $videoPath, thumbnailPath: $thumbnailPath, currentTemp: $currentTemp, feelsTemp: $feelsTemp, tempMin: $tempMin, tempMax: $tempMax, humidity: $humidity, speed: $speed, city: $city, typeCd: $typeCd, typeDtCd: $typeDtCd, depthNo: $depthNo, crtDtm: $crtDtm, replyCnt: $replyCnt, likeCnt: $likeCnt, viewCnt: $viewCnt, icon: $icon, videoId: $videoId, size1: $size1, thumbnail: $thumbnail, preview: $preview, mp4: $mp4, hls: $hls, range1: $range1, total: $total)';
  }

  @override
  bool operator ==(covariant BoardWeatherListData other) {
    if (identical(this, other)) return true;

    return other.custId == custId &&
        other.custNm == custNm &&
        other.nickNm == nickNm &&
        other.profilePath == profilePath &&
        other.anonyYn == anonyYn &&
        other.likeYn == likeYn &&
        other.followYn == followYn &&
        other.suject == suject &&
        other.location == location &&
        other.country == country &&
        other.contents == contents &&
        other.parentId == parentId &&
        other.distance == distance &&
        other.boardId == boardId &&
        other.hideYn == hideYn &&
        other.lat == lat &&
        other.lon == lon &&
        other.sky == sky &&
        other.rain == rain &&
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
        other.crtDtm == crtDtm &&
        other.replyCnt == replyCnt &&
        other.likeCnt == likeCnt &&
        other.viewCnt == viewCnt &&
        other.icon == icon &&
        other.videoId == videoId &&
        other.size1 == size1 &&
        other.thumbnail == thumbnail &&
        other.preview == preview &&
        other.mp4 == mp4 &&
        other.hls == hls &&
        other.range1 == range1 &&
        other.total == total;
  }

  @override
  int get hashCode {
    return custId.hashCode ^
        custNm.hashCode ^
        nickNm.hashCode ^
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
        anonyYn.hashCode ^
        hideYn.hashCode ^
        lat.hashCode ^
        lon.hashCode ^
        sky.hashCode ^
        rain.hashCode ^
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
        crtDtm.hashCode ^
        replyCnt.hashCode ^
        likeCnt.hashCode ^
        viewCnt.hashCode ^
        icon.hashCode ^
        videoId.hashCode ^
        size1.hashCode ^
        thumbnail.hashCode ^
        preview.hashCode ^
        mp4.hashCode ^
        hls.hashCode ^
        range1.hashCode ^
        total.hashCode;
  }
}
