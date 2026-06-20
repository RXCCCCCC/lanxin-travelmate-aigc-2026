import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/app.dart';

void main() {
  testWidgets('LanXinApp retries local sync on launch and resume', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      LanXinApp(onRetryPendingSync: () async => retryCount += 1),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(retryCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));

    expect(retryCount, 2);
  });
}
