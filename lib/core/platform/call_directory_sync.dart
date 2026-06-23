import 'dart:io';
import 'package:flutter/services.dart';

// Pushes the current blocked-number list to the iOS CXCallDirectoryExtension
// via the App Group UserDefaults suite and requests a directory reload.
// No-ops on Android.
class CallDirectorySync {
  static const _channel = MethodChannel('com.sentri.sentri/calldirectory');

  static Future<void> sync({
    required List<String> blockedNumbers,
    List<Map<String, String>> callerIds = const [],
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('syncBlocklist', {
        'blocked':   blockedNumbers,
        'callerIds': callerIds,
      });
    } on PlatformException {
      // Extension reload errors are non-fatal — the directory will sync on
      // the next successful reload (e.g., next time the user opens Settings > Phone).
    }
  }
}
