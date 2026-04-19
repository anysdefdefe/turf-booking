// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_bookings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches all bookings for the stadiums owned by the user.

@ProviderFor(ownerBookings)
final ownerBookingsProvider = OwnerBookingsProvider._();

/// Fetches all bookings for the stadiums owned by the user.

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
  /// Fetches all bookings for the stadiums owned by the user.
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

String _$ownerBookingsHash() => r'bbebd03043f7c8b8b829b4d09a461e3163f0d39b';
