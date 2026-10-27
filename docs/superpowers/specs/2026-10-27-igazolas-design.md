# Igazolás beküldése (szülői fiók) – design

Dátum: 2026-10-27 · Állapot: jóváhagyásra vár

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
  `CaseProvider` (vagy a meglévő minták szerinti helper) a fenti hívásokkal. A POST body
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
- Valódi KRÉTA: csak olvasó hívások (típusok, gyerekadatok, kérelemlista) próbálhatók a
  felhasználó engedélyével; **beküldés soha** engedély nélkül.
