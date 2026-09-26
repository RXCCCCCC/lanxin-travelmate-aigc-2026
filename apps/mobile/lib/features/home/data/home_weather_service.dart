import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../trip/data/location_selection_service.dart';

class HomeWeatherSummary {
  const HomeWeatherSummary({
    required this.title,
    required this.subtitle,
    required this.state,
    this.city,
    this.condition,
    this.temperatureC,
    this.hint,
  });

  final String title;
  final String subtitle;
  final HomeWeatherState state;
  final String? city;
  final String? condition;
  final int? temperatureC;
  final String? hint;

  static const idle = HomeWeatherSummary(
    title: '定位天气',
    subtitle: '点击获取当前位置',
    state: HomeWeatherState.idle,
  );

  static const loading = HomeWeatherSummary(
    title: '定位中',
    subtitle: '正在获取真实天气',
    state: HomeWeatherState.loading,
  );

  factory HomeWeatherSummary.failure(String message) {
    return HomeWeatherSummary(
      title: '天气失败',
      subtitle: message,
      state: HomeWeatherState.failure,
    );
  }

  factory HomeWeatherSummary.fromToolResult(Map<String, dynamic> result) {
    final condition = result['condition']?.toString();
    final city = result['city']?.toString();
    final temperature = (result['temperatureC'] as num?)?.round();
    final fallback = result['fallback'] == true;
    final title = fallback
        ? '天气待确认'
        : [
            if (city != null && city.isNotEmpty) city,
            if (condition != null && condition.isNotEmpty) condition,
          ].join(' ');
    final hint =
        result['travelHint']?.toString() ??
        result['fallbackReason']?.toString() ??
        '来自真实天气工具';
    final subtitle = temperature == null ? hint : '$temperature°C · $hint';
    return HomeWeatherSummary(
      title: title.isEmpty ? '天气已更新' : title,
      subtitle: subtitle,
      state: fallback ? HomeWeatherState.failure : HomeWeatherState.ready,
      city: city,
      condition: condition,
      temperatureC: temperature,
      hint: hint,
    );
  }
}

enum HomeWeatherState { idle, loading, ready, failure }

class HomeWeatherService {
  HomeWeatherService({
    Dio? dio,
    LocationSelectionService? locationSelectionService,
  }) : _dio = dio ?? buildApiClient(),
       _locationSelectionService =
           locationSelectionService ?? LocationSelectionService();

  final Dio _dio;
  final LocationSelectionService _locationSelectionService;

  Future<HomeWeatherSummary> fetchCurrentWeather() async {
    final location = await _locationSelectionService.currentLocation();
    if (location == null) {
      return HomeWeatherSummary.failure(
        _locationSelectionService.lastFailureMessage ?? '无法获取当前位置',
      );
    }
    try {
      final response = await _dio.post<dynamic>(
        '/api/tools/weather_tool/call',
        data: {
          'userId': 'guest',
          'payload': {
            'location': location.coordinateText,
            'longitude': location.longitude,
            'latitude': location.latitude,
          },
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final result = data['result'];
        if (result is Map<String, dynamic>) {
          return HomeWeatherSummary.fromToolResult(result);
        }
      }
      return HomeWeatherSummary.failure('天气工具返回格式异常');
    } on DioException {
      return HomeWeatherSummary.failure('天气服务暂时连不上，点此重试');
    }
  }
}
