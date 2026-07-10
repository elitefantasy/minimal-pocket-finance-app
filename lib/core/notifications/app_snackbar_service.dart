import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef SnackbarUndoCallback = Future<void> Function();

class AppSnackbarService {
  AppSnackbarService();

  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void showSuccess(String message, {Duration? duration}) {
    _show(
      message: message,
      duration: duration,
      backgroundColor: Colors.green.shade700,
    );
  }

  void showError(String message, {Duration? duration}) {
    _show(
      message: message,
      duration: duration,
      backgroundColor: Colors.red.shade700,
    );
  }

  void showInfo(String message, {Duration? duration}) {
    _show(message: message, duration: duration);
  }

  void showUndo({
    required String message,
    required SnackbarUndoCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    _show(
      message: message,
      duration: duration,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          try {
            await onUndo();
          } on Object catch (error) {
            showError('Unable to undo: $error');
          }
        },
      ),
    );
  }

  void _show({
    required String message,
    Duration? duration,
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) {
      return;
    }

    // Clearing first prevents old SnackBars from waiting in a queue.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        action: action,
      ),
    );
  }
}

final appSnackbarProvider = Provider<AppSnackbarService>((ref) {
  return AppSnackbarService();
});
