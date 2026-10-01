/// Helper utility for opening addresses or coordinates in map applications.
class MapLauncherHelper {
  MapLauncherHelper._();

  static Future<void> openMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    // Construct maps URL and launch with url_launcher when configured
    // Example: https://www.google.com/maps/search/?api=1&query=$latitude,$longitude
  }
}
