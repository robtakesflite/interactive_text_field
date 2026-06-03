import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';

/// A framework-agnostic interactive text field.
///
/// Wraps Flutter's [EditableText] without any Material or Cupertino
/// dependency. Behavior (syntax highlighting, slash commands, completion,
/// markdown styling, …) is contributed by [InteractiveTextPlugin]s
/// attached to the [InteractiveTextController].
///
/// Style this widget by wrapping it in a [DecoratedBox], [Container],
/// or any other decoration widget — the field itself only renders text.
class InteractiveTextField extends StatefulWidget {
  const InteractiveTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.keyboardType,
    this.textInputAction,
    this.cursorColor = const Color(0xFF000000),
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.backgroundCursorColor = const Color(0xFF666666),
    this.selectionColor,
    this.selectionControls,
    this.showCursor,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.scrollPadding = const EdgeInsets.all(20),
    this.enableInteractiveSelection = true,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.contextMenuBuilder,
    this.scrollController,
    this.scrollPhysics,
    this.strutStyle,
    this.textHeightBehavior,
    this.textWidthBasis = TextWidthBasis.parent,
    this.decoration,
    this.padding = EdgeInsets.zero,
    this.locale,
    this.baseStyleAnimationDuration = const Duration(milliseconds: 260),
    this.baseStyleAnimationCurve = Curves.easeOutBack,
  });

  final InteractiveTextController controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Color cursorColor;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color backgroundCursorColor;
  final Color? selectionColor;
  final TextSelectionControls? selectionControls;
  final bool? showCursor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final GestureTapCallback? onTap;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final bool enableSuggestions;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final StrutStyle? strutStyle;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final Decoration? decoration;
  final EdgeInsetsGeometry padding;
  final Locale? locale;

  /// How long to animate transitions of the field's base [TextStyle]
  /// when plugins change [overrideBaseStyle].
  final Duration baseStyleAnimationDuration;

  /// Curve for the base-style animation.
  final Curve baseStyleAnimationCurve;

  @override
  State<InteractiveTextField> createState() => InteractiveTextFieldState();
}

class InteractiveTextFieldState extends State<InteractiveTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditableTextState> _editableTextKey =
      GlobalKey<EditableTextState>();
  FocusNode? _internalFocusNode;
  bool _hasFocus = false;
  late final TextSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableTextKey;

  @override
  bool get forcePressEnabled => true;

  @override
  bool get selectionEnabled =>
      widget.enableInteractiveSelection && !widget.readOnly && widget.enabled;

  EditableTextState? get editableTextState => _editableTextKey.currentState;

  /// Caret rectangle in the editor's local coordinate system, or null if
  /// no caret is currently positioned.
  Rect? caretRectForSelection() {
    final state = _editableTextKey.currentState;
    if (state == null) return null;
    final renderEditable = state.renderEditable;
    final selection = widget.controller.value.selection;
    if (!selection.isValid) return null;
    return renderEditable.getLocalRectForCaret(selection.extent);
  }

  RenderEditable? get renderEditable =>
      _editableTextKey.currentState?.renderEditable;

  FocusNode get effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        TextSelectionGestureDetectorBuilder(delegate: this);
    effectiveFocusNode.addListener(_handleFocusChange);
    widget.controller.attachCaretRectProvider(caretRectForSelection);
  }

  @override
  void didUpdateWidget(covariant InteractiveTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _internalFocusNode?.removeListener(_handleFocusChange);
      effectiveFocusNode.addListener(_handleFocusChange);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.detachCaretRectProvider();
      widget.controller.attachCaretRectProvider(caretRectForSelection);
    }
  }

  void _handleFocusChange() {
    final has = effectiveFocusNode.hasFocus;
    if (has != _hasFocus) {
      setState(() => _hasFocus = has);
    }
  }

  @override
  void dispose() {
    widget.controller.detachCaretRectProvider();
    effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    return widget.controller.dispatchKeyEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = widget.style ??
        const TextStyle(fontSize: 16, color: Color(0xFF000000));
    final effectiveSelectionColor =
        widget.selectionColor ?? const Color(0x4D2196F3);

    final tapHandler = AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        var resolvedStyle = defaultStyle;
        for (final p in widget.controller.plugins) {
          final override = p.overrideBaseStyle(
            widget.controller.text,
            resolvedStyle,
          );
          if (override != null) {
            resolvedStyle = resolvedStyle.merge(override);
          }
        }
        final overlays = widget.controller.buildOverlays(context);

        return TweenAnimationBuilder<TextStyle>(
          tween: TextStyleTween(end: resolvedStyle),
          duration: widget.baseStyleAnimationDuration,
          curve: widget.baseStyleAnimationCurve,
          builder: (context, animatedStyle, _) {
            final editable = RepaintBoundary(
              child: EditableText(
                key: _editableTextKey,
                controller: widget.controller,
                focusNode: effectiveFocusNode,
                readOnly: widget.readOnly || !widget.enabled,
                obscureText: widget.obscureText,
                autocorrect: widget.autocorrect,
                enableSuggestions: widget.enableSuggestions,
                smartDashesType: widget.smartDashesType ??
                    (widget.obscureText
                        ? SmartDashesType.disabled
                        : SmartDashesType.enabled),
                smartQuotesType: widget.smartQuotesType ??
                    (widget.obscureText
                        ? SmartQuotesType.disabled
                        : SmartQuotesType.enabled),
                style: animatedStyle,
                strutStyle: widget.strutStyle,
                cursorColor: widget.cursorColor,
                backgroundCursorColor: widget.backgroundCursorColor,
                cursorWidth: widget.cursorWidth,
                cursorHeight: widget.cursorHeight,
                cursorRadius: widget.cursorRadius,
                selectionColor: _hasFocus ? effectiveSelectionColor : null,
                selectionControls: widget.selectionControls,
                showCursor: widget.showCursor,
                textAlign: widget.textAlign,
                textDirection: widget.textDirection,
                textCapitalization: widget.textCapitalization,
                autofocus: widget.autofocus,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                expands: widget.expands,
                keyboardType: widget.keyboardType ??
                    (widget.maxLines == 1
                        ? TextInputType.text
                        : TextInputType.multiline),
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                onEditingComplete: widget.onEditingComplete,
                onTapOutside: (_) => effectiveFocusNode.unfocus(),
                scrollPadding: widget.scrollPadding,
                enableInteractiveSelection: widget.enableInteractiveSelection,
                contextMenuBuilder: widget.contextMenuBuilder ??
                    _defaultContextMenuBuilder,
                scrollController: widget.scrollController,
                scrollPhysics: widget.scrollPhysics,
                textHeightBehavior: widget.textHeightBehavior,
                textWidthBasis: widget.textWidthBasis,
                locale: widget.locale,
                rendererIgnoresPointer: true,
                paintCursorAboveText: true,
              ),
            );

            return _selectionGestureDetectorBuilder.buildGestureDetector(
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  editable,
                  ...overlays,
                ],
              ),
            );
          },
        );
      },
    );

    final focusWrapped = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: tapHandler,
    );

    Widget content = focusWrapped;
    if (widget.padding != EdgeInsets.zero) {
      content = Padding(padding: widget.padding, child: content);
    }
    if (widget.decoration != null) {
      content = DecoratedBox(decoration: widget.decoration!, child: content);
    }
    return content;
  }
}

/// Minimal Material/Cupertino-free context menu for the editor.
/// Surfaces the standard cut / copy / paste / select-all actions using
/// only `widgets.dart` primitives.
Widget _defaultContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  final items = editableTextState.contextMenuButtonItems;
  if (items.isEmpty) return const SizedBox.shrink();

  final anchor = editableTextState.contextMenuAnchors.primaryAnchor;
  return CustomSingleChildLayout(
    delegate: DesktopTextSelectionToolbarLayoutDelegate(anchor: anchor),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1F000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            _ContextMenuItem(
              label: _contextMenuLabel(item),
              onPressed: item.onPressed,
            ),
        ],
      ),
    ),
  );
}

String _contextMenuLabel(ContextMenuButtonItem item) {
  if (item.label != null) return item.label!;
  switch (item.type) {
    case ContextMenuButtonType.cut:
      return 'Cut';
    case ContextMenuButtonType.copy:
      return 'Copy';
    case ContextMenuButtonType.paste:
      return 'Paste';
    case ContextMenuButtonType.selectAll:
      return 'Select All';
    case ContextMenuButtonType.delete:
      return 'Delete';
    case ContextMenuButtonType.lookUp:
      return 'Look Up';
    case ContextMenuButtonType.searchWeb:
      return 'Search Web';
    case ContextMenuButtonType.share:
      return 'Share';
    case ContextMenuButtonType.liveTextInput:
      return 'Live Text';
    default:
      return '';
  }
}

class _ContextMenuItem extends StatefulWidget {
  const _ContextMenuItem({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  State<_ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Container(
          color: _hovered && enabled
              ? const Color(0xFFEEF5FE)
              : const Color(0x00000000),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              color: enabled
                  ? const Color(0xFF1F1F1F)
                  : const Color(0xFFBDBDBD),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
