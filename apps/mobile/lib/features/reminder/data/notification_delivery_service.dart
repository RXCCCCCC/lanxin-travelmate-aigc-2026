import 'package:flutter/services.dart';

class NotificationDeliveryService {
  NotificationDeliveryService({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('lanxin_travelmate/notifications');

  final MethodChannel _channel;
  String? lastFailureMessage;

  Future<bool> showReminder({
    required String title,
    required String body,
  }) async {
    lastFailureMessage = null;
    final safeTitle = title.trim().isEmpty ? '蓝心同行提醒' : title.trim();
    final safeBody = body.trim();
    if (safeBody.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('showReminderNotification', {
            'title': safeTitle,
            'body': safeBody,
          }) ??
          false;
    } on MissingPluginException {
      lastFailureMessage = '当前 Android 设备未接入系统通知通道';
      return false;
    } on PlatformException catch (error) {
      lastFailureMessage = _messageForPlatformError(error);
      return false;
    }
  }

  String _messageForPlatformError(PlatformException error) {
    return switch (error.code) {
      'notification_permission_denied' => '通知权限已被拒绝，请在系统设置中允许通知；应用内提醒仍会保留',
      'notification_busy' => '正在处理上一次通知授权请求，请稍后再试',
      'notification_unavailable' => '系统通知暂不可用，已保留应用内提醒',
      _ => error.message ?? '系统通知暂不可用，已保留应用内提醒',
    };
  }
}
