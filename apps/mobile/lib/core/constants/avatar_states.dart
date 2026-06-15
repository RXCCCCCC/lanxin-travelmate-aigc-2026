enum AvatarState {
  idle('lanxiaoxin_frontdisplay', '待机'),
  hello('lanxiaoxin_hello', '打招呼'),
  thinking('lanxiaoxin_thinking', '思考中'),
  planning('lanxiaoxin_planning', '规划中'),
  warning('lanxiaoxin_warning', '提醒'),
  excited('lanxiaoxin_excited', '兴奋'),
  tired('lanxiaoxin_tired', '累了'),
  happy('lanxiaoxin_wave', '开心'),
  speaking('lanxiaoxin_listening', '说话'),
  listening('lanxiaoxin_listening', '倾听'),
  afterPlaying('lanxiaoxin_after_playing', '玩累了');

  const AvatarState(this.assetName, this.label);

  final String assetName;
  final String label;

  String get assetPath => 'assets/avatars/$assetName.png';

  static AvatarState fromApiName(String value) {
    for (final state in AvatarState.values) {
      if (state.name == value) return state;
    }
    return AvatarState.thinking;
  }
}
