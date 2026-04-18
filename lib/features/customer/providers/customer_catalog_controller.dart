import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'customer_providers.dart';

part 'customer_catalog_controller.g.dart';

@riverpod
class CustomerCatalogController extends _$CustomerCatalogController {
  @override
  FutureOr<void> build() async {
    await ref.read(courtRepositoryProvider).refreshCatalog();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(courtRepositoryProvider).refreshCatalog(),
    );
  }
}
