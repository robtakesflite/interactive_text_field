import 'package:flutter/widgets.dart';

import 'plugin_context.dart';

/// Base class for all plugins on an [InteractiveTextController].
///
/// Plugins are pure where possible: [decorate] takes a snapshot of editor
/// state and returns styled ranges. Side effects (overlays, keyboard
/// shortcuts, completion popups) go through [buildOverlay] and [onKeyEvent].
///
/// Plugins are attached/detached as the controller is created or disposed,
/// or as plugins are added/removed at runtime.
abstract class InteractiveTextPlugin {
  PluginContext? _context;

  /// The runtime context. Available only between [onAttach] and [onDetach].
  @protected
  PluginContext get context {
    final ctx = _context;
    assert(
      ctx != null,
      'PluginContext is null. Did you forget to add this plugin to a controller?',
    );
    return ctx!;
  }

  /// Whether this plugin is currently attached to a controller.
  bool get isAttached => _context != null;

  /// A stable identifier; defaults to the runtime type. Override if you
  /// expect multiple instances of the same plugin type on one controller.
  Object get id => runtimeType;

  @mustCallSuper
  void attach(PluginContext ctx) {
    _context = ctx;
    onAttach();
  }

  @mustCallSuper
  void detachInternal() {
    onDetach();
    _context = null;
  }

  void onAttach() {}
  void onDetach() {}

  /// Produce styled ranges for the current editor state. Implementations
  /// must be pure — no side effects. Return an empty result if there is
  /// nothing to decorate.
  DecorationResult decorate(DecorationContext context) =>
      const DecorationResult.empty();

  /// Called after every text change. Plugins may inspect the change but
  /// must not mutate the editor here — use [transformValue] instead.
  void onTextChanged(TextChange change) {}

  /// Called after the selection changes (with or without a text change).
  void onSelectionChanged(TextSelection selection) {}

  /// Allows a plugin to rewrite the incoming [TextEditingValue]. Plugins
  /// run in registration order; whoever transforms wins for that frame.
  /// Return [value] unchanged to no-op.
  TextEditingValue transformValue(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue;

  /// Hardware/IME key handling. Return [KeyEventResult.handled] to consume
  /// the event; [KeyEventResult.ignored] to pass to the next plugin / the
  /// editor itself.
  KeyEventResult onKeyEvent(KeyEvent event) => KeyEventResult.ignored;

  /// Optional overlay widget rendered above the editor. Use this for
  /// completion popups, suggestion menus, etc. Plugins that don't need
  /// an overlay should return null.
  Widget? buildOverlay(BuildContext context) => null;

  /// Contribute a transformation of the field's base [TextStyle]. The
  /// returned style is merged onto whatever style the field is rendering,
  /// affecting *all* text (not specific ranges — for that, use [decorate]).
  ///
  /// Plugins are queried in registration order; each receives the result
  /// of the previous plugin. Return null to pass-through.
  ///
  /// Use this for global, content-driven effects: iMessage-style scaling
  /// where text grows for short messages, all-caps shouting, mood themes.
  TextStyle? overrideBaseStyle(String text, TextStyle current) => null;
}
