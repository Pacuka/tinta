# KRÉTA API-térkép + kamu KRÉTA szerver

Dátum: 2026-10-27

## Cél

A szülői és diákos funkciókat (üzenetküldés, csatolmány, igazolás / e-ügyintézés) úgy lehessen fejleszteni
és kipróbálni, hogy semmi ne jusson el az iskolához. Siker:

- A Tinta egy fejlesztői kapcsolóval a gépen futó kamu szerverhez csatlakozik.
- Ott be lehet lépni diákként és szülőként is.
- Látszanak a kitalált jegyek, órarend és üzenetek.
- Egy elküldött üzenet vagy igazolás a kamu szerver naplójában jelenik meg, nem a KRÉTA-ban.

## Mi NEM kerül nyilvánosságra

- Az API-térkép és a kamu szerver a repón **kívül** van: `~/Downloads/folio-projekt/kreta-api-terkep/` és
  `~/Downloads/folio-projekt/kamu-kreta/`.
- Nem kerül a GitHubra. Valódi adatot (nevet, jegyet, tokent) nem tartalmaz, csak kitalált adatot.
- A Tintában a kapcsoló csak **debug** buildben létezik. A kiadott APK-ban nincs ilyen, és a http-engedély is
  csak a debug buildben van.

## 1. API-térkép

- Egy szkript (`terkep.py`, csak Python standard könyvtárral) végigmegy a két szétszedett hivatalos appon
  (`hu.ekreta.student` és `hu.ekreta.guardian`, mindkettő 5.17.0, adb-vel lehúzva, jadx-szel visszafordítva).
- Kigyűjti:
  - a Retrofit-hívásokat: metódus, útvonal, melyik API-hoz tartozik (mobil / e-ügyintézés / IDP / DKT / IER),
    melyik appban van meg;
  - a kérés- és válaszosztályokat: a `@SerializedName` mezőneveket és a típusokat.
- A kimenet `endpoints.json` (gépi) és `README.md` (ember olvassa).
- A Zan-féle doksi ([docs.zan1456.dev/e-kreta/app](https://docs.zan1456.dev/e-kreta/app)) csak az útvonalakat
  sorolja fel, ezért ezt kiegészítésnek használjuk, nem forrásnak.

## 2. Kamu KRÉTA szerver

- `kamu-kreta/server.py`, Python standard könyvtárral (nincs telepítendő függőség), a `8765`-ös porton.
- Egyetlen szerver szolgálja ki az összes KRÉTA-hostot, útvonal-előtag alapján:
  - **IDP:**
    - `/connect/authorize`: egy egyszerű kamu belépő oldal két gombbal, „Diák” és „Szülő”. Átirányít a
      kért `redirect_uri?code=...&state=...` címre.
    - `/connect/token`: kamu JWT-t ad vissza. Ugyanazok a claimek vannak benne, mint a valódiban (`role`,
      `name`, `kreta:institute_code` stb.), aláírás nélkül. Kezeli a refresh tokent is.
  - **Mobil API (`/ellenorzo/V3/Sajat/...`):** kitalált adatok a `fixtures/` mappából (TanuloAdatlap jegyekkel,
    órarenddel, mulasztással és Gondviselők listával).
  - **E-ügyintézés (`/api/v1/...`):**
    - postafiók, címzettek, `POST kommunikacio/uzenetek`;
    - `POST ideiglenesfajlok` és a feltöltés;
    - `adatszotarak/kerelemtipusok`, `POST/GET ugy/kerelmek`.
    - Minden beküldés a `kamu-kreta/naplo/` mappába kerül JSON-ként, és a `http://localhost:8765/_naplo`
      oldalon látszik.
- Ismeretlen útvonalra 404-et ad, és naplózza, így látszik, mit hiányol a Tinta.

## 3. Tinta: fejlesztői kapcsoló

- A `BaseKreta` hostjai (IDP, mobil API, e-ügyintézés) egy kapcsolható felülírásból jönnek. Ha a
  „Kamu KRÉTA” be van kapcsolva, minden a `http://127.0.0.1:8765` címre megy.
  - A telefon az `adb reverse tcp:8765 tcp:8765` paranccsal éri el a gépet.
- A kapcsoló a fejlesztői beállításoknál van, és csak `kDebugMode` alatt látszik.
- `android/app/src/debug/AndroidManifest.xml`: `usesCleartextTraffic="true"`. Csak a debug buildben, mert a
  kamu szerver sima http.

## Tesztelés

- A szkriptnek és a szervernek Python-tesztjei vannak (`unittest`):
  - a térkép megtalál egy-egy ismert hívást (`POST kommunikacio/uzenetek`, `GET sajat/TanuloAdatlap`);
  - a token claimjei helyesek;
  - a beküldés bekerül a naplóba.
- Dart-teszt: bekapcsolt felülírásnál a `BaseKreta` hostjai a kamu címre mutatnak, kikapcsolva a valódira.
- Telefonon, debug buildben:
  - belépés diákként és szülőként;
  - üzenet küldése;
  - a napló megnézése.

## Nem része

- Az igazolás felülete a Tintában: ez a következő lépés, erre a szerverre építve.
- Tanári fiók.
- iPhone-os rész.
