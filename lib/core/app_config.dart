import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for backend connection settings.
///
/// The ProInterview backend is expected to run locally (see project README /
/// plan docs for setup). Android emulators can't reach the host machine via
/// `localhost` - they need the special alias `10.0.2.2`. A physical device on
/// the same network would need the host machine's LAN IP instead; that case
/// isn't handled here and would need `apiBaseUrl` to be made configurable.
class AppConfig {
  AppConfig._();

  static const int _backendPort = 5001;

  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:$_backendPort/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_backendPort/api';
    return 'http://localhost:$_backendPort/api';
  }

  static const Duration requestTimeout = Duration(seconds: 15);
}
