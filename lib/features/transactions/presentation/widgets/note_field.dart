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
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
