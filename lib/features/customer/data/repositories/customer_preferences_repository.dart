import 'package:flutter/foundation.dart';

class CustomerPreferencesRepository {
  CustomerPreferencesRepository._();

  static final CustomerPreferencesRepository instance =
      CustomerPreferencesRepository._();

  final ValueNotifier<Set<String>> likedCourtIds = ValueNotifier<Set<String>>(
    <String>{},
  );

  bool isLiked(String courtId) => likedCourtIds.value.contains(courtId);

  void toggleLike(String courtId) {
    final updated = Set<String>.from(likedCourtIds.value);
    if (!updated.remove(courtId)) {
      updated.add(courtId);
    }
    likedCourtIds.value = updated;
  }

  void clearAllLikes() {
    likedCourtIds.value = <String>{};
  }
}
