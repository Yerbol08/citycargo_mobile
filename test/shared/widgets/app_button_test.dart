import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citycargo_mobile/shared/widgets/app_button.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('AppButton Widget Tests', () {
    testWidgets('renders label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AppButton(label: 'Submit')),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('renders loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AppButton(label: 'Submit', isLoading: true)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('renders outlined button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AppButton(label: 'Cancel', outlined: true)),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildTestWidget(
          AppButton(
            label: 'Submit',
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when loading', (WidgetTester tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildTestWidget(
          AppButton(
            label: 'Submit',
            isLoading: true,
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, isFalse);
    });
  });
}
