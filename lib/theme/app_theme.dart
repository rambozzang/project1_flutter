// import 'package:flutter/material.dart';

// class AppTheme {
//   // 라이트 모드 색상
//   static const Color primaryBlue = Colors.white;
//   static const Color secondaryBlue = Color(0xFF42A5F5);
//   static const Color backgroundWhite = Color(0xFFFFFFFF);
//   static const Color textPrimary = Color(0xFF333333);
//   static const Color textSecondary = Color(0xFF666666);
//   static const Color dividerColor = Color(0xFFE0E0E0);
//   static const Color cardBackground = Color(0xFFFAFAFA);
//   static const Color iconColor = Color(0xFF757575);
//   static const Color errorRed = Color(0xFFE53935);
//   static const Color successGreen = Color(0xFF43A047);

//   // 다크 모드 색상
//   static const Color darkPrimaryBlue = Color.fromARGB(255, 0, 0, 0); // 더 진한 파란색
//   static const Color darkSecondaryBlue = Color(0xFF1E88E5); // 더 진한 보조 파란색
//   static const Color darkBackground = Color(0xFF121212); // 다크모드 기본 배경
//   static const Color darkCardBackground = Color(0xFF1E1E1E); // 다크모드 카드 배경
//   static const Color darkTextPrimary = Color(0xFFE0E0E0); // 다크모드 주요 텍스트
//   static const Color darkTextSecondary = Color(0xFFAAAAAA); // 다크모드 보조 텍스트
//   static const Color darkDividerColor = Color(0xFF2C2C2C); // 다크모드 구분선
//   static const Color darkIconColor = Color(0xFFBDBDBD); // 다크모드 아이콘

//   // light theme 정의 (기존 코드 유지)
//   static final ThemeData light = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,

//     colorScheme: ColorScheme.fromSeed(
//       seedColor: Colors.white,
//       surface: Colors.white,
//       // primary: primaryBlue,
//     ),
//     // 기본 색상
//     primaryColor: Colors.white,
//     scaffoldBackgroundColor: Colors.white,
//     // AppBar 테마
//     // 사용: lib/app/bbs/bbs_view_page.dart, lib/app/auth/login_page.dart 등 모든 상단 앱바
//     appBarTheme: const AppBarTheme(
//       backgroundColor: primaryBlue,
//       foregroundColor: Colors.white,
//       elevation: 0,
//       centerTitle: false,
//       titleSpacing: 0.0,
//       titleTextStyle: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.w600,
//         color: Colors.black,
//       ),
//       iconTheme: IconThemeData(color: Colors.black),
//     ),

//     // 카드 테마
//     // 사용: lib/app/bbs/bbs_list_page.dart의 게시글 카드
//     // lib/app/weathergogo/weather_gogo_page.dart의 날씨 카드
//     cardTheme: CardTheme(
//       color: cardBackground,
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//     ),

//     // 텍스트 테마
//     // headlineLarge: lib/app/bbs/bbs_view_page.dart의 게시글 제목
//     // headlineMedium: lib/app/weathergogo/weather_gogo_page.dart의 섹션 제목
//     // bodyLarge: 게시글 본문, 댓글 내용
//     // bodyMedium: 부가 정보, 날짜, 작성자 정보
//     // labelLarge: 버튼 텍스트, 링크 텍스트
//     textTheme: const TextTheme(
//       headlineLarge: TextStyle(
//         fontSize: 24,
//         fontWeight: FontWeight.bold,
//         color: textPrimary,
//       ),
//       headlineMedium: TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//         color: textPrimary,
//       ),
//       bodyLarge: TextStyle(
//         fontSize: 16,
//         color: textPrimary,
//       ),
//       bodyMedium: TextStyle(
//         fontSize: 14,
//         color: textSecondary,
//       ),
//       labelLarge: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w600,
//         color: primaryBlue,
//       ),
//     ),

//     // 버튼 테마
//     // 사용: lib/app/auth/login_page.dart의 로그인 버튼
//     // lib/app/bbs/bbs_write_page.dart의 글쓰기 버튼
//     // lib/app/weathergogo/weather_gogo_page.dart의 날씨 검색 버튼
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: primaryBlue,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     ),

//     // 입력 필드 테마
//     // 사용: lib/app/auth/login_page.dart의 이메일/비밀번호 입력
//     // lib/app/bbs/bbs_write_page.dart의 글쓰기 폼
//     // lib/widget/animation_searchbar.dart의 검색창
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: Colors.grey[50],
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: dividerColor),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: dividerColor),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: primaryBlue),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: errorRed),
//       ),
//     ),

//     // 아이콘 테마
//     // 사용: lib/app/bbs/bbs_view_page.dart의 액션 아이콘
//     // lib/app/weathergogo/weather_gogo_page.dart의 날씨 아이콘
//     iconTheme: const IconThemeData(
//       color: iconColor,
//       size: 24,
//     ),

//     // 리스트타일 테마
//     // 사용: lib/app/bbs/bbs_my_list_page.dart의 게시글 목록
//     // lib/app/alram/alram_page.dart의 알림 목록
//     listTileTheme: const ListTileThemeData(
//       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       tileColor: backgroundWhite,
//     ),

//     // 구분선 테마
//     // 사용: lib/app/bbs/bbs_list_page.dart의 게시글 구분선
//     // lib/app/comments/bbs_comments_page.dart의 댓글 구분선
//     dividerTheme: const DividerThemeData(
//       color: dividerColor,
//       thickness: 1,
//       space: 1,
//     ),

//     // 칩 테마
//     // 사용: lib/app/bbs/bbs_search_page.dart의 검색 필터
//     // lib/app/weathergogo/weather_gogo_page.dart의 날씨 태그
//     chipTheme: ChipThemeData(
//       backgroundColor: Colors.grey[100]!,
//       labelStyle: const TextStyle(color: textPrimary),
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//     ),

//     // 탭바 테마
//     // 사용: lib/app/bbs/bbs_view_page.dart의 탭 메뉴
//     // lib/app/weathergogo/weather_gogo_page.dart의 날씨 탭
//     tabBarTheme: const TabBarTheme(
//       labelColor: primaryBlue,
//       unselectedLabelColor: textSecondary,
//       indicatorColor: primaryBlue,
//     ),

//     // 바텀시트 테마
//     // 사용: lib/app/bbs/comments/bbs_comments_bottom_page.dart
//     // lib/app/weathergogo/weather_detail_bottom_sheet.dart
//     bottomSheetTheme: const BottomSheetThemeData(
//       backgroundColor: backgroundWhite,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//     ),

//     // FloatingActionButton 테마
//     // 사용: lib/app/bbs/bbs_list_page.dart의 글쓰기 버튼
//     // lib/app/weathergogo/weather_gogo_page.dart의 새로고침 버튼
//     floatingActionButtonTheme: const FloatingActionButtonThemeData(
//       backgroundColor: Colors.white,
//       foregroundColor: Colors.white,
//     ),

//     // 분홍빛을 완전히 제거하기 위한 설정
//     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     splashColor: Colors.transparent,
//     highlightColor: Colors.transparent,
//     hoverColor: Colors.transparent,
//   );

//   // dark theme 정의
//   static final ThemeData dark = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,

//     // 기본 색상
//     primaryColor: Colors.black,
//     scaffoldBackgroundColor: darkBackground,

//     // AppBar 테마
//     appBarTheme: const AppBarTheme(
//       backgroundColor: darkBackground,
//       foregroundColor: darkTextPrimary,
//       elevation: 0,
//       centerTitle: false,
//       titleSpacing: 0.0,
//       titleTextStyle: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.w600,
//         color: darkTextPrimary,
//       ),
//       iconTheme: IconThemeData(color: darkTextPrimary),
//     ),

//     // 카드 테마
//     cardTheme: CardTheme(
//       color: darkCardBackground,
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//     ),

//     // 텍스트 테마
//     textTheme: const TextTheme(
//       headlineLarge: TextStyle(
//         fontSize: 24,
//         fontWeight: FontWeight.bold,
//         color: darkTextPrimary,
//       ),
//       headlineMedium: TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//         color: darkTextPrimary,
//       ),
//       bodyLarge: TextStyle(
//         fontSize: 16,
//         color: darkTextPrimary,
//       ),
//       bodyMedium: TextStyle(
//         fontSize: 14,
//         color: darkTextSecondary,
//       ),
//       labelLarge: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w600,
//         color: darkPrimaryBlue,
//       ),
//     ),

//     // 버튼 테마
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: darkPrimaryBlue,
//         foregroundColor: darkTextPrimary,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     ),

//     // 입력 필드 테마
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: darkCardBackground,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: darkDividerColor),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: darkDividerColor),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: darkPrimaryBlue),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: errorRed),
//       ),
//     ),

//     // 아이콘 테마
//     iconTheme: const IconThemeData(
//       color: darkIconColor,
//       size: 24,
//     ),

//     // 리스트타일 테마
//     listTileTheme: const ListTileThemeData(
//       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       tileColor: darkCardBackground,
//     ),

//     // 구분선 테마
//     dividerTheme: const DividerThemeData(
//       color: darkDividerColor,
//       thickness: 1,
//       space: 1,
//     ),

//     // 칩 테마
//     chipTheme: ChipThemeData(
//       backgroundColor: darkCardBackground,
//       labelStyle: const TextStyle(color: darkTextPrimary),
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//     ),

//     // 탭바 테마
//     tabBarTheme: const TabBarTheme(
//       labelColor: darkPrimaryBlue,
//       unselectedLabelColor: darkTextSecondary,
//       indicatorColor: darkPrimaryBlue,
//     ),

//     // 바텀시트 테마
//     bottomSheetTheme: const BottomSheetThemeData(
//       backgroundColor: darkCardBackground,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//     ),

//     // FloatingActionButton 테마
//     floatingActionButtonTheme: const FloatingActionButtonThemeData(
//       backgroundColor: darkPrimaryBlue,
//       foregroundColor: darkTextPrimary,
//     ),

//     dialogTheme: const DialogTheme(
//       backgroundColor: Colors.white,
//       titleTextStyle: TextStyle(
//         color: Colors.black,
//         fontSize: 18,
//         fontWeight: FontWeight.w700,
//       ),
//       contentTextStyle: TextStyle(
//         color: Colors.black,
//         fontSize: 14,
//         fontWeight: FontWeight.w400,
//       ),
//     ),
//   );
// }
