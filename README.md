<h1 align="left">
<img src="folio/assets/icons/ic_rounded.png" alt="Tinta ikon" width="30px" style="vertical-align: middle;">
<span style="vertical-align: middle;">Tinta</span>
</h1>

### Nem hivatalos e-napló alkalmazás az e-KRÉTA rendszerhez – tanulóktól, tanulóknak.

> A Tinta **nem hivatalos** alkalmazás, nem áll kapcsolatban az e-KRÉTA rendszer
> fejlesztőjével és üzemeltetőjével (Educational Development Informatikai Zrt.,
> korábban eKRÉTA Informatikai Zrt.). Az „e-KRÉTA” név a
> tulajdonosáé. Használata saját felelősségre történik.

## Letöltés

- **Android:** a legfrissebb APK a [Releases](https://github.com/Pacuka/tinta/releases/latest) oldalon
  (`arm64` a legtöbb mai telefonra, `armeabi` a régebbiekre).
- **iPhone:** a `Tinta.ipa` ugyanott; telepítés AltStore-ral, lásd az
  [iPhone-os útmutatót](ipa-sideloading.md).
- **Wear OS óra** (pl. Galaxy Watch): a Tinta óra-app a telefonos Tintától kapja az
  adatokat – a párosítás a telefonos app *Beállítások → Egyéb → WearOS* menüjében,
  az órán megjelenő kóddal történik.

Androidon az app magától szól, ha új verzió érhető el.

> **Xiaomi / Redmi / POCO:** hogy az értesítések megbízhatóan jöjjenek, a
> *Beállítások → Alkalmazások → Tinta* menüben kapcsold be az **Automatikus indítást**,
> az **Akkumulátorkímélőnél** pedig válaszd a **Nincs korlátozás** lehetőséget.

## Mit tud?

- Jegyek, átlagok, statisztika, jegykalkulátor
- Órarend, házik (a beírás pontos idejével), számonkérések, hiányzások, üzenetek
- Elmaradó óra és helyettesítés jól láthatóan jelölve (ki tartja az órát)
- Értesítés új jegyről, üzenetről, házi feladatról és órarend-változásról –
  push-szerver nélkül, minden a telefonon fut, órák előtt is ránéz
- Belépés a KRÉTA hivatalos oldalán (a jelszót nem a Tinta kéri be), captchával is
- Az appban megnyitott üzenet a KRÉTÁ-ban is olvasottá válik
- Saját dizájn: tintacsík minden oldalon, amit egy kis toll rajzol meg; témák
  (Kobalt, Fekete-sárga, Petrol, Üveg, Material You)
- Névnapi és szülinapi köszöntés, vicces napi köszöntések
- Szülői fiók: igazolás beküldése (akár orvosi papír fotójával), fogadóóra-foglalás,
  üzenet a tanároknak, több gyerek egy appban
- Tanév rendje (szünetek, tanítás nélküli napok), LÉP/NÉP-programok, kérdőívek
- Wear OS óra-app: mai órák, értesítések a csuklón

## Adatvédelem

A Tinta nem gyűjt semmilyen statisztikát, és magától nem küld hibajelentést. A
tanulmányi adataid csak a telefonod és a KRÉTA szerverei között közlekednek,
titkosított kapcsolaton. A bejelentkezési adatok nem kerülnek a telefon felhőmentésébe.

Más szerverhez csak ezekben az esetekben fordul az app:

- **GitHub:** új verzió keresése (személyes adat nélkül), illetve ha egy hibánál a
  „Hiba jelentése” gombot választod – ilyenkor egy előre kitöltött hibajegy nyílik
  meg, és beküldés előtt látod, mi kerül bele.
- **Firka szerver:** csak ha témát osztasz meg vagy töltesz le.
- **Google Fonts:** csak ha a beállításokban másik betűtípust választasz.

## Hogyan készül?

A Tinta kódjának nagy részét a Claude nevű AI írja. Én mondom meg, mit csináljon,
átnézem, és kiadás előtt kipróbálom. A Dartot még tanulom: a kódot nagyjából értem,
de nem minden részét látom át egyedül.

- Arról, hogy mi kerüljön az appba, hogyan nézzen ki és mikor jelenjen meg, én döntök.
- Kiadás előtt valódi telefonon, saját diák- és szülői fiókkal próbálom ki. Amit
  élesben nem lehet (pl. igazolás, fogadóóra-foglalás), azt egy tesztszerveren.
- Automatikus tesztek is futnak.

## Honnan származik?

A Tinta a [Folio](https://github.com/Zan1456/folio) (Zan) továbbfejlesztése, ami a
Filc / reFilc / Firka-Legacy alkalmazásokra épül. Köszönet minden korábbi fejlesztőnek!

Licenc: [AGPL-3.0](LICENSE.md)

Hibát találtál? Írj egy [hibajegyet](https://github.com/Pacuka/tinta/issues).
