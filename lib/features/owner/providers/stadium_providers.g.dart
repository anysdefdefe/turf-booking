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

/// Returns the list of courts for a given stadium.
/// Used by the dashboard to display the court count and by manage screens.

@ProviderFor(courtsForStadium)
final courtsForStadiumProvider = CourtsForStadiumFamily._();

/// Returns the list of courts for a given stadium.
/// Used by the dashboard to display the court count and by manage screens.

final class CourtsForStadiumProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourtModel>>,
          List<CourtModel>,
          FutureOr<List<CourtModel>>
        >
    with $FutureModifier<List<CourtModel>>, $FutureProvider<List<CourtModel>> {
  /// Returns the list of courts for a given stadium.
  /// Used by the dashboard to display the court count and by manage screens.
  CourtsForStadiumProvider._({
    required CourtsForStadiumFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'courtsForStadiumProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courtsForStadiumHash();

  @override
  String toString() {
    return r'courtsForStadiumProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CourtModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourtModel>> create(Ref ref) {
    final argument = this.argument as String;
    return courtsForStadium(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CourtsForStadiumProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courtsForStadiumHash() => r'77f9a63ac27ee52f9c22f87b69d4f13dd0842f06';

/// Returns the list of courts for a given stadium.
/// Used by the dashboard to display the court count and by manage screens.

final class CourtsForStadiumFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CourtModel>>, String> {
  CourtsForStadiumFamily._()
    : super(
        retry: null,
        name: r'courtsForStadiumProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns the list of courts for a given stadium.
  /// Used by the dashboard to display the court count and by manage screens.

  CourtsForStadiumProvider call(String stadiumId) =>
      CourtsForStadiumProvider._(argument: stadiumId, from: this);

  @override
  String toString() => r'courtsForStadiumProvider';
}

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
