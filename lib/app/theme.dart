import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Vibrant Emerald
  static const Color primary = Color(0xFF05A66B);
  static const Color primaryDark = Color(0xFF024B30);
  static const Color primaryLight = Color(0xFFE0F7EC);
  static const Color success = Color(0xFF00C675);
  static const Color successLight = Color(0xFFE0F9ED);
  static const Color courier = Color(0xFFF5A623);
  static const Color courierLight = Color(0xFFFEF5E6);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningLight = Color(0xFFFEF5E6);
  static const Color danger = Color(0xFFFF4B4B);
  static const Color dangerLight = Color(0xFFFFEDED);
  static const Color info = Color(0xFF2B78FF);
  static const Color infoLight = Color(0xFFE8F1FF);
  
  static const Color grayBg = Color(0xFFF4F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF2F0);
  static const Color grayText = Color(0xFF88968F);
  static const Color border = Colors.transparent;
  static const Color textPrimary = Color(0xFF1A211E);
  static const Color textSecondary = Color(0xFF5D6B64);
  
  // Gradients can be used in specific widgets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C675), Color(0xFF05A66B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSizes {
  static const double radiusSm = 8.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double buttonHeight = 52.0;
  static const double inputHeight = 50.0;
  static const double horizontalPadding = 16.0;
  static const double bottomNavHeight = 72.0;
}

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.interTextTheme();
  
  return ThemeData(
    useMaterial3: true,
    textTheme: baseTextTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.success,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.grayBg,
    dividerColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.grayBg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: const Color(0x14000000), // 8% black shadow
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surfaceMuted,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: AppSizes.bottomNavHeight,
      backgroundColor: Colors.white,
      indicatorColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: AppColors.grayText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: AppColors.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      thickness: 1,
      space: 1,
    ),
  );
}

ThemeData buildDarkTheme() {
  const darkSurface = Color(0xFF1E2622);
  const darkBg = Color(0xFF121614);
  const darkBorder = Colors.transparent;
  const darkText = Color(0xFFE2E9E5);
  const darkTextSec = Color(0xFFA1AEA6);

  final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: darkText,
    displayColor: darkText,
  );

  return ThemeData(
    useMaterial3: true,
    textTheme: baseTextTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.success,
      error: AppColors.danger,
      surface: darkSurface,
      onSurface: darkText,
    ),
    scaffoldBackgroundColor: darkBg,
    dividerColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 12,
      shadowColor: const Color(0x33000000), // 20% black shadow for dark mode
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        elevation: 6,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkText,
        backgroundColor: darkBg,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: AppSizes.bottomNavHeight,
      backgroundColor: darkSurface,
      indicatorColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : darkTextSec,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : darkTextSec,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBg,
      labelStyle: const TextStyle(
        color: darkTextSec,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: darkTextSec),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: darkBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: darkBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: darkText,
      contentTextStyle: const TextStyle(color: darkBg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      modalBackgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
    ),
  );
}
