import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:turf_booking/features/owner/data/models/stadium_model.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';

part 'stadium_providers.g.dart';

/// Returns the single stadium owned by the current user, or null if
/// no stadium has been created yet. This is the data source for the
/// [OwnerGatewayScreen] routing decision.
@riverpod
Future<StadiumModel?> currentStadium(Ref ref) {
  return ref.watch(stadiumRepositoryProvider).getMyStadium();
}
