class AuthConfig {
  // 외부에서 찾을수 있는 앱스키마
  static const String callScheme = 'auth-callback';
  // Google 정보
  static const String googleCliendId =
      '94642466533-p3tvrk3883ad3d8kftd9mrboipi89poo.apps.googleusercontent.com';

  static const String googleAuthURL = 'accounts.google.com';
  static const String googleAuthURI = '/o/oauth2/v2/auth';
  static const String googleRedirectURL = '/login/oauth2/mobile/google';
}
