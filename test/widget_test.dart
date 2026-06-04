import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test : MaterialApp basique se monte', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Coach Tarot'))),
    );
    expect(find.text('Coach Tarot'), findsOneWidget);
  });
}
