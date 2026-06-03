import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

void main() {
  group('StaticListCompletionProvider', () {
    const provider = StaticListCompletionProvider(['hello', 'help', 'helper']);

    test('returns matches with shared prefix, stripped of prefix', () async {
      final result = await Future.value(provider.complete(
        const CompletionRequest(text: 'hel', cursor: 3, prefix: 'hel'),
      ));
      expect(result.candidates, hasLength(3));
      expect(
        result.candidates.map((c) => c.text).toSet(),
        {'lo', 'p', 'per'},
      );
    });

    test('case-insensitive prefix match', () async {
      final result = await Future.value(provider.complete(
        const CompletionRequest(text: 'HE', cursor: 2, prefix: 'HE'),
      ));
      expect(result.candidates, isNotEmpty);
    });

    test('drops candidates equal to the prefix', () async {
      final result = await Future.value(provider.complete(
        const CompletionRequest(text: 'hello', cursor: 5, prefix: 'hello'),
      ));
      expect(result.candidates, isEmpty);
    });

    test('returns empty when prefix is empty', () async {
      final result = await Future.value(provider.complete(
        const CompletionRequest(text: '', cursor: 0, prefix: ''),
      ));
      expect(result.candidates, isEmpty);
    });

    test('non-matching prefix returns empty', () async {
      final result = await Future.value(provider.complete(
        const CompletionRequest(text: 'xyz', cursor: 3, prefix: 'xyz'),
      ));
      expect(result.candidates, isEmpty);
    });
  });

  group('CompositeCompletionProvider', () {
    test('concatenates results from each underlying provider', () async {
      const a = StaticListCompletionProvider(['alpha', 'aleph']);
      const b = StaticListCompletionProvider(['action', 'about']);
      const composite = CompositeCompletionProvider([a, b]);
      final result = await composite.complete(
        const CompletionRequest(text: 'a', cursor: 1, prefix: 'a'),
      );
      expect(result.candidates, hasLength(4));
    });
  });
}
