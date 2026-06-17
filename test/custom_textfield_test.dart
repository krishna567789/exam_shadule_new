import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_shadule_new/widgets/custom_textfield.dart';

void main() {
  testWidgets('CustomTextField displays correct label and handles text input', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'username',
            controller: controller,
          ),
        ),
      ),
    );

    // Verify label is displayed in uppercase
    expect(find.text('USERNAME'), findsOneWidget);

    // Enter text and verify controller is updated
    await tester.enterText(find.byType(TextField), 'john_doe');
    expect(controller.text, 'john_doe');
  });

  testWidgets('CustomTextField respects obscureText setting', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'password',
            obscureText: true,
          ),
        ),
      ),
    );

    // Find the TextField and verify it has obscureText set to true
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.obscureText, isTrue);
  });
}
