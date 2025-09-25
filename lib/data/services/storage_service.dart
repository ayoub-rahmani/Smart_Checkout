import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<String>> uploadProductImages(List<File> imageFiles, String productId) async {
    List<String> imageUrls = [];

    try {
      // Quick connection test
      await _storage.ref().getMetadata().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Storage connection timeout - check internet'),
      );

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];

        // Basic validation
        if (!await file.exists()) throw Exception('Image ${i + 1} not found');
        final size = await file.length();
        if (size == 0) throw Exception('Image ${i + 1} is empty');
        if (size > 10 * 1024 * 1024) throw Exception('Image ${i + 1} too large (max 10MB)');

        // Upload with simple path
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(file.path)}';
        final ref = _storage.ref('products/$productId/$fileName');

        final uploadTask = ref.putFile(file, SettableMetadata(
          contentType: _getContentType(file.path),
        ));

        final snapshot = await uploadTask.timeout(
          const Duration(minutes: 2),
          onTimeout: () => throw Exception('Upload timeout for image ${i + 1}'),
        );

        if (snapshot.state == TaskState.success) {
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        } else {
          throw Exception('Upload failed for image ${i + 1}');
        }
      }

      return imageUrls;
    } catch (e) {
      // Cleanup on failure
      for (String url in imageUrls) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }

      // Return user-friendly error
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied - check Firebase Storage rules');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Upload timeout - check your internet connection');
      } else {
        throw Exception('Upload failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  String _getContentType(String filePath) {
    switch (path.extension(filePath).toLowerCase()) {
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.png': return 'image/png';
      case '.webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

  Future<void> deleteProductImages(String productId) async {
    try {
      final result = await _storage.ref('products/$productId').listAll();
      for (Reference ref in result.items) {
        await ref.delete();
      }
    } catch (e) {
      print('Delete error: $e');
    }
  }
}