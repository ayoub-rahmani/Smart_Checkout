import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<String>> uploadProductImages(List<File> images, String productId) async {
    List<String> urls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        print('Starting upload for image $i...');

        // Read file as bytes first
        final Uint8List bytes = await images[i].readAsBytes();
        print('Read ${bytes.length} bytes from image $i');

        final String path = 'products/$productId/image_$i.jpg';
        final Reference ref = _storage.ref().child(path);

        // Use putData with metadata
        final SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'max-age=3600',
        );

        print('Uploading to path: $path');

        // Upload with retry logic
        String? downloadUrl;
        int retries = 3;

        while (retries > 0 && downloadUrl == null) {
          try {
            final UploadTask uploadTask = ref.putData(bytes, metadata);

            // Wait for completion
            final TaskSnapshot snapshot = await uploadTask;

            if (snapshot.state == TaskState.success) {
              downloadUrl = await snapshot.ref.getDownloadURL();
              print('Image $i uploaded successfully: $downloadUrl');
            } else {
              throw Exception('Upload state: ${snapshot.state}');
            }
          } catch (e) {
            retries--;
            print('Upload attempt failed. Retries left: $retries. Error: $e');

            if (retries > 0) {
              await Future.delayed(Duration(seconds: 2));
            } else {
              rethrow;
            }
          }
        }

        if (downloadUrl != null) {
          urls.add(downloadUrl);
        }
      }

      return urls;
    } catch (e) {
      print('Upload failed completely: $e');

      // Cleanup uploaded images
      for (String url in urls) {
        try {
          await _storage.refFromURL(url).delete();
          print('Cleaned up: $url');
        } catch (cleanupError) {
          print('Cleanup failed for $url: $cleanupError');
        }
      }

      throw Exception('Upload failed: $e');
    }
  }

  Future<void> deleteProductImages(String productId) async {
    try {
      final ListResult result = await _storage.ref().child('products/$productId').listAll();

      for (Reference ref in result.items) {
        await ref.delete();
      }
    } catch (e) {
      print('Failed to delete images: $e');
    }
  }
}