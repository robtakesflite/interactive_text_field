import 'package:flutter/widgets.dart';

import 'styled_range.dart';

/// Read-only snapshot of editor state passed to plugins during decoration.
@immutable
class DecorationContext {
  const DecorationContext({
    required this.text,
    required this.selection,
    required this.composing,
    required this.hasFocus,
  });

  final String text;
  final TextSelection selection;
  final TextRange composing;
  final bool hasFocus;
}

/// Mutable context handed to plugins during attach, allowing them to
/// register overlay builders, request rebuilds, read editor state, or
/// write back into the editor.
class PluginContext {
  PluginContext({
    required this.requestRebuild,
    required this.requestOverlayRebuild,
    required this.readEditorState,
    required this.readCaretRect,
    required this.writeValue,
  });

  final VoidCallback requestRebuild;
  final VoidCallback requestOverlayRebuild;
  final DecorationContext Function() readEditorState;
  final Rect? Function() readCaretRect;

  /// Set the controller's [TextEditingValue]. The change is broadcast
  /// through the controller and visible to every plugin's
  /// [onTextChanged] and [onSelectionChanged].
  final void Function(TextEditingValue value) writeValue;
}

/// Snapshot describing a single text change.
@immutable
class TextChange {
  const TextChange({
    required this.oldValue,
    required this.newValue,
  });

  final TextEditingValue oldValue;
  final TextEditingValue newValue;

  String get oldText => oldValue.text;
  String get newText => newValue.text;
  bool get isInsertion => newText.length > oldText.length;
  bool get isDeletion => newText.length < oldText.length;
  bool get isReplacement =>
      newText.length == oldText.length && newText != oldText;
}

@immutable
class DecorationResult {
  const DecorationResult(this.ranges);
  const DecorationResult.empty() : ranges = const <StyledRange>[];

  final List<StyledRange> ranges;
}
