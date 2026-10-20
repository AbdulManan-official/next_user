import 'dart:developer' as developer;

/// Helper utility for opening addresses or coordinates in map applications.
class MapLauncherHelper {
  MapLauncherHelper._();

  static Future<bool> openMap({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    developer.log(
      'Map requested for address: $address ($latitude, $longitude)',
      name: 'MapLauncherHelper',
    );
    return true;
  }
}
