<h1 align="left">
<img src="folio/assets/icons/ic_rounded.png" alt="Tinta ikon" width="30px" style="vertical-align: middle;">
<span style="vertical-align: middle;">Tinta</span>
</h1>

### Nem hivatalos e-napló alkalmazás az e-KRÉTA rendszerhez – tanulóktól, tanulóknak.

> A Tinta **nem hivatalos** alkalmazás, nem áll kapcsolatban az e-KRÉTA rendszer
> fejlesztőjével és üzemeltetőjével (eKRÉTA Informatikai Zrt.). Az „e-KRÉTA” név a
> tulajdonosáé. Használata saját felelősségre történik.

## Letöltés

- **Android:** a legfrissebb APK a [Releases](https://github.com/Pacuka/tinta/releases/latest) oldalon
  (`arm64` a legtöbb mai telefonra, `armeabi` a régebbiekre).
- **iPhone:** a `Tinta.ipa` ugyanott; telepítés AltStore-ral, lásd az
  [iPhone-os útmutatót](ipa-sideloading.md).

Androidon az app magától szól, ha új verzió érhető el.

> **Xiaomi / Redmi / POCO:** hogy az értesítések megbízhatóan jöjjenek, a
> *Beállítások → Alkalmazások → Tinta* menüben kapcsold be az **Automatikus indítást**,
> az **Akkumulátorkímélőnél** pedig válaszd a **Nincs korlátozás** lehetőséget.

## Mit tud?

- Jegyek, átlagok, statisztika, jegykalkulátor
- Órarend, házik (a beírás pontos idejével), számonkérések, hiányzások, üzenetek
- Értesítés új jegyről, üzenetről, házi feladatról és órarend-változásról –
  push-szerver nélkül, minden a telefonon fut
- Az appban megnyitott üzenet a KRÉTÁ-ban is olvasottá válik
- Belépés captchával is (ha a KRÉTA ellenőrzést kér)
- Saját témák (Kobalt, Fekete-sárga, Petrol, Material You), névnapi és szülinapi köszöntés

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

A Tinta fejlesztésében mesterséges intelligencia (Claude) segít, de **emberi
felügyelet mellett**, nem „vaktában összegenerálva”:

- Arról, hogy mi kerüljön az appba, hogyan nézzen ki és mikor jelenjen meg, ember dönt.
- Minden változtatást valódi telefonon, saját KRÉTA-fiókkal kipróbálunk, mielőtt kiadjuk.
- Automatikus tesztek futnak, és a kód biztonsági átnézésen is átment
  (pl. titkosított kapcsolat ellenőrzése, a bejelentkezési adatok védelme).
- Az AI a kódírást gyorsítja, a felelősség és az ellenőrzés emberi.

## Honnan származik?

A Tinta a [Folio](https://github.com/Zan1456/folio) (Zan) továbbfejlesztése, ami a
Filc / reFilc / Firka-Legacy alkalmazásokra épül. Köszönet minden korábbi fejlesztőnek!

Licenc: [AGPL-3.0](LICENSE.md)

Hibát találtál? Írj egy [hibajegyet](https://github.com/Pacuka/tinta/issues).
