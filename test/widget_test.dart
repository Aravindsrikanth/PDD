import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icu_app/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const ICUSuitePro(),
      ),
    );

    // Verify that the login screen is shown (it should contain 'Clinical Authentication')
    expect(find.text('Clinical Authentication'), findsOneWidget);
  });
}
