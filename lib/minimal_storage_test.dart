import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MinimalStorageTest {
  static Future<void> testConnection() async {
    try {
      print('=== STORAGE CONNECTION TEST ===');

      // 1. Check auth
      final user = FirebaseAuth.instance.currentUser;
      print('User: ${user?.uid}');
      print('Email: ${user?.email}');

      if (user == null) {
        print('❌ No authenticated user');
        return;
      }

      // 2. Test storage reference
      final storage = FirebaseStorage.instance;
      final ref = storage.ref('test/connection.txt');
      print('Storage ref created: ${ref.fullPath}');

      // 3. Test simple upload
      final data = 'test-${DateTime.now().millisecondsSinceEpoch}';
      print('Attempting upload...');

      await ref.putString(data).timeout(Duration(seconds: 30));
      print('✅ Upload successful');

      // 4. Test download
      final downloadUrl = await ref.getDownloadURL();
      print('✅ Download URL: $downloadUrl');

      // 5. Clean up
      await ref.delete();
      print('✅ Cleanup successful');

    } catch (e) {
      print('❌ Storage test failed: $e');
      print('Error type: ${e.runtimeType}');

      if (e.toString().contains('permission-denied')) {
        print('🔧 Fix: Update Firebase Storage rules');
      } else if (e.toString().contains('network')) {
        print('🔧 Fix: Check internet connection');
      } else if (e.toString().contains('not-found')) {
        print('🔧 Fix: Check Firebase project configuration');
      }
    }
  }

  static Future<String?> uploadSingleImage(File imageFile) async {
    try {
      print('=== SINGLE IMAGE UPLOAD ===');

      // Basic validation
      if (!await imageFile.exists()) {
        throw Exception('File does not exist');
      }

      final size = await imageFile.length();
      print('File size: ${size} bytes');

      if (size > 5 * 1024 * 1024) { // 5MB limit
        throw Exception('File too large (max 5MB)');
      }

      // Simple upload path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance.ref('uploads/$timestamp.jpg');

      print('Uploading to: ${ref.fullPath}');

      // Upload with basic metadata
      final task = ref.putFile(imageFile, SettableMetadata(
        contentType: 'image/jpeg',
      ));

      // Wait for completion
      final snapshot = await task.timeout(Duration(minutes: 2));

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        print('✅ Upload successful: $url');
        return url;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

    } catch (e) {
      print('❌ Image upload failed: $e');
      return null;
    }
  }
}