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

  static Future<bool> ensureMicrophone() async {
    if (!_needsRuntimePermissions) return true;
    return _request(Permission.microphone, label: 'microphone');
  }

  static Future<bool> ensureCamera() async {
    if (!_needsRuntimePermissions) return true;
    return _request(Permission.camera, label: 'camera');
  }

  static Future<bool> ensureForCall({required bool video}) async {
    if (!await ensureMicrophone()) return false;
    if (video && !await ensureCamera()) return false;
    return true;
  }

  static Future<bool> _request(Permission permission, {required String label}) async {
    try {
      final status = await permission.request();
      if (!status.isGranted) {
        if (kDebugMode) {
          debugPrint('[CallMediaPermissions] $label denied: $status');
        }
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CallMediaPermissions] $label request failed: $e');
      }
      if (e is MissingPluginException) return true;
      return false;
    }
  }
}
