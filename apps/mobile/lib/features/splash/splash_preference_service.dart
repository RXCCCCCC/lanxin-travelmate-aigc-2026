import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum SplashPlaybackPolicy {
  never('never', '永不播放'),
  daily('daily', '每日第一次打开时播放'),
  everyLaunch('everyLaunch', '每次重新打开应用都播放');

  const SplashPlaybackPolicy(this.value, this.label);

  final String value;
  final String label;

  static SplashPlaybackPolicy fromValue(String? value) {
    return SplashPlaybackPolicy.values.firstWhere(
      (item) => item.value == value,
      orElse: () => SplashPlaybackPolicy.daily,
    );
  }
}

class SplashPreferenceService {
  static const _policyFileName = 'splash_playback_policy.txt';
  static const _lastPlayedFileName = 'splash_last_played_date.txt';

  Future<SplashPlaybackPolicy> readPolicy() async {
    final file = await _file(_policyFileName);
    if (!await file.exists()) return SplashPlaybackPolicy.daily;
    return SplashPlaybackPolicy.fromValue((await file.readAsString()).trim());
  }

  Future<void> savePolicy(SplashPlaybackPolicy policy) async {
    final file = await _file(_policyFileName);
    await file.writeAsString(policy.value);
  }

  Future<bool> shouldPlay() async {
    final policy = await readPolicy();
    return switch (policy) {
      SplashPlaybackPolicy.never => false,
      SplashPlaybackPolicy.everyLaunch => true,
      SplashPlaybackPolicy.daily => await _shouldPlayDaily(),
    };
  }

  Future<void> markPlayedToday() async {
    final file = await _file(_lastPlayedFileName);
    await file.writeAsString(_todayKey(DateTime.now()));
  }

  Future<bool> _shouldPlayDaily() async {
    final file = await _file(_lastPlayedFileName);
    if (!await file.exists()) return true;
    return (await file.readAsString()).trim() != _todayKey(DateTime.now());
  }

  Future<File> _file(String name) async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/$name');
  }

  String _todayKey(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
