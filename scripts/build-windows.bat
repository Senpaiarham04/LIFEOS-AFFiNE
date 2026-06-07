@echo off
setlocal enabledelayedexpansion

:: Build Windows Desktop Installer for AFFiNE LifeOS
:: Based on release-all.yml desktop job

set TAG=%1
if "%TAG%"=="" set TAG=local-dev

cd /D "%~dp0.."
set ROOT=%CD%

echo ===================================================
echo Building AFFiNE Desktop (Windows x64) - %TAG%
echo ===================================================

:: Step 1: Install dependencies
echo [1/5] Installing dependencies...
call yarn install --immutable --inline-builds
if %ERRORLEVEL% neq 0 (
    echo ERROR: yarn install failed
    exit /b 1
)

:: Step 2: Generate electron assets
echo [2/5] Generating electron assets...
set RELEASE_VERSION=%TAG%
call yarn affine @affine/electron generate-assets
if %ERRORLEVEL% neq 0 (
    echo ERROR: generate-assets failed
    exit /b 1
)

:: Step 3: Build desktop
echo [3/5] Building desktop...
call yarn affine @affine/electron build
if %ERRORLEVEL% neq 0 (
    echo ERROR: desktop build failed
    exit /b 1
)

:: Step 4: Package with electron-forge
echo [4/5] Packaging...
call yarn affine @affine/electron package --platform=win32 --arch=x64
if %ERRORLEVEL% neq 0 (
    echo ERROR: packaging failed
    exit /b 1
)

:: Step 5: Make Squirrel installer
echo [5/5] Creating Squirrel installer...
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

echo ===================================================
echo Desktop build complete!
echo Output: AFFiNE-LifeOS-%TAG%-win32-x64.exe
echo ===================================================
endlocal
