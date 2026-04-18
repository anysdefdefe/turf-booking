// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(courtRepository)
final courtRepositoryProvider = CourtRepositoryProvider._();

final class CourtRepositoryProvider
    extends
        $FunctionalProvider<CourtRepository, CourtRepository, CourtRepository>
    with $Provider<CourtRepository> {
  CourtRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courtRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courtRepositoryHash();

  @$internal
  @override
  $ProviderElement<CourtRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CourtRepository create(Ref ref) {
    return courtRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourtRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourtRepository>(value),
    );
  }
}

String _$courtRepositoryHash() => r'e4df841e45715df7304f434ca9d6c48d99185774';

@ProviderFor(customerBookingRepository)
final customerBookingRepositoryProvider = CustomerBookingRepositoryProvider._();

final class CustomerBookingRepositoryProvider
    extends
        $FunctionalProvider<
          CustomerBookingRepository,
          CustomerBookingRepository,
          CustomerBookingRepository
        >
    with $Provider<CustomerBookingRepository> {
  CustomerBookingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingRepositoryHash();

  @$internal
  @override
  $ProviderElement<CustomerBookingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CustomerBookingRepository create(Ref ref) {
    return customerBookingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomerBookingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomerBookingRepository>(value),
    );
  }
}

String _$customerBookingRepositoryHash() =>
    r'c19e4294a966942030db7683f74fd35b57c68d16';
