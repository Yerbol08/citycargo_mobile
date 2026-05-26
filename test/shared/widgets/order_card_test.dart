import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citycargo_mobile/shared/widgets/order_card.dart';
import 'package:citycargo_mobile/shared/models/api_response_model.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';

void main() {
  final testOrder = const OrderSummary(
    id: '1',
    number: 'ORD-001',
    status: 'created',
    senderAddress: 'Sender Str 1',
    recipientAddress: 'Recipient Str 2',
    priceMinor: 150000,
    currency: 'KZT',
  );

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('OrderCard Widget Tests', () {
    testWidgets('renders basic order info correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(OrderCard(order: testOrder)),
      );

      // We need to wait for AppLocalizations to load if it's asynchronous, but typically it is synchronous for material app with explicit delegates.
      await tester.pumpAndSettle();

      expect(find.text('ORD-001'), findsOneWidget);
      expect(find.text('Sender Str 1'), findsOneWidget);
      expect(find.text('Recipient Str 2'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          OrderCard(
            order: testOrder,
            onTap: () => tapped = true,
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OrderCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
