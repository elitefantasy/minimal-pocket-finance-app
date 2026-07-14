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
    final messenger = messengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(
          messenger.context,
        ).snackBarTheme.backgroundColor,
        content: Row(
          children: <Widget>[
            Expanded(child: Text(message)),
            TextButton(
              onPressed: () async {
                messenger.hideCurrentSnackBar();

                try {
                  await onUndo();
                } on Object catch (error) {
                  showError('Unable to undo: $error');
                }
              },
              child: const Text('UNDO'),
            ),
          ],
        ),
      ),
    );
  }

  void _show({
    required String message,
    Duration? duration,
    Color? backgroundColor,
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
      ),
    );
  }
}

final appSnackbarProvider = Provider<AppSnackbarService>((ref) {
  return AppSnackbarService();
});
