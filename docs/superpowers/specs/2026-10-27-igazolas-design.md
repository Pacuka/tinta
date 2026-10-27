# Igazolás beküldése (szülői fiók) – design

Dátum: 2026-10-27 · Állapot: jóváhagyva

## Cél

A szülő a Tintából tudjon igazolást (KRÉTA e-ügyintézés „TMGI” kérelem) beküldeni a
gyereke hiányzására, és lássa a korábbi igazolásai állapotát – ugyanúgy, mint a hivatalos
e-KRÉTA szülői appban.

**Siker:** a kamu KRÉTA-val végigmegy a beküldés; a kamu naplójában pontosan olyan kérés
jelenik meg, mint amit a hivatalos app küldene; a beküldött igazolás megjelenik a listában.
Valódi iskolához tesztből **semmi** nem megy ki (csak a felhasználó kifejezett engedélyével).

## Hatókör

- **Csak szülői fiók** (`Role.parent`) – diákfióknál a funkció nem látszik (a jogosultság
  a szülői fiókhoz tartozik).
- Nincs fájlcsatolás (a hivatalos app TMGI-űrlapja sem kínál).
- Nincs utólagos javítás (`POST ugy/kerelmek/{id}` – hiánypótlás) – később, ha kell.

## Ami a hivatalos appban van (hu.ekreta.guardian 5.17.0, visszafejtve)

- Belépési pont: lebegő „Igazolás” gomb a Mulasztások oldalon (hiányzás nélkül is látszik).
- Űrlap: kezdő dátum*, záró dátum*, igazolás típusa* (lenyíló), indoklás (opcionális),
  Mégse / Küldés. Küldés csak ha minden kötelező mező ki van töltve és kezdet ≤ vég.
  Küldés előtt megerősítő párbeszédablak.
- Valódi típusok (a felhasználó szülői fiókjából, 2026-10-27): Orvosi igazolás,
  Gondviselői igazolás, Hivatalos távollét, Pályaválasztási célú igazolás, Az iskolai
  házirendben rögzített egyéb igazolás, Szolgáltatói igazolás, Kikérő (utólagos igazolás).

### Hívások (eugyintezes API, `/api/v1/…`)

| Mire | Hívás |
|---|---|
| igazolás-típusok | `GET adatszotarak/tmgiigazolastipusok` → `[TypeDto]` |
| kérelemtípusok (ebből a `kod == "TMGI"`) | `GET adatszotarak/kerelemtipusok` → `[TypeDto]` |
| gyerek adatai | `GET kreta/gyerekemadatok` → `{vezetekNev, keresztNev, oktatasiAzonosito, osztaly}` |
| korábbi kérelmek | `GET ugy/kerelmek` (opcionális `isLezartakIs`) → `[CaseDto]` |
| beküldés | `POST ugy/kerelmek` body = `TmgiCasePostDto` |

`TypeDto` = `{azonosito, kod, nev, leiras, rovidNev}`.

`TmgiCasePostDto` (JSON nevek, a hivatalos app kitöltése szerint):

```json
{
  "tanuloCsaladiNev": "<gyerekemadatok.vezetekNev>",
  "tanuloKeresztNev": "<gyerekemadatok.keresztNev>",
  "tanuloOktatasiAzonosito": "<gyerekemadatok.oktatasiAzonosito, szövegként>",
  "tanuloOsztaly": "<gyerekemadatok.osztaly>",
  "tipus": { ...a kerelemtipusok TMGI eleme... },
  "igazolasTipus": { ...a kiválasztott tmgiigazolastipus... },
  "tipusKod": "TMGI",
  "igazoltTavolletKezdeteDatum": "YYYY-MM-DD",
  "igazoltTavolletVegeDatum": "YYYY-MM-DD",
  "indoklas": "<szöveg vagy üres>",
  "kerelemKotelezoDokumentumLista": [],
  "csatolmanyok": []
}
```

Dátum: a hivatalos app a választott napot ISO helyi dátumként (`DateTimeFormatter`
ISO_LOCAL_DATE, `yyyy-MM-dd`) adja át. **Ezt az implementáció elején még egyszer
ellenőrizzük** a visszafejtett kódban (a formatter-konstans obfuszkált); ha mégis más,
a terv szerint igazítjuk.

## Tinta – felépítés

- `folio_kreta_api`: új modellek (`TmgiType`, `CaseItem`), `KretaAPI` útvonalak, és egy
  `CaseProvider` (ChangeNotifier, a `MessageProvider` mintájára) a fenti hívásokkal. A POST body
  összerakása **külön, tiszta függvény** (`buildTmgiBody(...)`) → unit-tesztelhető.
- UI (`folio_mobile_ui`):
  - Hiányzások oldal: lebegő **„Igazolás”** gomb, csak `Role.parent`-nél.
  - **Igazolások** lap: felül a korábbi kérelmek (dátumtartomány, típus, állapot), alul /
    lebegő „Új igazolás” gomb. Üres állapot, ha nincs.
  - **Új igazolás** űrlap: két dátumválasztó, típus-lenyíló (KRÉTA-ból), indoklás,
    Küldés gomb csak érvényes űrlapnál. Küldés előtt összegző megerősítés
    („Ezt küldöd be az iskolának: … – Biztos?”).
  - Tinta-stílus (Kobalt/Üveg témák, Outfit), magyar szövegek; az i18n-kulcsok a meglévő
    `.i18n` mintát követik.
- Hibakezelés: hálózati hiba / KRÉTA-hiba → érthető magyar üzenet; ha a válasz tartalmaz
  hibaüzenetet (pl. `hibakod`/`uzenet`), azt kiírjuk. Sikeres küldés után a lista frissül.
- A KRÉTA hívások a meglévő `KretaClient` + szülői UA logikát használják; a kamu KRÉTA
  (`FakeKreta`) mód automatikusan működik.

## Kamu KRÉTA bővítés (`kreta-dev/kamu-kreta`)

- `tmgiigazolastipusok` → a fenti 7 valódi típus (kitalált `azonosito`/`kod` értékekkel).
- `kreta/gyerekemadatok` → kamu gyerek.
- `ugy/kerelmek` GET a beküldötteket adja vissza `CaseDto`-szerű alakban (állapot:
  „Beküldve (kamu)”); a POST már naplóz.

## Tesztelés

- Unit teszt: `buildTmgiBody` pontosan a fenti JSON-t adja (mezőnevek, dátumformátum,
  `tipusKod`).
- Telefonon (kamu KRÉTA, szülői kamu fiók): gomb látszik szülőnél / nem látszik diáknál;
  beküldés → kamu napló + lista; hibás űrlap nem küldhető; megerősítő ablak megjelenik.
- Valódi KRÉTA, 1. lépés (biztonságos): a valódi szülői fiókkal csak az olvasó hívások
  (típusok, gyerekadatok, kérelemlista) – ellenőrizzük, hogy a valódi válaszok alakja
  egyezik a modellekkel. Ez semmit nem küld az iskolának.
- Valódi KRÉTA, 2. lépés (éles beküldés): csak akkor, amikor **ténylegesen van**
  igazolandó hiányzás, és a fiók tulajdonosa (szülő) ezt kéri. Előtte a kamu-tesztnek
  zöldnek kell lennie. Próba-/kamu-igazolást valódi iskolához soha nem küldünk.
- Állapot: jóváhagyva 2026-10-27.

---

## 2. kör – teljes e-Ügyintézés igazolás (a hivatalos szülői app minden funkciója)

Felhasználói kérés (2026-10-27): „amit tud, ne hagyjuk ki”. A hivatalos app (5.17.0)
visszafejtése alapján ezek hiányoznak az 1. körből. **Az 1. kör „nincs fájlcsatolás”
pontja téves volt**: a csatolás rész a típus kiválasztása után jelenik meg.

### 2.1 Csatolás az űrlapon
- Típusonként kötelező dokumentum (a hivatalos `TmgiType.codeToUpload`):
  ORVOSI → 36, HIVATALOS_TAVOLLET → 39, SZOLGALTATOI → 40, KIKERO → 41;
  GONDVISELOI, PALYAVALASZTASI_CELU, HAZIRENDBEN_ROGZITETT_EGYEB → nincs kötelező, csak
  „Egyéb csatolt dokumentumok”. (A típus `kod`-ja alapján; a kamu szerver is ezeket a
  valódi kódokat kapja.)
- Kötelezőnél: „Kötelezően csatolandó dokumentumok” rész, Küldés tiltva amíg nincs
  csatolva („A kérelemhez kötelező dokumentumot csatolni.”). Egyéb csatolmány: több is
  lehet, bármelyik típusnál.
- Forrás: kamera, galéria (kép), fájl (PDF). Feltöltés azonnal a kiválasztás után:
  `POST /ideiglenesfajlok` multipart → `TemporaryFileDto`; hiba esetén „Feltöltés
  újrapróbálása”; csatolmány törölhető (megerősítéssel). Nem támogatott típus → üzenet.
- Body: kötelező → `kerelemKotelezoDokumentumLista: [{tipus: {azonosito: <codeToUpload>…},
  fajl: {ideiglenesFajlAzonosito}, fajlNev}]`; egyéb → `csatolmanyok: [{fajl:
  {ideiglenesFajlAzonosito}, fajlNev}]`. A pontos mezőket (ApplicationDocumentTypeDto,
  TemporaryFileDto mező-sorrend) az implementáció első lépése ellenőrzi a visszafejtett
  kódban.
- Kilépés kitöltött űrlapról → „Az oldalon megadott adatok törlésre kerülnek! Biztosan
  félbeszakítod?”; megerősítő szöveg kiegészül: „A beküldés után a kérelem már nem
  módosítható.”

### 2.2 Ügy részletei (lista elemre koppintva) – `GET ugy/kerelmek/{id}`
- Állapot, ügyintéző neve, beküldés időpontja, tanuló neve + oktatási azonosító,
  kérelmezett időszak, típus, indoklás, kötelező és egyéb csatolmányok (megnyitás),
  nyomtatható változat letöltése/megnyitása (ha van).
- Döntések (`hatarozatLista`): Elfogadva / Elfogadva módosítással / Elutasítva /
  Hiánypótlás határozattal / üzenettel; döntés dátuma, szövege, aláíró neve
  (`GET ugy/alkalmazott/{kerelemAzonosito}/{kretaAzonosito}`), igazolt távollét napjai.
- A listán állapot-jelzés: Feldolgozásra vár / Elfogadva / Elutasítva / Hiánypótlás
  szükséges / Hiánypótlás beküldve.

### 2.3 Hiánypótlás – `POST ugy/kerelmek/{ugyId}` (RectificationPostDto)
- Ha a döntés hiánypótlást kér: „Hiánypótló dokumentum csatolása” + beküldés
  (dokumentum kötelező), ugyanazzal a feltöltéssel és megerősítéssel.

### 2.4 Lista
- „Lezártak is” kapcsoló (`isLezartakIs`), hogy a régi/elfogadott igazolások is látszanak.

### Kamu KRÉTA
- Valódi típuskódok; `ideiglenesfajlok` multipart fogadás + naplózás; `ugy/kerelmek/{id}`
  részletek; egy kamu ügy hiánypótlást kérő döntéssel, hogy a 2.3 tesztelhető legyen;
  `ugy/alkalmazott/...`.

### Biztonság / tesztelés
- Ugyanazok a szabályok: valódi iskolához semmi, csak kamu. Unit teszt a body-ra
  (kötelező + egyéb csatolmány, hiánypótlás body), a feltöltés-válasz értelmezésére és a
  döntés-állapotok leképezésére; telefonon végigjárva kamuval (kép + PDF csatolás,
  részletek, hiánypótlás).
- Az 1. kör review-jából elhalasztott apróságok (KretaType ==, dupla koppintás védelem,
  azonnali „beküldve” visszajelzés) ebben a körben javulnak, mert az űrlap átépül.
