import '../../core/constants/avatar_states.dart';

enum MemoryScope {
  longTerm('长期'),
  currentTrip('本次'),
  temporary('临时');

  const MemoryScope(this.label);
  final String label;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.avatarState,
  });

  final String id;
  final MessageSender sender;
  final String text;
  final String time;
  final AvatarState? avatarState;
}

enum MessageSender { user, assistant }

class MemoryCapsule {
  const MemoryCapsule({
    required this.id,
    required this.title,
    required this.content,
    required this.scope,
    required this.createdAt,
    this.tags = const [],
    this.isNew = false,
  });

  final String id;
  final String title;
  final String content;
  final MemoryScope scope;
  final String createdAt;
  final List<String> tags;
  final bool isNew;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.avatarUrl,
    required this.dietaryPreferences,
    required this.travelPace,
    required this.transportPreference,
    required this.budgetLevel,
    required this.interestTags,
  });

  final String name;
  final String avatarUrl;
  final List<String> dietaryPreferences;
  final String travelPace;
  final String transportPreference;
  final String budgetLevel;
  final List<String> interestTags;
}

class TripPlan {
  const TripPlan({
    required this.title,
    required this.dateRange,
    required this.destination,
    required this.days,
    required this.risks,
  });

  final String title;
  final String dateRange;
  final String destination;
  final List<TripDay> days;
  final List<String> risks;
}

class TripDay {
  const TripDay({required this.dayLabel, required this.items});
  final String dayLabel;
  final List<TripItem> items;
}

class TripItem {
  const TripItem({
    required this.time,
    required this.location,
    required this.activity,
    required this.reason,
    this.isCurrent = false,
  });

  final String time;
  final String location;
  final String activity;
  final String reason;
  final bool isCurrent;
}

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.triggerReason,
    required this.actionLabel,
    this.iconName = 'notifications_active_outlined',
  });

  final String id;
  final String title;
  final String description;
  final String triggerReason;
  final String actionLabel;
  final String iconName;
}

class PhotoCandidate {
  const PhotoCandidate({
    required this.id,
    required this.location,
    required this.score,
    required this.description,
  });

  final String id;
  final String location;
  final double score;
  final String description;
}

class TripReview {
  const TripReview({
    required this.title,
    required this.dateRange,
    required this.route,
    required this.highlightPhotoCount,
    required this.newMemoryCount,
    required this.highlightPhotos,
    required this.newMemories,
    required this.nextTripSuggestions,
  });

  final String title;
  final String dateRange;
  final String route;
  final int highlightPhotoCount;
  final int newMemoryCount;
  final List<String> highlightPhotos;
  final List<String> newMemories;
  final List<String> nextTripSuggestions;
}
