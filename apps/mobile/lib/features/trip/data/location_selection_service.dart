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

  Future<SelectedLocation?> currentLocation() async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getCurrentLocation',
      );
      if (result == null) return null;
      final location = SelectedLocation.fromMap(result);
      if (location.latitude == 0 && location.longitude == 0) return null;
      return location;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
