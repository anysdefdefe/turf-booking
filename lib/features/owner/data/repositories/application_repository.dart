import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/shared/exceptions/app_exceptions.dart';

part 'application_repository.g.dart';

class ApplicationRepository {
  final SupabaseClient _client;

  ApplicationRepository(this._client);

  /// Submits an owner application and uploads the proof of ownership document to Supabase Storage.
  Future<void> submitApplication({
    required String businessName,
    required String phone,
    required String message,
    required Uint8List documentBytes,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AppAuthException('User must be logged in to submit an application.');
      }

      final userId = user.id;
      final bucketName = 'proof_of_ownership';
      final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Path conforms to RLS policy: folder name must equal user id
      final filePath = '$userId/$fileName';

      // 1. Upload to Supabase Storage
      await _client.storage.from(bucketName).uploadBinary(
        filePath,
        documentBytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'application/pdf', 
        ),
      );

      // 2. We store the specific storage path in the database. 
      // Because the bucket is private (public = false), we do not generate a getPublicUrl.
      // The admin UI will use this path to generate a `createSignedUrl` when reviewing the application.
      final String documentUrl = filePath;

      // 3. Insert into the existing owner_applications table
      await _client.from('owner_applications').insert({
        'user_id': userId,
        'business_name': businessName,
        'phone': phone,
        'message': message,
        'document_url': documentUrl,
      });

    } on StorageException catch (e) {
      throw UnknownException('Document upload failed: ${e.message}', e);
    } on PostgrestException catch (e) {
      throw UnknownException('Application submission failed: ${e.message}', e);
    } catch (e) {
      throw UnknownException('An unexpected error occurred during submission.', e);
    }
  }
}

@riverpod
ApplicationRepository applicationRepository(ApplicationRepositoryRef ref) {
  return ApplicationRepository(Supabase.instance.client);
}
