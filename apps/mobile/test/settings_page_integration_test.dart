import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/settings/settings_page.dart';

void main() {
  testWidgets('SettingsPage shows persona presets prompt action mapping and sample copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SettingsPage())));

    expect(find.text('活泼向导'), findsOneWidget);
    expect(find.text('细心管家'), findsOneWidget);
    expect(find.text('冷静规划师'), findsOneWidget);
    expect(find.text('元气拍档'), findsOneWidget);
    expect(find.text('安静陪伴'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('规划中 → planning'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('规划中 → planning'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('精力低时'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('精力低时'), findsOneWidget);
  });
}
