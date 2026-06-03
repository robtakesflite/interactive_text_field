import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class CodeDemo extends StatefulWidget {
  const CodeDemo({super.key});

  @override
  State<CodeDemo> createState() => _CodeDemoState();
}

class _CodeDemoState extends State<CodeDemo> {
  late final InteractiveTextController _controller;
  late final SyntaxHighlightPlugin _syntax;
  String _language = SyntaxLanguages.dart;
  bool _dark = false;

  static const Map<String, String> _samples = {
    SyntaxLanguages.dart: '''
class Fish {
  final String name;
  final int weight;
  const Fish({required this.name, required this.weight});

  bool get isBig => weight >= 1000;
}

void main() {
  final list = [Fish(name: 'snapper', weight: 850)];
  for (final f in list) {
    print('\${f.name} weighs \${f.weight}g, big? \${f.isBig}');
  }
}
''',
    SyntaxLanguages.python: '''
from dataclasses import dataclass

@dataclass
class Fish:
    name: str
    weight: int

    @property
    def is_big(self) -> bool:
        return self.weight >= 1000

if __name__ == "__main__":
    f = Fish("snapper", 850)
    print(f"{f.name}: big? {f.is_big}")
''',
    SyntaxLanguages.rust: '''
struct Fish { name: String, weight: u32 }

impl Fish {
    fn is_big(&self) -> bool { self.weight >= 1000 }
}

fn main() {
    let f = Fish { name: "snapper".into(), weight: 850 };
    println!("{}: big? {}", f.name, f.is_big());
}
''',
    SyntaxLanguages.sql: '''
-- Find the heaviest fish per species
SELECT species, name, weight
FROM catches
WHERE weight > 500
ORDER BY weight DESC
LIMIT 10;
''',
    SyntaxLanguages.html: '''
<!DOCTYPE html>
<html lang="en">
  <head><title>Catch</title></head>
  <body>
    <h1>Snapper</h1>
    <p>Weight: <strong>850g</strong></p>
  </body>
</html>
''',
    SyntaxLanguages.json: '''
{
  "fish": [
    { "name": "snapper", "weight": 850 },
    { "name": "grouper", "weight": 1200 }
  ]
}
''',
    SyntaxLanguages.bash: '''
#!/usr/bin/env bash
set -euo pipefail

for fish in snapper grouper kingfish; do
  echo "caught: \$fish"
done
''',
  };

  @override
  void initState() {
    super.initState();
    _syntax = SyntaxHighlightPlugin(
      language: _language,
      theme: SyntaxThemes.githubLight,
      priority: 5,
    );
    _controller = InteractiveTextController(
      plugins: [_syntax],
      text: _samples[_language]!,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setLanguage(String lang) {
    setState(() {
      _language = lang;
      _syntax.language = lang;
      _controller.text = _samples[lang]!;
    });
  }

  void _toggleTheme() {
    setState(() {
      _dark = !_dark;
      _syntax.theme = _dark ? SyntaxThemes.vsCodeDark : SyntaxThemes.githubLight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = _dark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
    final fg = _dark ? const Color(0xFFD4D4D4) : const Color(0xFF24292E);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            children: [
              for (final lang in _samples.keys)
                ChoiceChip(
                  label: Text(lang),
                  selected: _language == lang,
                  onSelected: (_) => _setLanguage(lang),
                ),
              FilterChip(
                label: const Text('Dark'),
                selected: _dark,
                onSelected: (_) => _toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: InteractiveTextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              cursorColor: _dark ? const Color(0xFFAEAFAD) : const Color(0xFF1976D2),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: fg,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
