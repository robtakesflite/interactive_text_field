import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard test: the package must not import Material or Cupertino.
/// Wrapping the field in a Material/Cupertino theme is fine for users,
/// but the package itself stays framework-agnostic.
void main() {
  test('package does not import Material or Cupertino', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ should exist');

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
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
          'The package leaks a Material/Cupertino import in: $offenders. '
          'Use widgets.dart / rendering.dart / painting.dart instead.',
    );
  });
}
