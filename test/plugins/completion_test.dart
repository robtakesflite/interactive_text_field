import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class _DelayedProvider extends CompletionProvider {
  _DelayedProvider(this.delay, this.candidates);
  final Duration delay;
  final List<CompletionCandidate> candidates;
  int requests = 0;

  @override
  Future<CompletionResult> complete(CompletionRequest request) async {
    requests++;
    await Future<void>.delayed(delay);
    return CompletionResult(candidates: candidates);
  }
}

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

  group('CompletionPlugin async safety', () {
    testWidgets('disposing the controller mid-request does not throw',
        (tester) async {
      // Regression: previously, `_request` would await the provider and
      // then unconditionally touch `context`. If the controller was
      // disposed during the await, the `_context!` unwrap threw.
      final provider = _DelayedProvider(
        const Duration(milliseconds: 80),
        [const CompletionCandidate(text: 'ello')],
      );
      final plugin = CompletionPlugin(
        provider: provider,
        debounce: Duration.zero,
      );
      final controller = InteractiveTextController(plugins: [plugin]);

      controller.text = 'h';
      controller.selection = const TextSelection.collapsed(offset: 1);
      // Give the request a chance to dispatch.
      await tester.pump(const Duration(milliseconds: 10));
      expect(provider.requests, 1);
      // Dispose while the provider future is still pending.
      controller.dispose();
      // Pump past the provider's resolution. If the bug were still there,
      // the post-await context access would throw asynchronously.
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('async provider populates the candidate when settled',
        (tester) async {
      final provider = _DelayedProvider(
        const Duration(milliseconds: 30),
        [const CompletionCandidate(text: 'lp')],
      );
      final plugin = CompletionPlugin(
        provider: provider,
        debounce: Duration.zero,
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      controller.text = 'he';
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump(const Duration(milliseconds: 100));
      expect(plugin.currentCandidate?.text, 'lp');
    });
  });
}
