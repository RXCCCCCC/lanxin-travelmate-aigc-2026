import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class ProfilePayload {
  const ProfilePayload({
    required this.userId,
    required this.travelPace,
    required this.dietaryPreferences,
    required this.interestTags,
    required this.transportPreferences,
    required this.budgetPreference,
    this.personality = 'gentle_companion',
    this.proactivityLevel = 'standard',
    this.syncStrategy = 'all',
    this.notificationEnabled = true,
    this.voiceEnabled = true,
    this.textModePreferred = false,
    this.customPrompt,
  });

  final String userId;
  final String travelPace;
  final List<String> dietaryPreferences;
  final List<String> interestTags;
  final List<String> transportPreferences;
  final String budgetPreference;
  final String personality;
  final String proactivityLevel;
  final String syncStrategy;
  final bool notificationEnabled;
  final bool voiceEnabled;
  final bool textModePreferred;
  final String? customPrompt;

  factory ProfilePayload.fromJson(Map<String, dynamic> json) {
    return ProfilePayload(
      userId: json['userId'] as String? ?? 'guest',
      travelPace: json['travelPace'] as String? ?? 'light',
      dietaryPreferences: _stringList(json['dietaryPreferences']),
      interestTags: _stringList(json['interestTags']),
      transportPreferences: _stringList(json['transportPreferences']),
      budgetPreference: json['budgetPreference'] as String? ?? 'medium',
      personality: json['personality'] as String? ?? 'gentle_companion',
      proactivityLevel: json['proactivityLevel'] as String? ?? 'standard',
      syncStrategy: json['syncStrategy'] as String? ?? 'all',
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      voiceEnabled: json['voiceEnabled'] as bool? ?? true,
      textModePreferred: json['textModePreferred'] as bool? ?? false,
      customPrompt: json['customPrompt'] as String?,
    );
  }

  factory ProfilePayload.fallback({String userId = 'guest'}) {
    return ProfilePayload(
      userId: userId,
      travelPace: 'light',
      dietaryPreferences: const [],
      interestTags: const [],
      transportPreferences: const [],
      budgetPreference: 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'travelPace': travelPace,
      'dietaryPreferences': dietaryPreferences,
      'interestTags': interestTags,
      'transportPreferences': transportPreferences,
      'budgetPreference': budgetPreference,
      'personality': personality,
      'proactivityLevel': proactivityLevel,
      'syncStrategy': syncStrategy,
      'notificationEnabled': notificationEnabled,
      'voiceEnabled': voiceEnabled,
      'textModePreferred': textModePreferred,
      'customPrompt': customPrompt,
    };
  }
}

class ProfileService {
  ProfileService({Dio? dio}) : _dio = dio ?? buildApiClient();

  final Dio _dio;

  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/profile/me',
        queryParameters: {'userId': userId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return ProfilePayload.fromJson(data);
      return ProfilePayload.fallback(userId: userId);
    } on DioException {
      return ProfilePayload.fallback(userId: userId);
    }
  }

  Future<ProfilePayload> updateProfile({
    String userId = 'guest',
    required ProfilePayload profile,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/profile/me',
        queryParameters: {'userId': userId},
        data: profile.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return ProfilePayload.fromJson(data);
      return profile;
    } on DioException {
      return profile;
    }
  }
}

List<String> _stringList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList();
}
