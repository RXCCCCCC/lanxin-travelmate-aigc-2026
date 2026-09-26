import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/splash/splash_video_gate.dart';

void main() {
  test(
    'SplashVideoGate keeps opening sound, mutes idle loop, and waits for CTA',
    () {
      const gate = SplashVideoGate(child: SizedBox.shrink());

      expect(gate.videoVolume, 1.0);
      expect(gate.idleVideoVolume, 0.0);
      expect(gate.idleAssetPath, 'assets/splash/lanxin_idle_silent.mp4');
      expect(
        gate.continueLabel,
        '\u5f00\u59cb\u6211\u4eec\u7684\u65c5\u884c\u5427!!!',
      );
      expect(gate.maximumDisplay, const Duration(seconds: 30));
      expect(gate.childRevealDuration, const Duration(milliseconds: 3000));
    },
  );

  testWidgets('SplashVideoGate clears inherited yellow text underline', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(decoration: TextDecoration.underline),
          child: SplashVideoGate(
            enabled: false,
            child: Text('plain child text'),
          ),
        ),
      ),
    );

    final context = tester.element(find.text('plain child text'));
    expect(DefaultTextStyle.of(context).style.decoration, TextDecoration.none);
  });
}
