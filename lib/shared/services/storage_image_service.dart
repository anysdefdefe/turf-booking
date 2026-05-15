import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turf_booking/app/constants/app_constants.dart';

class StorageImageService {
  StorageImageService(this._client);

  final SupabaseClient _client;

  Future<String?> resolveStorageUrl({
    required String? storagePath,
    required String bucketName,
  }) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    if (storagePath.startsWith('http://') ||
        storagePath.startsWith('https://')) {
      return storagePath;
    }

    try {
      return await _client.storage
          .from(bucketName)
          .createSignedUrl(storagePath, 60 * 60);
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadImageBytes({
    required String bucketName,
    required String ownerId,
    required String folder,
    required String sourcePath,
    required Uint8List bytes,
    String? oldStoragePath,
  }) async {
    validateImageSelection(
      sourcePath: sourcePath,
      byteLength: bytes.lengthInBytes,
    );

    final extension = _fileExtension(sourcePath);
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}${extension.isEmpty ? '.jpg' : extension}';
    final storagePath = '$ownerId/$folder/$fileName';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(extension),
          ),
        );

    if (oldStoragePath != null &&
        oldStoragePath.isNotEmpty &&
        oldStoragePath != storagePath &&
        !oldStoragePath.startsWith('http')) {
      try {
        await _client.storage.from(bucketName).remove([oldStoragePath]);
      } catch (_) {
        // Ignore cleanup failures; the new image has already been saved.
      }
    }

    return storagePath;
  }

  void validateImageSelection({
    required String sourcePath,
    required int byteLength,
  }) {
    final extension = _fileExtension(sourcePath);
    if (!AppConstants.allowedStorageImageExtensions.contains(extension)) {
      throw const FormatException('Only JPG and PNG images are allowed.');
    }

    if (byteLength > AppConstants.maxStorageImageUploadBytes) {
      throw const FormatException('Image must be smaller than 10 MB.');
    }
  }

  Future<void> validatePickedImage(XFile file) async {
    final byteLength = await file.length();
    validateImageSelection(sourcePath: file.path, byteLength: byteLength);
  }

  String _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) return '';
    return path.substring(dotIndex).toLowerCase();
  }

  String _contentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
