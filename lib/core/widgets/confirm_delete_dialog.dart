import 'package:flutter/material.dart';

/// Shared confirmation dialog for destructive-looking actions that are
/// actually a soft delete on the backend (catalog items, customers). Returns
/// `true` only if the user explicitly tapped "Delete".
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  String message = 'It will disappear from lists here, but any past sales or purchases that reference it are unaffected.',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
