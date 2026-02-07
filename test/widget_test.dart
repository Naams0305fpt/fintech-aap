import 'package:flutter_test/flutter_test.dart';
import 'package:fintech/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinTechApp());

    // Verify app renders
    expect(find.text('FinTech'), findsOneWidget);
  });
}
