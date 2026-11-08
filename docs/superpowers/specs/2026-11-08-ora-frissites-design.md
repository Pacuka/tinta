# Óra-app frissítése a telefonról — terv

## Miért

Az óra-app (`folio_wear`) ma csak gépről, `adb install`-lal kerül fel és
frissül (wear-os.md). Ez a legtöbb diáknak túl bonyolult, ezért minden új
verziónál lemaradnak. Cél: ha van új óra-verzió, a telefonos Tinta töltse le,
küldje át, és az órán egy jóváhagyással feltelepüljön.

## Célok

- A telefon tudja, milyen verzió fut az órán, és szól, ha van újabb.
- Egy gombnyomással letölti a GitHub-kiadásból a `tinta-wear-*.apk`-t, és
  átküldi az órára.
- Az órán a rendszer telepítőablaka jön fel; jóváhagyás után frissül az app.
- A telefonon látszik, hol tart: letöltés, átküldés, telepítés, kész vagy hiba.

## Nem cél

- Csendes, jóváhagyás nélküli frissítés (az Android nem engedi).
- Első telepítés a telefonról. Ehhez már futnia kell az óra-appnak, ami
  fogadja a fájlt, úgyhogy az első telepítés marad `adb`-vel.
- Automatikus frissítés a háttérben; csak gombnyomásra indul.

## Amit nem szabad elrontani

- Az óra-app továbbra se menjen ki az internetre. Az adatvédelmi oldal ezt
  ígéri („az óra-app nem kapcsolódik a KRÉTA-hoz és az internethez”).
- Az óra csak a párosított telefonról fogadjon frissítést. A telepítésnél az
  Android amúgy is ellenőrzi, hogy ugyanazzal a kulccsal van-e aláírva, mint a
  fent lévő app, így idegen APK-val nem lehet lecserélni.
- Óra nélküli telefonon semmi ne változzon (se gomb, se hibaüzenet).

## Lehetőségek, amiket megnéztünk

1. **A telefon tölti le és küldi át (EZ LETT).** Az óra offline marad, az
   adatvédelmi szöveg igaz marad. Több kód kell (átküldés + telepítés az órán).
2. Az óra maga tölti le a GitHubról. Kevesebb kód, de az órának internet
   kellene, ami ellentmond az adatvédelmi oldalnak, és órán lassú is.
3. Csak értesítés a telefonon, a telepítés marad `adb`-vel. A legkevesebb
   munka, de pont a lényeget nem oldja meg.

A felhasználó az 1-est választotta (2026-11-08).

## Hogyan

**Verzió:** az óra a meglévő üzenetcsatornán (`/folio/...` útvonalak) elküldi
a telefonnak a saját verzióját (versionName és versionCode), például
csatlakozáskor és a telefon kérésére. A telefon ezt összeveti a legfrissebb
GitHub-kiadással, amelyikben van `tinta-wear` fájl (a meglévő
`UpdateProvider` által letöltött kiadáslistából).

**Telefon (Flutter + Kotlin):**
- A Beállítások óra-részében (`_buildWearSection`) új sor: „Óra-app: 1.6.1 —
  frissítés elérhető (1.6.2)” és egy „Frissítés” gomb. Ha az óra friss: csak
  a verzió látszik.
- A gomb letölti az APK-t a telefon ideiglenes mappájába (a meglévő
  letöltőkóddal), majd a `WearSyncManager` a Wearable `ChannelClient`-tel
  átküldi az órára (`/folio/wear-update` csatorna).
- Állapotok: letöltés (%) → átküldés → „Hagyd jóvá az órán” → kész / hiba.

**Óra (Kotlin):**
- `REQUEST_INSTALL_PACKAGES` engedély a manifestben.
- A `WearDataListenerService` fogadja a csatornát, de csak akkor, ha a küldő
  a párosított telefon. A fájlt az app saját mappájába menti.
- `PackageInstaller` munkamenettel telepít; a rendszer jóváhagyó ablakát
  (`STATUS_PENDING_USER_ACTION`) feldobja. Az eredményt visszaküldi a
  telefonnak, a fájlt utána törli.
- Ha az órán nincs engedélyezve az „ismeretlen forrás” ennek az appnak, a
  rendszer beállítóablakát nyitja meg, a telefonon pedig ez a tipp látszik.

**Tesztelés:** Dart egységtesztek a verzió-összevetésre és a
`tinta-wear` fájl kiválasztására. Végpontig az órás emulátoron
(tinta-wear AVD), párosítva a telefonos emulátorral vagy a Redmivel. Igazi
Galaxy Watch-on később, az öcs órájával; ha a Samsung tiltja, a gomb helyett
a telefon az `adb`-s leírásra mutat.

## A fejlesztőre bízva

- Pontos szövegek (magyar, angol, német), ikon, a sor kinézete.
- Hogy a letöltött APK-t a telefon meddig tartja meg (javaslat: a meglévő
  `cleanupOldUpdateApks` törli).
- Időkorlátok és újrapróbálás az átküldésnél.
