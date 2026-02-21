param(
  [Parameter(Mandatory = $true)] [string]$ApiKey,
  [Parameter(Mandatory = $true)] [string]$AppId,
  [Parameter(Mandatory = $true)] [string]$MessagingSenderId,
  [Parameter(Mandatory = $true)] [string]$ProjectId,
  [string]$AuthDomain = "",
  [string]$StorageBucket = "",
  [string]$MeasurementId = ""
)

flutter run -d chrome `
  --dart-define=FIREBASE_WEB_API_KEY=$ApiKey `
  --dart-define=FIREBASE_WEB_APP_ID=$AppId `
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=$MessagingSenderId `
  --dart-define=FIREBASE_WEB_PROJECT_ID=$ProjectId `
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=$AuthDomain `
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET=$StorageBucket `
  --dart-define=FIREBASE_WEB_MEASUREMENT_ID=$MeasurementId
