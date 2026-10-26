# Hozzájárulás a Tintához

Köszönjük, ha segítesz! Hibát a [hibajegyek](https://github.com/Pacuka/tinta/issues)
között jelezhetsz; ha kódot küldenél, nyiss egy Pull Requestet a `main` ágra, és
írd le benne, mit változtattál (képernyőképpel, ha a felületet érinti).

Nagyobb változtatás előtt érdemes előbb egy hibajegyben megbeszélni az ötletet.

## Fejlesztői környezet

- **Flutter 3.47.5** (stable)
- **JDK 17** az Android-építéshez
- iOS-hez macOS és Xcode 26 (vagy a GitHub Actions `iOS (unsigned IPA)` folyamata)

## Építés

```bash
git clone https://github.com/Pacuka/tinta.git
cd tinta/folio
flutter pub get

# Android (teszt): saját debug kulccsal írja alá
flutter build apk --debug --flavor github

# Android (kiadás)
flutter build apk --release --flavor github --split-per-abi
```

Kiadási aláíráshoz hozz létre egy saját kulcsot, és a `folio/android/key.properties`
fájlban add meg (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`). Ha ez a
fájl hiányzik, a kiadás debug kulccsal készül.

> A kulcsfájlt (`.jks`) és a `key.properties`-t **soha ne töltsd fel** – a
> `.gitignore` ki is zárja őket.

## Tesztek

```bash
cd folio && flutter test
```

## Eredet

A Tinta a [Folio](https://github.com/Zan1456/folio) továbbfejlesztése, ami a
Filc / reFilc / Firka-Legacy alkalmazásokra épül. Licenc: [AGPL-3.0](LICENSE.md).
