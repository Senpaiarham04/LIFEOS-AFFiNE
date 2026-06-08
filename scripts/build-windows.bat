@echo off
setlocal enabledelayedexpansion

:: Build Windows Desktop Installer for AFFiNE LifeOS
:: Based on release-all.yml desktop job

set TAG=%1
if "%TAG%"=="" set TAG=local-dev

:: Strip optional v prefix for version comparison
set VER=%TAG%
if "%VER:~0,1%"=="v" set VER=%VER:~1%

cd /D "%~dp0.."
set ROOT=%CD%

echo ===================================================
echo Building AFFiNE Desktop (Windows x64) - %TAG%
echo ===================================================

:: Step 0: Set version in package.json (like CI)
echo [0/6] Setting version %TAG% in package.json...
node scripts\set-version.mjs %TAG%

:: Step 1: Install dependencies
echo [1/6] Installing dependencies...
call yarn install --immutable --inline-builds
if %ERRORLEVEL% neq 0 (
    echo ERROR: yarn install failed
    exit /b 1
)

:: Step 2: Generate electron assets
echo [2/6] Generating electron assets...
set RELEASE_VERSION=%VER%
call yarn affine @affine/electron generate-assets
if %ERRORLEVEL% neq 0 (
    echo ERROR: generate-assets failed
    exit /b 1
)

:: Step 3: Build desktop
echo [3/6] Building desktop...
call yarn affine @affine/electron build
if %ERRORLEVEL% neq 0 (
    echo ERROR: desktop build failed
    exit /b 1
)

:: Step 4: Package with electron-forge
echo [4/6] Packaging...
call yarn affine @affine/electron package --platform=win32 --arch=x64
if %ERRORLEVEL% neq 0 (
    echo ERROR: packaging failed
    exit /b 1
)

:: Step 5: Make Squirrel installer
echo [5/6] Creating Squirrel installer...
call yarn affine @affine/electron make-squirrel --platform=win32 --arch=x64
if %ERRORLEVEL% neq 0 (
    echo WARN: make-squirrel had issues, checking output...
)

:: Find and rename the installer
echo.
echo Searching for built installer...
for /r "%ROOT%\packages\frontend\apps\electron\out" %%f in (*.exe) do (
    copy "%%f" "%ROOT%\AFFiNE-LifeOS-%TAG%-win32-x64.exe" >nul
    echo FOUND: %%f
    echo COPIED TO: %ROOT%\AFFiNE-LifeOS-%TAG%-win32-x64.exe
)

:: Step 6: Restore original package.json versions
echo [6/6] Restoring package.json versions...
git checkout -- package.json packages/frontend/apps/electron/package.json 2>nul
if %ERRORLEVEL% neq 0 (
    echo WARN: Could not restore via git, skipping
)

echo ===================================================
echo Desktop build complete!
echo Output: AFFiNE-LifeOS-%TAG%-win32-x64.exe
echo ===================================================
endlocal
