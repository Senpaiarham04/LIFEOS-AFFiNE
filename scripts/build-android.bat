@echo off
setlocal enabledelayedexpansion

:: Build Android APK for AFFiNE LifeOS
:: Based on release-all.yml android job
:: Prerequisites: Java 21 JDK, Android SDK, Rust Android targets

set TAG=%1
if "%TAG%"=="" set TAG=local-dev

cd /D "%~dp0.."
set ROOT=%CD%

echo ===================================================
echo Building AFFiNE Android APK - %TAG%
echo ===================================================

:: Step 1: Set version in package.json
echo [1/8] Setting version...
node -e "
  const pkg = require('./package.json');
  pkg.version = '%TAG%'.replace(/^v/, '');
  require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2));
"

:: Step 2: Install dependencies
echo [2/8] Installing dependencies...
call yarn install --immutable --inline-builds
if %ERRORLEVEL% neq 0 (
    echo ERROR: yarn install failed
    exit /b 1
)

:: Step 3: Build Android web dist
echo [3/8] Building Android web bundle...
call yarn affine @affine/android build
if %ERRORLEVEL% neq 0 (
    echo ERROR: android web build failed
    exit /b 1
)

:: Step 4: Focus Android deps
echo [4/8] Focusing Android dependencies...
call yarn workspaces focus @affine/android
if %ERRORLEVEL% neq 0 (
    echo WARN: workspace focus had issues, continuing...
)

:: Step 5: Cap sync
echo [5/8] Running Capacitor sync...
call yarn workspace @affine/android cap sync
if %ERRORLEVEL% neq 0 (
    echo ERROR: cap sync failed
    exit /b 1
)

:: Step 6: Create google-services.json (dummy)
echo [6/8] Creating google-services.json...
if not exist "%ROOT%\packages\frontend\apps\android\App\app\google-services.json" (
    mkdir "%ROOT%\packages\frontend\apps\android\App\app" 2>nul
    (
        echo { "project_info": { "project_number": "0", "project_id": "affine-lifeos" },
        echo   "client": [{
        echo     "client_info": {
        echo       "mobilesdk_app_id": "1:0:android:0",
        echo       "android_client_info": { "package_name": "app.affine.pro" }
        echo     },
        echo     "oauth_client": [],
        echo     "api_key": [{ "current_key": "AIzaSyDummy" }],
        echo     "services": {
        echo       "analytics_service": { "status": 2 },
        echo       "cloud_messaging_service": { "status": 2 },
        echo       "appinvite_service": { "status": 2 },
        echo       "google_signin_service": { "status": 2 },
        echo       "ads_service": { "status": 2 }
        echo     }
        echo   }],
        echo   "configuration_version": "1"
        echo }
    ) > "%ROOT%\packages\frontend\apps\android\App\app\google-services.json"
    echo Created dummy google-services.json
) else (
    echo google-services.json already exists
)

:: Step 7: Generate keystore (if missing)
echo [7/8] Checking keystore...
if not exist "%ROOT%\packages\frontend\apps\android\affine.keystore" (
    echo Generating debug keystore...
    keytool -genkey -v -keystore "%ROOT%\packages\frontend\apps\android\affine.keystore" ^
        -alias key0 -keyalg RSA -keysize 2048 -validity 10000 ^
        -storepass affine123 -keypass affine123 ^
        -dname "CN=AFFiNE LifeOS, OU=LifeOS, O=LifeOS, L=Unknown, ST=Unknown, C=DE"
) else (
    echo Keystore already exists
)

:: Step 8: Build APK
echo [8/8] Building APK...
set VERSION_NAME=%TAG%
set AFFINE_ANDROID_KEYSTORE_PASSWORD=affine123
set AFFINE_ANDROID_KEYSTORE_ALIAS_PASSWORD=affine123
call yarn workspace @affine/android cap build android --flavor canary --androidreleasetype APK
if %ERRORLEVEL% neq 0 (
    echo ERROR: APK build failed
    exit /b 1
)

:: Find and rename APK
echo.
echo Searching for built APK...
for /r "%ROOT%\packages\frontend\apps\android\App\app\build\outputs\apk" %%f in (*.apk) do (
    copy "%%f" "%ROOT%\AFFiNE-LifeOS-%TAG%.apk" >nul
    echo FOUND: %%f
    echo COPIED TO: %ROOT%\AFFiNE-LifeOS-%TAG%.apk
)

echo ===================================================
echo Android build complete!
echo Output: AFFiNE-LifeOS-%TAG%.apk
echo ===================================================
endlocal
