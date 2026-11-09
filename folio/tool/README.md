# Fordítás: két változat, egy kódbázis

| | F-Droid / IzzyOnDroid | GitHub (Firebase-es) |
|---|---|---|
| Parancs | `tool/build-fdroid.sh` | `tool/build-firebase.sh` |
| Firebase | nincs, a függőségek között sem | `tinta_push_firebase` csomag |
| Azonnali push | nincs | csak `tool/push.json` megléte esetén |
| Értesítések | időzített ellenőrzés az órarend alapján | ugyanaz, plusz push |
| Alkalmazáson belüli frissítő | nincs (`FLAVOR=fdroid`) | van |
| Android-változat | `fdroid` | `github` |

A különbség egyetlen csomagcsere: az alkalmazás a `tinta_push` csomagot használja. Ennek alapváltozata (`../tinta_push`) nem csinál semmit és nincs függősége. A Firebase-es szkript ideiglenesen egy `pubspec_overrides.yaml` fájllal a `../tinta_push_firebase` változatot teszi a helyére. A két változat API-ja azonos, az alkalmazás kódja nem változik.

A további paraméterek (pl. `--target-platform`, `--build-number`, `--split-debug-info`) mindkét szkriptnek átadhatók.

**A GitHubos kiadás jelenleg nem ezzel a szkripttel készül**, hanem a `../tool/release.sh`-val (telefonos APK-k, óra-APK-k, SHA256SUMS, debug-szimbólumok egy lépésben). Ez a `github` változatot fordítja, de a `tinta_push` alapváltozatával, vagyis Firebase nélkül, mert `tool/push.json` még nincs. Ha a push egyszer bekapcsolható, a `release.sh` telefonos lépését kell a `build-firebase.sh`-ra cserélni.

## `tool/push.json` (nincs a gitben)

A Firebase-projekt adatai, `--dart-define-from-file` formátumban:

```json
{
  "TINTA_PUSH_API_KEY": "…",
  "TINTA_PUSH_APP_ID": "…",
  "TINTA_PUSH_SENDER_ID": "…",
  "TINTA_PUSH_PROJECT_ID": "…"
}
```

Csak olyan Firebase-projekt adható meg, amelyre a KRÉTA engedélyezetten küld értesítést. Ilyen jelenleg nincs, ezért a fájl hiányzik, és a push ki van kapcsolva. A KRÉTA-oldali regisztráció (a push-token bejelentése) addig nincs megírva, a régi Folio-megoldás a git-történetben van (`738baea1^:folio/lib/helpers/notification_helper.dart`).

## KRÉTA-azonosítók (fordításkor állíthatók)

| Beállítás | Mire való | Alapérték |
|---|---|---|
| `KRETA_CLIENT_ID` | OAuth-kliensazonosító, diák | a hivatalos diákalkalmazásé |
| `KRETA_REDIRECT_URI` | OAuth-visszairányítás, diák | a hivatalos diákalkalmazásé |
| `KRETA_GUARDIAN_CLIENT_ID` | OAuth-kliensazonosító, szülő | a hivatalos szülőalkalmazásé |
| `KRETA_GUARDIAN_REDIRECT_URI` | OAuth-visszairányítás, szülő | a hivatalos szülőalkalmazásé |
| `KRETA_CLIENT_VERSION` | a hivatalos stílusú User-Agentben szereplő verzió | `5.18.0` |
| `TINTA_OWN_UA=true` | saját User-Agent: `Tinta/<verzió> (…; +https://tinta.pacuka.hu)` | ki |
| `TINTA_NO_APIKEY=true` | a hivatalos API-kulcs elhagyása | ki |

A Tinta saját verziója (`pubspec.yaml`) ezektől független. Az alapértékek átmeneti kompatibilitási értékek, amíg a KRÉTA üzemeltetője nem ad saját hozzáférést. Ha ad, ezek a beállítások állítandók át.

## Átállás saját azonosítókra (ha a KRÉTA engedélyt ad)

1. `cp tool/sajat-azonosito.json.minta tool/sajat-azonosito.json`, és töltsd ki a kapott adatokkal.
2. Fordítás mindkét változatban ugyanazzal a paraméterrel:
   `tool/build-fdroid.sh --dart-define-from-file=tool/sajat-azonosito.json`
   `tool/build-firebase.sh --dart-define-from-file=tool/sajat-azonosito.json`
3. Ezzel egyszerre átáll: saját User-Agent, API-kulcs nélkül, saját Client ID-k és visszairányítási címek. A saját User-Agentet és az API-kulcs nélküli működést 2026. október 31-én kipróbáltuk, működik.

Ha a KRÉTA saját API-kulcsot ad, a `TINTA_NO_APIKEY` helyett annak beállítása kell (ehhez kódmódosítás szükséges: `KretaClient._apiKey`).

### Push saját azonosítóval

A végleges felállás: **a Tinta saját Firebase-projektje** (vagy a KRÉTA által támogatott nyílt csatorna, pl. UnifiedPush), amelyre a KRÉTA a regisztráció után maga küld értesítést.

1. A KRÉTA üzemeltetője engedélyezi, hogy a Tinta projektjének tokenjeire is küldjön (lásd `ugyved/tinta-firebase-es-verzio-allapot-*.md`).
2. A Tinta saját Firebase-projektjének adatai a `tool/push.json`-ba kerülnek (a fejlesztő Firebase-fiókjából).
3. A push-token bejelentése a KRÉTA-nál a kapott dokumentáció szerint (`TintaPush.token()` és `TintaPush.onTokenRefresh` adja a tokent).
4. A push csak a GitHubos (Firebase-es) változatban lesz. Az F-Droidosban marad az időzített ellenőrzés.
