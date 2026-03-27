import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_coach/main.dart';

void main() {
  testWidgets('App should launch', (WidgetTester tester) async {
    await tester.pumpWidget(const TarotCoachApp());
    expect(find.text('TarotCoach'), findsOneWidget);
  });
}
