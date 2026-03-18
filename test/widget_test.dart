import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voom/widgets/buttons.dart';

void main() {
  testWidgets('LogoWidget renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame, testing an isolated widget
    // to avoid native plugin initialization errors (like Firebase).
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: LogoWidget(size: 100),
        ),
      ),
    ));

    // Verify that the LogoWidget is rendered
    expect(find.byType(LogoWidget), findsOneWidget);
  });
}
