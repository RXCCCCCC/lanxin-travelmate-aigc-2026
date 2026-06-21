import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/constants/avatar_states.dart';

void main() {
  test('AvatarState maps backend api aliases to visual states', () {
    expect(AvatarState.fromApiName('trip_planning'), AvatarState.planning);
    expect(AvatarState.fromApiName('warning-risk'), AvatarState.warning);
    expect(AvatarState.fromApiName('after_playing'), AvatarState.afterPlaying);
    expect(AvatarState.fromApiName('unknown-state'), AvatarState.thinking);
  });

  test('AvatarState maps persisted event types to expressive states', () {
    expect(AvatarState.fromEvent('blind_box_completed'), AvatarState.excited);
    expect(AvatarState.fromEvent('weather_risk'), AvatarState.warning);
    expect(AvatarState.fromEvent('memory_confirmed'), AvatarState.happy);
    expect(
      AvatarState.fromEvent('unmapped', fallbackApiName: 'listening'),
      AvatarState.listening,
    );
  });

  test('AvatarState exposes real asset paths and motion parameters', () {
    expect(AvatarState.excited.assetPath, endsWith('.png'));
    expect(
      AvatarState.excited.floatAmplitude,
      greaterThan(AvatarState.tired.floatAmplitude),
    );
    expect(AvatarState.warning.pulseScale, greaterThan(1));
  });
}
