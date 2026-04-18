// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ApplicationController)
final applicationControllerProvider = ApplicationControllerProvider._();

final class ApplicationControllerProvider
    extends $AsyncNotifierProvider<ApplicationController, void> {
  ApplicationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applicationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applicationControllerHash();

  @$internal
  @override
  ApplicationController create() => ApplicationController();
}

String _$applicationControllerHash() =>
    r'5a8e5e4480195b7091f94ff76dea584af9ba1a67';

abstract class _$ApplicationController extends $AsyncNotifier<void> {
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

@ProviderFor(checkPendingApplication)
final checkPendingApplicationProvider = CheckPendingApplicationProvider._();

final class CheckPendingApplicationProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  CheckPendingApplicationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkPendingApplicationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkPendingApplicationHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return checkPendingApplication(ref);
  }
}

String _$checkPendingApplicationHash() =>
    r'79173d87fdd29cbe1dec087de5b4f2972ed1f9e5';
