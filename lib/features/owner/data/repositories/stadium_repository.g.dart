// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stadium_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(stadiumRepository)
final stadiumRepositoryProvider = StadiumRepositoryProvider._();

final class StadiumRepositoryProvider
    extends
        $FunctionalProvider<
          StadiumRepository,
          StadiumRepository,
          StadiumRepository
        >
    with $Provider<StadiumRepository> {
  StadiumRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stadiumRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stadiumRepositoryHash();

  @$internal
  @override
  $ProviderElement<StadiumRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StadiumRepository create(Ref ref) {
    return stadiumRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StadiumRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StadiumRepository>(value),
    );
  }
}

String _$stadiumRepositoryHash() => r'ec33110e3544b0586f093704c48c46391c75af48';
