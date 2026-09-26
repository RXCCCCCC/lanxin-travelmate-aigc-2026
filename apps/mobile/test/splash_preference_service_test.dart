import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/splash/splash_preference_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SplashPlaybackPolicy defaults unknown values to daily', () {
    expect(
      SplashPlaybackPolicy.fromValue('unexpected'),
      SplashPlaybackPolicy.daily,
    );
    expect(SplashPlaybackPolicy.fromValue(null), SplashPlaybackPolicy.daily);
  });

  test(
    'SplashPreferenceService applies daily every-launch and never policies',
    () async {
      final directory = await Directory.systemTemp.createTemp('lanxin_splash_');
      PathProviderPlatform.instance = _FakePathProvider(directory.path);
      final service = SplashPreferenceService();

      expect(await service.readPolicy(), SplashPlaybackPolicy.daily);
      expect(await service.shouldPlay(), isTrue);

      await service.markPlayedToday();
      expect(await service.shouldPlay(), isFalse);

      await service.savePolicy(SplashPlaybackPolicy.everyLaunch);
      expect(await service.shouldPlay(), isTrue);

      await service.savePolicy(SplashPlaybackPolicy.never);
      expect(await service.shouldPlay(), isFalse);
    },
  );
}
