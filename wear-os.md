# Tinta Wear OS órára

Az óra-app a telefonos Tintából kapja az órarendet és az értesítéseket. Az órán nem kell
bejelentkezni a KRÉTA-ba.

## Mi kell hozzá?

- **Wear OS-es óra:** például Galaxy Watch4 vagy újabb, Pixel Watch. A régi, Tizen-es
  Galaxy órákon nem fut.
- **Androidos telefon**, amelyhez az óra párosítva van. iPhone-nal nem működik.
- **Tinta 1.6.1 vagy újabb a telefonon** a hivatalos GitHub-kiadásból, belépve, legalább egyszer frissítve. Régebbi verzióval is működik, de a Teendők oldal és a tanulmányi átlag hiányzik.
- **Számítógép**, az [Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools)
  csomaggal (ebben van az `adb` parancs).
- **Közös Wi-Fi** a számítógépnek és az órának. Ha nem találják egymást, próbáld telefonos
  hotspottal.

## 1. Fejlesztői mód bekapcsolása az órán

1. Nyisd meg a **Beállításokat** az órán.
2. Galaxy Watchon: **Az óráról → Szoftver**, majd koppints ötször a **Szoftververzióra**.
   Más órán általában: **Rendszer → Névjegy**, majd ötször a **Build-számra**.
3. Lépj vissza: megjelent a **Fejlesztői beállítások** menü.
4. Kapcsold be az **ADB-hibakeresést** és a **Vezeték nélküli hibakeresést**, és engedélyezd.

A menüpontok neve órától és nyelvtől függően kicsit eltérhet.

## 2. Az óra összekötése a számítógéppel

Ezt csak egyszer kell megcsinálni.

1. Az órán: **Fejlesztői beállítások → Vezeték nélküli hibakeresés → Új eszköz párosítása**.
   Az óra mutat egy IP-címet, egy portot és egy kódot.
2. A számítógépen nyiss terminált, és írd be az óra adataival:

       adb pair IP-CÍM:PORT

3. Add meg az órán látható kódot.
4. Lépj vissza a **Vezeték nélküli hibakeresés** oldalra. Itt egy másik portot látsz,
   ezt használd:

       adb connect IP-CÍM:MÁSIK-PORT

5. Ellenőrzés: az `adb devices` listájában ott kell lennie az órának.

## 3. Az app telepítése

Töltsd le a legfrissebb `tinta-wear-….apk` fájlt a [Releases](https://github.com/Pacuka/tinta/releases/latest) oldalról. Lépj abba a mappába, ahol a fájl van, és futtasd a saját fájlnévvel:

    adb install tinta-wear-1.6.1.apk

Ha az `adb devices` több eszközt is mutat, add meg, melyikre menjen:

    adb -s IP-CÍM:MÁSIK-PORT install tinta-wear-1.6.1.apk

Sikeres telepítés után a parancs ezt írja ki: `Success`.

## 4. Párosítás a telefonnal

1. A telefonon nyisd meg a Tintát: **Beállítások → Egyéb → WearOS**. Maradjon nyitva.
2. Az órán indítsd el a Tintát. Megjelenik egy hatjegyű kód.
3. A telefonon pár másodpercen belül felugrik a párosítás. Írd be az órán látható kódot.

Kész: az órán megjelennek a mai órák és az értesítések.

## 5. Számlap és gyorsnézet

- **Gyorsnézeti lap:** a számlapról húzz balra a lapok végéig, nyomd meg a **+** gombot, és válaszd a **Tinta** lapot.
- **Számlap-kiegészítő:** nyomd hosszan a számlapot, majd **Testreszabás → Kiegészítők**. Egy mezőben válaszd a **Tinta óra** lehetőséget. Nem minden számlapon van ilyen mező.

## 6. Frissítés

Új verziónál töltsd le az új `tinta-wear` fájlt, és ismételd meg a 3. lépést. Ha a géped már párosítva van, elég a 2. lépésből az `adb connect`. A beállításaid megmaradnak.

## 7. Ha végeztél

A biztonság kedvéért kapcsold ki az órán a **Vezeték nélküli hibakeresést**. Az app ettől
tovább működik.

## Ha valami nem megy

| Mit látsz? | Mit tegyél? |
| --- | --- |
| Az órán: „Nincs telefon kapcsolat” | Nézd meg, hogy az óra csatlakozik-e a telefonhoz a Galaxy Wearable vagy a Pixel Watch appban. |
| Nem ugrik fel a párosítás a telefonon | Nyisd meg a Tinta WearOS-beállításait, és várj pár másodpercet. Ez csak nyitott Tintával működik. |
| Az órán: „Csatlakozás a telefonhoz…” párosítás után | Frissítsd az adatokat a telefonos Tintában, majd koppints az **Újrapróbálás** gombra. |
| Üres az óra, pedig van óra aznap | A telefonon: **Beállítások → Egyéb → WearOS → Manuális szinkronizálás**. |
| `adb pair` vagy `adb connect` hibát ír | Kapcsold ki és be a Vezeték nélküli hibakeresést, majd próbáld újra. A portok ilyenkor változnak. |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Már van az órán más aláírású Tinta. Töröld (`adb uninstall hu.pacuka.tinta`), majd telepítsd újra. |
