import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const LanXinApp(onRetryPendingSync: _noopRetry, splashEnabled: false),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('App root clears inherited text underline for all pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      const DefaultTextStyle(
        style: TextStyle(decoration: TextDecoration.underline),
        child: LanXinApp(onRetryPendingSync: _noopRetry, splashEnabled: false),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(TextField));
    expect(DefaultTextStyle.of(context).style.decoration, TextDecoration.none);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}

Future<void> _noopRetry() async {}
