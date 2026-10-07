$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "       MERAJ3I - Shorebird Patch Script      " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. التأكد من المسار
$ProjectDir = "C:\meraj3i\myapp"
if ((Get-Location).Path -ne $ProjectDir) {
    if (Test-Path $ProjectDir) {
        Set-Location $ProjectDir
    } else {
        throw "Project directory $ProjectDir does not exist."
    }
}

# 2. توحيد بيئة العمل 
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.20.1"
$env:JAVA_TOOL_OPTIONS = "-Duser.language=en -Duser.country=US"

# 3. فحص الأدوات
Write-Host "Checking Dependencies..." -ForegroundColor Yellow
$null = shorebird --version 2>&1
if ($LASTEXITCODE -ne 0) { throw "Shorebird is missing." }

# 4. جلب الحزم
Write-Host "Fetching Packages..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

# 5. إنشاء الترقيع
Write-Host "Running Shorebird Patch..." -ForegroundColor Yellow
shorebird patch android --flutter-version=3.47.6
if ($LASTEXITCODE -ne 0) { throw "Shorebird patch failed." }

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "        Patch Completed Successfully!        " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
