import 'package:flutter/services.dart';

/// Blocks paste operations by rejecting any new value that is longer
/// than the old value by more than a threshold (indicating a paste).
/// Single character typing is always allowed.
class NoPasteFormatter extends TextInputFormatter {
  /// Max characters that can appear in a single edit. Anything above
  /// this is treated as a paste and rejected. Default 2 allows for
  /// autocorrect/autocomplete inserting a couple chars.
  final int maxNewCharsPerEdit;

  NoPasteFormatter({this.maxNewCharsPerEdit = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow deletions always
    if (newValue.text.length <= oldValue.text.length) return newValue;

    // Calculate how many new characters were added
    final added = newValue.text.length - oldValue.text.length;

    // If more than threshold, it's likely a paste — reject
    if (added > maxNewCharsPerEdit) return oldValue;

    return newValue;
  }
}
