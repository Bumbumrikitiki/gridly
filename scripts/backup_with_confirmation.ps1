$ErrorActionPreference = 'Stop'

$answer = Read-Host 'Wykonać kopię zapasową projektu Gridly? (T/N)'
if ($answer -notin @('T','t','TAK','tak','Y','y','YES','yes')) {
    Write-Output 'Backup anulowany przez użytkownika.'
    exit 0
}

$scriptPath = Join-Path $PSScriptRoot 'daily_backup.ps1'
if (-not (Test-Path $scriptPath)) {
    throw "Nie znaleziono skryptu backupu: $scriptPath"
}

& $scriptPath
Write-Output 'Backup wykonany.'
