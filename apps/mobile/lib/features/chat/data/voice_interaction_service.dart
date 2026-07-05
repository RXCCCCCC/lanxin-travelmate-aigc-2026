import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class VoiceInteractionService {
  VoiceInteractionService({MethodChannel? channel, String? apiBaseUrl})
    : _channel = channel ?? const MethodChannel('lanxin_travelmate/voice'),
      _apiBaseUrl = apiBaseUrl ?? defaultApiBaseUrl;

  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final MethodChannel _channel;
  final String _apiBaseUrl;
  String? lastFailureMessage;

  Future<bool> startListening() async {
    lastFailureMessage = null;
    try {
      final started = await _channel.invokeMethod<bool>('startPcmRecording');
      if (started != true) {
        lastFailureMessage = '无法启动麦克风录音';
        return false;
      }
      return true;
    } on MissingPluginException {
      lastFailureMessage = '当前 Android 设备未接入系统语音识别通道';
      return false;
    } on PlatformException catch (error) {
      lastFailureMessage = _messageForPlatformError(error);
      return false;
    }
  }

  Future<String?> stopListening() async {
    lastFailureMessage = null;
    try {
      final base64 = await _channel.invokeMethod<String>('stopPcmRecording');
      if (base64 == null || base64.isEmpty) {
        lastFailureMessage = '未录制到语音内容，请重试';
        return null;
      }
      return await _sendToBackendAsr(base64);
    } on MissingPluginException {
      lastFailureMessage = '当前 Android 设备未接入系统语音识别通道';
      return null;
    } on PlatformException catch (error) {
      lastFailureMessage = _messageForPlatformError(error);
      return null;
    }
  }

  Future<String?> _sendToBackendAsr(String audioBase64) async {
    final dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 25),
      headers: {'content-type': 'application/json'},
    ));
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/audio/asr/recognize',
        data: {'audio_base64': audioBase64, 'userId': 'guest'},
      );
      final data = response.data;
      if (data == null) {
        lastFailureMessage = '语音识别服务无响应';
        return null;
      }
      if (data['fallback'] == true) {
        lastFailureMessage =
            data['fallbackReason']?.toString() ?? '语音识别服务暂不可用';
        return null;
      }
      final text = data['text']?.toString().trim();
      if (text == null || text.isEmpty) {
        lastFailureMessage = '未识别到语音内容，请重新说一遍';
        return null;
      }
      return text;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        lastFailureMessage = '无法连接后端服务，请确认网络和服务器状态';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        lastFailureMessage = '语音识别超时，请重试';
      } else {
        lastFailureMessage = '语音识别请求失败，请重试';
      }
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
      'microphone_permission_denied' =>
        '麦克风权限已被拒绝，请在系统设置中允许麦克风或改用文字输入',
      'voice_unavailable' => '系统语音识别服务不可用，请安装或启用语音识别服务',
      'voice_busy' => '正在处理上一段语音，请稍后再试',
      'tts_unavailable' => '系统中文语音播报暂不可用，已保留文字回复',
      _ => error.message ?? '系统语音能力暂不可用，请改用文字输入',
    };
  }
}
