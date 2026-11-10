# Üveg téma: igazi Liquid Glass — munkaterv

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Az „Üveg” témában a kezelőelemek (menüsáv, szűrők, lapok, ablakok, kapcsolók) igazi Liquid Glass kinézetet kapnak. iPhone-on fix helyen az Apple saját elemei jönnek, máshol a `liquid_glass_widgets` csomag.

**Architecture:** Minden üveges ág az `isGlassTheme(context)` mögött van (`folio/lib/theme/glass.dart`), így a többi téma érintetlen. A hangolt értékek egy helyen vannak (`folio/lib/theme/glass_settings.dart`). Minden elemtípusnak egy „Tinta…” csomagolója van, ez dönti el, hogy natív, csomagos vagy régi elem kell. A hívási helyek csak a csomagolót hívják.

**Tech Stack:** Flutter 3.47, `liquid_glass_widgets` ^1.17.1, `cupertino_native_better` 1.8.1 (már benne van), Swift (iOS AppDelegate), Impeller/Vulkan Androidon.

**Spec:** `docs/superpowers/specs/2026-11-10-uveg-liquid-glass-design.md`

## Global Constraints

- Más témák (Kobalt, Fekete-sárga, Petrol, Material You) kinézete és viselkedése nem változhat. Minden új ág `isGlassTheme(context)` mögött van.
- Tartalomkártyák (jegyek, órák, üzenetek, házik) nem lesznek üvegek.
- `GlassQuality.standard` minden csomagos elemen, kivéve, ha egy lépés mást mond (a prémiumon szivárványos szegély jött elő a lencsén).
- Menüsáv-értékek (a próbából, betű szerint): `settings` = `LiquidGlassSettings.ios27Dark` vagy `ios27Light` `.copyWith(blur: 6)`; `indicatorSettings` = `LiquidGlassSettings.ios27Indicator.copyWith(chromaticAberration: 0.001)`; `indicatorColor` = sötétben `Colors.white.withValues(alpha: 0.12)`, világosban `Colors.black.withValues(alpha: 0.06)`; `indicatorExpansion` = `EdgeInsets.symmetric(horizontal: 10, vertical: 4)`; `verticalPadding: 8`.
- A `chromaticAberration: 0` „nem beállítottnak” számít a csomag indikátor-összefésülésében, ezért mindig `0.001`-et kell adni.
- iPhone-on görgethető listában nem lehet natív (platform view) elem.
- `import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';` az egyetlen import, `src/` soha.
- Minden szöveg, ami a felhasználó elé kerül, helyes magyar (a meglévő i18n kulcsokat kell használni, ahol vannak).
- A munka külön ágon megy (`uveg-glass`, git worktree a `tinta` ág HEAD-jéről, miután a widgetes munka commitolva van). A `glass-spike` ág és a worktree eldobható.
- Csak helyi commit. Pusht és kiadást csak a felhasználó kérésére.

## Review Focus

1. **App indítási ideje más témáknál:** a `LiquidGlassWidgets.initialize()` minden felhasználónál lefut. Elvárás: Kobalt témában az indulás nem lassul érezhetően (mérés: hidegindítás logcat `Displayed` ideje előtte és utána). → Task 1, Step 6.
2. **Témaváltás futás közben:** Üvegről Kobaltra váltva a régi menüsáv/kapcsoló jöjjön vissza újraindítás nélkül, és fordítva. → widget teszt a Task 2-ben és a Task 6-ban.
3. **Cenzúrázott / bemutató mód a szűrősávban** (`FilterBar.censored`): az üveges ág se mutasson valódi címkéket. → Task 3 teszt.
4. **Billentyűzet a lapokban** (például becenév, üzenetírás): üveghátterű lapnál a szövegmező ne csússzon a billentyűzet alá. → Task 4 kézi ellenőrzés + teszt a `viewInsets`-re.
5. **iOS-en nincs válasz a natív csatornáról** (régi build, szimulátor hiba): az átlátszóság-figyelő alapértéke `false` legyen, és ne dobjon kivételt. → Task 1 teszt.

---

### Task 1: Alapok — csomag, beállítások egy helyen, iOS átlátszóság-figyelő

**Files:**
- Modify: `folio/pubspec.yaml`, `folio_mobile_ui/pubspec.yaml` (`liquid_glass_widgets: ^1.17.1`)
- Modify: `folio/lib/main.dart` (a `runApp(App(...))` körül)
- Create: `folio/lib/theme/glass_settings.dart`
- Create: `folio/lib/helpers/reduce_transparency.dart`
- Modify: `folio/ios/Runner/AppDelegate.swift`
- Modify: `folio/lib/app.dart` (a `MaterialApp` `builder:`-e, kb. 257. sor)
- Test: `folio/test/reduce_transparency_test.dart`, `folio/test/glass_settings_test.dart`

**Interfaces:**
- Produces:
  - `LiquidGlassSettings tintaBarSettings(bool dark)`
  - `LiquidGlassSettings tintaIndicatorSettings()`
  - `Color tintaIndicatorColor(bool dark)`
  - `const GlassQuality tintaGlassQuality = GlassQuality.standard;`
  - mindegyik a `folio/lib/theme/glass_settings.dart` fájlban
  - `class ReduceTransparency { static final ValueNotifier<bool> enabled; static Future<void> init(); }`, csatorna: `app.zan1456.folio/accessibility`, metódus: `reduceTransparency` (`bool`), Swiftből hívott esemény: `reduceTransparencyChanged` (`bool`)

- [ ] **Step 1: Write the failing tests**
  - `glass_settings_test.dart`: `tintaBarSettings(true).blur == 6`; `tintaBarSettings(false).blur == 6`; `tintaIndicatorSettings().chromaticAberration == 0.001`; `tintaIndicatorColor(true) == Colors.white.withValues(alpha: 0.12)`; `tintaIndicatorColor(false) == Colors.black.withValues(alpha: 0.06)`.
  - `reduce_transparency_test.dart`:
    - `init()` mock nélkül (`MissingPluginException`): `enabled.value == false`, nincs kivétel;
    - a mock `true`-t ad vissza: `enabled.value == true`;
    - egy bejövő `reduceTransparencyChanged(false)` hívás után `enabled.value == false`.
    - Nem iOS platformon (`debugDefaultTargetPlatformOverride = TargetPlatform.android`) az `init()` nem hívja a csatornát.
- [ ] **Step 2:** `cd folio && flutter test test/glass_settings_test.dart test/reduce_transparency_test.dart` → FAIL (a fájlok nem léteznek).
- [ ] **Step 3: Add the dependency and implement `glass_settings.dart` + `reduce_transparency.dart`.** A Global Constraints értékei kellenek. A `ReduceTransparency.init()` csak `Platform.isIOS` esetén hív, és minden kivételt elnyel.
- [ ] **Step 4: Swift oldal.** A meglévő `methodChannel` mintájára második `FlutterMethodChannel("app.zan1456.folio/accessibility")`:
  - a `reduceTransparency` → `UIAccessibility.isReduceTransparencyEnabled`;
  - a `UIAccessibility.reduceTransparencyStatusDidChangeNotification` figyelése → `invokeMethod("reduceTransparencyChanged", arguments: Bool)`.
- [ ] **Step 5: Bekötés.**
  - `main.dart`: `await LiquidGlassWidgets.initialize();` és `await ReduceTransparency.init();` a `runApp` előtt; `runApp(LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: App(...)))`.
  - `app.dart` builder: `ValueListenableBuilder` a `ReduceTransparency.enabled`-en, köré `GlassAccessibilityScope(reduceTransparency: enabled ? true : null, child: child!)`. A `null` azt jelenti, hogy a rendszerjelzés dönt.
- [ ] **Step 6: Ellenőrzés.**
  - `flutter test` (folio + folio_mobile_ui) → minden zöld, és `flutter analyze` → nincs új error vagy warning.
  - Hidegindítás Kobalt témában a Redmin: `adb logcat -d | grep "Displayed hu.pacuka.tinta"`, háromszor előtte és háromszor utána. A különbség 150 ms alatt legyen, különben írd be a jelentésbe.
- [ ] **Step 7: Commit:** `feat(uveg): liquid_glass_widgets alapok, közös üvegbeállítások, iOS átlátszóság-figyelő`

### Task 2: Androidos menüsáv

**Files:**
- Modify: `folio_mobile_ui/lib/screens/navigation/nabar.dart` (az `if (glass)` ág, kb. 61. sortól; a régi `BackdropFilter`-es kapszula törlődik)
- Test: `folio_mobile_ui/test/navbar_glass_test.dart`

**Interfaces:**
- Consumes: `tintaBarSettings`, `tintaIndicatorSettings`, `tintaIndicatorColor`, `tintaGlassQuality` (Task 1)

- [ ] **Step 1: Failing test (`navbar_glass_test.dart`)**
  - Üveg + Android (`debugDefaultTargetPlatformOverride`): `find.byType(GlassTabBar)` → `findsOneWidget`, és `find.byType(BackdropFilter)` a `Navbar` alatt → `findsNothing`.
  - Kobalt + Android: `GlassTabBar` → `findsNothing`.
  - Üveg → Kobalt átállítás `pump` után: `GlassTabBar` eltűnik (Review Focus 2).
  - Koppintás a 3. fülre: `onSelected` 2-vel hívódik.
- [ ] **Step 2:** `cd folio_mobile_ui && flutter test test/navbar_glass_test.dart` → FAIL.
- [ ] **Step 3: Implement.** `GlassTabBar.bottom`, `SafeArea(top: false)` alatt. Tabok: `GlassTab(icon: i.icon, activeIcon: i.activeIcon, label: i.title)`. A Global Constraints értékei kellenek, plusz `quality: tintaGlassQuality`. Színek: kiválasztott ikon és felirat `colorScheme.secondary`, a többi `colorScheme.onSurface`. Az iOS-ág (`CNTabBar`) változatlan marad.
- [ ] **Step 4:** a teszt PASS, a teljes `flutter test` zöld.
- [ ] **Step 5: Kézi ellenőrzés.**
  - Kamu build (`flutter build apk --release --flavor github --split-per-abi --target-platform android-arm64 -Pkamu=true`), bemutató mód, Üveg téma.
  - Képernyőkép sötét és világos módban, és `screenrecord` egy fülváltásról.
  - Nincs szivárványos szegély, nincs fekete kapszula nyugalomban.
- [ ] **Step 6: Commit:** `feat(uveg): Liquid Glass menüsáv Androidon`

### Task 3: Szűrősáv

**Files:**
- Modify: `folio_mobile_ui/lib/common/filter_bar.dart`
- Test: `folio_mobile_ui/test/filter_bar_glass_test.dart`

**Interfaces:**
- Consumes: `tintaGlassQuality`
- Produces: a `FilterBar` publikus API-ja változatlan (`items`, `controller`, `onTap`, `censored`, `pillStyle`, `scrollable`, `padding`, `tabAlignment`, `disableFading`).

- [ ] **Step 1: Failing test**
  - Üveg + `pillStyle: true`: a kiválasztott elem mögött a csomag üveg-indikátora van (`find.byType(GlassTabBar)` vagy `find.byType(GlassSegmentedControl)`, attól függően, melyiket választod a Step 3-ban), és a régi `BoxDecoration` indikátor nincs.
  - A `TabController.animateTo(2)` után az üveges elem kiválasztott indexe 2.
  - Koppintás az 1. elemre → `onTap(1)` és `controller.index == 1`.
  - `censored: true`: nincs valódi címke a fában (Review Focus 3).
  - Kobalt: a régi `TabBar` jelenik meg.
- [ ] **Step 2:** teszt → FAIL.
- [ ] **Step 3: Implement.**
  - Üveg + `pillStyle`: `GlassTabBar.inline`, vagy ha az nem görgethető elég elemmel, `GlassSegmentedControl`, `quality: tintaGlassQuality`.
  - A kiválasztott index a `TabController`-ből jön (`controller.animation`-t kell hallgatni). Választáskor `controller.animateTo(i)` és `onTap(i)`.
  - A címkék a `Tab` elemek `text`-jéből jönnek. Ha egy elem nem `Tab` szöveggel, vagy `censored`, akkor marad a régi `TabBar`.
  - Ha a régi `TabBar` marad, a régi üveges `BoxDecoration` maradhat.
- [ ] **Step 4:** teszt PASS, teljes `flutter test` zöld.
- [ ] **Step 5: Kézi ellenőrzés:** kezdőlap és jegyek szűrői, vízszintes görgetés, a lapozás és a szűrő együtt mozog. Képernyőkép.
- [ ] **Step 6: Commit:** `feat(uveg): üveg szűrősáv`

### Task 4: Alsó lapok

**Files:**
- Modify: `folio_mobile_ui/lib/common/bottom_sheet_menu/rounded_bottom_sheet.dart` (`RoundedBottomSheet.build`)
- Test: `folio_mobile_ui/test/rounded_sheet_glass_test.dart`

**Interfaces:**
- Consumes: `tintaBarSettings`, `tintaGlassQuality`
- Produces: a `showRoundedModalBottomSheet` és a `RoundedBottomSheet` aláírása változatlan. A 25 hívási hely nem változik.

- [ ] **Step 1: Failing test**
  - Üveg: a `RoundedBottomSheet` alatt `find.byType(GlassContainer)` → `findsOneWidget`, és a gyerek, valamint a fogantyú továbbra is látszik.
  - Kobalt: nincs `GlassContainer`, a háttér a `scaffoldBackgroundColor` (vagy a megadott `backgroundColor`).
  - `MediaQuery(viewInsets: EdgeInsets.only(bottom: 300))` mellett a gyerek alja a billentyűzet fölött van (Review Focus 4).
- [ ] **Step 2:** teszt → FAIL.
- [ ] **Step 3: Implement.**
  - Üvegnél a `Container` helyett `GlassContainer`, `LiquidRoundedSuperellipse(borderRadius: borderRadius)`, `settings: tintaBarSettings(dark)`, `quality: tintaGlassQuality`.
  - Ha nem lehet csak a felső sarkokat lekerekíteni, akkor `ClipRRect` csak felső sugárral, és az üveg alja a képernyő alá nyúlik.
  - A megadott `backgroundColor` Üvegnél is felülír (az a hívó szándéka, például egy teljesen színes lap).
- [ ] **Step 4:** teszt PASS, teljes `flutter test` zöld.
- [ ] **Step 5: Kézi ellenőrzés:** jegy részletei, órarend-óra, becenév (billentyűzettel), üzenet-melléklet. Görgethető lap tartalma görög, szöveg olvasható. Képernyőképek.
- [ ] **Step 6: Commit:** `feat(uveg): üveghátterű alsó lapok`

### Task 5: Megerősítő ablakok

**Files:**
- Create: `folio_mobile_ui/lib/common/tinta_confirm.dart`
- Modify: azok a `showDialog` hívások, amelyek builderje sima `AlertDialog`, csak cím és szöveg van benne, és legfeljebb 2 gomb (a jelöltek: `notes_page.dart:442, 552, 595`, `settings_screen.dart:239, 356, 2299, 2343, 2774`, `absences_page.dart:337`, `profile_screen.dart:289`). Ami egyedi tartalmat (mezőt, listát, képet) mutat, marad.
- Test: `folio_mobile_ui/test/tinta_confirm_test.dart`

**Interfaces:**
- Produces: `Future<bool> showTintaConfirm(BuildContext context, {required String title, String? message, required String confirmLabel, required String cancelLabel, bool destructive = false})`
  - Üveg + iOS → `CNAlert.show<bool>` (a mégse gomb `isCancel: true`, a megerősítés `isDestructive: destructive`);
  - Üveg + Android → `GlassDialog.show` két `GlassDialogAction`-nel (`isDestructive: destructive`, a megerősítés `isPrimary: !destructive`);
  - minden más → a meglévő `AlertDialog` kinézet.
  - Bezárás gomb nélkül = `false`.

- [ ] **Step 1: Failing test**
  - Kobalt: megjelenik egy `AlertDialog`, a megerősítésre `true`, a mégsére `false`.
  - Üveg + Android: `find.byType(GlassDialog)`-féle elem (vagy a csomag dialógusának gombcímkéi látszanak), a megerősítés → `true`.
  - Üveg + iOS: a `cupertino_native_better` alert-csatornájának mockja kapja a hívást a címmel és két akcióval, és ha a mock a megerősítés értékét adja vissza, az eredmény `true`, ha `null`-t, akkor `false`.
- [ ] **Step 2:** teszt → FAIL.
- [ ] **Step 3: Implement** `showTintaConfirm`. A hívásonkénti átírás: a régi gombcímke-szövegeket és a régi viselkedést (mi történik `true` után) változatlanul kell átvinni. Minden átírt hely kap egy sort a commit üzenetbe.
- [ ] **Step 4:** teszt PASS, teljes `flutter test` zöld.
- [ ] **Step 5: Kézi ellenőrzés:** legalább a kijelentkezés és egy jegyzet törlése Androidon, Üveg és Kobalt témában is. Képernyőkép.
- [ ] **Step 6: Commit:** `feat(uveg): megerősítő ablakok (iPhone: natív, Android: üveg)`

### Task 6: Kapcsolók és csúszkák

**Files:**
- Create: `folio_mobile_ui/lib/common/tinta_switch.dart`
- Modify: `Switch(` → `TintaSwitch(`: `settings_screen.dart` (1100, 1129, 1183, 1259, 1301, 1339, 1377 és a többi találat a fájlban), `home_edit_screen.dart:219`. `Slider(` → `TintaSlider(`: `settings_screen.dart:615`, `settings_helper.dart:525`, `grade_calculator.dart:121`.
- Test: `folio_mobile_ui/test/tinta_switch_test.dart`

**Interfaces:**
- Produces:
  - `class TintaSwitch extends StatelessWidget { const TintaSwitch({super.key, required bool value, required ValueChanged<bool>? onChanged, Color? activeColor}); }`
  - `class TintaSlider extends StatelessWidget { const TintaSlider({super.key, required double value, required ValueChanged<double>? onChanged, double min = 0, double max = 1, int? divisions, String? label, ValueChanged<double>? onChangeEnd, Color? activeColor}); }`
  - Üveg → `GlassSwitch` / `GlassSlider` (`quality: tintaGlassQuality`); más téma → `Switch` / `Slider` ugyanazokkal a paraméterekkel.
  - `onChanged: null` = letiltott állapot mindkét ágon.

- [ ] **Step 1: Failing test**
  - Kobalt: `TintaSwitch` alatt `Switch`, koppintásra `onChanged(!value)`.
  - Üveg: `GlassSwitch`, koppintásra `onChanged(!value)`.
  - `onChanged: null` Üvegnél: koppintásra nincs hívás.
  - Üveg → Kobalt átállítás után `Switch` (Review Focus 2).
  - `TintaSlider` Üvegnél: `GlassSlider`, és a `divisions: 4` megmarad (a húzás 0,25-ös lépésekben ad értéket).
- [ ] **Step 2:** teszt → FAIL.
- [ ] **Step 3: Implement** a két csomagolót, és cseréld a hívásokat. A hívási helyek egyéb paramétereit (például `activeColor`) vidd át, ha a csomagoló ismeri. Ha nem ismeri, a régi viselkedés maradjon Kobaltban.
- [ ] **Step 4:** teszt PASS, teljes `flutter test` zöld.
- [ ] **Step 5: Kézi ellenőrzés:**
  - a beállítások oldal végiggörgetése Üveg témában: sima görgetés, a kapcsolók váltanak;
  - a kerekítés csúszka (0,5-ös lépések);
  - a jegyszámoló csúszkája.
  - Képernyőkép.
- [ ] **Step 6: Commit:** `feat(uveg): üveg kapcsolók és csúszkák`

### Task 7: Világos mód, takarítás, átadás

**Files:**
- Modify: `folio/lib/theme/glass_settings.dart` (csak ha a világos képernyőképek szerint kell)
- Modify: `folio/lib/theme/glass.dart` (`glassHairline`: 0,8 → 0,5 px, ha a képernyőképen jobb, és ezt a jelentésben indokolni kell)
- Test: a meglévő `folio/test/glass_palette_test.dart` maradjon zöld

- [ ] **Step 1:** Képernyőképek Üveg témában világos és sötét módban: kezdőlap, jegyek, órarend, beállítások, egy lap, egy ablak. Ugyanezek Kobalt témában is (Global Constraints: semmi nem változhat).
- [ ] **Step 2:** Ha a világos mód menüsávja vagy lapja túl átlátszó (olvasható szöveg a mögötte lévő tartalomból), emelj a `tintaBarSettings(false)` `blur`-ján, de csak a világos ágon. A `glass_settings_test.dart` értékét is frissítsd.
- [ ] **Step 3:** `flutter test` és `flutter analyze` a teljes repón → zöld, és nincs új warning.
- [ ] **Step 4:** iOS IPA build a GitHub Actionsön (csak ha a felhasználó engedi a pusht). Ha nem, írd a jelentésbe, hogy iPhone-on nincs ellenőrizve.
- [ ] **Step 5: Commit:** `chore(uveg): világos mód hangolás, takarítás`
