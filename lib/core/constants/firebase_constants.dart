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
}
