// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_bookings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ownerBookingsRepository)
final ownerBookingsRepositoryProvider = OwnerBookingsRepositoryProvider._();

final class OwnerBookingsRepositoryProvider
    extends
        $FunctionalProvider<
          OwnerBookingsRepository,
          OwnerBookingsRepository,
          OwnerBookingsRepository
        >
    with $Provider<OwnerBookingsRepository> {
  OwnerBookingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerBookingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerBookingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<OwnerBookingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OwnerBookingsRepository create(Ref ref) {
    return ownerBookingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OwnerBookingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OwnerBookingsRepository>(value),
    );
  }
}

String _$ownerBookingsRepositoryHash() =>
    r'c792c24b5c39596dd3f0c2857b2f207121b11fb3';
