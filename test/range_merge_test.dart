import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

void main() {
  group('mergeRangesToSpans', () {
    test('returns a single span for empty range list', () {
      final spans = mergeRangesToSpans(text: 'hello', ranges: const []);
      expect(spans, hasLength(1));
      expect(spans.first.text, 'hello');
      expect(spans.first.style, isNull);
    });

    test('returns empty list for empty text', () {
      final spans = mergeRangesToSpans(text: '', ranges: const []);
      expect(spans, isEmpty);
    });

    test('produces non-overlapping spans covering entire text', () {
      final spans = mergeRangesToSpans(
        text: 'hello world',
        ranges: [
          StyledRange(
            start: 0,
            end: 5,
            style: const TextStyle(color: Color(0xFFFF0000)),
          ),
        ],
      );
      final reconstructed = spans.map((s) => s.text ?? '').join();
      expect(reconstructed, 'hello world');
    });

    test('higher priority overrides lower for overlapping ranges', () {
      final spans = mergeRangesToSpans(
        text: 'abcdef',
        ranges: [
          StyledRange(
            start: 0,
            end: 6,
            style: const TextStyle(color: Color(0xFF000001)),
            priority: 1,
          ),
          StyledRange(
            start: 2,
            end: 4,
            style: const TextStyle(color: Color(0xFF000002)),
            priority: 10,
          ),
        ],
      );
      final cdSpan = spans.firstWhere((s) => s.text == 'cd');
      expect(cdSpan.style?.color, const Color(0xFF000002));
    });

    test('clips ranges that extend past text length', () {
      final spans = mergeRangesToSpans(
        text: 'ab',
        ranges: [
          StyledRange(
            start: 0,
            end: 100,
            style: const TextStyle(color: Color(0xFF00FF00)),
          ),
        ],
      );
      expect(spans.length, 1);
      expect(spans.first.text, 'ab');
      expect(spans.first.style?.color, const Color(0xFF00FF00));
    });

    test('drops empty/inverted ranges', () {
      final spans = mergeRangesToSpans(
        text: 'abc',
        ranges: [
          StyledRange(start: 1, end: 1, style: const TextStyle()),
          StyledRange(start: 5, end: 10, style: const TextStyle()),
        ],
      );
      expect(spans, hasLength(1));
      expect(spans.first.text, 'abc');
    });

    test('merges adjacent spans with identical style', () {
      final spans = mergeRangesToSpans(
        text: 'abcdef',
        ranges: [
          StyledRange(
            start: 0,
            end: 3,
            style: const TextStyle(color: Color(0xFF111111)),
          ),
          StyledRange(
            start: 3,
            end: 6,
            style: const TextStyle(color: Color(0xFF111111)),
          ),
        ],
      );
      expect(spans, hasLength(1));
      expect(spans.first.text, 'abcdef');
    });

    test('base style is merged under range styles', () {
      final spans = mergeRangesToSpans(
        text: 'ab',
        ranges: [
          StyledRange(
            start: 0,
            end: 2,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
        baseStyle: const TextStyle(color: Color(0xFF0000FF)),
      );
      expect(spans.first.style?.fontWeight, FontWeight.bold);
      expect(spans.first.style?.color, const Color(0xFF0000FF));
    });
  });
}
