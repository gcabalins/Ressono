import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Defines reusable text styles for the application.
/// 
/// All typography styles should be declared here to maintain
/// consistency and simplify global style updates.
class AppTextStyles {

  /// Style used for primary titles.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Style used for subtitles and secondary text.
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  /// Style used for button labels.
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
}