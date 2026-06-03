import 'package:flutter/painting.dart';

import '../plugin.dart';
import '../plugin_context.dart';
import '../syntax/grammar.dart';

export '../syntax/grammar.dart'
    show
        Grammar,
        GrammarRule,
        GrammarRegistry,
        BuiltInGrammars,
        SyntaxLanguages,
        SyntaxTheme;

/// Ready-to-use themes. A theme is just a map of token-class names
/// (`keyword`, `string`, `comment`, …) to [TextStyle]s, so you can also
/// build your own.
class SyntaxThemes {
  SyntaxThemes._();

  static const SyntaxTheme githubLight = {
    'comment': TextStyle(color: Color(0xFF6A737D), fontStyle: FontStyle.italic),
    'keyword': TextStyle(color: Color(0xFFD73A49), fontWeight: FontWeight.w600),
    'literal': TextStyle(color: Color(0xFF005CC5)),
    'number': TextStyle(color: Color(0xFF005CC5)),
    'string': TextStyle(color: Color(0xFF032F62)),
    'type': TextStyle(color: Color(0xFFE36209)),
    'class': TextStyle(color: Color(0xFFE36209)),
    'function': TextStyle(color: Color(0xFF6F42C1)),
    'meta': TextStyle(color: Color(0xFF6A737D)),
    'tag': TextStyle(color: Color(0xFF22863A)),
    'attr': TextStyle(color: Color(0xFF6F42C1)),
    'variable': TextStyle(color: Color(0xFFE36209)),
    'built_in': TextStyle(color: Color(0xFFE36209)),
    'selector-tag': TextStyle(color: Color(0xFF6F42C1)),
    'section': TextStyle(color: Color(0xFF005CC5), fontWeight: FontWeight.w600),
    'strong': TextStyle(fontWeight: FontWeight.bold),
    'emphasis': TextStyle(fontStyle: FontStyle.italic),
    'code': TextStyle(color: Color(0xFF032F62), fontFamily: 'monospace'),
    'link': TextStyle(
      color: Color(0xFF032F62),
      decoration: TextDecoration.underline,
    ),
  };

  static const SyntaxTheme vsCodeDark = {
    'comment': TextStyle(color: Color(0xFF6A9955), fontStyle: FontStyle.italic),
    'keyword': TextStyle(color: Color(0xFF569CD6), fontWeight: FontWeight.w600),
    'literal': TextStyle(color: Color(0xFF569CD6)),
    'number': TextStyle(color: Color(0xFFB5CEA8)),
    'string': TextStyle(color: Color(0xFFCE9178)),
    'type': TextStyle(color: Color(0xFF4EC9B0)),
    'class': TextStyle(color: Color(0xFF4EC9B0)),
    'function': TextStyle(color: Color(0xFFDCDCAA)),
    'meta': TextStyle(color: Color(0xFF9B9B9B)),
    'tag': TextStyle(color: Color(0xFF569CD6)),
    'attr': TextStyle(color: Color(0xFF9CDCFE)),
    'variable': TextStyle(color: Color(0xFF9CDCFE)),
    'built_in': TextStyle(color: Color(0xFF4EC9B0)),
    'selector-tag': TextStyle(color: Color(0xFFD7BA7D)),
    'section': TextStyle(color: Color(0xFF569CD6)),
    'strong': TextStyle(fontWeight: FontWeight.bold),
    'emphasis': TextStyle(fontStyle: FontStyle.italic),
    'code': TextStyle(color: Color(0xFFCE9178), fontFamily: 'monospace'),
    'link': TextStyle(
      color: Color(0xFFCE9178),
      decoration: TextDecoration.underline,
    ),
  };
}

/// Syntax-highlights code in the languages defined by [BuiltInGrammars]
/// (Dart, SQL, Python, Rust, Go, JavaScript, TypeScript, HTML, CSS, JSON,
/// YAML, Bash, Markdown). To add more, register a [Grammar] with the
/// registry and pass its name as [language].
///
/// Replaces the previous `highlight`-package-backed implementation —
/// hand-tuned grammars, no transitive dependencies.
class SyntaxHighlightPlugin extends InteractiveTextPlugin {
  SyntaxHighlightPlugin({
    String? language,
    SyntaxTheme theme = SyntaxThemes.githubLight,
    int priority = 0,
    GrammarRegistry? registry,
  })  : _language = language,
        _theme = theme,
        _priority = priority,
        _registry = registry ?? GrammarRegistry.defaults;

  String? _language;
  SyntaxTheme _theme;
  int _priority;
  final GrammarRegistry _registry;

  String? get language => _language;
  set language(String? value) {
    if (value == _language) return;
    _language = value;
    if (isAttached) context.requestRebuild();
  }

  SyntaxTheme get theme => _theme;
  set theme(SyntaxTheme value) {
    _theme = value;
    if (isAttached) context.requestRebuild();
  }

  int get priority => _priority;
  set priority(int value) {
    _priority = value;
    if (isAttached) context.requestRebuild();
  }

  GrammarRegistry get registry => _registry;

  @override
  DecorationResult decorate(DecorationContext ctx) {
    if (ctx.text.isEmpty || _language == null) {
      return const DecorationResult.empty();
    }
    final grammar = _registry.lookup(_language);
    if (grammar == null) return const DecorationResult.empty();
    final ranges = tokenize(
      text: ctx.text,
      grammar: grammar,
      theme: _theme,
      basePriority: _priority,
    );
    return DecorationResult(ranges);
  }
}
