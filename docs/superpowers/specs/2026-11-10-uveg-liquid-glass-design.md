# Üveg téma: igazi Liquid Glass — terv

2026-11-10 · Tinta (Flutter) · állapot: jóváhagyásra vár

## Miért

A felhasználó azt kérte, hogy az „Üveg” téma úgy nézzen ki, „mintha az Apple csinálta volna”: legyen igazi folyékony üveg, ne csak homályosítás, és kövesse az iPhone beállításait. A mostani Üveg téma `BackdropFilter`-homályosításból és egyforma fehér keretből áll. Az Apple-szabályok szerint pont ez árulja el, hogy utánzat: nincs rajta fénytörés a peremen, és a fény sem csillan rajta egyenetlenül.

## Célok

- Az Üveg témában a kezelőelemek igazi Liquid Glass kinézetet kapnak: fénytörést a peremen, fénycsíkot, tejes elmosást.
- iPhone-on, ahol lehet és jól néz ki, az Apple saját elemei jönnek (a felhasználó döntése). Androidon a `liquid_glass_widgets` csomag mindenhol, ahol csak lehet.
- Az app követi a kisegítő beállításokat: Mozgás csökkentése, Átlátszóság csökkentése, Kontraszt növelése.
- A görgetés ugyanolyan sima marad, mint most.

## Nem cél

- Más témák (Kobalt, Fekete-sárga, Petrol, Material You) változatlanok maradnak, minden az `isGlassTheme` mögött van.
- A tartalomkártyák (jegyek, órák, üzenetek, házik) nem lesznek üvegek, tömörek maradnak. Ez Apple-szabály, és a csomagé is.
- Nem írjuk át az egész appot `GlassScaffold`-ra, és a SnackBarokból (47 darab) sem lesz `GlassToast` ebben a körben.
- Nem lesz új téma: a meglévő Üveg téma fejlődik tovább.

## Amire nem szabad, hogy kifusson

- Akadó görgetés bárhol, főleg a hosszú listáknál (jegyek, órarend, üzenetek).
- Szivárványos, „olcsó” szegély a lencsén. Ezt a próba során láttuk prémium minőségben.
- Olvashatatlan szöveg az üveg alatt vagy az üvegen.
- Bármi változás a többi témában.

## Korlátok

- Flutter 3.47 helyben, a csomaghoz ≥ 3.41 kell. Androidon az Impeller (Vulkan) már be van kapcsolva (`AndroidManifest.xml`, `EnableImpeller=true`).
- `liquid_glass_widgets` ^1.17.1 (MIT, nincs további függősége). A `cupertino_native_better` 1.8.1 már benne van (`folio_mobile_ui/pubspec.yaml`).
- A csomag egy `Material` ősre számít a szövegekhez. A Tinta `MaterialApp`-ot használ, ezért `brightnessResolver: Theme.maybeBrightnessOf` kell.
- Az Apple saját elemei iOS-en platform view-k. A cikk szerint görgethető listában használhatatlanul akadnak, ezért **listában iPhone-on is a csomag elemei kellenek**. Az Apple-elemek csak fix helyre kerülnek.
- A Flutter nem adja ki az iOS „Átlátszóság csökkentése” kapcsolót. A csomag ezt a „Kontraszt növelése” jelzésből közelíti, ezért saját kis iOS-kódra van szükség.
- iPhone-on itt nem tudunk tesztelni. Az IPA a GitHub Actionsön épül, és a barát iPhone-ján (vagy egy szimulátoros képernyőképen) lehet ellenőrizni.

## Utak, amiket mérlegeltünk

1. **Kevert (KIVÁLASZTVA, a felhasználó döntése):** iPhone-on az Apple saját elemei, ahol fix helyen vannak és jól néznek ki, máshol a csomag. Androidon mindenhol a csomag. Ez iPhone-on a legigazibb, és magától követi a rendszerbeállításokat. Ára: két megoldás, iOS-en külön tesztelni.
2. **Mindenhol a csomag, csak az iPhone-os menüsáv marad natív.** Egyszerűbb, és a két telefonon egyforma, de iPhone-on kevésbé „igazi”.
3. **A saját kód feljavítása** (perem, shader). Nem kell hozzá új csomag, de ez a legtöbb munka, és ez hasonlít a legkevésbé az Apple-ére.

## Amit a próba eldöntött (2026-11-10, Redmi Note 12 Pro, Android 16, Vulkan)

A próba egy eldobható `glass-spike` ágon készült, „Tinta Kamu” néven, és a felhasználó jóváhagyta: „sima”, és tetszik.

- Androidos menüsáv: `GlassTabBar.bottom`, a következő értékekkel:
  - `settings`: `LiquidGlassSettings.ios27Dark/ios27Light` `.copyWith(blur: 6)`. A preset magában túl átlátszó, a sáv mögötti szöveg olvasható maradt.
  - `indicatorSettings`: `ios27Indicator` `.copyWith(chromaticAberration: 0.001)`. A 0 „nem beállítottnak” számít, és akkor visszajön a 0,15-ös alapérték.
  - `indicatorColor`: sötétben `white 12%`, világosban `black 6%`. Az alapértéktől csúnya fekete folt lett nyugalomban.
  - `quality: GlassQuality.standard`. A prémiumon szivárványos szegély maradt a lencse szélén, a standardon tiszta.
  - `indicatorExpansion`: vízszintesen 10, függőlegesen 4. `verticalPadding: 8`.
  - A kiválasztott ikon és felirat a téma `secondary` színét kapja, a többi az `onSurface`-t.
- `main.dart`: `await LiquidGlassWidgets.initialize()` és `LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: App(...))`.

## Mi hova kerül

| Elem | iPhone (Üveg) | Android (Üveg) | Megjegyzés |
|---|---|---|---|
| Alsó menüsáv (`nabar.dart`) | marad a `CNTabBar` (natív) | `GlassTabBar.bottom`, a próba értékeivel | |
| Szűrőgombok (`filter_bar.dart`: kezdőlap, jegyek) | csomag (`GlassChip` / `GlassSegmentedControl`) | csomag | görgethető fejlécben vannak, ezért nem natív |
| Alsó lapok (`showRoundedModalBottomSheet` és a 25 hívás) | csomag (`GlassModalSheet` vagy üveghátterű lap) | csomag | a `cupertino_native_better` nem ad igazi natív lapot, csak egy Flutteres burkot |
| Figyelmeztető ablakok (`showDialog`, 18 hívás) | `CNAlert` (natív `UIAlertController`, nincs platform view) | `GlassDialog` | csak az egyszerű igen/nem/OK ablakok; az egyedi tartalmúak maradnak |
| Kapcsolók és csúszkák a beállításoknál | csomag (`GlassSwitch`, `GlassSlider`) | csomag | listában vannak, ezért iPhone-on sem natív |
| Kártyák, listák | változatlan, tömör | változatlan, tömör | Apple-szabály |
| Háttérfény (`GlassBackdrop`) | marad | marad | ad valamit, amit az üveg megtörhet |
| Mostani kártyakeret (`glassHairline`) | marad, vagy 0,5 px-es hajszálvonalra vékonyodik | ugyanígy | a kivitelező dönti el, hogy néz ki jobban |

## Kisegítő beállítások

- **Mozgás csökkentése:** a csomag magától kezeli (a rugós animációk azonnal a helyükre ugranak).
- **Kontraszt növelése:** a csomag magától átvált egy sima, homályosított panelre.
- **Átlátszóság csökkentése (iOS):** új, kicsi natív csatorna. Kiolvassa a `UIAccessibility.isReduceTransparencyEnabled` értékét, és figyeli a változás értesítését. Ha be van kapcsolva: `GlassAccessibilityScope(reduceTransparency: true)` az app tetején, és minden saját üvegelem tömör felületre vált. A natív Apple-elemek ezt maguktól követik.
- **„Átlátszó / Színezett” üveg (iOS 26.1+):** nem találtunk hozzá nyilvános API-t. A natív elemek maguktól követik, a csomag elemei nem. Ezt itt kimondjuk, és nem találunk ki rá semmit.
- **Android:** nincs „átlátszóság csökkentése” kapcsoló. Az „Animációk eltávolítása” és a magas kontraszt jelzéseit a csomag olvassa.

## Sorrend (mindegyik külön kipróbálható lépés)

1. Alapok: csomag, `initialize`/`wrap`, a beállítások egy helyen (`folio/lib/theme/glass.dart`), és az iOS-es átlátszóság-csatorna.
2. Androidos menüsáv a próba értékeivel. Szakaszhatár: képernyőkép és videó a fülváltásról.
3. Szűrőgombok.
4. Alsó lapok.
5. Figyelmeztető ablakok (iPhone: `CNAlert`, Android: `GlassDialog`).
6. Kapcsolók és csúszkák a beállításoknál.

Minden lépés után: tesztek, analyzer, képernyőkép a Redmin világos és sötét módban is, és a görgetés kézi kipróbálása. Az iPhone-os részeket IPA-build után a barát iPhone-ján kell megnézni.

## Ami a kivitelezőre marad

- A pontos `GlassChip` vagy `GlassSegmentedControl` választás a szűrőknél: az a jó, amelyik vízszintesen görgethető, és ugyanannyi elemet elbír, mint a mostani.
- Melyik lapok kapnak `GlassModalSheet`-et, és melyek csak üveghátteret: azok a lapok, amelyekben görgethető tartalom vagy szövegmező van, ne törjenek el.
- A világos mód hangolása. A próba sötétben készült, a világos értékeket képernyőkép alapján kell finomítani.
- Mi legyen a régi, saját androidos üvegsáv kódjával (`nabar.dart`, a második `if (glass)` ág): törlés, ha az új mindenhol működik.

## Tesztelés

- Egységtesztek: a natív átlátszóság-csatorna Dart oldala (alapérték, ha nincs válasz), és hogy más témában semmi nem vált üvegre.
- Golden vagy widget teszt a menüsávra Üveg és Kobalt témában (a csomag shaderei headless környezetben a „minimal” utat használják, ezt figyelembe kell venni).
- Kézi teszt: képernyőkép és felvétel a Redmin. iPhone: barát vagy szimulátor.
