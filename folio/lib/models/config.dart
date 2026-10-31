import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Config {
  String _userAgent;
  Map? json;
  static const String _version =
      String.fromEnvironment("APPVER", defaultValue: "3.0.4");

  Config({required String userAgent, this.json}) : _userAgent = userAgent;

  factory Config.fromJson(Map json) {
    return Config(
      userAgent: json["user_agent"] ?? "hu.ekreta.student/\$0/\$1/\$2",
      json: json,
    );
  }

  /// Official e-KRÉTA app version used in the official-style User-Agent.
  /// Separate from Tinta's own version (pubspec). Set at build time with
  /// --dart-define=KRETA_CLIENT_VERSION=x.y.z; the default is not updated
  /// automatically (see ugyved/tinta-firebase-es-verzio-allapot-*.md).
  static const kretaAppVersion =
      String.fromEnvironment("KRETA_CLIENT_VERSION", defaultValue: "5.18.0");

  static String? _deviceUserAgent;

  /// Same format as the official app (UserAgentStringProvider):
  /// hu.ekreta.student/<app version>/<Build.MODEL>/<Android release>/<SDK>
  static Future<void> initDeviceUserAgent() async {
    // Default (temporary): the official app's User-Agent, for compatibility
    // until KRÉTA answers about Tinta's own access (see ugyved/).
    // Tinta's own identity: --dart-define=TINTA_OWN_UA=true (tested working).
    if (const bool.fromEnvironment("TINTA_OWN_UA")) {
      final os = Platform.isAndroid
          ? "Android ${(await DeviceInfoPlugin().androidInfo).version.release}"
          : Platform.operatingSystem;
      final version = (await PackageInfo.fromPlatform()).version;
      _deviceUserAgent = "Tinta/$version ($os; +https://tinta.pacuka.hu)";
      // ignore: avoid_print
      print("INFO KRÉTA user agent: $_deviceUserAgent");
      return;
    }
    if (Platform.isIOS) {
      // The official iOS app is native; its requests look like this.
      _deviceUserAgent = "eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0";
      return;
    }
    if (!Platform.isAndroid) return;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      _deviceUserAgent = "hu.ekreta.student/$kretaAppVersion/${info.model}/"
          "${info.version.release}/${info.version.sdkInt}";
      // ignore: avoid_print
      print("INFO KRÉTA user agent: $_deviceUserAgent");
    } catch (_) {}
  }

  String get userAgent =>
      _deviceUserAgent ??
      _userAgent
          .replaceAll("\$0", _version)
          .replaceAll("\$1", platform)
          .replaceAll("\$2", "0");

  static String get platform {
    if (Platform.isAndroid) {
      return "Android";
    } else if (Platform.isIOS) {
      return "iOS";
    } else if (Platform.isLinux) {
      return "Linux";
    } else if (Platform.isWindows) {
      return "Windows";
    } else if (Platform.isMacOS) {
      return "MacOS";
    } else {
      return "Unknown";
    }
  }

  @override
  String toString() => json.toString();
}
