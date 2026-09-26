enum AvatarAssetFormat { png, gif, webp }

extension AvatarAssetFormatExtension on AvatarAssetFormat {
  String get extensionName => switch (this) {
    AvatarAssetFormat.png => 'png',
    AvatarAssetFormat.gif => 'gif',
    AvatarAssetFormat.webp => 'webp',
  };
}

enum AvatarState {
  idle(
    'lanxiaoxin_frontdisplay',
    '待机',
    aliases: ['standby', 'default', 'frontdisplay'],
    eventTypes: ['idle', 'session_started'],
    floatAmplitude: 4,
  ),
  hello(
    'lanxiaoxin_hello',
    '打招呼',
    aliases: ['hi', 'greeting', 'welcome', 'wave_hello'],
    eventTypes: ['guest_created', 'chat_started'],
    floatAmplitude: 5,
  ),
  thinking(
    'lanxiaoxin_thinking',
    '思考中',
    aliases: ['think', 'reasoning', 'loading', 'fallback'],
    eventTypes: ['model_fallback', 'tool_fallback', 'schema_validation'],
    floatAmplitude: 3,
    motionDuration: Duration(milliseconds: 3600),
  ),
  planning(
    'lanxiaoxin_planning',
    '规划中',
    aliases: ['plan', 'trip_planning', 'route_planning'],
    eventTypes: ['trip_planned', 'trip_replanned', 'route_adjusted'],
    floatAmplitude: 6,
  ),
  warning(
    'lanxiaoxin_warning',
    '提醒',
    aliases: ['alert', 'risk', 'reminder', 'warning_risk'],
    eventTypes: ['reminder_triggered', 'weather_risk', 'permission_denied'],
    floatAmplitude: 2,
    motionDuration: Duration(milliseconds: 2200),
    pulseScale: 1.025,
  ),
  excited(
    'lanxiaoxin_excited',
    '兴奋',
    aliases: ['excite', 'celebrate', 'reward'],
    eventTypes: [
      'blind_box_completed',
      'photo_highlighted',
      'review_generated',
    ],
    floatAmplitude: 8,
    motionDuration: Duration(milliseconds: 1800),
    pulseScale: 1.04,
  ),
  tired(
    'lanxiaoxin_tired',
    '累了',
    aliases: ['low_energy', 'energy_low', 'rest'],
    eventTypes: ['low_energy_detected', 'slow_pace_suggested'],
    floatAmplitude: 2,
    motionDuration: Duration(milliseconds: 4200),
  ),
  happy(
    'lanxiaoxin_wave',
    '开心',
    aliases: ['wave', 'happy', 'rapport_up', 'affection_up'],
    eventTypes: ['memory_confirmed', 'sync_completed', 'profile_updated'],
    floatAmplitude: 7,
    motionDuration: Duration(milliseconds: 2100),
    pulseScale: 1.03,
  ),
  speaking(
    'lanxiaoxin_listening',
    '说话',
    aliases: ['speak', 'talking', 'tts'],
    eventTypes: ['voice_reply_started', 'tts_completed'],
  ),
  listening(
    'lanxiaoxin_listening',
    '倾听',
    aliases: ['listen', 'asr', 'recording'],
    eventTypes: ['asr_started', 'voice_input_received'],
    floatAmplitude: 4,
  ),
  afterPlaying(
    'lanxiaoxin_after_playing',
    '玩累了',
    aliases: ['after_playing', 'trip_finished', 'review_done'],
    eventTypes: ['trip_finished', 'day_reviewed'],
    floatAmplitude: 3,
    motionDuration: Duration(milliseconds: 3800),
  );

  const AvatarState(
    this.assetName,
    this.label, {
    this.aliases = const [],
    this.eventTypes = const [],
    this.floatAmplitude = 6,
    this.motionDuration = const Duration(seconds: 3),
    this.pulseScale = 1,
  });

  final String assetName;
  final String label;
  AvatarAssetFormat get assetFormat => AvatarAssetFormat.png;
  final List<String> aliases;
  final List<String> eventTypes;
  final double floatAmplitude;
  final Duration motionDuration;
  final double pulseScale;

  String get assetPath =>
      'assets/avatars/$assetName.${assetFormat.extensionName}';

  static AvatarState fromApiName(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return AvatarState.thinking;
    for (final state in AvatarState.values) {
      final candidates = [
        state.name,
        state.assetName,
        state.label,
        ...state.aliases,
      ];
      if (candidates.any((item) => _normalize(item) == normalized)) {
        return state;
      }
    }
    return AvatarState.thinking;
  }

  static AvatarState fromEvent(String? eventType, {String? fallbackApiName}) {
    final normalized = _normalize(eventType ?? '');
    if (normalized.isNotEmpty) {
      for (final state in AvatarState.values) {
        if (state.eventTypes.any((item) => _normalize(item) == normalized)) {
          return state;
        }
      }
    }
    return AvatarState.fromApiName(fallbackApiName ?? '');
  }

  static String _normalize(String value) =>
      value.trim().replaceAll('-', '_').replaceAll(' ', '_').toLowerCase();
}
