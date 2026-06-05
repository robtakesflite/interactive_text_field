import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard test: the *core* package must not import Material or Cupertino.
/// Explicit opt-in theme adapters (e.g. `field_material.dart`,
/// `field_cupertino.dart`) intentionally do — they're the bridge for users
/// who want themed defaults — but the rest of the library stays
/// framework-agnostic.
const _adapterWhitelist = <String>{
  'lib/src/field_material.dart',
  'lib/src/field_cupertino.dart',
};

void main() {
  test('core package does not import Material or Cupertino', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ should exist');

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (_adapterWhitelist.contains(entity.path)) continue;
      final content = entity.readAsStringSync();
      if (content.contains("package:flutter/material.dart") ||
          content.contains("package:flutter/cupertino.dart")) {
        offenders.add(entity.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'The core package leaks a Material/Cupertino import in: $offenders. '
          'Use widgets.dart / rendering.dart / painting.dart instead, or add '
          'the file to _adapterWhitelist if it is an explicit theme adapter.',
    );
  });
}
