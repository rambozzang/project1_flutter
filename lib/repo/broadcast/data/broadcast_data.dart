class BroadcastCatalogItem {
  final int contentId;
  final int boardId;
  final int qualityScore;
  final double licenseFee;
  final String? videoPath;
  final String? thumbnailPath;
  final String? location;
  final String? currentTemp;
  final String? weatherInfo;
  final double? lat;
  final double? lon;
  final String? crtDtm;
  final String nickNm;

  BroadcastCatalogItem({
    required this.contentId,
    required this.boardId,
    required this.qualityScore,
    required this.licenseFee,
    this.videoPath,
    this.thumbnailPath,
    this.location,
    this.currentTemp,
    this.weatherInfo,
    this.lat,
    this.lon,
    this.crtDtm,
    required this.nickNm,
  });

  factory BroadcastCatalogItem.fromMap(Map<String, dynamic> map) =>
      BroadcastCatalogItem(
        contentId: map['contentId'] ?? 0,
        boardId: map['boardId'] ?? 0,
        qualityScore: map['qualityScore'] ?? 0,
        licenseFee: double.tryParse(map['licenseFee']?.toString() ?? '0') ?? 0,
        videoPath: map['videoPath'],
        thumbnailPath: map['thumbnailPath'],
        location: map['location'],
        currentTemp: map['currentTemp'],
        weatherInfo: map['weatherInfo'],
        lat: double.tryParse(map['lat']?.toString() ?? ''),
        lon: double.tryParse(map['lon']?.toString() ?? ''),
        crtDtm: map['crtDtm'],
        nickNm: map['nickNm'] ?? '',
      );
}
