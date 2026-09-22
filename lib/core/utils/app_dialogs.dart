// path: lib/core/utils/app_dialogs.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Central place for showing a message as a modal popup (instead of a
/// SnackBar) — used everywhere the app previously showed a bottom snackbar
/// for success/error/info feedback, so the person has to actively dismiss
/// it rather than it disappearing on its own.
class AppDialogs {
  AppDialogs._();

  static Future<void> showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
    String? title,
  }) {
    final resolvedTitle = title ?? (isError ? 'Something went wrong' : 'Success');
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.danger : AppColors.neon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(resolvedTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}