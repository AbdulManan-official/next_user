/// Centralized API URLs and Endpoints configuration.
class AppUrls {
  AppUrls._();

  // Base URL
  static const String baseUrl = 'https://api.example.com/api/v1';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String resendOtp = '$baseUrl/auth/resend-otp';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refresh-token';

  // User Profile Endpoints
  static const String profile = '$baseUrl/user/profile';
  static const String updateProfile = '$baseUrl/user/profile/update';

  // Services / Booking Endpoints
  static const String servicesList = '$baseUrl/services';
  static const String createBooking = '$baseUrl/bookings/create';
  static const String bookingHistory = '$baseUrl/bookings/history';
  static const String bookingDetails = '$baseUrl/bookings/details';

  // Notifications
  static const String notifications = '$baseUrl/notifications';
}
