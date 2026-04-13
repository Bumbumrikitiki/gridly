# Automated daily backup with Git tagging and cloud upload
# Runs 02:00 AM every day via Windows Task Scheduler
# Usage: powershell -ExecutionPolicy Bypass -File auto_backup_s1.ps1

param(
    [string]$BackupDir = "D:\Dom\Gridly\backups",
    [string]$ProjectDir = "d:\Dom\Gridly\moja budowa 8.04.26 v2",
    [switch]$UploadToCloud = $false,
    [string]$CloudPath = ""
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dateTag = Get-Date -Format "yyyy-MM-dd"
$backupFile = "$BackupDir\gridly_backup_$timestamp.tar.gz"
$backupLogFile = "$BackupDir\backup_$dateTag.log"

# Create backup directory if not exists
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

# Initialize log file
$logMessage = "=== Gridly Backup - $timestamp ===" | Tee-Object -FilePath $backupLogFile -Append
Write-Host $logMessage

try {
    Push-Location $ProjectDir
    
    # 1. Git status check
    $gitStatus = & git status --porcelain
    if ($gitStatus) {
        Write-Host "⚠️  Uncommitted changes detected. Stashing..." -ForegroundColor Yellow
        & git stash push -m "auto-stash-$timestamp" | Tee-Object -FilePath $backupLogFile -Append
    }
    
    # 2. Create backup archive
    Write-Host "📦 Creating backup archive: $backupFile" -ForegroundColor Cyan
    $excludePatterns = @(".git", "build", ".dart_tool", "node_modules", ".gradle", ".idea") -join "|"
    
    # Using 7-Zip if available, fallback to PowerShell compression
    if (Get-Command 7z -ErrorAction SilentlyContinue) {
        & 7z a -ttar -so . | 7z a -si -tgzip $backupFile | Tee-Object -FilePath $backupLogFile -Append
        $backupSize = (Get-Item $backupFile).Length / 1MB
        Write-Host "✓ Backup created: $([math]::Round($backupSize, 2)) MB" -ForegroundColor Green
    } else {
        Write-Host "Note: 7-Zip not found, using native PowerShell compression" -ForegroundColor Yellow
        Compress-Archive -Path . -DestinationPath ($backupFile -replace "\.tar\.gz$", ".zip") -Force
        $backupFile = $backupFile -replace "\.tar\.gz$", ".zip"
    }
    
    # 3. Create Git tag
    $tagName = "backup/daily-$timestamp"
    & git tag $tagName
    Write-Host "🏷️  Git tag created: $tagName" -ForegroundColor Green | Tee-Object -FilePath $backupLogFile -Append
    
    # 4. Upload to cloud if configured
    if ($UploadToCloud -and $CloudPath) {
        Write-Host "☁️  Uploading to cloud: $CloudPath" -ForegroundColor Cyan
        if ($CloudPath -match "^s3://") {
            # AWS S3 upload (requires AWS CLI)
            $bucket = $CloudPath -replace "^s3://", "" -replace "/.*", ""
            $key = "{0}/{1}" -f ($CloudPath -replace "s3://[^/]+/", ""), (Split-Path $backupFile -Leaf)
            & aws s3 cp $backupFile "s3://$bucket/$key" --region eu-central-1
        } elseif (Test-Path $CloudPath) {
            # Local network or NAS backup
            Copy-Item $backupFile $CloudPath -Force
        }
        Write-Host "✓ Upload complete" -ForegroundColor Green | Tee-Object -FilePath $backupLogFile -Append
    }
    
    # 5. Cleanup old backups (keep last 7 days)
    Write-Host "🧹 Cleaning up old backups..." -ForegroundColor Yellow
    $cutoffDate = (Get-Date).AddDays(-7)
    Get-Item "$BackupDir\gridly_backup_*.tar.gz", "$BackupDir\gridly_backup_*.zip" -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -lt $cutoffDate } | 
        Remove-Item -Force -Verbose | Tee-Object -FilePath $backupLogFile -Append
    
    # 6. Summary
    $summaryMsg = @"
✅ Backup completed successfully!
   File: $backupFile
   Size: $([math]::Round((Get-Item $backupFile).Length / 1MB, 2)) MB
   Tag: $tagName
   Log: $backupLogFile
"@
    Write-Host $summaryMsg -ForegroundColor Green
    Write-Host $summaryMsg | Tee-Object -FilePath $backupLogFile -Append
    
} catch {
    $errorMsg = "❌ Backup failed: $_`nStack: $($_.ScriptStackTrace)"
    Write-Host $errorMsg -ForegroundColor Red
    Write-Host $errorMsg | Tee-Object -FilePath $backupLogFile -Append
    exit 1
} finally {
    Pop-Location
}
