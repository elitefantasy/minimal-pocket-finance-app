import 'package:flutter/material.dart';

/// Shared color tokens for the Minimal Pocket Finance light theme.
abstract final class AppColors {
  // base
  static const background = Color(0xFFF8FBFD);
  static const surface = Color(0xFFFFFFFF);
  
  // Text
  static const text = Color(0xFF09151A);
  
  // Brand Colors
  static const primary = Color(0xFF389CE2);
  static const secondary = Color(0xFF4F6FD8);
  static const accent = Color(0xFF5C6AC4);
  
  // Semantic Colors
  static const success = Color(0xFF3FAE72);
  static const warning = Color(0xFFE9A23B);
  static const error = Color(0xFFD85A5A);
  static const info = Color(0xFF4C8EDB);
  static const border = Color(0xFFDCE5E8);
  static const divider = Color(0xFFEAF0F2);
  static const disabled = Color(0xFF9AA7AD);

  //static const onPrimary = text;
  static const onPrimary = Color(0xFFFFFFFF);
  //static const onSecondary = surface;
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSurface = text;
  static const onError = surface;
}
