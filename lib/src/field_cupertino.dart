import 'package:flutter/cupertino.dart';

import 'controller.dart';
import 'field.dart';

/// A Cupertino-themed [InteractiveTextField].
///
/// Reads defaults from the ambient [CupertinoThemeData] (cursor color,
/// selection color, text style, selection handles, context menu) so the
/// field matches the rest of a Cupertino app without manual styling.
///
/// All parameters override the theme-resolved defaults when supplied.
class CupertinoInteractiveTextField extends StatelessWidget {
  const CupertinoInteractiveTextField({
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
    this.cursorColor,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius = const Radius.circular(2.0),
    this.backgroundCursorColor,
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
    this.baseStyleAnimationDuration = const Duration(milliseconds: 220),
    this.baseStyleAnimationCurve = Curves.easeOutCubic,
    this.mouseCursor,
    this.cursorOpacityAnimates = true,
    this.forcePressEnabled = true,
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
  final Color? cursorColor;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? backgroundCursorColor;
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
  final Duration baseStyleAnimationDuration;
  final Curve baseStyleAnimationCurve;
  final MouseCursor? mouseCursor;

  /// Cupertino defaults to `true` to match native iOS cursor blink.
  final bool cursorOpacityAnimates;
  final bool forcePressEnabled;

  static Widget _adaptiveContextMenu(
    BuildContext context,
    EditableTextState state,
  ) {
    return CupertinoAdaptiveTextSelectionToolbar.editableText(
      editableTextState: state,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    final resolvedCursorColor = cursorColor ?? theme.primaryColor;
    final resolvedSelectionColor =
        selectionColor ?? theme.primaryColor.withValues(alpha: 0.2);
    final resolvedStyle = style ?? theme.textTheme.textStyle;
    final resolvedBackgroundCursorColor = backgroundCursorColor ??
        CupertinoDynamicColor.resolve(CupertinoColors.inactiveGray, context);

    return InteractiveTextField(
      controller: controller,
      focusNode: focusNode,
      style: resolvedStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      cursorColor: resolvedCursorColor,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      backgroundCursorColor: resolvedBackgroundCursorColor,
      selectionColor: resolvedSelectionColor,
      selectionControls: selectionControls ?? cupertinoTextSelectionControls,
      showCursor: showCursor,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      onTap: onTap,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      contextMenuBuilder: contextMenuBuilder ?? _adaptiveContextMenu,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      decoration: decoration,
      padding: padding,
      locale: locale,
      baseStyleAnimationDuration: baseStyleAnimationDuration,
      baseStyleAnimationCurve: baseStyleAnimationCurve,
      mouseCursor: mouseCursor,
      cursorOpacityAnimates: cursorOpacityAnimates,
      forcePressEnabled: forcePressEnabled,
    );
  }
}
