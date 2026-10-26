import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

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

  /// Version of the official e-KRÉTA Android app we present ourselves as.
  /// Keep in sync with the Play Store version.
  static const kretaAppVersion = "5.17.0";

  static String? _deviceUserAgent;

  /// Same format as the official app (UserAgentStringProvider):
  /// hu.ekreta.student/<app version>/<Build.MODEL>/<Android release>/<SDK>
  static Future<void> initDeviceUserAgent() async {
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
