import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime mic/camera permissions for native mobile calls (not Web).
class CallMediaPermissions {
  const CallMediaPermissions._();

  static bool get _needsRuntimePermissions {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<bool> ensureForCall({required bool video}) async {
    if (!_needsRuntimePermissions) return true;

    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (kDebugMode) {
          debugPrint('[CallMediaPermissions] microphone denied: $mic');
        }
        return false;
      }

      if (!video) return true;

      final camera = await Permission.camera.request();
      if (!camera.isGranted) {
        if (kDebugMode) {
          debugPrint('[CallMediaPermissions] camera denied: $camera');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CallMediaPermissions] request failed: $e');
      }
      if (e is MissingPluginException) return true;
      return false;
    }
  }
}
