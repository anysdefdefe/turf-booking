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
