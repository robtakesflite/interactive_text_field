import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'plugin.dart';
import 'plugin_context.dart';
import 'range_merge.dart';
import 'styled_range.dart';

typedef RangeRecognizerFactory = GestureRecognizer? Function(StyledRange range);

/// A [TextEditingController] that composes styled ranges from a stack of
/// [InteractiveTextPlugin]s and renders them via [buildTextSpan].
///
/// Plugins are kept in a registry and notified of text/selection changes.
/// They contribute [StyledRange]s which are merged with priority into a
/// flat [TextSpan] tree before rendering.
class InteractiveTextController extends TextEditingController {
  InteractiveTextController({
    super.text,
    List<InteractiveTextPlugin>? plugins,
    RangeRecognizerFactory? recognizerFactory,
  }) : _recognizerFactory = recognizerFactory {
    if (plugins != null) {
      for (final p in plugins) {
        _attach(p);
      }
    }
    addListener(_handleValueChanged);
  }

  final List<InteractiveTextPlugin> _plugins = <InteractiveTextPlugin>[];
  RangeRecognizerFactory? _recognizerFactory;
  TextEditingValue _previousValue = TextEditingValue.empty;
  Rect? Function()? _caretRectProvider;

  bool _disposed = false;

  /// Wire-up: called by the widget host so plugins can ask for the caret
  /// rect (e.g. to position popups). Returns null if no field is attached
  /// or if the caret isn't currently positioned.
  Rect? caretRect() => _caretRectProvider?.call();

  /// Internal: bound by [InteractiveTextField]. Don't call from app code.
  // ignore: use_setters_to_change_properties
  void attachCaretRectProvider(Rect? Function() provider) {
    _caretRectProvider = provider;
  }

  void detachCaretRectProvider() {
    _caretRectProvider = null;
  }

  /// Set the recognizer factory for converting [StyledRange]s into
  /// gesture recognizers (e.g. tappable links). Replaces the existing one.
  set recognizerFactory(RangeRecognizerFactory? factory) {
    _recognizerFactory = factory;
    notifyListeners();
  }

  /// Read-only view of currently registered plugins.
  List<InteractiveTextPlugin> get plugins => List.unmodifiable(_plugins);

  T? findPlugin<T extends InteractiveTextPlugin>() {
    for (final p in _plugins) {
      if (p is T) return p;
    }
    return null;
  }

  void addPlugin(InteractiveTextPlugin plugin) {
    _attach(plugin);
    notifyListeners();
  }

  void removePlugin(InteractiveTextPlugin plugin) {
    final removed = _plugins.remove(plugin);
    if (removed) {
      plugin.detachInternal();
      notifyListeners();
    }
  }

  void _attach(InteractiveTextPlugin plugin) {
    final ctx = PluginContext(
      requestRebuild: _safeNotify,
      requestOverlayRebuild: _safeNotify,
      readEditorState: _snapshot,
      readCaretRect: () => _caretRectProvider?.call(),
      writeValue: (v) => value = v,
    );
    plugin.attach(ctx);
    _plugins.add(plugin);
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  DecorationContext _snapshot() {
    return DecorationContext(
      text: value.text,
      selection: value.selection,
      composing: value.composing,
      hasFocus: true,
    );
  }

  void _handleValueChanged() {
    final old = _previousValue;
    final cur = value;
    _previousValue = cur;
    if (old.text != cur.text) {
      final change = TextChange(oldValue: old, newValue: cur);
      for (final p in _plugins) {
        p.onTextChanged(change);
      }
    }
    if (old.selection != cur.selection) {
      for (final p in _plugins) {
        p.onSelectionChanged(cur.selection);
      }
    }
  }

  /// Internal flag to prevent re-entry when applying transforms in
  /// the [value] setter.
  bool _applyingTransform = false;

  @override
  set value(TextEditingValue newValue) {
    if (_applyingTransform || _plugins.isEmpty) {
      super.value = newValue;
      return;
    }
    _applyingTransform = true;
    try {
      var working = newValue;
      for (final p in _plugins) {
        working = p.transformValue(value, working);
      }
      super.value = working;
    } finally {
      _applyingTransform = false;
    }
  }

  /// Dispatch a key event through plugins. Returns the first non-ignored
  /// result, or [KeyEventResult.ignored] if no plugin handles it.
  KeyEventResult dispatchKeyEvent(KeyEvent event) {
    for (final p in _plugins) {
      final r = p.onKeyEvent(event);
      if (r != KeyEventResult.ignored) return r;
    }
    return KeyEventResult.ignored;
  }

  /// Collect overlays from every plugin. Order matches plugin registration.
  List<Widget> buildOverlays(BuildContext context) {
    final overlays = <Widget>[];
    for (final p in _plugins) {
      final w = p.buildOverlay(context);
      if (w != null) overlays.add(w);
    }
    return overlays;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final snapshot = DecorationContext(
      text: value.text,
      selection: value.selection,
      composing: value.composing,
      hasFocus: true,
    );

    final ranges = <StyledRange>[];
    for (final p in _plugins) {
      ranges.addAll(p.decorate(snapshot).ranges);
    }

    final children = mergeRangesToSpans(
      text: value.text,
      ranges: ranges,
      baseStyle: style,
      recognizerFor: _recognizerFactory,
    );

    if (!withComposing || !value.isComposingRangeValid) {
      return TextSpan(style: style, children: children);
    }

    final composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            const TextStyle(decoration: TextDecoration.underline);

    return TextSpan(
      style: style,
      children: _applyComposingUnderline(
        children,
        value.composing,
        composingStyle,
      ),
    );
  }

  List<TextSpan> _applyComposingUnderline(
    List<TextSpan> spans,
    TextRange composing,
    TextStyle composingStyle,
  ) {
    final out = <TextSpan>[];
    int offset = 0;
    for (final span in spans) {
      final text = span.text ?? '';
      final spanStart = offset;
      final spanEnd = offset + text.length;
      offset = spanEnd;

      final compStart = composing.start;
      final compEnd = composing.end;
      if (compEnd <= spanStart || compStart >= spanEnd) {
        out.add(span);
        continue;
      }

      final localStart = (compStart - spanStart).clamp(0, text.length);
      final localEnd = (compEnd - spanStart).clamp(0, text.length);
      if (localStart > 0) {
        out.add(TextSpan(text: text.substring(0, localStart), style: span.style));
      }
      out.add(TextSpan(
        text: text.substring(localStart, localEnd),
        style: (span.style ?? const TextStyle()).merge(composingStyle),
      ));
      if (localEnd < text.length) {
        out.add(TextSpan(text: text.substring(localEnd), style: span.style));
      }
    }
    return out;
  }

  @override
  void dispose() {
    _disposed = true;
    removeListener(_handleValueChanged);
    for (final p in List.of(_plugins)) {
      p.detachInternal();
    }
    _plugins.clear();
    super.dispose();
  }
}
