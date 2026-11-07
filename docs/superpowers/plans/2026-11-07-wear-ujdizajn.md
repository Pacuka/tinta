# Tinta Wear OS új dizájn (1. rész) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Wear OS app kap egy gyűrűs kezdőlapot, Tintacsík órarendet, vízszintes lapozást és egységes Tinta-megjelenést, csak a `folio_wear` módosításával.

**Architecture:** A mai állapotot egy tiszta Dart-függvény számolja a leckékből és az időből, a képernyők ezt rajzolják ki. A lapozás kikerül a `main.dart`-ból egy külön `WearShell` widgetbe, ahol a függőleges görgetés már nem vált lapot.

**Tech Stack:** Flutter 3.47, Dart, provider, intl, wear; `flutter_test`; Android Emulator, AVD `tinta-wear`.

**Spec:** `docs/superpowers/specs/2026-11-07-wear-ujdizajn-design.md`

## Global Constraints

- Csak `folio_wear/` változik. A telefonos app, az adatformátum és a natív Kotlin-kód marad.
- Színek csak a `lib/theme/wear_theme.dart` fájlból: kobalt `#2440C8`, tintakék `#7C93FF`, világos tintakék `#A9B8FF`, szünet `#6FD6C0`, elmaradt `#E57373`, helyettesítés `#FFB74D`, háttér fekete.
- Felirat pontosan: „Mára végeztél”, „Ma nincs órád”, „Szünet”, „Első óra”, „Elmarad”, „Utána: tárgy, terem”.
- Terem változatlan névvel, ajtóikonnal, toldalék nélkül.
- Nincs folyamatos animáció, a kezdőlap percenként frissül.
- Commit csak a felhasználó kérésére; a feladatok végén nincs commit lépés.
- Minden feladat után: `cd folio_wear && flutter test`. Whole-file `dart format` tilos.

## Review Focus

1. Elavult adat (a kapott héten nincs mai és későbbi lecke): „Ma nincs órád”, következő óra sor nélkül. Teszt: 1. feladat.
2. A mai összes óra elmaradt: „Ma nincs órád”, de a Tintacsík mutatja az elmaradt órákat. Teszt: 1. és 4. feladat.
3. Hosszú tantárgy- és teremnév kis, 384 px-es kerek kijelzőn: nincs Flutter overflow. Teszt: 3. és 4. feladat.
4. Az app órákig háttérben volt: visszatéréskor azonnal a friss állapot látszik. Teszt: 3. feladat.
5. Korábban bekapcsolt `offline_mode`: az óra mégis kér szinkront. Teszt: 5. feladat.

---

### Task 1: Téma és napi állapot

**Files:**
- Create: `folio_wear/lib/theme/wear_theme.dart`, `folio_wear/lib/models/day_state.dart`
- Test: `folio_wear/test/day_state_test.dart`

**Interfaces:**
- Produces: `class WearColors` statikus konstansokkal: `cobalt, ink, inkLight, breakTeal, cancelled, substitution`.
- Produces: `enum DayPhase { inLesson, inBreak, beforeFirst, doneToday, noLessons }`
- Produces: `class DayState { DayPhase phase; WearLesson? current; WearLesson? next; WearLesson? upcoming; double progress; int minutesLeft; }`
- Produces: `DayState dayStateAt(List<WearLesson> lessons, DateTime now)`

- [ ] **Step 1: Írd meg a teszteket**

Segéd: `lesson(start, end, {status})`, mai napon rögzített időkkel. Tesztnevek és elvárások:

- `during lesson`: 8:00–8:45, 9:00–9:45, most 8:21 → `inLesson`, `current` az első, `next` a második, `minutesLeft == 24`, `progress` ≈ 21/45.
- `exactly at start is in lesson`: most 8:00 → `inLesson`.
- `exactly at end is break`: most 8:45 → `inBreak`, `next` a második, `minutesLeft == 15`, `progress == 0`.
- `partial minute rounds up`: most 8:21:30 → `minutesLeft == 24`.
- `before first`: most 7:10 → `beforeFirst`, `next` az első, `minutesLeft == 50`.
- `done today with known upcoming`: most 15:00, holnap 8:00-s lecke is van → `doneToday`, `upcoming` a holnapi.
- `cancelled lesson is skipped`: a 8:00-s elmaradt, most 8:10 → `beforeFirst`, `next` a 9:00-s.
- `all cancelled today`: minden mai elmaradt → `noLessons`.
- `no lessons today, later lesson known`: → `noLessons`, `upcoming` a későbbi.
- `stale data`: csak múltbeli napok leckéi → `noLessons`, `upcoming == null`.
- `empty list`: → `noLessons`.

- [ ] **Step 2: Futtasd, buknia kell**

Run: `cd folio_wear && flutter test test/day_state_test.dart`
Expected: FAIL, `dayStateAt` nincs definiálva.

- [ ] **Step 3: Valósítsd meg a két fájlt**

A `current` feltétele `start <= now < end`, az elmaradt leckék nem számítanak, a `minutesLeft` felfelé kerekít. Szünetben a `progress` az előző óra végétől a következő kezdetéig tart, `beforeFirst`, `doneToday` és `noLessons` esetén 0. Az `upcoming` a legkorábbi nem elmaradt lecke, ami későbbi napon van, mint a `now`.

- [ ] **Step 4: Futtasd, át kell mennie**

Run: `cd folio_wear && flutter test test/day_state_test.dart`
Expected: minden teszt PASS.

### Task 2: Vízszintes lapozás

**Files:**
- Create: `folio_wear/lib/screens/wear_shell.dart`
- Modify: `folio_wear/lib/main.dart` (a `_WearMainScreen` és állapota kikerül, a `_ConnectionDot` átköltözik; a `ColorScheme` magja `WearColors.cobalt`)
- Test: `folio_wear/test/wear_shell_test.dart`

**Interfaces:**
- Consumes: `WearColors`.
- Produces: `class WearShell extends StatefulWidget` (const konstruktor), a három képernyő `scrollController` paraméterrel, ahogy eddig.

- [ ] **Step 1: Írd meg a teszteket**

`WearDataProvider` mock csatornával, 12 leckével, `Size(454, 454)` képernyőn:

- `vertical drag past the end keeps the page`: többszöri felfelé húzás a lista aljáig és tovább; a Beállítások és Értesítések cím nem jelenik meg.
- `crown past the end keeps the page`: `WearDataProvider.onRotaryInput!(5.0)` 20-szor; ugyanaz.
- `horizontal drag changes page`: balra húzás után látszik az „Értesítések”, újra balra a „Beállítások”.
- `crown works without a scrollable page`: üres listával sem dob hibát és nem vált lapot.

- [ ] **Step 2: Futtasd, buknia kell**

Run: `cd folio_wear && flutter test test/wear_shell_test.dart`
Expected: FAIL, `WearShell` nincs definiálva.

- [ ] **Step 3: Valósítsd meg a `WearShell`-t**

Vízszintes `PageView` alapfizikával, a lapozó pontok és a kapcsolatjelző megmarad. A korona csak az aktív `ScrollController`-t mozgatja `delta * 120.0` lépéssel a határok közé szorítva. Nincs `OverscrollNotification`-figyelés és `_switchPage`. Lapváltáskor `HapticFeedback.mediumImpact()`.

- [ ] **Step 4: Futtasd, át kell mennie**

Run: `cd folio_wear && flutter test`
Expected: minden teszt PASS.

### Task 3: Gyűrűs kezdőlap

**Files:**
- Create: `folio_wear/lib/widgets/progress_ring.dart`, `folio_wear/lib/widgets/home_ring.dart`
- Modify: `folio_wear/lib/screens/home_screen.dart`
- Test: `folio_wear/test/home_ring_test.dart`

**Interfaces:**
- Consumes: `DayState`, `dayStateAt`, `WearColors`.
- Produces: `ProgressRing({required double progress, required Color color})`
- Produces: `HomeRing({required List<WearLesson> lessons, DateTime Function() clock = DateTime.now})`

- [ ] **Step 1: Írd meg a teszteket**

Rögzített `clock` mellett, a spec táblázata szerint:

- `in lesson`: látszik a „3. óra”, a tantárgy, a „24” és az „Utána: Angol, 305”.
- `break`: „Szünet”, a percek, a következő tantárgy.
- `before first`: „Első óra”; 60 percnél távolabb a kezdés időpontja, 60 percen belül a percek.
- `done`: „Mára végeztél”, ismert következő óra nélkül nincs további sor.
- `no lessons`: „Ma nincs órád”.
- `long names fit`: 60 karakteres tantárgy és terem `Size(384, 384)` és `Size(454, 454)` méreten, `tester.takeException()` null.
- `refreshes on resume`: a `clock` továbblép, majd `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed)` és `pump` után az új percszám látszik.
- `refreshes each minute`: `pump(const Duration(minutes: 1))` után az új percszám látszik.

- [ ] **Step 2: Futtasd, buknia kell**

Run: `cd folio_wear && flutter test test/home_ring_test.dart`
Expected: FAIL, `HomeRing` nincs definiálva.

- [ ] **Step 3: Valósítsd meg**

`ProgressRing` `CustomPainter`, 12 óránál indul, kerek végekkel, halvány sávon. `HomeRing` egy `Timer.periodic(1 perc)` és `WidgetsBindingObserver` mellett újraépül, a magassága a kijelző magassága. A `home_screen.dart` mostani fejlécét és `_EmptyState`-jét váltja: a `CustomScrollView` első eleme a gyűrű, akkor is, ha ma nincs lecke.

- [ ] **Step 4: Futtasd, át kell mennie**

Run: `cd folio_wear && flutter test`
Expected: minden teszt PASS.

### Task 4: Tintacsík órarend

**Files:**
- Create: `folio_wear/lib/widgets/ink_timeline.dart`
- Modify: `folio_wear/lib/screens/home_screen.dart` (`_LessonList`, `_LessonTile`, `_StatusBadge` kivezetése)
- Test: `folio_wear/test/ink_timeline_test.dart`

**Interfaces:**
- Consumes: `WearLesson`, `WearColors`, `dayStateAt`.
- Produces: `InkTimeline({required List<WearLesson> lessons, required DateTime now})`, sliver-kompatibilisen beilleszthető a kezdőlap `CustomScrollView`-jába.

- [ ] **Step 1: Írd meg a teszteket**

- `cancelled lesson`: áthúzott név, „Elmarad”.
- `all cancelled still listed`: minden elmaradt lecke látszik.
- `substitute`: a helyettes neve látszik.
- `current lesson`: „még 24 perc” és a terem.
- `homework and exam icons`: a `hasHomework` és `hasExam` ikon látszik.
- `no lessons today`: a kapott hét órái naponként csoportosítva, ahogy a `weekLessonsByDay` adja.
- `long names fit`: 60 karakteres nevek `Size(384, 384)` méreten, kivétel nélkül.

- [ ] **Step 2: Futtasd, buknia kell**

Run: `cd folio_wear && flutter test test/ink_timeline_test.dart`
Expected: FAIL, `InkTimeline` nincs definiálva.

- [ ] **Step 3: Valósítsd meg**

A vonal és a pontok `Stack`/`CustomPaint`, a színek a Global Constraints szerint, az elmúlt óra halvány. A `home_screen.dart`-ból töröld a már nem használt widgeteket és design tokeneket.

- [ ] **Step 4: Futtasd, át kell mennie**

Run: `cd folio_wear && flutter test`
Expected: minden teszt PASS.

### Task 5: Értesítések, beállítások, offline mód

**Files:**
- Modify: `folio_wear/lib/screens/notifications_screen.dart`, `folio_wear/lib/screens/wear_settings_screen.dart`, `folio_wear/lib/screens/pairing_screen.dart`, `folio_wear/lib/screens/connecting_screen.dart`, `folio_wear/lib/providers/wear_data_provider.dart`
- Test: `folio_wear/test/wear_pairing_test.dart`

**Interfaces:**
- Consumes: `WearColors`.
- Törlendő: `WearDataProvider.offlineMode`, `setOfflineMode`, `_offlineMode`.

- [ ] **Step 1: Írd meg a tesztet**

`saved offline mode is ignored`: a mock `getCachedData` `offlineMode: true`-t ad; indítás után a `requestSync` hívás megtörténik.

- [ ] **Step 2: Futtasd, buknia kell**

Run: `cd folio_wear && flutter test test/wear_pairing_test.dart`
Expected: FAIL, nincs `requestSync` hívás.

- [ ] **Step 3: Valósítsd meg**

Vedd ki az offline módot a providerből és a beállításokból. Értesítések: nagy, kerek jegy, a mockup szerinti sorok, a mostani rövid időpont marad. Beállítások: „Szinkronizálás most”, telefon állapota, „Leválasztás” a mostani megerősítéssel. A párosító és a csatlakozó képernyő a `WearColors` színeit kapja, a működése nem változik.

- [ ] **Step 4: Futtasd, át kell mennie**

Run: `cd folio_wear && flutter test && flutter analyze lib test`
Expected: minden teszt PASS, az `analyze` legfeljebb a már meglévő `unnecessary_cast` figyelmeztetést írja.

### Task 6: Ellenőrzés a virtuális órán

**Files:**
- Modify: `tinta-platformok/wear-os/tinta-wear-1.6.0.apk`, `tinta-platformok/wear-os/SHA256SUMS`

- [ ] **Step 1: Telepítsd az x64 buildet**

Run: `cd folio_wear && flutter build apk --release --target-platform android-x64 && adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk`
Expected: `Success`.

- [ ] **Step 2: Nézd végig kitalált adatokkal**

A `shared_prefs/folio_wear.xml` feltöltésével állítsd be sorban: óra alatt, szünet, első óra előtt, mára végeztél, ma nincs óra, hosszú nevek. Mindegyikről készíts képet. Ellenőrizd a függőleges görgetést a lista végén, a balra húzást és a kezdőlapon a jobbra húzást.
Expected: nincs levágott szöveg, a görgetés nem vált lapot. Ha a jobbra húzásos kilépés nem megbízható, jegyezd fel a felhasználónak.

- [ ] **Step 3: Nézd meg kis kijelzőn**

Hozz létre 384×384-es kerek AVD-t (`wearos_small_round`), és ismételd meg a hosszú neves esetet.
Expected: nincs levágott elem.

- [ ] **Step 4: Építsd meg a végleges APK-t**

Run: `cd folio_wear && flutter build apk --release --target-platform android-arm,android-arm64`, másold a `tinta-platformok/wear-os/tinta-wear-1.6.0.apk` helyére, majd frissítsd a `SHA256SUMS` fájlt.
Expected: `apksigner` szerint a tanúsítvány SHA-256 kezdete `aa48661e`, a csomagnév `hu.pacuka.tinta`.

- [ ] **Step 5: Hagyd nyitva a felhasználónak**

Indítsd újra az x64 buildet a látható emulátor-ablakban, az „óra alatt” adatokkal.
Expected: a felhasználó a saját képernyőjén kipróbálhatja.
