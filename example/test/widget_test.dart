import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('home screen shows demo list', (tester) async {
    await tester.pumpWidget(const InteractiveTextFieldExample());
    expect(find.text('Plain Field'), findsOneWidget);
    expect(find.text('Regex Highlighting'), findsOneWidget);
    expect(find.text('Syntax Highlighting'), findsOneWidget);
  });
}
