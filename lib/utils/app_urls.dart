/// Centralized API URLs and Endpoints configuration for the Next User app.
/// Matches the live Laravel backend host and structure used across NextGen & NextUser.
class AppUrls {
  AppUrls._();

  // =========================================================================
  // BASE URL CONFIGURATION
  // Live Base Domain: https://daydoenterprises.us/api
  // =========================================================================
  static const String baseHost = 'https://daydoenterprises.us';
  static String get baseUrl => '$baseHost/api';

  // =========================================================================
  // CLIENT AUTHENTICATION & SYNC ENDPOINTS
  // =========================================================================
  /// POST /api/auth/sync — Finds or creates user record in backend DB after Firebase login
  static String get authSync => '$baseUrl/auth/sync';

  /// GET /api/user/profile & PUT /api/user/profile
  static String get userProfile => '$baseUrl/user/profile';

  /// PUT /api/users/me & DELETE /api/users/me
  static String get usersMe => '$baseUrl/users/me';

  /// POST /api/user/fcm-token
  static String get fcmToken => '$baseUrl/user/fcm-token';

  /// POST /api/logout
  static String get logout => '$baseUrl/logout';

  // =========================================================================
  // CLIENT SERVICES & BOOKINGS
  // =========================================================================
  static String get servicesList => '$baseUrl/services';
  static String get createBooking => '$baseUrl/bookings/create';
  static String get bookingHistory => '$baseUrl/bookings/history';
  static String bookingDetails(String id) => '$baseUrl/bookings/$id';

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================
  static String get notifications => '$baseUrl/notifications';
}
