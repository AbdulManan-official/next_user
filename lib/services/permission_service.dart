/// Centralized device permission handler (Camera, Location, Microphone, Photos).
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  Future<bool> requestCameraPermission() async {
    return true;
  }

  Future<bool> requestLocationPermission() async {
    return true;
  }

  Future<bool> requestMicrophonePermission() async {
    return true;
  }
}
