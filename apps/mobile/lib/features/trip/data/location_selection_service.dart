import 'package:flutter/services.dart';

class SelectedLocation {
  const SelectedLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.provider,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String? provider;

  String get coordinateText =>
      '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

  factory SelectedLocation.fromMap(Map<dynamic, dynamic> map) {
    return SelectedLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      provider: map['provider']?.toString(),
    );
  }
}

class LocationSelectionService {
  LocationSelectionService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('lanxin_travelmate/location');

  final MethodChannel _channel;
  String? lastFailureMessage;

  Future<SelectedLocation?> currentLocation() async {
    lastFailureMessage = null;
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getCurrentLocation',
      );
      if (result == null) {
        lastFailureMessage = '暂未获取到系统定位结果，请打开定位服务或稍后重试';
        return null;
      }
      final location = SelectedLocation.fromMap(result);
      if (location.latitude == 0 && location.longitude == 0) {
        lastFailureMessage = '系统定位返回无效坐标，请手动输入当前位置';
        return null;
      }
      return location;
    } on MissingPluginException {
      lastFailureMessage = '当前 Android 设备未接入定位通道';
      return null;
    } on PlatformException catch (error) {
      lastFailureMessage = _messageForPlatformError(error);
      return null;
    }
  }

  String _messageForPlatformError(PlatformException error) {
    return switch (error.code) {
      'location_permission_denied' => '定位权限已被拒绝，请在系统设置中允许定位或手动输入坐标',
      'location_unavailable' => '系统定位服务暂不可用，请打开 GPS/网络定位后重试',
      'location_busy' => '正在处理上一次定位请求，请稍后再试',
      _ => error.message ?? '无法获取真实定位，请手动输入坐标',
    };
  }
}
