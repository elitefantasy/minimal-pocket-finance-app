import 'dart:async';

import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/features/recurring/application/recurring_notifier.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/services/recurring_processing_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringProcessingServiceProvider = Provider<RecurringProcessingService>(
  (ref) {
    return RecurringProcessingService(ref.watch(recurringRepositoryProvider));
  },
);

final recurringLifecycleProvider = Provider<RecurringLifecycleController>((
  ref,
) {
  final controller = RecurringLifecycleController(ref);
  ref.onDispose(controller.dispose);
  controller.start();
  return controller;
});

class RecurringLifecycleController with WidgetsBindingObserver {
  RecurringLifecycleController(this._ref);

  final Ref _ref;
  bool _isProcessing = false;
  bool _hasLeftForeground = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_processSafely());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _hasLeftForeground = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _hasLeftForeground) {
      _hasLeftForeground = false;
      unawaited(_processSafely());
    }
  }

  Future<void> _processSafely() async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    try {
      final generatedCount = await _ref
          .read(recurringProcessingServiceProvider)
          .processDueTransactions();
      if (generatedCount > 0) {
        _ref
          ..invalidate(transactionNotifierProvider)
          ..invalidate(recurringNotifierProvider);
      }
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'recurring transaction processing',
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }
}
