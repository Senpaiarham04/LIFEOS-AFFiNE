@echo off
setlocal enabledelayedexpansion

:: Build Docker Image for AFFiNE LifeOS (VPS deployment)
:: Based on release-all.yml docker job
:: Prerequisites: Docker Desktop, WSL2 backend

set TAG=%1
if "%TAG%"=="" set TAG=latest

cd /D "%~dp0.."
set ROOT=%CD%

echo ===================================================
echo Building AFFiNE Docker Image (linux/amd64) - %TAG%
echo ===================================================

:: Step 1: Install dependencies
echo [1/7] Installing dependencies...
call yarn install --immutable --inline-builds
if %ERRORLEVEL% neq 0 (
    echo ERROR: yarn install failed
    exit /b 1
)

:: Step 2: Build server-native (Rust)
echo [2/7] Building server-native (Rust)...
set CC=clang -D_BSD_SOURCE
call yarn workspace @affine/server-native build --target x86_64-unknown-linux-gnu
if %ERRORLEVEL% neq 0 (
    echo ERROR: server-native build failed
    exit /b 1
)

:: Step 3: Prepare native binaries
echo [3/7] Preparing native binaries for bundler...
for %%a in (x64 arm64 armv7) do (
    copy /Y "%ROOT%\packages\backend\native\server-native.node" "%ROOT%\packages\backend\native\server-native.%%a.node"
)

:: Step 4: Build web frontend
echo [4/7] Building web frontend...
set BUILD_TYPE=canary
call yarn affine @affine/web build
if %ERRORLEVEL% neq 0 (
    echo ERROR: web build failed
    exit /b 1
)

:: Step 5: Build admin
echo [5/7] Building admin panel...
call yarn affine @affine/admin build
if %ERRORLEVEL% neq 0 (
    echo WARN: admin build had issues, continuing...
)

:: Step 6: Build mobile frontend
echo [6/7] Building mobile frontend...
call yarn affine @affine/mobile build
if %ERRORLEVEL% neq 0 (
    echo WARN: mobile build had issues, continuing...
)

:: Step 7: Build server
echo [7/7] Building server bundle...
call yarn workspace @affine/server build
if %ERRORLEVEL% neq 0 (
    echo ERROR: server build failed
    exit /b 1
)

:: Install production deps + Prisma
echo [Prisma] Generating Prisma client...
call yarn config set --json supportedArchitectures.cpu "[\"x64\"]" 2>nul
call yarn config set --json supportedArchitectures.libc "[\"glibc\"]" 2>nul
call yarn workspaces focus @affine/server --production
call yarn workspace @affine/server prisma generate

:: Check Docker
echo.
echo Checking Docker Desktop...
docker info >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo WARNING: Docker Desktop is not running.
    echo The build artifacts are ready at:
    echo   packages/backend/server/dist/
    echo   packages/frontend/apps/web/dist/
    echo.
    echo To build the Docker image later, start Docker Desktop and run:
    echo   docker build -t affine-custom:%TAG% -f .github/deployment/node/Dockerfile .
    exit /b 0
)

:: Build Docker image
echo [Docker] Building image...
docker build ^
    --pull ^
    --platform linux/amd64 ^
    -t affine-custom:%TAG% ^
    -f .github/deployment/node/Dockerfile ^
    --provenance=false ^
    .
if %ERRORLEVEL% neq 0 (
    echo ERROR: Docker build failed
    exit /b 1
)

echo ===================================================
echo Docker build complete!
echo Image: affine-custom:%TAG%
echo.
echo To push to GHCR:
echo   docker tag affine-custom:%TAG% ghcr.io/senpaiarham04/affine-custom:%TAG%
echo   docker push ghcr.io/senpaiarham04/affine-custom:%TAG%
echo ===================================================
endlocal
