import 'package:flutter/services.dart';

class VoiceInteractionService {
  VoiceInteractionService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('lanxin_travelmate/voice');

  final MethodChannel _channel;
  String? lastFailureMessage;

  Future<String?> listenOnce() async {
    lastFailureMessage = null;
    try {
      final value = await _channel.invokeMethod<String>('startVoiceInput');
      final text = value?.trim();
      return text == null || text.isEmpty ? null : text;
    } on MissingPluginException {
      lastFailureMessage = '当前 Android 设备未接入系统语音识别通道';
      return null;
    } on PlatformException catch (error) {
      lastFailureMessage = _messageForPlatformError(error);
      return null;
    }
  }

  Future<bool> speak(String text) async {
    lastFailureMessage = null;
    final value = text.trim();
    if (value.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('speakText', {'text': value}) ??
          false;
    } on MissingPluginException {
      lastFailureMessage = '当前 Android 设备未接入系统语音播报通道';
      return false;
    } on PlatformException catch (error) {
      lastFailureMessage = _messageForPlatformError(error);
      return false;
    }
  }

  String _messageForPlatformError(PlatformException error) {
    return switch (error.code) {
      'microphone_permission_denied' => '麦克风权限已被拒绝，请在系统设置中允许麦克风或改用文字输入',
      'voice_unavailable' => '系统语音识别服务不可用，请安装或启用语音识别服务',
      'voice_busy' => '正在处理上一段语音，请稍后再试',
      'tts_unavailable' => '系统中文语音播报暂不可用，已保留文字回复',
      _ => error.message ?? '系统语音能力暂不可用，请改用文字输入',
    };
  }
}
