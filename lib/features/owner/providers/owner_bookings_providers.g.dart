// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_bookings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches all bookings explicitly scoped to the active stadium.

@ProviderFor(ownerBookings)
final ownerBookingsProvider = OwnerBookingsProvider._();

/// Fetches all bookings explicitly scoped to the active stadium.

final class OwnerBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BookingModel>>,
          List<BookingModel>,
          FutureOr<List<BookingModel>>
        >
    with
        $FutureModifier<List<BookingModel>>,
        $FutureProvider<List<BookingModel>> {
  /// Fetches all bookings explicitly scoped to the active stadium.
  OwnerBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerBookingsHash();

  @$internal
  @override
  $FutureProviderElement<List<BookingModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BookingModel>> create(Ref ref) {
    return ownerBookings(ref);
  }
}

String _$ownerBookingsHash() => r'b4dc133da73c97d17a1287af9d2ae1c55881e76a';
