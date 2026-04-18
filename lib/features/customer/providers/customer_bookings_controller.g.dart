// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_bookings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomerBookingsController)
final customerBookingsControllerProvider =
    CustomerBookingsControllerProvider._();

final class CustomerBookingsControllerProvider
    extends $AsyncNotifierProvider<CustomerBookingsController, void> {
  CustomerBookingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingsControllerHash();

  @$internal
  @override
  CustomerBookingsController create() => CustomerBookingsController();
}

String _$customerBookingsControllerHash() =>
    r'5892ce6cbde2704c8ae8a146f15865fe2122e043';

abstract class _$CustomerBookingsController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
