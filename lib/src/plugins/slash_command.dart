import 'package:flutter/widgets.dart';

import 'trigger.dart';

/// A single `/command` definition.
@immutable
class SlashCommand {
  const SlashCommand({
    required this.name,
    required this.description,
    this.aliases = const [],
    this.icon,
    this.priority = 0,
    this.onInvoke,
  });

  /// The command's primary name. `/help` ↔ `name: 'help'`.
  final String name;

  /// Human-readable explanation of what the command does.
  final String description;

  /// Alternate names that resolve to the same command.
  final List<String> aliases;

  /// Optional leading icon for the popup row.
  final Widget? icon;

  /// Sort order in suggestion list (higher = first).
  final int priority;

  /// Called when this command is selected. The trigger plugin closes the
  /// popup; default behavior keeps `/command` in the text. Use [onInvoke]
  /// to swap that out for whatever your app needs.
  final void Function()? onInvoke;

  /// True when [name] or any alias contains [query] (case-insensitive).
  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (name.toLowerCase().contains(q)) return true;
    for (final a in aliases) {
      if (a.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

/// Drop-in slash command plugin. Pass in your command list; the plugin
/// handles detection, filtering, and rendering. Provide `onAccept` to
/// customize what happens when a command is chosen — by default, the
/// command is inserted as `/name `.
class SlashCommandPlugin extends TriggerPlugin<SlashCommand> {
  SlashCommandPlugin({
    required List<SlashCommand> commands,
    TextStyle? rowStyle,
    TextStyle? selectedRowStyle,
    TextStyle? subtitleStyle,
    Color? selectedBackground,
    super.highlightStyle = const TextStyle(
      color: Color(0xFF1976D2),
      fontWeight: FontWeight.w600,
    ),
    super.priority,
    super.closeOnSpace = true,
    super.onAccept,
    super.onClose,
    super.menuBuilder,
  }) : super(
          trigger: '/',
          resolver: (query) {
            final filtered = commands.where((c) => c.matches(query.query)).toList()
              ..sort((a, b) => b.priority.compareTo(a.priority));
            return filtered
                .map((c) => TriggerSuggestion<SlashCommand>(
                      label: '/${c.name}',
                      subtitle: c.description,
                      value: c,
                      insertText: '/${c.name}',
                      leading: c.icon,
                      data: c,
                    ))
                .toList();
          },
          itemBuilder: (context, suggestion, selected) =>
              _SlashRow(
                suggestion: suggestion,
                selected: selected,
                rowStyle: rowStyle,
                selectedRowStyle: selectedRowStyle,
                subtitleStyle: subtitleStyle,
                selectedBackground: selectedBackground,
              ),
        );
}

class _SlashRow extends StatelessWidget {
  const _SlashRow({
    required this.suggestion,
    required this.selected,
    this.rowStyle,
    this.selectedRowStyle,
    this.subtitleStyle,
    this.selectedBackground,
  });

  final TriggerSuggestion<SlashCommand> suggestion;
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
        ? (selectedBackground ?? const Color(0xFFEEF5FE))
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
              const SizedBox(width: 8),
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
