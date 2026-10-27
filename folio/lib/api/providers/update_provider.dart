import 'dart:io';

import 'package:folio/api/client.dart';
import 'package:folio/models/release.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateProvider extends ChangeNotifier {
  // Private
  late List<Release> _releases;
  Release? _update;
  Release? _preview;

  /// A newer stable release: popup, badge, home tile.
  bool get available => _update != null;

  /// The stable release to offer.
  Release? get update => _update;

  /// A newer, untested pre-release: only a small warning in Settings.
  Release? get preview => _preview;

  // Public
  List<Release> get releases => _releases;

  UpdateProvider({
    List<Release> initialReleases = const [],
    required BuildContext context,
  }) {
    _releases = List.castFrom(initialReleases);
  }

  Future<void> fetch() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final current = Version.fromString(packageInfo.version);

    if (!Platform.isAndroid) return;

    _releases = await FilcAPI.getReleases() ?? [];
    _releases.sort((a, b) => -a.version.compareTo(b.version));
    final (update, preview) = pickUpdates(_releases, current);
    _update = update;
    _preview = preview;

    // ignore: avoid_print
    if (_update != null) print("INFO: New update: ${_update!.version}");
    notifyListeners();
  }

  Future<Map> installedVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    Map<String, String> release = {
      "app_name": appName,
      "package_name": packageName,
      "version": version,
      "build_number": buildNumber,
    };

    return release;
  }
}
