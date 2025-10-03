class FirebaseConstants {
  // Collection names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';

  // Storage paths
  static const String productImagesPath = 'product_images';
  static const String userProfilesPath = 'user_profiles';

  // Cloud Functions
  static const String generateProductLinkFunction = 'generateProductLink';
  static const String processOrderFunction = 'processOrder';
  static const String sendNotificationFunction = 'sendNotification';

  // Order statuses
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPacked = 'packed';
  static const String orderStatusShipped = 'shipped';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Payment methods
  static const String paymentCOD = 'cod';
  static const String paymentD17 = 'd17';
  static const String paymentFlouci = 'flouci';

  // Firebase Hosting Domains (Your actual domains)
  static const String webAppDomain = 'checkout-e765c.web.app';
  static const String firebaseAppDomain = 'checkout-e765c.firebaseapp.com';

  // Base URLs for different environments
  static const String baseUrl = 'https://checkout-e765c.web.app';
  static const String backupBaseUrl = 'https://checkout-e765c.firebaseapp.com';

  // Dynamic Links domain (if you set up Firebase Dynamic Links)
  static const String dynamicLinksDomain = 'checkout-e765c.page.link';

  // API endpoints
  static const String checkoutEndpoint = '/checkout';
  static const String trackOrderEndpoint = '/track';
  static const String productEndpoint = '/product';

  // Full URLs for common actions
  static String getCheckoutUrl(String productId, {Map<String, String>? variants}) {
    String url = '$baseUrl/checkout?product=$productId';

    if (variants != null && variants.isNotEmpty) {
      variants.forEach((key, value) {
        url += '&${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}';
      });
    }

    return url;
  }

  static String getTrackingUrl(String orderCode) {
    return '$baseUrl/track?order=$orderCode';
  }

  static String getProductUrl(String productId) {
    return '$baseUrl/product?id=$productId';
  }

  // Web popup dimensions
  static const Map<String, dynamic> webPopupDimensions = {
    'width': 400,
    'height': 700,
    'minWidth': 350,
    'minHeight': 600,
  };
}