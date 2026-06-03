import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../styled_range.dart';

/// One scanning rule within a [Grammar]. Tokens produced are tagged with
/// a [tokenClass] (matching theme keys like `keyword`, `string`, etc.)
/// and a numeric [priority] for overlap resolution.
@immutable
class GrammarRule {
  const GrammarRule({
    required this.pattern,
    required this.tokenClass,
    this.priority = 0,
  });

  /// Pattern to match. Use lookarounds for word boundaries; rules execute
  /// independently and the tokenizer resolves overlaps by priority.
  final RegExp pattern;

  /// Theme key. Should match a key in [SyntaxTheme].
  final String tokenClass;

  /// Higher priority overrides lower priority on the same range.
  final int priority;
}

/// A simple regex-based grammar definition for a language. This is the
/// in-house replacement for the `highlight` package — fewer languages,
/// hand-tuned, no runtime dependency footprint.
@immutable
class Grammar {
  const Grammar({required this.name, required this.rules, this.aliases = const []});

  /// Canonical language name (e.g. `dart`, `sql`, `python`).
  final String name;

  /// Alternate names that resolve to this grammar (e.g. `js` → `javascript`).
  final List<String> aliases;

  /// The scanning rules, applied independently.
  final List<GrammarRule> rules;
}

/// Map of `tokenClass` → [TextStyle].
typedef SyntaxTheme = Map<String, TextStyle>;

/// Apply [grammar] to [text] starting at [offset] (absolute character
/// position in the editor) and return a list of [StyledRange]s.
///
/// Pass [theme] to map [GrammarRule.tokenClass] to an actual [TextStyle].
/// Pass [basePriority] to bias the priority of all emitted ranges.
List<StyledRange> tokenize({
  required String text,
  required Grammar grammar,
  required SyntaxTheme theme,
  int offset = 0,
  int basePriority = 0,
}) {
  final out = <StyledRange>[];
  for (final rule in grammar.rules) {
    final style = theme[rule.tokenClass];
    if (style == null) continue;
    for (final m in rule.pattern.allMatches(text)) {
      if (m.end <= m.start) continue;
      out.add(StyledRange(
        start: offset + m.start,
        end: offset + m.end,
        style: style,
        priority: basePriority + rule.priority,
        data: rule.tokenClass,
      ));
    }
  }
  return out;
}

/// A grammar registry. The default registry is preloaded with the
/// in-house grammars under [BuiltInGrammars].
class GrammarRegistry {
  GrammarRegistry();

  final Map<String, Grammar> _grammars = <String, Grammar>{};

  /// Add a grammar to the registry. Looks up by [Grammar.name] and any
  /// [Grammar.aliases].
  void register(Grammar grammar) {
    _grammars[grammar.name.toLowerCase()] = grammar;
    for (final alias in grammar.aliases) {
      _grammars[alias.toLowerCase()] = grammar;
    }
  }

  Grammar? lookup(String? name) {
    if (name == null) return null;
    return _grammars[name.toLowerCase()];
  }

  Iterable<Grammar> get all => _grammars.values.toSet();

  /// Default registry, populated with [BuiltInGrammars.all].
  static final GrammarRegistry defaults = (() {
    final r = GrammarRegistry();
    for (final g in BuiltInGrammars.all) {
      r.register(g);
    }
    return r;
  })();
}

/// Hand-curated grammars for common languages. Add your own with
/// [GrammarRegistry.register] or by constructing a [Grammar] directly.
class BuiltInGrammars {
  BuiltInGrammars._();

  /// Every grammar shipped with the package.
  static List<Grammar> get all => <Grammar>[
        dart,
        javascript,
        typescript,
        python,
        rust,
        go,
        sql,
        html,
        css,
        json,
        yaml,
        bash,
        markdown,
      ];

  // --- Dart ---------------------------------------------------------------

  static final Grammar dart = Grammar(
    name: 'dart',
    rules: [
      GrammarRule(
        pattern: RegExp(r'//.*'),
        tokenClass: 'comment',
        priority: 10,
      ),
      GrammarRule(
        pattern: RegExp(r'/\*[\s\S]*?\*/'),
        tokenClass: 'comment',
        priority: 10,
      ),
      GrammarRule(
        pattern: RegExp(
          r'''(?:r?'''
          r'''(?:'''
          r"""'''[\s\S]*?'''"""
          r'|'
          r'"""[\s\S]*?"""'
          r'|'
          r"'(?:\\.|[^'\\\n])*'"
          r'|'
          r'"(?:\\.|[^"\\\n])*"'
          r'))',
        ),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:abstract|as|assert|async|await|break|case|catch|class|'
          r'const|continue|covariant|default|deferred|do|dynamic|else|'
          r'enum|export|extends|extension|external|factory|false|final|'
          r'finally|for|Function|get|hide|if|implements|import|in|interface|'
          r'is|late|library|mixin|new|null|on|operator|part|required|rethrow|'
          r'return|sealed|set|show|static|super|switch|sync|this|throw|true|'
          r'try|typedef|var|void|when|while|with|yield)\b',
        ),
        tokenClass: 'keyword',
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:bool|int|double|num|String|List|Map|Set|Iterable|Future|'
          r'Stream|Object|Never|Symbol|Type|Record)\b',
        ),
        tokenClass: 'type',
      ),
      GrammarRule(
        pattern: RegExp(r'@\w+'),
        tokenClass: 'meta',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
        tokenClass: 'number',
      ),
      GrammarRule(
        pattern: RegExp(r'\b[A-Z][A-Za-z0-9_]*\b'),
        tokenClass: 'class',
      ),
      GrammarRule(
        pattern: RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)(?=\s*\()'),
        tokenClass: 'function',
      ),
    ],
  );

  // --- JavaScript / TypeScript -------------------------------------------

  static final Grammar javascript = Grammar(
    name: 'javascript',
    aliases: const ['js'],
    rules: [
      GrammarRule(pattern: RegExp(r'//.*'), tokenClass: 'comment', priority: 10),
      GrammarRule(
        pattern: RegExp(r'/\*[\s\S]*?\*/'),
        tokenClass: 'comment',
        priority: 10,
      ),
      GrammarRule(
        pattern: RegExp(
          r'''(?:`(?:\\.|[^`\\])*`|'(?:\\.|[^'\\\n])*'|"(?:\\.|[^"\\\n])*")''',
        ),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:async|await|break|case|catch|class|const|continue|debugger|'
          r'default|delete|do|else|export|extends|false|finally|for|function|'
          r'if|import|in|instanceof|let|new|null|of|return|static|super|'
          r'switch|this|throw|true|try|typeof|undefined|var|void|while|with|'
          r'yield|from|as)\b',
        ),
        tokenClass: 'keyword',
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:Array|Boolean|Date|Error|Function|JSON|Map|Math|Number|'
          r'Object|Promise|RegExp|Set|String|Symbol|console|document|'
          r'window)\b',
        ),
        tokenClass: 'built_in',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
        tokenClass: 'number',
      ),
      GrammarRule(
        pattern: RegExp(r'\b([a-zA-Z_$][a-zA-Z0-9_$]*)(?=\s*\()'),
        tokenClass: 'function',
      ),
    ],
  );

  static final Grammar typescript = Grammar(
    name: 'typescript',
    aliases: const ['ts'],
    rules: [
      ...javascript.rules,
      GrammarRule(
        pattern: RegExp(
          r'\b(?:any|never|unknown|number|string|boolean|object|null|'
          r'undefined|void|readonly|keyof|infer|public|private|protected|'
          r'abstract|implements|interface|enum|namespace|module|declare|type)\b',
        ),
        tokenClass: 'keyword',
      ),
    ],
  );

  // --- Python ------------------------------------------------------------

  static final Grammar python = Grammar(
    name: 'python',
    aliases: const ['py'],
    rules: [
      GrammarRule(pattern: RegExp(r'#.*'), tokenClass: 'comment', priority: 10),
      GrammarRule(
        pattern: RegExp(
          r'''(?:[rbuRBU]{0,2}(?:"""[\s\S]*?"""|''' "'''" r'[\s\S]*?' "'''"
          r'|"(?:\\.|[^"\\\n])*"|'
          r"'(?:\\.|[^'\\\n])*'))",
        ),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:False|None|True|and|as|assert|async|await|break|class|'
          r'continue|def|del|elif|else|except|finally|for|from|global|if|'
          r'import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|'
          r'with|yield|match|case)\b',
        ),
        tokenClass: 'keyword',
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:print|len|range|int|str|float|bool|list|dict|set|tuple|'
          r'enumerate|map|filter|zip|sum|max|min|abs|isinstance|type|'
          r'open|input)\b',
        ),
        tokenClass: 'built_in',
      ),
      GrammarRule(
        pattern: RegExp(r'@\w+'),
        tokenClass: 'meta',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
        tokenClass: 'number',
      ),
      GrammarRule(
        pattern: RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)(?=\s*\()'),
        tokenClass: 'function',
      ),
    ],
  );

  // --- Rust --------------------------------------------------------------

  static final Grammar rust = Grammar(
    name: 'rust',
    aliases: const ['rs'],
    rules: [
      GrammarRule(pattern: RegExp(r'//.*'), tokenClass: 'comment', priority: 10),
      GrammarRule(
        pattern: RegExp(r'/\*[\s\S]*?\*/'),
        tokenClass: 'comment',
        priority: 10,
      ),
      GrammarRule(
        pattern: RegExp(r'"(?:\\.|[^"\\\n])*"'),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:as|async|await|break|const|continue|crate|dyn|else|enum|'
          r'extern|false|fn|for|if|impl|in|let|loop|match|mod|move|mut|pub|'
          r'ref|return|self|Self|static|struct|super|trait|true|type|union|'
          r'unsafe|use|where|while|yield)\b',
        ),
        tokenClass: 'keyword',
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:bool|char|i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|'
          r'usize|f32|f64|str|String|Vec|Box|Option|Result|HashMap|HashSet)\b',
        ),
        tokenClass: 'type',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
        tokenClass: 'number',
      ),
      GrammarRule(
        pattern: RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)(?=\s*[\(\!])'),
        tokenClass: 'function',
      ),
      GrammarRule(
        pattern: RegExp(r'#\[[^\]]*\]'),
        tokenClass: 'meta',
      ),
    ],
  );

  // --- Go ----------------------------------------------------------------

  static final Grammar go = Grammar(
    name: 'go',
    aliases: const ['golang'],
    rules: [
      GrammarRule(pattern: RegExp(r'//.*'), tokenClass: 'comment', priority: 10),
      GrammarRule(
        pattern: RegExp(r'/\*[\s\S]*?\*/'),
        tokenClass: 'comment',
        priority: 10,
      ),
      GrammarRule(
        pattern: RegExp(r'`[^`]*`|"(?:\\.|[^"\\\n])*"'),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:break|case|chan|const|continue|default|defer|else|fallthrough|'
          r'for|func|go|goto|if|import|interface|map|package|range|return|'
          r'select|struct|switch|type|var|true|false|nil)\b',
        ),
        tokenClass: 'keyword',
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:bool|byte|complex64|complex128|error|float32|float64|int|int8|'
          r'int16|int32|int64|rune|string|uint|uint8|uint16|uint32|uint64|'
          r'uintptr)\b',
        ),
        tokenClass: 'type',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+(?:\.\d+)?\b'),
        tokenClass: 'number',
      ),
    ],
  );

  // --- SQL ---------------------------------------------------------------

  static final Grammar sql = Grammar(
    name: 'sql',
    rules: [
      GrammarRule(pattern: RegExp(r'--.*'), tokenClass: 'comment', priority: 10),
      GrammarRule(
        pattern: RegExp(r'/\*[\s\S]*?\*/'),
        tokenClass: 'comment',
        priority: 10,
      ),
      GrammarRule(
        pattern: RegExp(r"'(?:''|[^'])*'"),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:SELECT|FROM|WHERE|INSERT|INTO|VALUES|UPDATE|SET|DELETE|JOIN|'
          r'LEFT|RIGHT|INNER|OUTER|FULL|ON|GROUP|BY|ORDER|HAVING|LIMIT|OFFSET|'
          r'AS|AND|OR|NOT|IN|EXISTS|BETWEEN|LIKE|IS|NULL|CREATE|TABLE|DROP|'
          r'ALTER|ADD|COLUMN|PRIMARY|KEY|FOREIGN|REFERENCES|UNIQUE|INDEX|VIEW|'
          r'DATABASE|SCHEMA|TRIGGER|PROCEDURE|FUNCTION|CASE|WHEN|THEN|ELSE|END|'
          r'UNION|ALL|DISTINCT|COUNT|SUM|AVG|MIN|MAX|TRUE|FALSE|WITH)\b',
          caseSensitive: false,
        ),
        tokenClass: 'keyword',
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:INT|INTEGER|BIGINT|SMALLINT|TINYINT|DECIMAL|NUMERIC|FLOAT|'
          r'DOUBLE|REAL|VARCHAR|CHAR|TEXT|BOOLEAN|BOOL|DATE|TIME|TIMESTAMP|'
          r'BLOB|JSON|JSONB|UUID)\b',
          caseSensitive: false,
        ),
        tokenClass: 'type',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+(?:\.\d+)?\b'),
        tokenClass: 'number',
      ),
    ],
  );

  // --- HTML --------------------------------------------------------------

  static final Grammar html = Grammar(
    name: 'html',
    aliases: const ['xml'],
    rules: [
      GrammarRule(
        pattern: RegExp(r'<!--[\s\S]*?-->'),
        tokenClass: 'comment',
        priority: 10,
      ),
      GrammarRule(
        pattern: RegExp(r'<!DOCTYPE[^>]*>'),
        tokenClass: 'meta',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(r'</?[a-zA-Z][\w-]*'),
        tokenClass: 'tag',
        priority: 5,
      ),
      GrammarRule(
        pattern: RegExp(r'/?>'),
        tokenClass: 'tag',
        priority: 5,
      ),
      GrammarRule(
        pattern: RegExp(r'\b[a-zA-Z-]+(?==)'),
        tokenClass: 'attr',
        priority: 3,
      ),
      GrammarRule(
        pattern: RegExp(r'"(?:\\.|[^"\\])*"|\047(?:\\.|[^\047\\])*\047'),
        tokenClass: 'string',
        priority: 4,
      ),
    ],
  );

  // --- CSS ---------------------------------------------------------------

  static final Grammar css = Grammar(
    name: 'css',
    rules: [
      GrammarRule(
        pattern: RegExp(r'/\*[\s\S]*?\*/'),
        tokenClass: 'comment',
        priority: 10,
      ),
      GrammarRule(
        pattern: RegExp(r'"(?:\\.|[^"\\])*"|\047(?:\\.|[^\047\\])*\047'),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(r'#[A-Fa-f0-9]{3,8}\b'),
        tokenClass: 'number',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+(?:\.\d+)?(?:px|em|rem|%|vh|vw|s|ms)?\b'),
        tokenClass: 'number',
      ),
      GrammarRule(
        pattern: RegExp(r'[.#][\w-]+'),
        tokenClass: 'selector-tag',
      ),
      GrammarRule(
        pattern: RegExp(r'\b[a-zA-Z-]+(?=\s*:)'),
        tokenClass: 'attr',
      ),
    ],
  );

  // --- JSON --------------------------------------------------------------

  static final Grammar json = Grammar(
    name: 'json',
    rules: [
      GrammarRule(
        pattern: RegExp(r'"(?:\\.|[^"\\])*"(?=\s*:)'),
        tokenClass: 'attr',
        priority: 9,
      ),
      GrammarRule(
        pattern: RegExp(r'"(?:\\.|[^"\\])*"'),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(r'\b(?:true|false|null)\b'),
        tokenClass: 'literal',
      ),
      GrammarRule(
        pattern: RegExp(r'-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
        tokenClass: 'number',
      ),
    ],
  );

  // --- YAML --------------------------------------------------------------

  static final Grammar yaml = Grammar(
    name: 'yaml',
    aliases: const ['yml'],
    rules: [
      GrammarRule(pattern: RegExp(r'#.*'), tokenClass: 'comment', priority: 10),
      GrammarRule(
        pattern: RegExp(
          r'"(?:\\.|[^"\\\n])*"|\047(?:\\.|[^\047\\\n])*\047',
        ),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(r'^\s*([\w.-]+)\s*(?=:)', multiLine: true),
        tokenClass: 'attr',
      ),
      GrammarRule(
        pattern: RegExp(r'\b(?:true|false|null|yes|no|on|off)\b'),
        tokenClass: 'literal',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+(?:\.\d+)?\b'),
        tokenClass: 'number',
      ),
    ],
  );

  // --- Bash --------------------------------------------------------------

  static final Grammar bash = Grammar(
    name: 'bash',
    aliases: const ['shell', 'sh', 'zsh'],
    rules: [
      GrammarRule(pattern: RegExp(r'#.*'), tokenClass: 'comment', priority: 10),
      GrammarRule(
        pattern: RegExp(r'"(?:\\.|[^"\\])*"|\047[^\047]*\047'),
        tokenClass: 'string',
        priority: 8,
      ),
      GrammarRule(
        pattern: RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*|\$\{[^}]+\}'),
        tokenClass: 'variable',
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:if|then|else|elif|fi|for|in|do|done|while|until|case|esac|'
          r'function|return|break|continue|exit|local|export|readonly|'
          r'declare|source|alias|unalias|true|false|set|unset)\b',
        ),
        tokenClass: 'keyword',
      ),
      GrammarRule(
        pattern: RegExp(
          r'\b(?:echo|printf|read|cd|ls|cat|grep|sed|awk|find|rm|mv|cp|mkdir|'
          r'touch|chmod|chown|test|tee|sort|uniq|head|tail|cut|tr|xargs|sleep|'
          r'wait|wc)\b',
        ),
        tokenClass: 'built_in',
      ),
      GrammarRule(
        pattern: RegExp(r'\b\d+\b'),
        tokenClass: 'number',
      ),
    ],
  );

  // --- Markdown ---------------------------------------------------------

  static final Grammar markdown = Grammar(
    name: 'markdown',
    aliases: const ['md'],
    rules: [
      GrammarRule(
        pattern: RegExp(r'^#{1,6}\s+.+$', multiLine: true),
        tokenClass: 'section',
      ),
      GrammarRule(
        pattern: RegExp(r'\*\*(?:[^*]|\*[^*])+\*\*'),
        tokenClass: 'strong',
      ),
      GrammarRule(
        pattern: RegExp(r'`[^`]+`'),
        tokenClass: 'code',
      ),
      GrammarRule(
        pattern: RegExp(r'\[[^\]]+\]\([^)]+\)'),
        tokenClass: 'link',
      ),
    ],
  );
}

/// Convenience listing of language identifiers known to the default
/// registry. Use these strings as the [SyntaxHighlightPlugin] `language`.
class SyntaxLanguages {
  SyntaxLanguages._();

  static const String dart = 'dart';
  static const String javascript = 'javascript';
  static const String typescript = 'typescript';
  static const String python = 'python';
  static const String rust = 'rust';
  static const String go = 'go';
  static const String sql = 'sql';
  static const String html = 'html';
  static const String css = 'css';
  static const String json = 'json';
  static const String yaml = 'yaml';
  static const String bash = 'bash';
  static const String markdown = 'markdown';
}
