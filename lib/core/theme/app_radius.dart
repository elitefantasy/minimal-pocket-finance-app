import 'package:flutter/material.dart';

/// Shared border-radius tokens for Material and custom components.
abstract final class AppRadius {
  static const small = BorderRadius.all(Radius.circular(8));
  static const medium = BorderRadius.all(Radius.circular(12));
  static const large = BorderRadius.all(Radius.circular(16));
  static const extraLarge = BorderRadius.all(Radius.circular(24));
  static const pill = BorderRadius.all(Radius.circular(999));
}
