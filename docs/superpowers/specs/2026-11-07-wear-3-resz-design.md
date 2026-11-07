# Tinta Wear OS: 3. rész (gyorsnézeti lap és számlap-kiegészítő)

Dátum: 2026-11-07. Jóváhagyva a beszélgetésben, saját számlap nélkül.

## Cél

A mostani vagy következő óra az app megnyitása nélkül is látszódjon.

## Megoldás

Natív Kotlin, a mentett `timetable` adatból, hálózat és telefon nélkül.

- **Gyorsnézeti lap (Tile):** gyűrű, felső sor, tantárgy, hátralévő idő, terem, ugyanazokkal
  az állapotokkal és feliratokkal, mint a kezdőlap. Koppintásra megnyitja az appot.
  Frissesség: 60 másodperc, csak látható lapnál számol.
- **Számlap-kiegészítő:** `SHORT_TEXT` (visszaszámlálás és terem), `LONG_TEXT` (tantárgy és
  terem), `RANGED_VALUE` (gyűrű). A visszaszámlálást a számlap frissíti, így ez nem fogyaszt.
  Periódus: 5 perc. Mára nincs több óra esetén a következő ismert óra, ha nincs, üres.
- Új órarend érkezésekor mindkettő frissítést kér.

## Megfontolt megoldások

- Óránként előre kiszámolt idősor a Tile-ban: elvetve, a látható lap percenkénti frissítése
  egyszerűbb, és pontosabb.
- Saját számlap: külön projekt, most nem készül.

## Tesztelés

JUnit a napi állapotra, a feliratokra és a JSON-olvasásra, ugyanazokkal az esetekkel, mint a
Dart `day_state_test.dart`. Virtuális órán a lap és a kiegészítő kézi ellenőrzése.
