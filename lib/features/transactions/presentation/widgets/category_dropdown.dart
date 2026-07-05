import 'package:akm_finance_manager/models/category.dart';
import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<Category> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category.name,
              child: Text(category.name),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
      validator: (selectedCategory) {
        if (selectedCategory == null || selectedCategory.isEmpty) {
          return 'Category is required';
        }
        return null;
      },
    );
  }
}
