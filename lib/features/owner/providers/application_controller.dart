import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_booking/features/owner/data/repositories/application_repository.dart';

part 'application_controller.g.dart';

@riverpod
class ApplicationController extends _$ApplicationController {
  @override
  FutureOr<void> build() {
    // Initial state is just empty/ready.
  }

  Future<void> submit({
    required String businessName,
    required String phone,
    required String message,
    required Uint8List documentBytes,
  }) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(applicationRepositoryProvider);
      await repository.submitApplication(
        businessName: businessName,
        phone: phone,
        message: message,
        documentBytes: documentBytes,
      );
    });
  }
}

@riverpod
Future<bool> checkPendingApplication(Ref ref) async {
  return ref.watch(applicationRepositoryProvider).hasPendingApplication();
}
