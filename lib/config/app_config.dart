class AppConfig {
  AppConfig._();

  static const appleId = '6557075398';
  static const playStoreId = 'com.codelabtiger.skysnap';
  // 주의: 앱 버전 상수를 여기 두지 말 것 — bump_version.sh가 pubspec만 갱신해서 반드시 어긋난다.
  // 현재 버전은 PackageInfo.fromPlatform().version 으로 런타임 조회한다(root_page.checkAppVersion).
}
