import 'package:flutter/material.dart';

/// Reusable form field helpers for request forms
class RequestFormFields {
  /// Form label text
  static Widget label(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
