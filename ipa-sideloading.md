# Tinta telepítése iPhone-ra – lépésről lépésre

A Tinta nincs fent az App Store-ban, ezért kerülőúton kell feltenni („sideload”).
Nem bonyolult, de **elsőre kb. 20–30 perc**. Utána már csak pár koppintás.

## Mi kell hozzá?

- ✅ az iPhone-od + a **töltőkábele**
- ✅ egy **számítógép** (Windows vagy Mac) – csak az első telepítéshez és a frissítéshez
- ✅ az **Apple ID-d** (ugyanaz, amivel az App Store-ba belépsz) + a jelszava
- ✅ a gép és a telefon legyen **ugyanazon a wifin**

> ⚠️ **Fontos tudni:** ingyenes Apple ID-vel az Apple **7 napig** engedi futni az
> így telepített appokat. Utána a Tinta nem indul el, amíg nem „frissíted”
> (lásd a 4. lépést – fél perc). **Az adataid ilyenkor sem vesznek el.**

---

## 1. Töltsd le a Tintát (a telefonon)

1. Nyisd meg ezt a linket **az iPhone-on, Safariban**:
   **https://github.com/Pacuka/tinta/releases/latest**
2. Görgess le az **Assets** részhez, és koppints a **`Tinta.ipa`** fájlra.
3. Ha kérdezi, koppints a **Letöltés** gombra.
   A fájl a **Fájlok** app → **Letöltések** mappába kerül. Ennyi, most hagyd ott.

## 2. AltStore feltelepítése (csak egyszer kell)

Az AltStore egy kis app, ami „aláírja” a Tintát az Apple ID-ddel, hogy az iPhone elfogadja.

### Ha Windows-od van

1. Töltsd le és telepítsd ezt a kettőt **az Apple oldaláról** (NEM a Microsoft Store-ból,
   onnan nem működik):
   - iTunes: https://www.apple.com/itunes/download/win64
   - iCloud: https://updates.cdn-apple.com/2020/windows/001-39935-20200911-1A70AA56-F448-11EA-8CC0-99D41950005E/iCloudSetup.exe
   > Ha már fent van iTunes vagy iCloud a Microsoft Store-ból, előbb töröld le őket.
2. Töltsd le az **AltServert**: https://cdn.altstore.io/file/altstore/altinstaller.zip
   Csomagold ki, és futtasd a benne lévő `Setup.exe`-t.
3. Start menüben keress rá: **AltServer** → jobb klikk → **Futtatás rendszergazdaként**.
   (Látszólag nem történik semmi – a jobb alsó sarokban, a tálcán lesz egy kis ikonja,
   lehet, hogy a **^** nyíl alatt.)
4. Dugd be az iPhone-t kábellel, oldd fel. Ha a telefon kérdezi: **„Megbízol a
   számítógépben?” → Megbízom**, és írd be a kódodat.
5. Nyisd meg az **iTunes**-t, válaszd ki a telefont (kis telefon ikon bal fent), és
   pipáld be: **„Szinkronizálás ezzel az iPhone-nal Wi-Fi-n keresztül”** → **Alkalmaz**.
6. Kattints a tálcán az **AltServer ikonra** → **Install AltStore** → a te iPhone-od.
7. Add meg az Apple ID-det és a jelszavad. (Ezt az AltServer csak az Apple-nek küldi el.)
8. Várj, amíg kiírja, hogy sikerült (1–2 perc).

### Ha Maced van

1. Töltsd le az AltServert: https://altstore.io (lent: *Download AltServer for macOS*),
   és húzd az **Alkalmazások** mappába, majd indítsd el.
   Fent a menüsorban megjelenik egy kis rombusz ikon.
2. Dugd be az iPhone-t, a telefonon: **Megbízom** + kód.
3. Finderben kattints a telefonodra, és pipáld be:
   **„iPhone megjelenítése Wi-Fi-kapcsolat esetén”** → **Alkalmaz**.
4. Menüsor ikon → **Install AltStore** → a te iPhone-od → Apple ID + jelszó.

### Utána a telefonon (mindkét esetben)

1. **Beállítások → Általános → VPN és eszközkezelés** → koppints az Apple ID-dre →
   **Megbízom**.
2. **Beállítások → Adatvédelem és biztonság → Fejlesztői mód** → kapcsold be.
   A telefon újraindul, utána még egyszer rákérdez → **Bekapcsolás**.
   (Ha nem látod ezt a menüt, húzd ki és dugd vissza a kábelt, és nézd meg újra.)

Most már van egy **AltStore** ikon a kezdőképernyőn. 🎉

## 3. A Tinta feltelepítése

> A gépen fusson az AltServer, és a telefon legyen ugyanazon a wifin (vagy kábelen).

1. Nyisd meg az **AltStore** appot → alul **My Apps**.
2. Bal fent koppints a **+** gombra.
3. Keresd meg a **Letöltések** mappában a **`Tinta.ipa`**-t, és koppints rá.
4. Ha kéri, add meg újra az Apple ID-det. Pár perc, és a Tinta ott lesz a kezdőképernyőn.

## 4. Frissítés 7 naponta (fontos!)

Az AltStore a **My Apps** fülön mutatja, hány nap van még hátra.

- **Kézzel:** a gépen fusson az AltServer, legyetek egy wifin →
  **AltStore → My Apps → Refresh All**. Fél perc.
- **Automatikusan:** ha a gépen fut az AltServer és egy wifin vagytok, az AltStore
  időnként magától is frissít a háttérben.

Ha lejárt és nem indul a Tinta: semmi baj, csak csináld meg a Refresh All-t.

**Új Tinta verzió:** töltsd le újra a `Tinta.ipa`-t (1. lépés), és telepítsd ugyanúgy
(3. lépés) – a régi felülíródik, az adatok megmaradnak.

---

## Gyakori hibák

| Mit látsz? | Mit csinálj? |
|---|---|
| Az AltServer nem látja a telefont | A telefon legyen feloldva, a kábel bedugva; Windowson az iTunes-ban legyen bepipálva a Wi-Fi szinkron, és az AltServer rendszergazdaként fusson. |
| „Could not find AltServer” | A gépen nem fut az AltServer, vagy nem ugyanazon a wifin vagytok. Dugd be kábellel, úgy biztos megy. |
| „Untrusted Developer” / nem indul az app | Beállítások → Általános → VPN és eszközkezelés → Megbízom. |
| „Maximum number of apps” | Ingyenes Apple ID-vel egyszerre csak **3 saját app** lehet fent (az AltStore is számít). Törölj egyet a My Apps-ban. |
| Nem indul a Tinta egy hét után | Lejárt a 7 nap → AltStore → My Apps → Refresh All. |
| Fejlesztői mód menü nincs | Előbb telepítsd az AltStore-t (2. lépés), utána jelenik meg. |

## Más módszerek

A fenti AltStore-os út a legbiztosabb, de van más is. Mindegyikhez **ingyenes Apple ID**
kell, és mindegyiknél él a **7 napos** frissítés meg a **max. 3 app** szabály
(ezt az Apple szabja meg, nem a programok).

| Módszer | Gép kell? | Mire jó? |
|---|---|---|
| **AltStore** (fent leírva) | első telepítéshez + frissítéshez (wifin is megy) | a legismertebb, sok leírás van hozzá |
| **Sideloadly** – https://sideloadly.io | igen (Windows/Mac) | a legegyszerűbb: csak behúzod a `Tinta.ipa`-t a programba, beírod az Apple ID-t, kész. Be lehet állítani, hogy magától frissítsen, ha a telefon ugyanazon a wifin van. Windowson ugyanúgy az Apple oldaláról letöltött iTunes + iCloud kell hozzá. |
| **SideStore** – https://sidestore.io | csak **egyszer**, az elején | utána a 7 napos frissítés a telefonon megy, gép nélkül (egy kis „VPN” appot kell hozzá bekapcsolni). Haladóbbaknak, a beállítás kicsit macerásabb. |

## „Nem akarok 7 naponta frissíteni” – mik a lehetőségek?

Érthető. Ezek léteznek, de mindegyiknek ára van:

| Megoldás | Meddig megy? | Mennyibe kerül? | Mi a gond vele? |
|---|---|---|---|
| **Fizetős tanúsítvány** (webshopok árulják, a telefonod azonosítóját /UDID/ felveszik egy fejlesztői fiókba) | kb. 1 év | kb. 10–25 €/év | Egy idegen cég fiókjától függsz: ha az Apple letiltja, minden app leáll (a jobb boltok ilyenkor adnak újat). Elfogadható, ha tudod, mit veszel. |
| **Ingyenes, közös tanúsítványok + „DNS profil”** (pl. WSF, ESign „anti-revoke”, Scarlet, GBox) | ahogy épp sikerül – hetek, hónapok | ingyen | **Nem ajánlott.** Ezek több ezer ember között megosztott, gyakran kiszivárgott céges tanúsítványok, bármikor letilthatják őket. A DNS profil telepítése után ráadásul **minden** weboldal-cím, amit a telefonod megnyit, egy ismeretlen szerveren megy át. A Tintában KRÉTA-belépés van – ide ez nem való. |
| **Saját Apple fejlesztői fiók** | 1 év | 99 $/év | Átlagfelhasználónak nem éri meg. (Ha a Tintának egyszer lesz ilyen, a barátok kaphatnak 1 évig működő verziót – ha így lesz, ide beírom.) |

**Tipp, hogy a 7 nap ne legyen macera:** az AltStore és a Sideloadly is tud **magától**
frissíteni, ha a gépen fut a program, és a telefon ugyanazon a wifin van (pl. otthon
este). Ha ezt beállítod, gyakorlatilag nem kell vele foglalkoznod.

## És az EU-s megoldások?

Az EU-s szabályozás (DMA) miatt az EU-ban vett/használt iPhone-okon (iOS 17.4-től)
vannak **alternatív app boltok** (pl. **AltStore PAL**, évi kb. 1,5 €), és appot
weboldalról is lehet telepíteni. **A Tinta ezekkel sajnos (még) nem tehető fel:**
oda csak olyan app kerülhet, amit az Apple előtte ellenőrzött („hitelesített”), ehhez
pedig a fejlesztőnek fizetős Apple fejlesztői fiók kell (évi ~99 $). Ha a Tinta egyszer
odakerül, ide beírom. Addig a fenti módszerek közül válassz.

> Az AltStore PAL-ból fel lehet tenni a sima AltStore-t gép nélkül, de a Tinta
> aláírásához ott is kell egyszer egy számítógép, úgyhogy nem lesz tőle egyszerűbb.

## Kérdés, hiba?

Írj nekem, vagy nyiss hibajegyet: https://github.com/Pacuka/tinta/issues

> 🔒 A „gép nélkül, örökre, ingyen” megoldásokról (ESign, WSF, Scarlet, GBox…) lásd
> fent: bármikor leállhatnak, és a DNS profiljuk miatt nem tudhatod, ki látja, mit
> csinálsz a telefonon. Ha teheted, maradj az AltStore-nál vagy a Sideloadly-nél.
