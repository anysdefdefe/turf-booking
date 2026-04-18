// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(applicationRepository)
final applicationRepositoryProvider = ApplicationRepositoryProvider._();

final class ApplicationRepositoryProvider
    extends
        $FunctionalProvider<
          ApplicationRepository,
          ApplicationRepository,
          ApplicationRepository
        >
    with $Provider<ApplicationRepository> {
  ApplicationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applicationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applicationRepositoryHash();

  @$internal
  @override
  $ProviderElement<ApplicationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApplicationRepository create(Ref ref) {
    return applicationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApplicationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApplicationRepository>(value),
    );
  }
}

String _$applicationRepositoryHash() =>
    r'f20df18fc60e2e345453c6ccd0262e6b3464266c';
