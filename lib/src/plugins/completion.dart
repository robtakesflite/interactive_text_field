import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../plugin.dart';
import '../plugin_context.dart';

/// What a [CompletionProvider] returns: zero, one, or many candidate
/// continuations of the text at the current cursor.
@immutable
class CompletionResult {
  const CompletionResult({required this.candidates});
  const CompletionResult.none() : candidates = const <CompletionCandidate>[];

  final List<CompletionCandidate> candidates;
  bool get isEmpty => candidates.isEmpty;
}

@immutable
class CompletionCandidate {
  const CompletionCandidate({
    required this.text,
    this.confidence = 1.0,
    this.label,
    this.data,
  });

  /// What gets inserted on accept.
  final String text;

  /// Optional 0..1 score. Highest confidence wins by default.
  final double confidence;

  /// Optional human label; defaults to [text].
  final String? label;

  /// Arbitrary payload for callers (e.g. provenance metadata).
  final Object? data;
}

/// Snapshot passed to [CompletionProvider.complete].
@immutable
class CompletionRequest {
  const CompletionRequest({
    required this.text,
    required this.cursor,
    required this.prefix,
  });

  /// Full editor text.
  final String text;

  /// Cursor offset (TextSelection.extent).
  final int cursor;

  /// The word currently being typed, ending at [cursor]. Convenience for
  /// providers that only care about the word boundary.
  final String prefix;
}

/// Interface for a completion source. Implementations may be:
///   * synchronous & in-memory (e.g. a list of keywords),
///   * asynchronous & network-backed (e.g. an LLM),
///   * a hybrid that returns local results immediately and refines later.
///
/// Providers should respect cancellation: if a new request supersedes an
/// older one, the older one's result will be ignored by the plugin.
abstract class CompletionProvider {
  const CompletionProvider();
  FutureOr<CompletionResult> complete(CompletionRequest request);
}

/// Static word-list provider. Filters the list by the current prefix.
/// Good for trivial demos and language keyword sets.
class StaticListCompletionProvider extends CompletionProvider {
  const StaticListCompletionProvider(this.words);

  final List<String> words;

  @override
  CompletionResult complete(CompletionRequest request) {
    final prefix = request.prefix;
    if (prefix.isEmpty) return const CompletionResult.none();
    final out = <CompletionCandidate>[];
    for (final w in words) {
      if (w.length <= prefix.length) continue;
      if (!w.toLowerCase().startsWith(prefix.toLowerCase())) continue;
      out.add(CompletionCandidate(
        text: w.substring(prefix.length),
        label: w,
      ));
    }
    return CompletionResult(candidates: out);
  }
}

/// Combines results from multiple providers. Async providers are awaited
/// in parallel; results are concatenated in registration order.
class CompositeCompletionProvider extends CompletionProvider {
  const CompositeCompletionProvider(this.providers);

  final List<CompletionProvider> providers;

  @override
  Future<CompletionResult> complete(CompletionRequest request) async {
    final results = await Future.wait(
      providers.map((p) async => await p.complete(request)),
    );
    return CompletionResult(
      candidates: [for (final r in results) ...r.candidates],
    );
  }
}

/// Inline ghost-text completion plugin.
///
/// Displays the highest-confidence candidate as faded text *after* the
/// cursor. Press [acceptKey] (default Tab) to commit. Type any other key
/// to ignore.
///
/// This plugin is the foundation for AI-driven autocomplete: pass an
/// async [CompletionProvider] that talks to an LLM and the same UI and
/// keybindings carry through.
class CompletionPlugin extends InteractiveTextPlugin {
  CompletionPlugin({
    required this.provider,
    this.ghostStyle = const TextStyle(color: Color(0x60000000)),
    Set<LogicalKeyboardKey>? acceptKeys,
    Set<LogicalKeyboardKey>? cycleKeys,
    Set<LogicalKeyboardKey>? dismissKeys,
    this.minPrefix = 1,
    this.debounce = const Duration(milliseconds: 80),
    this.priority = 0,
  })  : acceptKeys = acceptKeys ?? {LogicalKeyboardKey.tab},
        cycleKeys = cycleKeys ?? <LogicalKeyboardKey>{},
        dismissKeys = dismissKeys ?? {LogicalKeyboardKey.escape};

  final CompletionProvider provider;
  final TextStyle ghostStyle;
  final Set<LogicalKeyboardKey> acceptKeys;
  final Set<LogicalKeyboardKey> cycleKeys;
  final Set<LogicalKeyboardKey> dismissKeys;
  final int minPrefix;
  final Duration debounce;
  final int priority;

  List<CompletionCandidate> _candidates = const [];
  int _selectedIndex = 0;
  int _requestGeneration = 0;
  Timer? _debounceTimer;
  int _lastCursorForCandidates = -1;
  String _lastTextForCandidates = '';

  /// The candidate currently shown as ghost text (or null if none).
  CompletionCandidate? get currentCandidate =>
      _candidates.isEmpty ? null : _candidates[_selectedIndex];

  /// All candidates produced by the last completion request.
  List<CompletionCandidate> get candidates => List.unmodifiable(_candidates);

  bool get hasSuggestion => _candidates.isNotEmpty;

  @override
  void onTextChanged(TextChange change) {
    _schedule();
  }

  @override
  void onSelectionChanged(TextSelection selection) {
    if (selection.isCollapsed &&
        selection.extent.offset != _lastCursorForCandidates) {
      _clear();
      _schedule();
    }
  }

  void _schedule() {
    _debounceTimer?.cancel();
    if (debounce == Duration.zero) {
      _request();
    } else {
      _debounceTimer = Timer(debounce, _request);
    }
  }

  void _request() async {
    final state = context.readEditorState();
    if (!state.selection.isValid || !state.selection.isCollapsed) {
      _clear();
      return;
    }
    final cursor = state.selection.extent.offset;
    final prefix = _wordPrefix(state.text, cursor);
    if (prefix.length < minPrefix) {
      _clear();
      return;
    }
    final gen = ++_requestGeneration;
    try {
      final result = await Future.value(provider.complete(
        CompletionRequest(text: state.text, cursor: cursor, prefix: prefix),
      ));
      if (gen != _requestGeneration) return;
      final cur = context.readEditorState();
      if (cur.selection.extent.offset != cursor || cur.text != state.text) {
        return;
      }
      if (result.candidates.isEmpty) {
        _clear();
        return;
      }
      _candidates = List.of(result.candidates)
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      _selectedIndex = 0;
      _lastCursorForCandidates = cursor;
      _lastTextForCandidates = cur.text;
      context.requestOverlayRebuild();
    } catch (_) {
      if (gen != _requestGeneration) return;
      _clear();
    }
  }

  String _wordPrefix(String text, int cursor) {
    int start = cursor;
    while (start > 0) {
      final code = text.codeUnitAt(start - 1);
      final isWord = (code >= 0x30 && code <= 0x39) ||
          (code >= 0x41 && code <= 0x5A) ||
          (code >= 0x61 && code <= 0x7A) ||
          code == 0x5F;
      if (!isWord) break;
      start--;
    }
    return text.substring(start, cursor);
  }

  void _clear() {
    if (_candidates.isEmpty) return;
    _candidates = const [];
    _selectedIndex = 0;
    _requestGeneration++;
    context.requestOverlayRebuild();
  }

  /// Programmatically clear the inline suggestion.
  void clear() => _clear();

  /// Accept the currently shown ghost suggestion. No-op if there's none.
  void acceptCurrent() {
    final cand = currentCandidate;
    if (cand == null) return;
    final state = context.readEditorState();
    final cursor = state.selection.extent.offset;
    if (cursor != _lastCursorForCandidates ||
        state.text != _lastTextForCandidates) {
      return;
    }
    final newText = state.text.substring(0, cursor) +
        cand.text +
        state.text.substring(cursor);
    final newOffset = cursor + cand.text.length;
    context.writeValue(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      ),
    );
    _clear();
  }

  void cycleNext() {
    if (_candidates.length < 2) return;
    _selectedIndex = (_selectedIndex + 1) % _candidates.length;
    context.requestOverlayRebuild();
  }

  void cyclePrevious() {
    if (_candidates.length < 2) return;
    _selectedIndex =
        (_selectedIndex - 1 + _candidates.length) % _candidates.length;
    context.requestOverlayRebuild();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (!hasSuggestion) return KeyEventResult.ignored;
    if (acceptKeys.contains(key)) {
      acceptCurrent();
      return KeyEventResult.handled;
    }
    if (cycleKeys.contains(key)) {
      cycleNext();
      return KeyEventResult.handled;
    }
    if (dismissKeys.contains(key)) {
      _clear();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // Inline completion is rendered via [buildOverlay] as ghost text, not as
  // a styled range over the editor's own buffer. No decoration ranges
  // contributed.

  @override
  Widget? buildOverlay(BuildContext context) {
    final cand = currentCandidate;
    if (cand == null) return null;
    final rect = this.context.readCaretRect();
    if (rect == null) return null;
    return Positioned(
      left: rect.right,
      top: rect.top,
      child: IgnorePointer(
        child: Text(
          cand.text,
          style: ghostStyle,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }

  @override
  void onDetach() {
    _debounceTimer?.cancel();
    super.onDetach();
  }
}
