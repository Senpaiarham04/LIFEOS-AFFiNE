# AFFiNE LifeOS Build Scripts

## Prerequisites

- **Node.js** v22.12+ (via `.nvmrc`)
- **Yarn** 4.x (enable via `corepack enable`)
- **Rust** stable toolchain
- **Docker Desktop** (für Docker-Build)
- **Java 21 JDK** + **Android SDK** (für APK-Build)
- **Rust Android targets**: `rustup target add aarch64-linux-android x86_64-linux-android`

## Schnellstart

```cmd
:: Alle drei Targets bauen
scripts\build-all.bat v0.26.4-toggle.1

:: Einzeln:
scripts\build-windows.bat v0.26.4-toggle.1
scripts\build-android.bat v0.26.4-toggle.1
scripts\build-docker.bat v0.26.4-toggle.1
```

## Scripts

| Script | Zweck | Output |
|---|---|---|
| `build-windows.bat` | Windows Desktop Installer | `AFFiNE-LifeOS-*-Setup.exe` |
| `build-android.bat` | Android APK | `AFFiNE-LifeOS-*.apk` |
| `build-docker.bat` | Docker Image (VPS) | Docker-Image `affine-custom:*` |
| `build-all.bat` | Alle drei nacheinander | s.o. |

## Workflow

1. Änderungen im Code vornehmen (z.B. Toggle-Features in `blocksuite/`)
2. Lokal testen: `yarn dev`
3. Build ausführen: `scripts\build-windows.bat`
4. Tag für Release: `git tag v0.26.4-toggle.1 && git push origin --tags`
5. Docker-Image für VPS: `docker tag` + `docker push ghcr.io/...`
