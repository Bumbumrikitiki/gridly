# Gridly Functions (subskrypcje Google Play)

Ten katalog zawiera backendowy szkielet walidacji subskrypcji i obsługi RTDN.

## Co robi backend

- `verifyAndroidSubscription` (callable):
  - przyjmuje `packageName` i `purchaseToken`,
  - pyta Google Play Developer API o status subskrypcji,
  - aktualizuje `users/{uid}.isPro` oraz `users/{uid}.entitlement`.
- `handlePlayRtdn` (Pub/Sub):
  - nasłuchuje topic `play-rtdn`,
  - po notyfikacji RTDN ponownie sprawdza status i odświeża entitlement.

## Wymagania

1. Firebase project z włączonym Cloud Functions i Firestore.
2. Połączony projekt Google Cloud z dostępem do Android Publisher API.
3. Konto serwisowe Functions z uprawnieniami do Android Publisher API.
4. Topic Pub/Sub `play-rtdn` (wskazany także w Play Console RTDN).

## Minimalny deployment

```bash
cd functions
npm install
firebase deploy --only functions
```

## Ważne

- Funkcje są ustawione w regionie `europe-central2`; trzymaj ten sam region po stronie aplikacji.
- Identyfikator pakietu użyty w aplikacji: `com.gridlytools.app`.
- Produkty subskrypcji w Play Console muszą istnieć i odpowiadać ID z aplikacji:
  - `gridly_pro_monthly`
  - `gridly_pro_yearly`

## Dalsze utwardzenie produkcyjne

- Dodać App Check i ograniczenia wywołań callable.
- Dodać audyt logów i alerting na błędy walidacji.
- Rozszerzyć model entitlement o historię transakcji i daty odnowień.
