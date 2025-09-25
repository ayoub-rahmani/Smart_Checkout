import 'dart:convert';
import 'package:crypto/crypto.dart';

class LinkGeneratorService {
  static const String baseUrl = 'https://yourapp.com';

  // Generate checkout link for a product
  static String generateProductLink(String productId, {Map<String, String>? variants}) {
    String link = '$baseUrl/buy/$productId';

    if (variants != null && variants.isNotEmpty) {
      final queryParams = variants.entries
          .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
          .join('&');
      link += '?$queryParams';
    }

    return link;
  }

  // Generate tracking link for an order
  static String generateTrackingLink(String orderCode) {
    return '$baseUrl/track/$orderCode';
  }

  // Generate shareable product link with metadata
  static String generateShareableLink(
      String productId,
      String productTitle,
      double price, {
        Map<String, String>? variants,
      }) {
    final baseLink = generateProductLink(productId, variants: variants);

    // Add metadata for social sharing
    final metadata = {
      'title': productTitle,
      'price': price.toString(),
      'currency': 'TND',
    };

    return baseLink; // In a real app, you might add UTM parameters or other tracking
  }

  // Parse product link to extract product ID and variants
  static Map<String, dynamic> parseProductLink(String link) {
    final uri = Uri.parse(link);
    final pathSegments = uri.pathSegments;

    if (pathSegments.length >= 2 && pathSegments[0] == 'buy') {
      return {
        'productId': pathSegments[1],
        'variants': uri.queryParameters,
      };
    }

    throw ArgumentError('Invalid product link format');
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
}
