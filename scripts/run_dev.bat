@echo off
REM =============================================================================
REM SIRE - Ejecucion en desarrollo (Windows CMD)
REM =============================================================================
REM Uso: scripts\run_dev.bat
REM
REM Inicia el backend (Fastify) en una ventana separada y luego ejecuta
REM la app Flutter. Al cerrar Flutter, debes cerrar manualmente la ventana
REM del backend.
REM =============================================================================

setlocal enabledelayedexpansion

REM ─── Banner ─────────────────────────────────────────────────────────────────
echo.
echo   ╔══════════════════════════════════════════════╗
echo   ║                                              ║
echo   ║   SIRE - Ejecucion en desarrollo             ║
echo   ║                                              ║
echo   ╚══════════════════════════════════════════════╝
echo.

REM ─── Verificacion previa ──────────────────────────────────────────────────
if not exist "backend\.env" (
    echo   ✗ backend\.env no encontrado.
    echo   -> Ejecuta primero: scripts\setup.bat
    pause
    exit /b 1
)

if not exist ".env" (
    echo   ✗ .env ^(Flutter^) no encontrado.
    echo   -> Ejecuta primero: scripts\setup.bat
    pause
    exit /b 1
)

REM Validar placeholders en .env de Flutter
set "HAS_PLACEHOLDER=0"
for %%v in (SUPABASE_URL SUPABASE_ANON_KEY API_BASE_URL) do (
    for /f "usebackq tokens=2 delims==" %%a in (`.env`) do (
        echo %%a | findstr /i "tu-proyecto\|tu-anon-key\|placeholder\|ejemplo" >nul 2>&1
        if not errorlevel 1 set "HAS_PLACEHOLDER=1"
    )
    REM Check if empty
    for /f "usebackq tokens=1,* delims==" %%k in (`findstr /b "%%v=" .env 2^>nul`) do (
        if "%%l"=="" set "HAS_PLACEHOLDER=1"
    )
)
if "!HAS_PLACEHOLDER!"=="1" (
    echo   ⚠ Algunas variables en .env aun tienen valor placeholder.
    echo   -> Edita .env con los valores reales de Supabase antes de continuar.
    echo   -> Las variables criticas son: SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
    echo.
    echo   ¿Deseas continuar de todas formas? [s/n]
    set /p CONTINUE_DESPI=
    if /i not "!CONTINUE_DESPI!"=="s" (
        echo   Ejecucion cancelada. Edita .env y vuelve a intentarlo.
        pause
        exit /b 1
    )
)

echo   ✓ Archivos .env verificados
echo.

REM ─── Iniciar Backend ──────────────────────────────────────────────────────
echo   [Backend] Iniciando Fastify en puerto 3000...
echo   [Backend] Se abrira en una ventana separada. No la cierres mientras uses la app.
echo.

start "SIRE Backend - Fastify :3000" cmd /c "cd /d %CD%\backend && echo   SIRE Backend - Fastify en puerto 3000 && echo   Cierra esta ventana SOLO cuando termines de usar la app. && echo. && npm run dev"

REM Esperar a que el backend esté listo (hasta 10s)
echo   -> Esperando a que el backend este listo...
set "WAITED=0"
:wait_backend
timeout /t 1 /nobreak >nul
set /a WAITED+=1

REM Intentar alcanzar el backend con curl (PowerShell fallback)
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:3000/api/v1/users/profiles' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   ✓ Backend respondiendo - listo
    goto :backend_ready
)

if %WAITED% lss 10 goto :wait_backend

echo   ⚠ Backend no respondio en 10s. Puede estar iniciandose aun.
echo   ⚠ La app Flutter arrancara igual, pero puede fallar si el backend no esta listo.

:backend_ready
echo.

REM ─── Iniciar Flutter ──────────────────────────────────────────────────────
echo   [Flutter] Listando dispositivos disponibles...
echo.
flutter devices 2>nul
echo.
echo   -> Conecta un dispositivo o inicia un emulador antes de continuar.
echo   -> Escribe el ID del dispositivo o presiona Enter para usar el predeterminado.
echo.
set /p DEVICE_ID="  ID del dispositivo (Enter = predeterminado): "

echo.
echo   [Flutter] Iniciando app...
echo   ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
echo.

if not "!DEVICE_ID!"=="" (
    flutter run -d "!DEVICE_ID!"
) else (
    flutter run
)

echo.
echo   ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
echo.
echo   [Flutter] App detenida.
echo   ⚠ Recuerda cerrar la ventana del backend ^("SIRE Backend - Fastify :3000"^).
echo.
pause
exit /b 0
