/// A modular, framework-agnostic interactive text field for Flutter.
///
/// Built on top of Flutter's primitive [EditableText] — no Material or
/// Cupertino dependency. Behavior is contributed by [InteractiveTextPlugin]s
/// attached to an [InteractiveTextController].
library;

export 'src/controller.dart';
export 'src/field.dart';
export 'src/plugin.dart';
export 'src/plugin_context.dart';
export 'src/range_merge.dart';
export 'src/styled_range.dart';

export 'src/plugins/regex_highlight.dart';
export 'src/plugins/syntax_highlight.dart';
export 'src/plugins/markdown.dart';
export 'src/plugins/trigger.dart';
export 'src/plugins/slash_command.dart';
export 'src/plugins/mention.dart';
export 'src/plugins/completion.dart';
export 'src/plugins/effects.dart';
