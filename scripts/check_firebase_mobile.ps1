$androidFile = "android/app/google-services.json"
$iosFile = "ios/Runner/GoogleService-Info.plist"

Write-Host "=== Firebase Mobile Config Check ===" -ForegroundColor Cyan

if (Test-Path $androidFile) {
  Write-Host "[OK] Android config found: $androidFile" -ForegroundColor Green
} else {
  Write-Host "[MISSING] Android config not found: $androidFile" -ForegroundColor Yellow
}

if (Test-Path $iosFile) {
  Write-Host "[OK] iOS config found: $iosFile" -ForegroundColor Green
} else {
  Write-Host "[MISSING] iOS config not found: $iosFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1) Firebase Console -> Project Settings -> Your Apps" 
Write-Host "2) Download google-services.json and place in android/app/"
Write-Host "3) Download GoogleService-Info.plist and place in ios/Runner/"
Write-Host "4) Run: flutter clean; flutter pub get"
Write-Host "5) Run app on Android/iOS"
