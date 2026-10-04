// Basic smoke test for the Space Traders app.
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/main.dart' as app;

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    app.main();
    await tester.pump();
    expect(find.text('SPACE TRADERS'), findsOneWidget);
  });
}
