import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_sizes.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class CategorySearchField extends ConsumerStatefulWidget {
  const CategorySearchField({
    required this.categories,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<Category> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<CategorySearchField> createState() => _CategorySearchFieldState();
}

class _CategorySearchFieldState extends ConsumerState<CategorySearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isOpen = false;
  bool _isCreating = false;
  int _highlightedIndex = 0;
  String? _creationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _isOpen = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CategorySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Category> get _matches {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.categories;
    }
    return widget.categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Category? get _exactMatch {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      return null;
    }
    for (final category in widget.categories) {
      if (category.name.toLowerCase() == query) {
        return category;
      }
    }
    return null;
  }

  List<Category> get _similarMatches {
    final query = _controller.text.trim().toLowerCase();
    if (query.length < 3 || _exactMatch != null) {
      return const <Category>[];
    }
    return widget.categories.where((category) {
      final candidate = category.name.toLowerCase();
      final threshold = candidate.length <= 6 ? 2 : 3;
      return _levenshteinDistance(query, candidate) <= threshold;
    }).take(3).toList(growable: false);
  }

  bool get _canCreate => _controller.text.trim().isNotEmpty && _exactMatch == null;

  void _select(String name) {
    _controller.text = name;
    widget.onChanged(name);
    setState(() {
      _isOpen = false;
      _creationError = null;
    });
    _focusNode.unfocus();
  }

  Future<void> _createCategory() async {
    if (!_canCreate || _isCreating) {
      return;
    }
    final name = _controller.text.trim();
    setState(() {
      _isCreating = true;
      _creationError = null;
    });
    final message = await ref.read(categoryNotifierProvider.notifier).addCategory(name);
    if (!mounted) {
      return;
    }
    if (message == null) {
      _select(name);
    } else {
      setState(() => _creationError = message);
    }
    if (mounted) {
      setState(() => _isCreating = false);
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_isOpen) {
      return KeyEventResult.ignored;
    }
    final options = _matches.length + (_canCreate ? 1 : 0);
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _isOpen = false);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && options > 0) {
      setState(() => _highlightedIndex = (_highlightedIndex + 1) % options);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && options > 0) {
      setState(
        () => _highlightedIndex = (_highlightedIndex - 1 + options) % options,
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter && options > 0) {
      if (_highlightedIndex < _matches.length) {
        _select(_matches[_highlightedIndex].name);
      } else {
        _createCategory();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final similarMatches = _similarMatches;

    return Focus(
      onKeyEvent: _onKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              labelText: 'Category',
              hintText: 'Search or create category',
              prefixIcon: Icon(AppIcons.category),
            ),
            textInputAction: TextInputAction.done,
            onTap: () => setState(() => _isOpen = true),
            onChanged: (_) {
              final exactMatch = _exactMatch;
              if (exactMatch != null) {
                widget.onChanged(exactMatch.name);
              }
              setState(() {
                _isOpen = true;
                _highlightedIndex = 0;
                _creationError = null;
              });
            },
            onFieldSubmitted: (_) {
              if (_exactMatch case final exactMatch?) {
                _select(exactMatch.name);
              } else {
                _createCategory();
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Category is required';
              }
              if (_exactMatch == null) {
                return 'Select an existing category or create a new one.';
              }
              return null;
            },
          ),
          if (_isOpen) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Material(
              color: context.colors.surfaceContainer,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: AppSizes.categoryPickerMaxHeight),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    ...matches.indexed.map(
                      (entry) => ListTile(
                        selected: entry.$2.name == widget.value ||
                            entry.$1 == _highlightedIndex,
                        leading: const Icon(AppIcons.category),
                        title: Text(entry.$2.name),
                        onTap: () => _select(entry.$2.name),
                        mouseCursor: SystemMouseCursors.click,
                      ),
                    ),
                    if (similarMatches.isNotEmpty) ...<Widget>[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xs,
                        ),
                        child: Text('Did you mean?'),
                      ),
                      ...similarMatches.map(
                        (category) => ListTile(
                          leading: const Icon(AppIcons.category),
                          title: Text(category.name),
                          onTap: () => _select(category.name),
                          mouseCursor: SystemMouseCursors.click,
                        ),
                      ),
                    ],
                    if (_canCreate)
                      ListTile(
                        selected: _highlightedIndex == matches.length,
                        leading: Icon(AppIcons.add, color: context.colors.primary),
                        title: Text(
                          _isCreating
                              ? 'Creating "${_controller.text.trim()}"...'
                              : 'Create "${_controller.text.trim()}"',
                          style: context.text.bodyLarge?.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                        onTap: _isCreating ? null : _createCategory,
                        mouseCursor: SystemMouseCursors.click,
                      ),
                    const Divider(height: AppSpacing.lg),
                    ListTile(
                      leading: Icon(AppIcons.settings, color: context.colors.secondary),
                      title: Text(
                        'Manage Categories',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => context.push('/categories'),
                      mouseCursor: SystemMouseCursors.click,
                    ),
                  ],
                ),
              ),
            ),
            if (_creationError case final error?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  error,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

int _levenshteinDistance(String source, String target) {
  var previous = List<int>.generate(target.length + 1, (index) => index);
  for (var sourceIndex = 1; sourceIndex <= source.length; sourceIndex++) {
    final current = <int>[sourceIndex];
    for (var targetIndex = 1; targetIndex <= target.length; targetIndex++) {
      final cost = source[sourceIndex - 1] == target[targetIndex - 1] ? 0 : 1;
      current.add(
        <int>[
          current[targetIndex - 1] + 1,
          previous[targetIndex] + 1,
          previous[targetIndex - 1] + cost,
        ].reduce((first, second) => first < second ? first : second),
      );
    }
    previous = current;
  }
  return previous.last;
}
