$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan

# -----------------------------------------------
# فحص حرج: Configuration Cache يجب ان يكون false
# السبب: shorebird_trace_init.gradle يستخدم APIs
# غير متوافقة مع Configuration Cache (Gradle 8+)
# -----------------------------------------------
$gradleProps = Get-Content "android\gradle.properties" -Raw -ErrorAction Stop
if ($gradleProps -notmatch "org\.gradle\.configuration-cache\s*=\s*false") {
    Write-Host "FAIL: org.gradle.configuration-cache ليس false!" -ForegroundColor Red
    Write-Host "اضف: org.gradle.configuration-cache=false" -ForegroundColor Yellow
    Write-Host "راجع BUILD_AND_RELEASE.md - القسم 2." -ForegroundColor DarkGray
    exit 1
}
Write-Host "OK: Configuration Cache معطل (متوافق مع Shorebird)" -ForegroundColor Green
Write-Host "      MERAJ3I - Shorebird Release Script     " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# -----------------------------------------------
# فحص حرج: Configuration Cache يجب ان يكون false
# السبب: shorebird_trace_init.gradle يستخدم APIs
# غير متوافقة مع Configuration Cache (Gradle 8+)
# -----------------------------------------------
$gradleProps = Get-Content "android\gradle.properties" -Raw -ErrorAction Stop
if ($gradleProps -notmatch "org\.gradle\.configuration-cache\s*=\s*false") {
    Write-Host "FAIL: org.gradle.configuration-cache ليس false!" -ForegroundColor Red
    Write-Host "اضف: org.gradle.configuration-cache=false" -ForegroundColor Yellow
    Write-Host "راجع BUILD_AND_RELEASE.md - القسم 2." -ForegroundColor DarkGray
    exit 1
}
Write-Host "OK: Configuration Cache معطل (متوافق مع Shorebird)" -ForegroundColor Green

# 1. ط§ظ„طھط£ظƒط¯ ظ…ظ† ط§ظ„ظ…ط³ط§ط±
$ProjectDir = "C:\meraj3i\myapp"
if ((Get-Location).Path -ne $ProjectDir) {
    if (Test-Path $ProjectDir) {
        Set-Location $ProjectDir
        Write-Host "Changed directory to $ProjectDir" -ForegroundColor Green
    } else {
        throw "Project directory $ProjectDir does not exist."
    }
}

# 2. طھظˆط­ظٹط¯ ط¨ظٹط¦ط© ط§ظ„ط¹ظ…ظ„ (ط¥طµظ„ط§ط­ ظ…ط´ظƒظ„ط© ط§ظ„ط£ط±ظ‚ط§ظ… ط§ظ„ط¹ط±ط¨ظٹط© ظˆط§ظ„ظ€ DEX)
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.20.1"
$env:JAVA_TOOL_OPTIONS = "-Duser.language=en -Duser.country=US"
Write-Host "Set JAVA_HOME to $env:JAVA_HOME" -ForegroundColor Green
Write-Host "Set JAVA_TOOL_OPTIONS to $env:JAVA_TOOL_OPTIONS" -ForegroundColor Green

# 3. ظپط­طµ ط§ظ„ط£ط¯ظˆط§طھ
Write-Host "`n[1/7] Checking Dependencies..." -ForegroundColor Yellow
$null = java -version 2>&1
if ($LASTEXITCODE -ne 0) { throw "Java is missing." }
$null = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) { throw "Flutter is missing." }
$null = shorebird --version 2>&1
if ($LASTEXITCODE -ne 0) { throw "Shorebird is missing." }
Write-Host "Dependencies OK." -ForegroundColor Green

# 4. ظپط­طµ Git
Write-Host "`n[2/7] Checking Git Status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Warning: You have uncommitted changes. Shorebird will include them in the release." -ForegroundColor DarkYellow
}

# 5. طھظ†ط¸ظٹظپ ط¢ظ…ظ† ظˆط¬ظ„ط¨ ط§ظ„ط­ط²ظ…
Write-Host "`n[3/7] Cleaning & Fetching Packages..." -ForegroundColor Yellow
flutter clean
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .dart_tool, build, android\.gradle
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

# 6. طھط­ظ„ظٹظ„ ط§ظ„ظƒظˆط¯
Write-Host "`n[4/7] Analyzing Code..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed. Please fix Dart issues." }

# 7. ط§ط®طھط¨ط§ط± ط§ظ„ط¨ظ†ط§ط، ط§ظ„ط£ط³ط§ط³ظٹ (APK)
Write-Host "`n[5/7] Building APK (Dry Run)..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "Flutter APK build failed." }

# 8. ط§ط®طھط¨ط§ط± ط¨ظ†ط§ط، ط­ط²ظ…ط© ط§ظ„طھط·ط¨ظٹظ‚ (AAB)
Write-Host "`n[6/7] Building AAB (Dry Run)..." -ForegroundColor Yellow
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { throw "Flutter AAB build failed. Please check build errors." }

# 9. ط¥طµط¯ط§ط± Shorebird
Write-Host "`n[7/7] Running Shorebird Release..." -ForegroundColor Yellow
shorebird release android --flutter-version=3.47.6
if ($LASTEXITCODE -ne 0) { throw "Shorebird release failed." }

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "       Release Completed Successfully!       " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan

# -----------------------------------------------
# فحص حرج: Configuration Cache يجب ان يكون false
# السبب: shorebird_trace_init.gradle يستخدم APIs
# غير متوافقة مع Configuration Cache (Gradle 8+)
# -----------------------------------------------
$gradleProps = Get-Content "android\gradle.properties" -Raw -ErrorAction Stop
if ($gradleProps -notmatch "org\.gradle\.configuration-cache\s*=\s*false") {
    Write-Host "FAIL: org.gradle.configuration-cache ليس false!" -ForegroundColor Red
    Write-Host "اضف: org.gradle.configuration-cache=false" -ForegroundColor Yellow
    Write-Host "راجع BUILD_AND_RELEASE.md - القسم 2." -ForegroundColor DarkGray
    exit 1
}
Write-Host "OK: Configuration Cache معطل (متوافق مع Shorebird)" -ForegroundColor Green
