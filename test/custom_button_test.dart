import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_shadule_new/widgets/custom_button.dart';

void main() {
  testWidgets('CustomButton displays correct text and handles tap', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Test Button',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    // Verify text is displayed
    expect(find.text('Test Button'), findsOneWidget);

    // Tap button and verify onPressed is triggered
    await tester.tap(find.text('Test Button'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('CustomButton shows loading indicator and disables callback', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Test Button',
            isLoading: true,
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    // Verify CircularProgressIndicator is displayed
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify button text is not shown when loading
    expect(find.text('Test Button'), findsNothing);

    // Tap button and verify onPressed is NOT triggered
    await tester.tap(find.byType(CustomButton));
    await tester.pump();

    expect(pressed, isFalse);
  });
}
