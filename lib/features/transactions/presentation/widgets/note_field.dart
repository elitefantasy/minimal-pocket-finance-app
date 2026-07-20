import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:flutter/material.dart';

class NoteField extends StatelessWidget {
  const NoteField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Note',
        prefixIcon: Icon(AppIcons.note),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
