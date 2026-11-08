# Óra-app frissítése a telefonról — megvalósítási terv

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A telefonos Tinta letölti a `tinta-wear-*.apk`-t a GitHub-kiadásból, átküldi az órára, az óra pedig a rendszer jóváhagyó ablakával feltelepíti.

**Architecture:** Az óra a meglévő Wearable üzenetcsatornán jelenti a verzióját. A telefon Dartban dönti el, van-e újabb óra-APK, letölti, majd a Kotlin `WearSyncManager` `ChannelClient.sendFile`-lal átküldi. Az óra `WearDataListenerService.onChannelOpened` fogadja, és amikor a Tinta előtérben van az órán, `PackageInstaller` munkamenettel telepíti; az eredményt üzenetben visszaküldi.

**Tech Stack:** Flutter/Dart (folio, folio_mobile_ui), Kotlin (phone `folio/android`, watch `folio_wear/android`), Google Play services Wearable (MessageClient, ChannelClient), Android PackageInstaller.

**Spec:** `docs/superpowers/specs/2026-11-08-ora-frissites-design.md`

## Global Constraints

- Az óra-app nem kap `INTERNET` engedélyt.
- Az óra csak akkor fogad frissítést, ha `is_paired` igaz (prefs `folio_wear`).
- Óra nélküli telefonon (`WearSyncManager.wearUnavailable`) nincs új sor és nincs új napló.
- Üzenet-útvonalak: `/folio/version-request` (telefon→óra), `/folio/watch-version` (óra→telefon, JSON `{"name":"1.6.1","code":10}`), csatorna `/folio/wear-update` (telefon→óra), `/folio/wear-update-result` (óra→telefon, `ok` vagy `error:<szöveg>`).
- Letöltött fájl: ideiglenes mappa, `folio_update_wear-<verzió>.apk` (a `cleanupOldUpdateApks` regexe takarítja).

## Review Focus

- Az órán a Tinta nincs előtérben, amikor a fájl megérkezik → a fájl megmarad, a telepítő a következő megnyitáskor jön fel; a telefon „Nyisd meg a Tintát az órán” üzenetet mutat.
- A felhasználó a rendszerablakban a Mégse gombot nyomja → a telefon hibát mutat, nem ragad „telepítés” állapotban (időkorlát: 5 perc).
- Az óra-verzió ugyanaz vagy újabb, mint a legfrissebb kiadás → nincs Frissítés gomb.
- A kiadásban nincs `tinta-wear` fájl → nincs Frissítés gomb.
- Megszakad a kapcsolat az átküldés közben → hibaállapot, újra lehet próbálni.

---

### Task 1: Dart — melyik kiadás kell az órára

**Files:**
- Modify: `folio/lib/models/release.dart`
- Test: `folio/test/wear_update_test.dart`

**Interfaces:**
- Produces: `ReleaseDownload? pickWearApk(List<ReleaseDownload> downloads)`; `Release? pickWearUpdate(List<Release> releases, String? watchVersion)` — a legújabb nem-előzetes kiadás, amelyben van óra-APK, és újabb a `watchVersion`-nél; `null`, ha `watchVersion` null/üres.

- [ ] Teszt: `pickWearApk` a `tinta-wear-1.6.2.apk`-t adja a telefonos APK-k és az .ipa mellől; nincs ilyen → null.
- [ ] Teszt: `pickWearUpdate([1.6.2 wear-rel, 1.6.3 wear nélkül, 1.7.0 prerelease], "1.6.1")` → 1.6.2; `"1.6.2"` → null; `null` → null.
- [ ] Futtatás: bukik. Megvalósítás. Futtatás: átmegy. Commit.

### Task 2: Óra — verzió jelentése és frissítés fogadása, telepítése

**Files:**
- Create: `folio_wear/android/app/src/main/kotlin/app/zan1456/folio/wear/WearUpdateInstaller.kt`
- Modify: `WearDataListenerService.kt`, `MainActivity.kt` (óra), `AndroidManifest.xml` (óra)

**Interfaces:**
- Produces: `object WearUpdateInstaller { fun pendingFile(ctx): File; fun installIfPending(activity: Activity); fun sendResult(ctx, result: String) }`, `InstallResultReceiver` (BroadcastReceiver).

- [ ] Manifest: `REQUEST_INSTALL_PACKAGES`, a listener intent-filterbe `CHANNEL_EVENT`, receiver regisztrálva (nem exportált).
- [ ] `/folio/version-request` → válasz `/folio/watch-version` a küldő node-nak.
- [ ] `onChannelOpened` (`/folio/wear-update`, csak ha `is_paired`) → `receiveFile` a `pendingFile`-ba; `onInputClosed` sikeres → ha `MainActivity` előtérben van, `installIfPending`.
- [ ] `MainActivity.onResume` → `installIfPending`.
- [ ] `installIfPending`: PackageInstaller session, commit a receiver PendingIntent-jével; `STATUS_PENDING_USER_ACTION` → `EXTRA_INTENT` indítása; siker/hiba → `sendResult`, fájl törlése.
- [ ] Ellenőrzés: `flutter build apk` a folio_wear-ben lefordul.

### Task 3: Telefon natív — verzió kérése, fájl küldése, eredmény továbbítása

**Files:**
- Modify: `folio/android/.../wear/WearSyncManager.kt`, `PhoneWearListenerService.kt`, `app/folio/legacy/MainActivity.kt`

**Interfaces:**
- Produces (MethodChannel `app.zan1456.folio/wear_sync`): `requestWatchVersion()`, `sendWearUpdate({path})` → `true` ha a fájl átment; natív→Dart: `onWatchVersion(String json)`, `onWearUpdateResult(String result)`.

- [ ] `WearSyncManager.requestWatchVersion()`, `sendUpdateFile(path, done: (Boolean, String?) -> Unit)` (ChannelClient openChannel → sendFile → `onOutputClosed`).
- [ ] `PhoneWearListenerService`: `/folio/watch-version`, `/folio/wear-update-result` → `MainActivity.wearChannel`.
- [ ] Ellenőrzés: lefordul.

### Task 4: Telefon Dart — állapot és Beállítások-sor

**Files:**
- Modify: `folio/lib/api/providers/wear_provider.dart`, `folio_mobile_ui/lib/screens/settings/settings_screen.dart`
- Test: `folio/test/wear_update_test.dart`

**Interfaces:**
- Consumes: Task 1, Task 3.
- Produces: `WearProvider.watchVersion`, `WearUpdateState { idle, downloading, sending, waitingForWatch, done, failed }`, `updateState`, `updateProgress`, `updateError`, `Future<void> updateWatch(Release r)`.

- [ ] Teszt: `parseWatchVersion('{"name":"1.6.1","code":10}') == "1.6.1"`, hibás JSON → null.
- [ ] `updateWatch`: letöltés (progress), `sendWearUpdate`, `waitingForWatch`, 5 perces időkorlát → `failed`.
- [ ] Beállítások: „Óra-app” sor a verzióval; ha `pickWearUpdate` ad kiadást: „Frissítés (x.y.z)” gomb és állapotszöveg.
- [ ] Teljes teszt, commit.

### Task 5: Végpontig emulátoron

- [ ] Telefon- és óraemulátor párosítva (vagy Redmi + óraemulátor), régi óra-verzió fent, újabb verziószámú óra-APK mint „kiadás”, végigkattintva. Képernyőképek. Napló a wear-os.md-be.
