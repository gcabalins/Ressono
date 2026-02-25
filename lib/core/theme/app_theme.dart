import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Provides the global theme configuration for the application.
/// 
/// This class defines the visual behavior of Material components,
/// including color scheme, scaffold background, and AppBar styling.
class AppTheme {

  /// Dark theme configuration used throughout the application.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    /// Global scaffold background color.
    scaffoldBackgroundColor: AppColors.background,

    /// Primary color reference.
    primaryColor: AppColors.primaryGold,

    /// AppBar default styling.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
    ),

    /// Application color scheme based on dark mode.
    colorScheme: const ColorScheme.dark().copyWith(
      primary: AppColors.primaryGold,
    ),
  );
}