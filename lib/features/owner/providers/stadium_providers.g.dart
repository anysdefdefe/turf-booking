// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stadium_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns the single stadium owned by the current user, or null if
/// no stadium has been created yet. This is the data source for the
/// [OwnerGatewayScreen] routing decision.

@ProviderFor(currentStadium)
final currentStadiumProvider = CurrentStadiumProvider._();

/// Returns the single stadium owned by the current user, or null if
/// no stadium has been created yet. This is the data source for the
/// [OwnerGatewayScreen] routing decision.

final class CurrentStadiumProvider
    extends
        $FunctionalProvider<
          AsyncValue<StadiumModel?>,
          StadiumModel?,
          FutureOr<StadiumModel?>
        >
    with $FutureModifier<StadiumModel?>, $FutureProvider<StadiumModel?> {
  /// Returns the single stadium owned by the current user, or null if
  /// no stadium has been created yet. This is the data source for the
  /// [OwnerGatewayScreen] routing decision.
  CurrentStadiumProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentStadiumProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentStadiumHash();

  @$internal
  @override
  $FutureProviderElement<StadiumModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StadiumModel?> create(Ref ref) {
    return currentStadium(ref);
  }
}

String _$currentStadiumHash() => r'43d7e7ff4137cdc0ad3674e27db6bd40ff3687d8';

/// AsyncNotifier that manages the Add Stadium form submission lifecycle.

@ProviderFor(AddStadiumController)
final addStadiumControllerProvider = AddStadiumControllerProvider._();

/// AsyncNotifier that manages the Add Stadium form submission lifecycle.
final class AddStadiumControllerProvider
    extends $AsyncNotifierProvider<AddStadiumController, void> {
  /// AsyncNotifier that manages the Add Stadium form submission lifecycle.
  AddStadiumControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addStadiumControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addStadiumControllerHash();

  @$internal
  @override
  AddStadiumController create() => AddStadiumController();
}

String _$addStadiumControllerHash() =>
    r'1dede05914852bcd216ff34b02dc3e20c44526cb';

/// AsyncNotifier that manages the Add Stadium form submission lifecycle.

abstract class _$AddStadiumController extends $AsyncNotifier<void> {
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
