import 'package:flutter/widgets.dart';

import 'trigger.dart';

/// A user/object that can be mentioned via `@`.
@immutable
class Mention {
  const Mention({
    required this.id,
    required this.displayName,
    this.subtitle,
    this.handle,
    this.avatar,
  });

  /// Stable identity (e.g. user ID).
  final String id;

  /// Name shown in the row.
  final String displayName;

  /// Optional secondary line.
  final String? subtitle;

  /// Optional handle (e.g. `@rob`). When set, the inserted text is the
  /// handle prefixed by `@`. When null, the display name is used as-is.
  final String? handle;

  /// Optional avatar (any widget — Image, Icon, CircleAvatar from your
  /// design system, etc.).
  final Widget? avatar;

  /// Default scoring for ranking purposes — override by passing your own
  /// resolver that produces a pre-ranked list.
  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (displayName.toLowerCase().contains(q)) return true;
    if (handle != null && handle!.toLowerCase().contains(q)) return true;
    return false;
  }
}

/// Drop-in `@mention` plugin. Provide a list of [Mention]s (or a custom
/// resolver via the parent class) and the plugin handles detection,
/// filtering, and rendering.
class MentionPlugin extends TriggerPlugin<Mention> {
  MentionPlugin({
    required List<Mention> mentions,
    TextStyle? rowStyle,
    TextStyle? selectedRowStyle,
    TextStyle? subtitleStyle,
    Color? selectedBackground,
    super.highlightStyle = const TextStyle(
      color: Color(0xFF7B1FA2),
      fontWeight: FontWeight.w600,
    ),
    super.priority,
    super.closeOnSpace = false,
    super.onAccept,
    super.onClose,
    super.menuBuilder,
  }) : super(
          trigger: '@',
          queryCharPredicate: _isMentionQueryChar,
          resolver: (query) {
            return mentions
                .where((m) => m.matches(query.query))
                .map(
                  (m) => TriggerSuggestion<Mention>(
                    label: m.handle != null ? '@${m.handle}' : m.displayName,
                    subtitle: m.subtitle ?? m.displayName,
                    value: m,
                    insertText:
                        m.handle != null ? '@${m.handle}' : '@${m.displayName}',
                    leading: m.avatar,
                    data: m,
                  ),
                )
                .toList();
          },
          itemBuilder: (context, suggestion, selected) => _MentionRow(
            suggestion: suggestion,
            selected: selected,
            rowStyle: rowStyle,
            selectedRowStyle: selectedRowStyle,
            subtitleStyle: subtitleStyle,
            selectedBackground: selectedBackground,
          ),
        );
}

/// Unicode letter (`\p{L}`), number (`\p{N}`), or underscore — so mention
/// handles work for non-Latin scripts (CJK, Cyrillic, Arabic, …) without
/// the previous ASCII-only behavior.
final RegExp _mentionQueryChar = RegExp(r'^[\p{L}\p{N}_]$', unicode: true);

bool _isMentionQueryChar(String ch) {
  if (ch.isEmpty) return false;
  return _mentionQueryChar.hasMatch(ch);
}

class _MentionRow extends StatelessWidget {
  const _MentionRow({
    required this.suggestion,
    required this.selected,
    this.rowStyle,
    this.selectedRowStyle,
    this.subtitleStyle,
    this.selectedBackground,
  });

  final TriggerSuggestion<Mention> suggestion;
  final bool selected;
  final TextStyle? rowStyle;
  final TextStyle? selectedRowStyle;
  final TextStyle? subtitleStyle;
  final Color? selectedBackground;

  @override
  Widget build(BuildContext context) {
    final defaultRow = const TextStyle(
      color: Color(0xFF1F1F1F),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final defaultSubtitle = const TextStyle(
      color: Color(0xFF6F6F6F),
      fontSize: 12,
    );
    final bg = selected
        ? (selectedBackground ?? const Color(0xFFF3E8FB))
        : const Color(0x00000000);
    return DefaultTextStyle.merge(
      style: defaultRow,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (suggestion.leading != null) ...[
              suggestion.leading!,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    suggestion.label,
                    style: (selected ? selectedRowStyle : rowStyle) ?? defaultRow,
                  ),
                  if (suggestion.subtitle != null)
                    Text(
                      suggestion.subtitle!,
                      style: subtitleStyle ?? defaultSubtitle,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
