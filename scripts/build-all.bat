@echo off
setlocal enabledelayedexpansion

:: Build ALL AFFiNE LifeOS targets
set TAG=%1
if "%TAG%"=="" set TAG=local-dev

cd /D "%~dp0.."
set ROOT=%CD%
set START_TIME=%TIME%

echo ===================================================
echo AFFiNE LifeOS - Build ALL Targets
echo Tag: %TAG%
echo Started: %START_TIME%
echo ===================================================
echo.

:: 1. Windows Desktop
echo ========== BUILDING WINDOWS DESKTOP ==========
call "%ROOT%\scripts\build-windows.bat" %TAG%
if %ERRORLEVEL% neq 0 (
    echo FAILED: Windows Desktop build
) else (
    echo OK: Windows Desktop build
)
echo.

:: 2. Android APK
echo ========== BUILDING ANDROID APK ==========
call "%ROOT%\scripts\build-android.bat" %TAG%
if %ERRORLEVEL% neq 0 (
    echo FAILED: Android APK build
) else (
    echo OK: Android APK build
)
echo.

:: 3. Docker Image
echo ========== BUILDING DOCKER IMAGE ==========
call "%ROOT%\scripts\build-docker.bat" %TAG%
if %ERRORLEVEL% neq 0 (
    echo FAILED: Docker image build
) else (
    echo OK: Docker image build
)

set END_TIME=%TIME%
echo.
echo ===================================================
echo ALL BUILDS COMPLETE
echo Started: %START_TIME%
echo Ended:   %END_TIME%
echo.
echo Outputs:
dir "%ROOT%\AFFiNE-LifeOS-*.*" 2>nul || echo   (no output files found)
echo ===================================================
endlocal
