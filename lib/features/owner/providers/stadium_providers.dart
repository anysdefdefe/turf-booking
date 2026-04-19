import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:turf_booking/features/owner/data/models/stadium_model.dart';
import 'package:turf_booking/features/owner/data/models/court_model.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';

part 'stadium_providers.g.dart';

/// Returns the single stadium owned by the current user, or null if
/// no stadium has been created yet. This is the data source for the
/// [OwnerGatewayScreen] routing decision.
@riverpod
Future<StadiumModel?> currentStadium(Ref ref) {
  return ref.watch(stadiumRepositoryProvider).getMyStadium();
}

/// Returns the list of courts for a given stadium.
/// Used by the dashboard to display the court count and by manage screens.
@riverpod
Future<List<CourtModel>> courtsForStadium(Ref ref, String stadiumId) {
  return ref.watch(stadiumRepositoryProvider).getCourtsForStadium(stadiumId);
}

/// Converts a [TimeOfDay] to Postgres-compatible HH:mm:ss string.
String _timeOfDayToPostgres(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m:00';
}

/// AsyncNotifier that manages the Add Stadium form submission lifecycle.
@riverpod
class AddStadiumController extends _$AddStadiumController {
  @override
  FutureOr<void> build() {
    // No-op. Initial state is AsyncData(null).
  }

  /// Submits the stadium and its courts to Supabase via the repository.
  ///
  /// [openTime] and [closeTime] are the stadium-level operating hours
  /// from the UI picker. They are cascaded to every court during
  /// insertion by the repository.
  Future<bool> submitStadium({
    required String name,
    String? description,
    List<String> amenities = const [],
    required String address,
    required String city,
    double? latitude,
    double? longitude,
    required TimeOfDay openTime,
    required TimeOfDay closeTime,
    required List<CourtInsertPayload> courts,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(stadiumRepositoryProvider).createStadiumWithCourts(
            name: name,
            description: description,
            amenities: amenities,
            address: address,
            city: city,
            latitude: latitude,
            longitude: longitude,
            openTime: _timeOfDayToPostgres(openTime),
            closeTime: _timeOfDayToPostgres(closeTime),
            courts: courts,
          );

      // Invalidate the gateway provider so it refetches on next access.
      ref.invalidate(currentStadiumProvider);
    });

    return !state.hasError;
  }
}
