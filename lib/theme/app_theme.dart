// import 'package:flutter/material.dart';
// import 'package:project1/theme/color_data.dart';
// import 'package:project1/theme/app_colors.dart';

// class AppTheme {
//   // Light Theme
//   static final ThemeData light = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,

//     // colorScheme: ColorScheme.fromSeed(
//     //   seedColor: Colors.white,
//     //   surface: Colors.white,
//     //   // primary: primaryBlue,
//     // ),

//     // 기본 색상
//     primaryColor: ColorsData.primary,
//     scaffoldBackgroundColor: ColorsData.white,

//     // ColorScheme
//     colorScheme: const ColorScheme.light(
//       primary: ColorsData.primary,

//       secondary: ColorsData.secondary,
//       surface: ColorsData.white,
//       // background: ColorsData.white,
//       error: ColorsData.error,
//       onPrimary: ColorsData.white,
//       onSecondary: ColorsData.white,
//       onSurface: ColorsData.textPrimary,
//       // onBackground: ColorsData.textPrimary,
//       onError: ColorsData.white,
//     ),

//     // AppBar Theme
//     appBarTheme: const AppBarTheme(
//       backgroundColor: ColorsData.appBarBackground,
//       foregroundColor: ColorsData.appBarText,
//       elevation: 0,
//       titleSpacing: 0.0,
//       centerTitle: false,
//       iconTheme: IconThemeData(color: ColorsData.appBarIcon),
//       titleTextStyle: TextStyle(
//         color: ColorsData.textPrimary,
//         fontSize: ColorsData.fontSizeLarge,
//         fontWeight: FontWeight.w600,
//       ),
//     ),

//     // Text Theme
//     textTheme: const TextTheme(
//       headlineLarge: TextStyle(color: ColorsData.textPrimary),
//       headlineMedium: TextStyle(color: ColorsData.textPrimary),
//       bodyLarge: TextStyle(color: ColorsData.textPrimary),
//       bodyMedium: TextStyle(color: ColorsData.textSecondary),
//       labelLarge: TextStyle(color: ColorsData.textPrimary),
//     ),

//     // Icon Theme
//     iconTheme: const IconThemeData(
//       color: ColorsData.iconBlack,
//       size: ColorsData.iconSizeMedium,
//     ),

//     // Card Theme
//     // cardTheme: CardTheme(
//     //   color: ColorsData.white,
//     //   elevation: 2,
//     //   shape: RoundedRectangleBorder(
//     //     borderRadius: BorderRadius.circular(ColorsData.radiusMedium),
//     //   ),
//     // ),

//     // Chip Theme
//     chipTheme: ChipThemeData(
//       backgroundColor: ColorsData.chipBackground,
//       labelStyle: const TextStyle(color: ColorsData.chipText),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(ColorsData.radiusMedium),
//       ),
//     ),

//     // Input Decoration Theme
//     inputDecorationTheme: InputDecorationTheme(
//       fillColor: ColorsData.inputBackground,
//       filled: true,
//       labelStyle: const TextStyle(color: ColorsData.inputLabel),
//       border: OutlineInputBorder(
//         borderSide: const BorderSide(color: ColorsData.inputBorder),
//         borderRadius: BorderRadius.circular(ColorsData.radiusMedium),
//       ),
//     ),

//     // Progress Indicator Theme
//     progressIndicatorTheme: const ProgressIndicatorThemeData(
//       color: ColorsData.progressBarActive,
//       linearTrackColor: ColorsData.progressBarInactive,
//     ),

//     extensions: [
//       AppColors.light,
//     ],
//   );

//   // Dark Theme
//   static final ThemeData dark = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,

//     // 기본 색상
//     primaryColor: ColorsData.darkPrimary,
//     scaffoldBackgroundColor: ColorsData.darkPrimary,

//     // ColorScheme
//     colorScheme: ColorScheme.dark(
//       primary: ColorsData.darkPrimary,
//       secondary: ColorsData.darkSecondary,
//       surface: ColorsData.darkGrey100,
//       background: ColorsData.darkPrimary,
//       error: ColorsData.darkError,
//       onPrimary: ColorsData.darkTextPrimary,
//       onSecondary: ColorsData.darkTextPrimary,
//       onSurface: ColorsData.darkTextPrimary,
//       onBackground: ColorsData.darkTextPrimary,
//       onError: ColorsData.darkTextPrimary,
//     ),

//     // AppBar Theme
//     appBarTheme: const AppBarTheme(
//       backgroundColor: ColorsData.darkAppBarBackground,
//       foregroundColor: ColorsData.darkAppBarText,
//       elevation: 0,
//       iconTheme: IconThemeData(color: ColorsData.darkAppBarIcon),
//       titleTextStyle: TextStyle(
//         color: ColorsData.darkTextPrimary,
//         fontSize: ColorsData.fontSizeLarge,
//         fontWeight: FontWeight.w600,
//       ),
//     ),

//     // Text Theme
//     textTheme: const TextTheme(
//       headlineLarge: TextStyle(color: ColorsData.darkTextPrimary),
//       headlineMedium: TextStyle(color: ColorsData.darkTextPrimary),
//       bodyLarge: TextStyle(color: ColorsData.darkTextPrimary),
//       bodyMedium: TextStyle(color: ColorsData.darkTextSecondary),
//       labelLarge: TextStyle(color: ColorsData.darkTextPrimary),
//     ),

//     // Icon Theme
//     iconTheme: const IconThemeData(
//       color: ColorsData.darkIconWhite,
//       size: ColorsData.iconSizeMedium,
//     ),

//     // Card Theme
//     // cardTheme: CardTheme(
//     //   color: ColorsData.darkGrey100,
//     //   elevation: 2,
//     //   shape: RoundedRectangleBorder(
//     //     borderRadius: BorderRadius.circular(ColorsData.radiusMedium),
//     //   ),
//     // ),

//     // Chip Theme
//     chipTheme: ChipThemeData(
//       backgroundColor: ColorsData.darkChipBackground,
//       labelStyle: const TextStyle(color: ColorsData.darkChipText),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(ColorsData.radiusMedium),
//       ),
//     ),

//     // Input Decoration Theme
//     inputDecorationTheme: InputDecorationTheme(
//       fillColor: ColorsData.darkInputBackground,
//       filled: true,
//       labelStyle: const TextStyle(color: ColorsData.darkInputLabel),
//       border: OutlineInputBorder(
//         borderSide: const BorderSide(color: ColorsData.darkInputBorder),
//         borderRadius: BorderRadius.circular(ColorsData.radiusMedium),
//       ),
//     ),

//     // Progress Indicator Theme
//     progressIndicatorTheme: const ProgressIndicatorThemeData(
//       color: ColorsData.darkProgressBarActive,
//       linearTrackColor: ColorsData.darkProgressBarInactive,
//     ),

//     extensions: [
//       AppColors.dark,
//     ],
//   );
// }

// extension AppThemeExtension on BuildContext {
//   AppColors get colors => Theme.of(this).extension<AppColors>()!;
// }
