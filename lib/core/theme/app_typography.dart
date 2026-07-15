import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const _fontFamily = 'Roboto';

  static TextTheme get textTheme => Typography.material2021().black.apply(
    fontFamily: _fontFamily,
    bodyColor: const Color(0xFF09151A),
    displayColor: const Color(0xFF09151A),
  );
}
