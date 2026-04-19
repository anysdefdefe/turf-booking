// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_catalog_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomerCatalogController)
final customerCatalogControllerProvider = CustomerCatalogControllerProvider._();

final class CustomerCatalogControllerProvider
    extends $AsyncNotifierProvider<CustomerCatalogController, void> {
  CustomerCatalogControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerCatalogControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerCatalogControllerHash();

  @$internal
  @override
  CustomerCatalogController create() => CustomerCatalogController();
}

String _$customerCatalogControllerHash() =>
    r'6d34322d6891af6ff625d24b14117310f06a77a5';

abstract class _$CustomerCatalogController extends $AsyncNotifier<void> {
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
