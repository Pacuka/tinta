# Tinta Wear OS: 2. rész (szűkített)

Dátum: 2026-11-07. Előzmény: `2026-11-07-wear-ujdizajn-design.md`.

## Cél és indok

Az óra kiegészítője a telefonnak: amit pár másodperc alatt megnézel, az legyen rajta, a
részletekhez ott a telefon. A felhasználó kérése szerint a szűkebb változat készül, nem kell
sok funkció az órára.

A kezdőlapon a mostani óra, a hátralévő idő és az értesítések a lényeg, ezért a kezdőlapon
a hosszú tantárgynév nem vágódhat le.

## Mi készül

1. **Hosszú tantárgynév a kezdőlapon:** két sorba törik, és szükség esetén kisebb betűvel
   jelenik meg, de nem kap `…`-t, amíg két sorban elfér. Ez csak az órát érinti.
2. **Ma és Holnap váltó az órarend tetején.** A „Holnap” a következő tanítási nap:
   pénteken a hétfő, és ilyenkor a felirat a nap neve („hétfő”). Ha nincs ismert következő
   nap, a váltó nem látszik.
3. **Teendők oldal** a Kezdőlap és az Értesítések között. A következő 7 nap házijai és
   dolgozatai, határidő szerint: tantárgy, típus ikon, „Ma”, „Holnap” vagy a nap neve.
   Teljes szöveg nincs.
4. **Tanulmányi átlag az Értesítések tetején**, egy sorban: „Tanulmányi átlag: 4,32”. A
   kerekített tantárgyi jegyek átlaga, ugyanaz az érték, mint a telefonos Jegyek oldal
   „tárgyak átl.” jelzése.

Ha ma nincs óra, az órarend a következő tanítási napot mutatja, a múltbeli napokat soha.

Sorrend: Kezdőlap, Teendők, Értesítések, Beállítások.

## Nem készül

Jegyek oldal, teljes heti böngészés, telefonos téma átvétele, a házi teljes szövege az
órán, kipipálható teendők. A rezgéshez nem készül kód: a telefon értesítései jellemzően
maguktól átjönnek. Ezt igazi órán ellenőrizzük, és csak hiba esetén térünk vissza rá.

## Megfontolt megoldások

- **Két új oldal (Teendők, Jegyek):** elvetve, túl sok egy kiegészítő apphoz.
- **Minden az Értesítésekben:** elvetve, a teendők elvesznének a többi között.
- **Egy új oldal, az átlag az Értesítésekben:** ez készül, a felhasználó ezt választotta.

## Adatok a telefonról

A telefonos Tinta 1.6.1-re frissül.

- A szinkron a következő hetet is letölti, ha péntek, szombat vagy vasárnap van
  (`Week.current().next()`). Hibája nem állíthatja meg a többi szinkront.
- A `/folio/timetable` üzenet az aktuális és, ha van, a következő hét óráit is tartalmazza.
  A formátum nem változik.
- Új üzenet: `/folio/extras`, a mentett adatok között is tárolva, a szinkronkérésre és a
  reggeli szinkronra is elküldve:

```json
{
  "average": 4.32,
  "todos": [
    {"id": "h1", "type": "homework", "subject": "Matematika", "due": 1794000000000},
    {"id": "e1", "type": "exam", "subject": "Történelem", "due": 1794000000000}
  ]
}
```

- `average` `null`, ha nincs jegy. `todos` legfeljebb 15 elem, a mai naptól számított 7 napon
  belül, határidő szerint. A tantárgynevek a telefonos átnevezéseket követik, mint az órarendben.
- A teljes üzenet 100 KB alatt marad, ami a Wear üzenetküldés korlátja.

## Kompatibilitás

- **Új óra, régi telefon:** a Teendők oldal ezt írja: „Frissítsd a Tintát a telefonon”, az
  átlag nem látszik, a váltó csak akkor, ha van következő napi adat. Minden más működik.
- **Régi óra, új telefon:** a régi app naplózza és kihagyja az ismeretlen üzenetet.
- Az óra az `extras` adatot elmenti, és kapcsolat nélkül is megmutatja.

## Hibakezelés

- Hibás `extras` üzenetnél megmarad az előző adat, az app nem omlik össze.
- Üres lista: „Nincs teendő a következő 7 napban”.
- A lejárt teendő a nap végén kikerül, az óra a mentett listát maga is szűri.

## Tesztelés

- Telefon: egységteszt az `extras` összeállítására (7 napos határ, 15-ös limit, rendezés,
  jegy nélküli eset), és arra, hogy a következő hét csak péntektől vasárnapig töltődik le.
- Óra: tesztek a hosszú névre 192 és 227 pont széles kijelzőn, a váltóra (hétköznap, péntek,
  nincs következő nap), a Teendők oldal három állapotára, az átlag sorára és a hibás üzenetre.
- A telefonos és az órás tesztek külön is, egymás után is lefutnak.
- Virtuális órán kitalált adatokkal minden képernyő.
- Igazi órán: az új üzenet megérkezése, rezgés, korona, párosítás, görgetés folyamatossága.
  Valódi KRÉTA-adat csak a felhasználó saját fiókjával, az ő jóváhagyásával.

## Kiadás

Telefon és óra is 1.6.1. A kiadást és a feltöltést a felhasználó végzi. Kiadás előtt
frissül a telepítési útmutató.
