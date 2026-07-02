import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LanXinApp(onRetryPendingSync: _noopRetry));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('lanxiaoxin'), findsOneWidget);
  });
}

Future<void> _noopRetry() async {}
