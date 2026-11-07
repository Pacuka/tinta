# Tinta Wear OS: új dizájn (1. rész)

Dátum: 2026-11-07. Jóváhagyott tervek: `.superpowers/brainstorm/301159-1794065041/content/` (`fooldal.html`, `kepernyok.html`).

## Cél

A Tinta olyan természetes legyen az órán, mint a Samsung és a Google saját appjai, de
maradjon a Tinta arculata. Egy pillantásból látszódjon a mostani vagy a következő óra.
A stílust és a működést követjük, logót, ikont és képet nem másolunk.

Az 1. rész csak az órát (`folio_wear`) érinti, és a kiadott 1.6.0-s telefonos Tintával működik.

## Nem része ennek a körnek

- 2. rész: holnapi és heti órarend, házik, dolgozatok, jegyek, jegyátlag, „2 új jegy”
  jelzés, rezgés, a telefonos téma átvétele. Ezekhez a telefonos app frissítése is kellhet.
- 3. rész: számlap-kiegészítő és gyorsnézeti lap (natív kód).

## Mozgás az appban

Vízszintes lapozás három lap között:

1. Kezdőlap: gyűrű, alatta az órarend (Tintacsík), egy görgethető lapon
2. Értesítések
3. Beállítások

- A korona és az ujj függőlegesen **csak az aktuális lapon görget**. A lista végén nem
  ugrik át másik lapra. Ez megszünteti a felhasználó által jelentett hibát, hogy az
  órarend görgetésekor véletlenül átcsúszik a beállításokba.
- Balra húzás: következő lap. A kezdőlapon jobbra húzás: kilépés az appból.
- Kikerül a `main.dart` túlgörgetésre és koronára épülő lapváltása.
- A jobbra húzásos kilépést emulátoron ellenőrizni kell, mert a Flutter lapozója
  elnyelheti a mozdulatot. Ha nem megy megbízhatóan, a kilépés a fizikai gombbal marad,
  és ezt jelezzük a felhasználónak.

## Kezdőlap (gyűrű)

A kijelző szélén körbefutó gyűrű, középen a szöveg. Egy teljes kijelzőnyi magas.

| Állapot | Mikor | Felső sor | Középen | Alatta | Gyűrű |
| --- | --- | --- | --- | --- | --- |
| Óra alatt | Most folyik egy nem elmaradt óra | „3. óra” | Tantárgy + hátralévő perc | Terem, „Utána: tárgy, terem” | Kék, az óra haladása |
| Szünet | Két nem elmaradt óra között | „Szünet” | Perc a következőig + tantárgy | Terem | Zöldeskék, a szünet haladása |
| Első óra előtt | Ma van még óra, de nem volt | „Első óra” | Tantárgy + kezdés időpontja, 60 percen belül hátralévő perc | Terem | Üres |
| Mára végeztél | Ma volt óra, de már nincs több | | „Mára végeztél” | Következő ismert óra, ha van | Nincs |
| Ma nincs óra | Mára nincs nem elmaradt óra | | „Ma nincs órád” | Következő ismert óra, ha van | Nincs |

- Az elmaradt órát a mostani és a következő óra számításánál kihagyjuk.
- A következő ismert óra csak a kapott adatból jön: ha nincs ilyen, a sor nem látszik.
- A kijelző percenként frissül, folyamatos animáció nincs, hogy kímélje az akkumulátort.
- A terem a tervtől eltérően változatlan formában, ajtóikonnal jelenik meg, mert a
  KRÉTA-ban lehet „Tornaterem” is, és a „12-es” toldalékot nem lehet biztonságosan
  képezni. A hosszú név `…`-re vágódik.

## Órarend (Tintacsík)

A gyűrű alatt függőleges tintavonal, rajta a mai órák. A felhasználó döntése szerint minden óra kártya a vonal mellett: a mostani kobaltkék, az elmaradt pirosas, a helyettesítés narancsos.

- Elmúlt óra: halvány. Mostani: nagyobb, kék pont, hátralévő perc és terem.
- Elmaradt: piros, áthúzott, „Elmarad”. Helyettesítés: narancs, a helyettes neve.
- Házi és dolgozat jelzése megmarad kis ikonnal.
- Ha ma nincs óra, a jelenlegi működés marad: a kapott hét órái naponként.

## Értesítések és beállítások

- Értesítések: tisztább sorok, a jegy nagy körben. Az időpont ma óra:perc, korábban dátum.
- Beállítások: „Szinkronizálás most”, telefon állapota, „Leválasztás” megerősítéssel.
- Az „Offline mód” megszűnik. A korábban elmentett értékét figyelmen kívül hagyjuk, hogy
  egy bekapcsolva hagyott óra is szinkronizáljon.

## Megjelenés

- Fekete háttér (OLED). Színek egy helyen, új `lib/theme/wear_theme.dart` fájlban:
  kobalt `#2440C8`, tintakék `#7C93FF` és `#A9B8FF`, szünet `#6FD6C0`, elmaradt `#E57373`,
  helyettesítés `#FFB74D`.
- A kék kártyafelületek a mockup szerint, a kerekítés nagy, a fontos szöveg nagy méretű.
- A párosító és a csatlakozó képernyő működése nem változik, csak a színei.

## Felépítés

- `lib/models/day_state.dart`: tiszta függvény, a mai állapotot adja a leckékből és az
  időből. Nem függ a Fluttertől, így jól tesztelhető.
- `lib/widgets/progress_ring.dart`: a gyűrű rajzolása.
- `lib/screens/home_screen.dart`: gyűrű és Tintacsík, a részeik külön widgetekben.
- `lib/main.dart`: vízszintes lapozás, a korona az aktuális lap listáját görgeti.
- `lib/providers/wear_data_provider.dart`: az offline mód kivétele.

## Hibakezelés

- Hiányos vagy üres adatnál a kezdőlap a „Ma nincs órád” állapotot mutatja, nem omlik össze.
- Megszakadt kapcsolatnál a mentett adatból működik tovább, ahogy eddig.
- Hosszú tantárgy- és teremnév sehol sem takarhat ki más elemet.

## Tesztelés

- Egységtesztek a `day_state.dart` minden állapotára, az elmaradt órákra és a határidőkre
  (pontosan az óra kezdetekor és végén).
- Widget-teszt: a lista végén továbbgörgetve a lap nem vált.
- A meglévő párosítási tesztek továbbra is átmennek.
- Kézi ellenőrzés a virtuális órán kitalált adatokkal: minden képernyő, nagy és kis kerek
  kijelző, hosszú nevek, görgetés és lapozás. A felhasználó is kipróbálja.
- Igazi órán: korona, jobbra húzás, párosítás, a telefonnal együtt. Az öcs órája kell hozzá.
