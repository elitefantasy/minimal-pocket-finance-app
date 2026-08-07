// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core & Notification imports
import 'package:minimal_pocket_finance_app/core/notifications/app_snackbar_service.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_durations.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';

// Model imports
import 'package:minimal_pocket_finance_app/models/attachment.dart';
import 'package:minimal_pocket_finance_app/models/transaction.dart';

// Application State/Notifier imports
import 'package:minimal_pocket_finance_app/features/categories/application/category_notifier.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';

// Presentation Widget imports
import 'package:minimal_pocket_finance_app/features/attachments/presentation/widgets/attachment_picker_section.dart';
import 'package:minimal_pocket_finance_app/features/transactions/presentation/widgets/amount_field.dart';
import 'package:minimal_pocket_finance_app/features/transactions/presentation/widgets/category_search_field.dart';
import 'package:minimal_pocket_finance_app/features/transactions/presentation/widgets/date_picker_field.dart';
import 'package:minimal_pocket_finance_app/features/transactions/presentation/widgets/note_field.dart';

/// Screen that provides input controls to modify an existing transaction record.
class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({required this.transaction, super.key});

  final Transaction transaction;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  // Global form key for tracking field validation states
  final _formKey = GlobalKey<FormState>();

  // Text fields controllers
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  // Trackable form state fields
  late String _selectedCategory;
  late DateTime _selectedDate;
  late List<Attachment> _attachments;
  bool _isSaving = false;
  bool _showNoteField = false;

  @override
  void initState() {
    super.initState();
    // Populate form fields with the initial values from the passed transaction
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _noteController = TextEditingController(text: widget.transaction.note);

    // Automatically expand the note field if a note already exists
    _showNoteField = widget.transaction.note.trim().isNotEmpty;
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;
    _attachments = List<Attachment>.from(widget.transaction.attachments);
  }

  @override
  void dispose() {
    // Dispose text controllers to prevent performance and memory leaks
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Packages form data and updates the transaction record via Riverpod.
  Future<void> _save() async {
    // Stop duplicate calls or validation failures early
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build a fresh immutable instance using the modified fields
      final updatedTransaction = widget.transaction.copyWith(
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        note: _noteController.text.trim(),
        date: _selectedDate,
        attachments: _attachments,
      );

      // Dispatch update request to the global transaction state notifier
      await ref
          .read(transactionNotifierProvider.notifier)
          .updateTransaction(updatedTransaction);

      // Check context mount before invoking navigation pop out of async gap
      if (mounted) {
        context.pop();
      }
    } on Object catch (error) {
      if (!mounted) return;

      // Render a notification detailing why the transaction could not be written
      ref
          .read(appSnackbarProvider)
          .showError('Unable to update transaction: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reactive handle to fetch user categories from the backend/database
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          data: (categories) => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                // Numerical transaction total entry input field
                AmountField(controller: _amountController),
                const SizedBox(height: AppSpacing.lg),

                // Category selector dropdown
                CategorySearchField(
                  categories: categories,
                  value: _selectedCategory,
                  onChanged: (category) {
                    if (category != null) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Checkbox toggle displaying or hiding the extra note field
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(AppIcons.note),
                  title: Text('Add note', style: context.text.titleSmall),
                  value: _showNoteField,
                  onChanged: (value) {
                    setState(() {
                      _showNoteField = value ?? false;
                      // Instantly wipe existing text state clean if user unchecks it
                      if (!_showNoteField) {
                        _noteController.clear();
                      }
                    });
                  },
                ),

                // Smooth transitional element ensuring clear layout expansion for the note field
                AnimatedSwitcher(
                  duration: AppDurations.normal,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      alignment: Alignment.topCenter,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: _showNoteField
                      ? Padding(
                          key: const ValueKey('note_field'),
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: NoteField(controller: _noteController),
                        )
                      : const SizedBox(key: ValueKey('empty_note')),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Date selection field anchor
                DatePickerField(
                  selectedDate: _selectedDate,
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Attachments section
                AttachmentPickerSection(
                  attachments: _attachments,
                  onAttachmentsChanged: (updated) {
                    setState(() => _attachments = updated);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Core execution button updating database storage
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
