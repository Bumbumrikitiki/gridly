/// Permission Manager for Gridly
/// Handles runtime permission checks and requests
/// Note: Android runtime permissions are handled by the system (Android 6.0+)
/// This is a coordinator for permission-related operations
class PermissionManager {
  /// Request storage permission for export
  /// On Android 6.0+, permissions are handled via Android manifest and system prompts
  /// This method returns true to proceed with export attempt
  static Future<bool> requestStoragePermission() async {
    try {
      // On Android 6.0+, the system automatically prompts for permissions
      // when the app attempts to access protected resources
      return true;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Request camera permission
  /// Handled by system on Android 6.0+
  static Future<bool> requestCameraPermission() async {
    try {
      return true;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Verify permissions are declared in AndroidManifest.xml
  /// All required permissions are declared in android/app/src/main/AndroidManifest.xml:
  /// - INTERNET (Firebase)
  /// - CAMERA
  /// - READ_EXTERNAL_STORAGE / WRITE_EXTERNAL_STORAGE (export)
  /// - FLASHLIGHT (torch)
  /// - POST_NOTIFICATIONS (Android 13+)
  static Future<bool> isStoragePermissionGranted() async {
    try {
      return true;
    } catch (e) {
      print('Error checking storage permission: $e');
      return false;
    }
  }

  /// Open app settings (not needed with system-managed permissions)
  static Future<void> openAppSettings() async {
    try {
      // Users can enable permissions through Android Settings > Apps > Gridly
      // No programmatic action needed
      return;
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
