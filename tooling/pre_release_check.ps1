#Requires -Version 5.1
<#
.SYNOPSIS
    MERAJ3I Pre-Release Check Script
.DESCRIPTION
    يفحص بيئة البناء وملفات المشروع قبل الإصدار.
    لا يعدّل أي ملفات ولا يُنشئ إصدارات بمفرده.
.PARAMETER Mode
    check  : فحص فقط (الوضع الافتراضي)
    build  : فحص + بناء Flutter (بدون Shorebird)
.EXAMPLE
    .\tooling\pre_release_check.ps1
    .\tooling\pre_release_check.ps1 -Mode build
#>

param(
    [ValidateSet("check", "build")]
    [string]$Mode = "check"
)

$ErrorActionPreference = "Stop"
$ProjectDir = "C:\meraj3i\myapp"
$LogDir = "$ProjectDir\tooling\logs"
$LogFile = "$LogDir\check_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$FailCount = 0
$WarnCount = 0

# =============================================
# الإصدارات المتوقعة (حدّثها عند تغيير أي أداة)
# =============================================
$EXPECTED_FLUTTER_MIN    = "3.47"
$EXPECTED_JAVA_VERSION   = "17"
$CRITICAL_GRADLE_PROP    = "org.gradle.configuration-cache=false"

# =============================================
# دوال مساعدة
# =============================================
function Write-Step {
    param([string]$Text, [string]$Color = "Cyan")
    $msg = "`n[CHECK] $Text"
    Write-Host $msg -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $msg -Encoding UTF8
}

function Write-OK {
    param([string]$Text)
    $msg = "  OK  $Text"
    Write-Host $msg -ForegroundColor Green
    Add-Content -Path $LogFile -Value $msg -Encoding UTF8
}

function Write-WARN {
    param([string]$Text)
    $script:WarnCount++
    $msg = "  WARN  $Text"
    Write-Host $msg -ForegroundColor Yellow
    Add-Content -Path $LogFile -Value $msg -Encoding UTF8
}

function Write-FAIL {
    param([string]$Text)
    $script:FailCount++
    $msg = "  FAIL  $Text"
    Write-Host $msg -ForegroundColor Red
    Add-Content -Path $LogFile -Value $msg -Encoding UTF8
}

function Assert-FileExists {
    param([string]$FilePath, [string]$Description, [bool]$Critical = $true)
    if (Test-Path $FilePath) {
        Write-OK "$Description موجود: $FilePath"
    } elseif ($Critical) {
        Write-FAIL "$Description مفقود: $FilePath"
    } else {
        Write-WARN "$Description غير موجود: $FilePath"
    }
}

function Assert-FileContains {
    param([string]$FilePath, [string]$Pattern, [string]$Description, [bool]$Critical = $true)
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        if ($content -match [regex]::Escape($Pattern)) {
            Write-OK "$Description"
        } elseif ($Critical) {
            Write-FAIL "$Description | الإعداد المطلوب '$Pattern' غير موجود في $FilePath"
        } else {
            Write-WARN "$Description | الإعداد المطلوب '$Pattern' غير موجود في $FilePath"
        }
    } else {
        Write-FAIL "الملف غير موجود: $FilePath"
    }
}

# =============================================
# البداية
# =============================================
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Add-Content -Path $LogFile -Value "=== MERAJ3I Pre-Release Check ===" -Encoding UTF8
Add-Content -Path $LogFile -Value "Date: $(Get-Date)" -Encoding UTF8
Add-Content -Path $LogFile -Value "Mode: $Mode" -Encoding UTF8

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   MERAJ3I Pre-Release Check — Mode: $Mode" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "السجل: $LogFile" -ForegroundColor DarkGray

# =============================================
# 1. التحقق من المسار
# =============================================
Write-Step "التحقق من مسار المشروع"
if ((Get-Location).Path -ne $ProjectDir) {
    if (Test-Path $ProjectDir) {
        Set-Location $ProjectDir
        Write-OK "تم الانتقال إلى $ProjectDir"
    } else {
        Write-FAIL "مسار المشروع غير موجود: $ProjectDir"
    }
}

# =============================================
# 2. التحقق من وجود الأدوات
# =============================================
Write-Step "التحقق من وجود الأدوات"

# Flutter
try {
    $flutterOut = (flutter --version 2>&1) -join " "
    if ($flutterOut -match "Flutter (\d+\.\d+)") {
        $ver = $Matches[1]
        if ([version]$ver -ge [version]$EXPECTED_FLUTTER_MIN) {
            Write-OK "Flutter $ver (متوافق مع الحد الأدنى $EXPECTED_FLUTTER_MIN)"
        } else {
            Write-WARN "Flutter $ver اقل من الحد الأدنى المتوقع $EXPECTED_FLUTTER_MIN"
        }
    }
} catch {
    Write-FAIL "Flutter غير مثبّت أو غير متاح في PATH"
}

# Shorebird
try {
    $shorebirdOut = (shorebird --version 2>&1) -join " "
    if ($shorebirdOut -match "Shorebird (\d+\.\d+)") {
        $ver = $Matches[1]
        Write-OK "Shorebird $ver"
    } else {
        Write-OK "Shorebird متاح"
    }
    if ($shorebirdOut -match "new version") {
        Write-WARN "يوجد إصدار جديد من Shorebird — شغّل: shorebird upgrade"
    }
} catch {
    Write-FAIL "Shorebird غير مثبّت أو غير متاح في PATH"
}

# Java
try {
    $javaOut = (java -version 2>&1) -join " "
    if ($javaOut -match "version ""(\d+)") {
        $ver = $Matches[1]
        if ($ver -eq $EXPECTED_JAVA_VERSION) {
            Write-OK "Java $ver (صحيح)"
        } else {
            Write-WARN "Java $ver — الإصدار المتوقع هو $EXPECTED_JAVA_VERSION"
        }
    }
} catch {
    Write-FAIL "Java غير مثبّت أو غير متاح في PATH"
}

# =============================================
# 3. التحقق من ملفات المشروع الأساسية
# =============================================
Write-Step "التحقق من ملفات المشروع"

Assert-FileExists "pubspec.yaml" "pubspec.yaml"
Assert-FileExists "pubspec.lock" "pubspec.lock (لا تحذفه!)"
Assert-FileExists "shorebird.yaml" "shorebird.yaml"
Assert-FileExists "android\gradle.properties" "gradle.properties"
Assert-FileExists "android\gradle\wrapper\gradle-wrapper.properties" "gradle-wrapper.properties"
Assert-FileExists "android\settings.gradle.kts" "settings.gradle.kts"
Assert-FileExists "android\app\build.gradle.kts" "app/build.gradle.kts"
Assert-FileExists "android\app\google-services.json" "google-services.json"
Assert-FileExists "android\key.properties" "key.properties (مفتاح التوقيع)" $false
Assert-FileExists "android\upload-keystore.jks" "upload-keystore.jks" $false

# =============================================
# 4. التحقق من إعدادات gradle.properties الحرجة
# =============================================
Write-Step "التحقق من إعدادات Gradle الحرجة"

Assert-FileContains "android\gradle.properties" `
    $CRITICAL_GRADLE_PROP `
    "Configuration Cache معطل (ضروري لتوافق Shorebird)" `
    $true

Assert-FileContains "android\gradle.properties" `
    "org.gradle.caching=true" `
    "Gradle Build Cache مفعّل" `
    $false

Assert-FileContains "android\gradle.properties" `
    "Duser.language=en" `
    "اللغة الإنجليزية لمنع مشكلة الأرقام العربية" `
    $false

# =============================================
# 5. التحقق من إعدادات app/build.gradle.kts الحرجة
# =============================================
Write-Step "التحقق من إعدادات app/build.gradle.kts"

Assert-FileContains "android\app\build.gradle.kts" `
    "multiDexEnabled = true" `
    "MultiDex مفعّل (مطلوب من Shorebird)" `
    $true

Assert-FileContains "android\app\build.gradle.kts" `
    "isMinifyEnabled = true" `
    "Minification مفعّل في release (مطلوب من Shorebird)" `
    $true

# =============================================
# 6. التحقق من Gradle Wrapper
# =============================================
Write-Step "التحقق من Gradle Wrapper"
if (Test-Path "android\gradle\wrapper\gradle-wrapper.properties") {
    $gwProps = Get-Content "android\gradle\wrapper\gradle-wrapper.properties" -Raw
    if ($gwProps -match "gradle-(\d+\.\d+)") {
        $gradleVer = $Matches[1]
        Write-OK "Gradle Wrapper: $gradleVer"
    }
}

# =============================================
# 7. flutter pub get
# =============================================
Write-Step "تشغيل flutter pub get"
try {
    $pubOut = (flutter pub get 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) {
        Write-OK "flutter pub get نجح"
    } else {
        Write-FAIL "flutter pub get فشل"
        Add-Content -Path $LogFile -Value $pubOut -Encoding UTF8
    }
} catch {
    Write-FAIL "خطأ أثناء flutter pub get: $_"
}

# =============================================
# 8. flutter analyze
# =============================================
Write-Step "تشغيل flutter analyze"
try {
    $analyzeOut = (flutter analyze 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) {
        Write-OK "flutter analyze — لا توجد مشاكل"
    } else {
        Write-FAIL "flutter analyze وجد مشاكل — راجع السجل"
        Add-Content -Path $LogFile -Value $analyzeOut -Encoding UTF8
    }
} catch {
    Write-FAIL "خطأ أثناء flutter analyze: $_"
}

# =============================================
# 9. بناء Flutter (وضع build فقط)
# =============================================
if ($Mode -eq "build") {
    Write-Step "بناء APK (flutter build apk --release)" "Magenta"
    try {
        $env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.20.1"
        $env:JAVA_TOOL_OPTIONS = "-Duser.language=en -Duser.country=US"

        $buildOut = (flutter build apk --release 2>&1) -join "`n"
        if ($LASTEXITCODE -eq 0) {
            Write-OK "flutter build apk --release نجح"
            $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
            if (Test-Path $apkPath) {
                $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
                Write-OK "APK موجود: $apkPath ($size MB)"
            } else {
                Write-WARN "APK غير موجود في المسار المتوقع: $apkPath"
            }
        } else {
            Write-FAIL "flutter build apk فشل — راجع السجل"
            Add-Content -Path $LogFile -Value $buildOut -Encoding UTF8
        }
    } catch {
        Write-FAIL "خطأ أثناء البناء: $_"
    }
}

# =============================================
# الملخص النهائي
# =============================================
Write-Host "`n=============================================" -ForegroundColor Cyan
if ($FailCount -eq 0 -and $WarnCount -eq 0) {
    Write-Host "  النتيجة: جميع الفحوصات نجحت!" -ForegroundColor Green
} elseif ($FailCount -eq 0) {
    Write-Host "  النتيجة: نجاح مع $WarnCount تحذير(ات)" -ForegroundColor Yellow
} else {
    Write-Host "  النتيجة: فشل — $FailCount خطأ, $WarnCount تحذير" -ForegroundColor Red
    Write-Host "  لا تُصدر إصداراً جديداً حتى تُصلح الأخطاء!" -ForegroundColor Red
}
Write-Host "  السجل الكامل: $LogFile" -ForegroundColor DarkGray
Write-Host "=============================================" -ForegroundColor Cyan

Add-Content -Path $LogFile -Value "`n=== النتيجة: Fails=$FailCount Warns=$WarnCount ===" -Encoding UTF8

if ($FailCount -gt 0) {
    exit 1
}
exit 0
