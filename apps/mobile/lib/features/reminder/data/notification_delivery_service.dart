import 'package:flutter/services.dart';

class NotificationDeliveryService {
  NotificationDeliveryService({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('lanxin_travelmate/notifications');

  final MethodChannel _channel;

  Future<bool> showReminder({
    required String title,
    required String body,
  }) async {
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
      return false;
    } on PlatformException {
      return false;
    }
  }
}
