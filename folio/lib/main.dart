/*
    Folio, the unofficial client for e-Kréta
    Copyright (C) 2025  Folio team

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program, if not, see <https://www.gnu.org/licenses/>.
*/

import 'package:folio/helpers/fake_kreta.dart';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/database/init.dart';
import 'package:folio/models/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:folio/models/config.dart';
import 'package:folio/helpers/update_notifier.dart';
import 'package:flutter/material.dart';
import 'package:folio/app.dart';
import 'package:flutter/services.dart';
import 'package:folio/utils/service_locator.dart';
import 'package:folio_mobile_ui/screens/error_screen.dart';
import 'package:folio_mobile_ui/screens/error_report_screen.dart';

import 'helpers/live_activity_helper.dart';

// days without touching grass: 5,843 (16 yrs)

void main() async {
  // Name day data attribution (CC BY-SA 4.0), shown on the licenses page.
  LicenseRegistry.addLicense(() => Stream.value(const LicenseEntryWithLineBreaks(
      ['Névnaptár (assets/data/namedays.json)'],
      'Forrás: Wikipédia, „Magyar névnapok listája betűrendben” '
      '(https://hu.wikipedia.org/wiki/Magyar_névnapok_listája_betűrendben), '
      'a Wikipédia szerzői. Licenc: CC BY-SA 4.0 '
      '(https://creativecommons.org/licenses/by-sa/4.0/). '
      'Fő névnapok: sbolch/name-days (https://github.com/sbolch/name-days), '
      'MIT licenc.')));
  try {
    WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
    // ignore: deprecated_member_use
    binding.renderView.automaticSystemUiAdjustment = false;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setupLocator();
    await Config.initDeviceUserAgent();
    await FakeKreta.load();

    // Tinta: Firebase (the official KRÉTA app's push project) removed for
    // good; notifications are local (UpdateNotifier).

    Startup startup = Startup();
    await startup.start();

    ErrorWidget.builder = errorBuilder;

    BackgroundFetch.registerHeadlessTask(backgroundHeadlessTask);

    // pre-cache required icons
    const todaySvg = SvgAssetLoader('assets/svg/menu_icons/today_selected.svg');
    const gradesSvg =
        SvgAssetLoader('assets/svg/menu_icons/grades_selected.svg');
    const timetableSvg =
        SvgAssetLoader('assets/svg/menu_icons/timetable_selected.svg');
    const notesSvg = SvgAssetLoader('assets/svg/menu_icons/notes_selected.svg');
    const absencesSvg =
        SvgAssetLoader('assets/svg/menu_icons/absences_selected.svg');

    svg.cache
        .putIfAbsent(todaySvg.cacheKey(null), () => todaySvg.loadBytes(null));
    svg.cache
        .putIfAbsent(gradesSvg.cacheKey(null), () => gradesSvg.loadBytes(null));
    svg.cache.putIfAbsent(
        timetableSvg.cacheKey(null), () => timetableSvg.loadBytes(null));
    svg.cache
        .putIfAbsent(notesSvg.cacheKey(null), () => notesSvg.loadBytes(null));
    svg.cache.putIfAbsent(
        absencesSvg.cacheKey(null), () => absencesSvg.loadBytes(null));

    runApp(App(
      database: startup.database,
      settings: startup.settings,
      user: startup.user,
    ));
  } catch (error, stackTrace) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Initialization Error:\n\n$error\n\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class Startup {
  late SettingsProvider settings;
  late UserProvider user;
  late DatabaseProvider database;

  Future<void> start() async {
    database = DatabaseProvider();
    var db = await initDB(database);
    await db.close();
    await database.init();
    settings = await database.query.getSettings(database);
    user = await database.query.getUsers(settings);

    if (!kIsWeb) {
      initAdditionalBackgroundFetch();
    }
  }
}

bool errorShown = false;
String lastException = '';

Widget errorBuilder(FlutterErrorDetails details) {
  return Builder(builder: (context) {
    if (Navigator.of(context).canPop()) Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!errorShown && details.exceptionAsString() != lastException) {
        errorShown = true;
        lastException = details.exceptionAsString();
        Navigator.of(context, rootNavigator: true)
            .push(MaterialPageRoute(builder: (context) {
          if (kReleaseMode) {
            return ErrorReportScreen(details);
          } else {
            return ErrorScreen(details);
          }
        })).then((_) => errorShown = false);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Text(
            details.exceptionAsString() +
                '\n\n' +
                (details.stack?.toString() ?? ''),
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ),
    );
  });
}

Future<void> initAdditionalBackgroundFetch() async {
  int status = await BackgroundFetch.configure(
      BackgroundFetchConfig(
          minimumFetchInterval: 15,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY,
          startOnBoot: true), (String taskId) async {
    if (kDebugMode) {
      print("[BackgroundFetch] Event received $taskId");
    }
    LiveActivityHelper liveActivityHelper = LiveActivityHelper();
    liveActivityHelper.backgroundJob();
    if (taskId != "com.transistorsoft.folioliveactivity") {
      await UpdateNotifier.onBackgroundEvent();
    }
    BackgroundFetch.finish(taskId);
  }, (String taskId) async {
    if (kDebugMode) {
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
    }
    BackgroundFetch.finish(taskId);
  });
  if (kDebugMode) {
    print('[BackgroundFetch] configure success: $status');
  }
  BackgroundFetch.scheduleTask(TaskConfig(
      taskId: "com.transistorsoft.folioliveactivity",
      delay: 300000, // 5 minutes
      periodic: true,
      forceAlarmManager: true,
      stopOnTerminate: false,
      enableHeadless: true));
}

@pragma('vm:entry-point')
void backgroundHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    if (kDebugMode) {
      print("[BackgroundFetch] Headless task timed-out: $taskId");
    }
    BackgroundFetch.finish(taskId);
    return;
  }
  if (kDebugMode) {
    print('[BackgroundFetch] Headless event received.');
  }
  if (taskId == "com.transistorsoft.folioliveactivity") {
    if (Platform.isIOS) LiveActivityHelper().backgroundJob();
  } else {
    // App process was dead: check KRÉTA for new data and notify.
    await UpdateNotifier.runHeadless();
  }
  BackgroundFetch.finish(task.taskId);
}
