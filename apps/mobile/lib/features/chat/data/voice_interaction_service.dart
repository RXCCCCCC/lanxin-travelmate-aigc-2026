import 'package:flutter/services.dart';

class VoiceInteractionService {
  VoiceInteractionService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('lanxin_travelmate/voice');

  final MethodChannel _channel;

  Future<String?> listenOnce() async {
    try {
      final value = await _channel.invokeMethod<String>('startVoiceInput');
      final text = value?.trim();
      return text == null || text.isEmpty ? null : text;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('speakText', {'text': value}) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
