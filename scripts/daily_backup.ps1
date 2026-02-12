$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$backupRoot = 'C:\Users\sowin\project_backups'
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$zipPath = Join-Path $backupRoot "gridly_$timestamp.zip"
$hashPath = Join-Path $backupRoot "gridly_$timestamp.sha256.txt"

if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot | Out-Null
}

$excludePattern = '\\(build|\.dart_tool|\.git|project_backups)\\'
$files = Get-ChildItem -Path $projectRoot -Recurse -File |
    Where-Object { $_.FullName -notmatch $excludePattern }

if (-not $files -or $files.Count -eq 0) {
    throw 'Brak plików do archiwizacji.'
}

Compress-Archive -Path $files.FullName -DestinationPath $zipPath -CompressionLevel Optimal
$hash = Get-FileHash -Path $zipPath -Algorithm SHA256
"File: $zipPath`nSHA256: $($hash.Hash)" | Set-Content -Path $hashPath -Encoding UTF8
