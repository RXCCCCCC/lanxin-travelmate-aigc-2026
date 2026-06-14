import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LanXinApp());
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);
  });
}
