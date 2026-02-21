# Firebase Mobile Setup (Android + iOS)

## 1) Android

1. W Firebase Console dodaj aplikację Android z package name:
   - `com.gridlytools.app`
2. Pobierz `google-services.json`.
3. Skopiuj plik do:
   - `android/app/google-services.json`

## 2) iOS

1. W Firebase Console dodaj aplikację iOS z bundle id (ustawionym w Xcode).
2. Pobierz `GoogleService-Info.plist`.
3. Skopiuj plik do:
   - `ios/Runner/GoogleService-Info.plist`

## 3) Już skonfigurowane w projekcie

- Android plugin Google Services jest włączony:
  - `android/settings.gradle.kts`
  - `android/app/build.gradle.kts`
- Web może działać przez `--dart-define` (patrz `scripts/run_web_with_firebase.ps1`).

## 4) Weryfikacja

Uruchom check:

```powershell
.\scripts\check_firebase_mobile.ps1
```

Następnie:

```powershell
flutter clean
flutter pub get
flutter run -d android
```

## 5) Uwaga

Bez powyższych plików logowanie Firebase/subskrypcje będą niedostępne na odpowiedniej platformie.
