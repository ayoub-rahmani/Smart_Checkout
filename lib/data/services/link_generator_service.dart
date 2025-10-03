// data/services/link_generator_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/constants/firebase_constants.dart';
class LinkGeneratorService {

  // Generate product checkout link using your actual Firebase domain
  static String generateProductLink(String productId, {Map<String, String>? variants}) {
    String link = '${FirebaseConstants.baseUrl}/checkout?product=$productId';

    if (variants != null && variants.isNotEmpty) {
      variants.forEach((key, value) {
        link += '&${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}';
      });
    }

    return link;
  }

  // Generate tracking link
  static String generateTrackingLink(String orderCode) {
    return '${FirebaseConstants.baseUrl}/track?order=$orderCode';
  }

  // Generate shareable product link with metadata
  static Future<void> generateShareableLink({
    required String productId,
    required String productTitle,
    required double price,
    Map<String, String>? variants,
  }) async {
    final productLink = generateProductLink(productId, variants: variants);

    final shareText = '''
🛍️ **$productTitle**
💰 Price: ${price.toStringAsFixed(3)} TND
${variants != null ? '🎯 Options: ${variants.entries.map((e) => '${e.key}: ${e.value}').join(', ')}' : ''}

🚀 **Instant Checkout:**
$productLink

💳 Secure Payment • 🚚 Fast Delivery • 📦 Easy Returns
''';

  }

  // Parse product link to extract product ID and variants
  static Map<String, dynamic> parseProductLink(String link) {
    final uri = Uri.parse(link);
    final productId = uri.queryParameters['product'];
    final variants = <String, String>{};

    uri.queryParameters.forEach((key, value) {
      if (key != 'product') {
        variants[key] = value;
      }
    });

    if (productId == null) {
      throw ArgumentError('Invalid product link: missing product ID');
    }

    return {
      'productId': productId,
      'variants': variants,
    };
  }

  // Generate QR code data for a product link
  static String generateQRCodeData(String productId, {Map<String, String>? variants}) {
    return generateProductLink(productId, variants: variants);
  }

  // Create a short link hash (for analytics or short URLs)
  static String generateShortHash(String productId) {
    final bytes = utf8.encode(productId + DateTime.now().millisecondsSinceEpoch.toString());
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  // Generate iframe embed code for websites
  static String generateEmbedCode(String productId, {Map<String, String>? variants}) {
    final productLink = generateProductLink(productId, variants: variants);
    return '''
<iframe 
  src="$productLink" 
  width="${FirebaseConstants.webPopupDimensions['width']}" 
  height="${FirebaseConstants.webPopupDimensions['height']}" 
  style="border: none; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);"
  allow="payment"
>
</iframe>
''';
  }
}