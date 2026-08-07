import 'package:flutter/material.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';

// make a blueprint for a reusable piece of text.
class TitleText extends StatelessWidget {
  // final -> This value is assigned once and cannot be changed.
  final String text;

  const TitleText({
    // this is a constructor
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.text.headlineLarge);
  }
}
