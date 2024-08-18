// lib/config/ad_unit_ids.dart

/*
android AdMob 앱 ID : ca-app-pub-7861255216779015~2088764563

날씨_화면   ca-app-pub-7861255216779015/3807303208

설정_화면  : ca-app-pub-7861255216779015/6890931420

알람_화면 : ca-app-pub-7861255216779015/2170771996

비디오_화면 : ca-app-pub-7861255216779015/9035579155 (전문광고)

Ios 앱 ID : ca-app-pub-7861255216779015~2822675009

날씨_화면 :  ca-app-pub-7861255216779015/6241894857

설정_화면:  ca-app-pub-7861255216779015/2760114724

알람_화면 : ca-app-pub-7861255216779015/9133951381

비디오_화면 : ca-app-pub-7861255216779015/8309654992 (전문광고)
*/
class AdUnitIds {
  static const Map<String, String> android = {
    'WeatherPage': 'ca-app-pub-7861255216779015/3807303208',
    'SettingPage': 'ca-app-pub-7861255216779015/6890931420', // ca-app-pub-7861255216779015/1017488334
    'AlramPage': 'ca-app-pub-7861255216779015/2170771996',
    'AlramPage2': 'ca-app-pub-7861255216779015/5750074293',
    'VideoPage': 'ca-app-pub-7861255216779015/9035579155', // 전면 광고
    'SeachPage': 'ca-app-pub-7861255216779015/7119453138',
    'WeathComPage': 'ca-app-pub-7861255216779015/1758846057', // 비교화면
    'WeathComPage2': 'ca-app-pub-7861255216779015/4794242934' // 비교화면2
  };

  static const Map<String, String> ios = {
    'WeatherPage': 'ca-app-pub-7861255216779015/6241894857',
    'SettingPage': 'ca-app-pub-7861255216779015/2760114724',
    'AlramPage': 'ca-app-pub-7861255216779015/9133951381',
    'AlramPage2': 'ca-app-pub-7861255216779015/7459591841',
    'VideoPage': 'ca-app-pub-7861255216779015/8309654992',
    'SeachPage': 'ca-app-pub-7861255216779015/1538973333',
    'WeathComPage': 'ca-app-pub-7861255216779015/9348990643', // 비교화면
    'WeathComPage2': 'ca-app-pub-7861255216779015/5926124101' // 비교화면2
  };
}
