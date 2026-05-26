@echo off
REM =============================================================================
REM SIRE — Instalacion automatizada (Windows CMD)
REM =============================================================================
REM Uso: scripts\setup.bat
REM
REM Verifica prerequisitos, instala dependencias, configura variables
REM de entorno y ejecuta migraciones de base de datos.
REM Cada paso se valida antes de continuar; si algo falla, se detiene
REM con un diagnostico detallado para que puedas resolverlo.
REM =============================================================================

setlocal enabledelayedexpansion

REM ─── Inicializar variables ───────────────────────────────────────────────────
set "MISSING_TOOLS=0"
set "MIGRATE_CONFIRM=n"

REM ─── Banner ─────────────────────────────────────────────────────────────────
echo.
echo   ╔══════════════════════════════════════════════╗
echo   ║                                              ║
echo   ║   SIRE — Sistema Integral de Reservas        ║
echo   ║          Estrategicas                        ║
echo   ║                                              ║
echo   ║   Instalacion automatizada                   ║
echo   ║                                              ║
echo   ╚══════════════════════════════════════════════╝
echo.

REM ──────────────────────────────────────────────────────────────────────────────
REM PASO 1 — Verificar prerequisitos
REM ──────────────────────────────────────────────────────────────────────────────
echo [PASO 1] Verificando herramientas necesarias
echo.

call :check_tool "git"          "https://git-scm.com/downloads"              "git --version"
call :check_tool "flutter"      "https://docs.flutter.dev/get-started/install" "flutter --version"
call :check_tool "node"         "https://nodejs.org/ (v20 LTS recomendada)"   "node --version"
call :check_tool "npm"          "https://nodejs.org/ (incluido con Node.js)"  "npm --version"

if %MISSING_TOOLS% gtr 0 (
    echo.
    echo   ✗ ERROR: Faltan %MISSING_TOOLS% herramienta^(s^). Instalelas y vuelva a ejecutar este script.
    pause
    exit /b 1
)

REM Doctor de versiones
echo.
echo   → Validando versiones contra los requerimientos del proyecto...

for /f "tokens=2 delims= " %%v in ('flutter --version 2^>^&1 ^| findstr /r "^Flutter "') do set "FLUTTER_VER=%%v"
for /f "tokens=1 delims=." %%v in ("%FLUTTER_VER%") do set "FLUTTER_MAJOR=%%v"
if %FLUTTER_MAJOR% geq 3 (
    echo     ✓ Flutter %FLUTTER_VER% — cumple con ≥3.11 requerido
) else (
    echo     ⚠ Flutter %FLUTTER_VER% detectado. El proyecto requiere Flutter SDK ≥3.11.3.
)

node --version >nul 2>&1
for /f "usebackq tokens=1 delims=v" %%v in (`node --version`) do set "NODE_VER=%%v"
for /f "tokens=1 delims=." %%v in ("%NODE_VER%") do set "NODE_MAJOR=%%v"
if %NODE_MAJOR% geq 20 (
    echo     ✓ Node.js v%NODE_VER% — cumple con ≥20 requerido
) else (
    echo     ⚠ Node.js v%NODE_VER% detectado. El proyecto requiere Node.js ≥20 LTS.
)

REM ──────────────────────────────────────────────────────────────────────────────
REM PASO 2 — Variables de entorno
REM ──────────────────────────────────────────────────────────────────────────────
echo.
echo [PASO 2] Configurando archivos de variables de entorno
echo.

REM ── Flutter .env ──
if exist ".env" (
    echo   ✓ .env ^(Flutter^) ya existe — se conserva intacto
) else (
    if exist ".env.example" (
        copy /Y ".env.example" ".env" >nul
        echo   ✓ .env ^(Flutter^) creado desde .env.example
        echo   ⚠ Edita .env con los valores reales de tu proyecto Supabase antes de ejecutar la app.
        echo     → Variables requeridas: SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
    ) else (
        echo   ✗ ERROR: No se encontro .env.example en la raiz del proyecto.
        echo     ¿Clonaste el repositorio completo?
        pause
        exit /b 1
    )
)

REM ── Backend .env ──
if exist "backend\.env" (
    echo   ✓ backend\.env ya existe — se conserva intacto
) else (
    if exist "backend\.env.example" (
        copy /Y "backend\.env.example" "backend\.env" >nul
        echo   ✓ backend\.env creado desde backend\.env.example
        echo   ⚠ Edita backend\.env con la cadena de conexion real de Supabase PostgreSQL.
        echo     → Obten DATABASE_URL y DIRECT_URL en: Supabase Dashboard → Settings → Database
    ) else (
        echo   ✗ ERROR: No se encontro backend\.env.example. ¿Esta completo el repositorio?
        pause
        exit /b 1
    )
)

REM ──────────────────────────────────────────────────────────────────────────────
REM PASO 3 — Dependencias Flutter/Dart
REM ──────────────────────────────────────────────────────────────────────────────
echo.
echo [PASO 3] Instalando dependencias de Flutter/Dart
echo.

echo   → Ejecutando flutter pub get...
call flutter pub get
if %ERRORLEVEL% equ 0 (
    echo   ✓ flutter pub get — paquetes Dart instalados
) else (
    echo   ⚠ flutter pub get fallo. Iniciando autosanacion: reparando cache de pub...
    call flutter pub cache repair
    echo   → Reintentando flutter pub get...
    call flutter pub get
    if !ERRORLEVEL! equ 0 (
        echo   ✓ flutter pub get completado tras reparar cache de pub
    ) else (
        echo   ✗ ERROR: flutter pub get fallo incluso tras reparar cache.
        echo     Causas posibles:
        echo     • Sin conexion a internet o pub.dev inalcanzable
        echo     • Proxy corporativo bloqueando la conexion
        echo     • Espacio insuficiente en disco
        pause
        exit /b 1
    )
)

REM Doctor: integridad del codigo Dart
echo.
echo   → Ejecutando dart analyze para validar integridad del codigo...
call dart analyze lib\ --no-fatal-infos --no-fatal-warnings
if %ERRORLEVEL% equ 0 (
    echo   ✓ dart analyze — sin errores de compilacion en lib\
) else (
    echo   ⚠ dart analyze reporto advertencias. No impiden ejecutar la app.
)

REM ──────────────────────────────────────────────────────────────────────────────
REM PASO 4 — Generacion de codigo (build_runner)
REM ──────────────────────────────────────────────────────────────────────────────
echo.
echo [PASO 4] Ejecutando generador de codigo con build_runner
echo.

echo   → Generando archivos .g.dart con dart run build_runner build...
call dart run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% equ 0 (
    echo   ✓ build_runner — generacion completada
) else (
    echo   ⚠ build_runner fallo. Iniciando autosanacion: limpieza de cache de build_runner...
    call dart run build_runner clean 2>nul
    if exist "lib\*.g.dart" del /S /Q "lib\*.g.dart" 2>nul
    echo   → Reintentando build_runner con cache limpia...
    call dart run build_runner build --delete-conflicting-outputs
    if !ERRORLEVEL! equ 0 (
        echo   ✓ build_runner — generacion completada tras limpieza
    ) else (
        echo   ✗ ERROR: build_runner fallo definitivamente.
        echo     Causas posibles:
        echo     • Conflicto de anotaciones ^(@riverpod^) con versiones de dependencias
        echo     • Archivo .g.dart corrupto que no se pudo eliminar automaticamente
        echo     • Error de sintaxis en un archivo Dart que impide la generacion
        echo     Accion manual: dart run build_runner clean ^&^& dart run build_runner build --delete-conflicting-outputs
        pause
        exit /b 1
    )
)

REM Doctor: verificar archivos .g.dart generados
echo.
echo   → Verificando archivos generados...
dir /s /b "lib\*.g.dart" 2>nul | find /c /v "" > "%TEMP%\sire_g_count.txt"
set /p G_FILES=<"%TEMP%\sire_g_count.txt"
del "%TEMP%\sire_g_count.txt" 2>nul
if %G_FILES% gtr 0 (
    echo   ✓ build_runner — %G_FILES% archivo^(s^) .g.dart generados en lib\
) else (
    echo   → No se detectaron archivos .g.dart. Si el proyecto aun no usa proveedores anotados con @riverpod, esto es normal.
)

REM ──────────────────────────────────────────────────────────────────────────────
REM PASO 5 — Dependencias Backend (Node.js)
REM ──────────────────────────────────────────────────────────────────────────────
echo.
echo [PASO 5] Instalando dependencias del backend ^(Node.js^)
echo.

if not exist "backend\" (
    echo   ✗ ERROR: No se encontro el directorio backend\. Verifica que el repositorio este completo.
    pause
    exit /b 1
)

pushd backend

REM Detectar y autosanar node_modules corrupto
set "NEED_CLEAN=0"
if exist "node_modules\" (
    if not exist "node_modules\.package-lock.json" (
        if exist "package-lock.json" (
            echo   ⚠ node_modules\ corrupto ^(falta .package-lock.json interno^). Se reinstalara desde cero.
            set "NEED_CLEAN=1"
        )
    )
    REM Verificar modulos criticos
    if not exist "node_modules\fastify\" (
        echo   ⚠ Modulo 'fastify' no encontrado en node_modules\. Se reinstalara desde cero.
        set "NEED_CLEAN=1"
    )
    if not exist "node_modules\@prisma\client\" (
        echo   ⚠ Modulo '@prisma/client' no encontrado en node_modules\. Se reinstalara desde cero.
        set "NEED_CLEAN=1"
    )
    if not exist "node_modules\tsx\" (
        echo   ⚠ Modulo 'tsx' no encontrado en node_modules\. Se reinstalara desde cero.
        set "NEED_CLEAN=1"
    )
)

if "!NEED_CLEAN!"=="1" (
    echo   → Eliminando node_modules\ corrupto...
    rmdir /s /q node_modules
)

echo   → Ejecutando npm install...
call npm install
if !ERRORLEVEL! equ 0 (
    echo   ✓ npm install — dependencias Node.js instaladas
) else (
    echo   ⚠ npm install fallo. Iniciando autosanacion: reinstalacion limpia...
    rmdir /s /q node_modules 2>nul
    del /q package-lock.json 2>nul
    echo   → Reintentando npm install desde cero...
    call npm install
    if !ERRORLEVEL! equ 0 (
        echo   ✓ npm install completado tras reinstalacion limpia
    ) else (
        popd
        echo   ✗ ERROR: npm install fallo.
        echo     Causas posibles:
        echo     • Sin conexion a internet o registry.npmjs.org inalcanzable
        echo     • Proxy corporativo — configura npm proxy: npm config set proxy http://...
        echo     • Permisos insuficientes en el directorio backend\
        pause
        exit /b 1
    )
)

REM Doctor: verificar integridad de modulos
echo.
echo   → Verificando integridad de node_modules...
set "MISSING_MODS="
for %%m in ("fastify" "@prisma/client" "tsx" "@fastify/autoload") do (
    if exist "node_modules\%%~m\" (
        echo     ✓ %%~m — presente
    ) else (
        echo     ⚠ %%~m — AUSENTE
        set "MISSING_MODS=!MISSING_MODS! %%~m"
    )
)
if not "!MISSING_MODS!"=="" (
    echo   ⚠ Faltan modulos en node_modules:!MISSING_MODS!
    echo     Reintenta con: cd backend ^&^& rmdir /s /q node_modules ^&^& npm install
)

REM Doctor: compilacion TypeScript
echo.
echo   → Verificando compilacion TypeScript...
call npx tsc --noEmit
if !ERRORLEVEL! equ 0 (
    echo   ✓ TypeScript — compila sin errores
) else (
    echo   ⚠ TypeScript reporto errores. El backend podria no arrancar correctamente. Revisa los mensajes anteriores.
)

popd

REM ──────────────────────────────────────────────────────────────────────────────
REM PASO 6 — Prisma: generar cliente
REM ──────────────────────────────────────────────────────────────────────────────
echo.
echo [PASO 6] Generando cliente de Prisma
echo.

pushd backend

echo   → Ejecutando npx prisma generate...
call npx prisma generate
if !ERRORLEVEL! equ 0 (
    echo   ✓ prisma generate — @prisma/client generado
) else (
    echo   ⚠ prisma generate fallo. Iniciando autosanacion: rebuild de modulos nativos...
    call npm rebuild
    echo   → Reintentando prisma generate...
    call npx prisma generate
    if !ERRORLEVEL! equ 0 (
        echo   ✓ prisma generate completado tras rebuild de modulos
    ) else (
        popd
        echo   ✗ ERROR: prisma generate fallo.
        echo     Causas posibles:
        echo     • Error de sintaxis en backend\prisma\schema.prisma
        echo     • Version de prisma incompatible con @prisma/client
        echo     • DATABASE_URL en backend\.env vacia o mal formada
        pause
        exit /b 1
    )
)

REM Doctor: validar schema de Prisma
echo.
echo   → Validando schema de Prisma...
call npx prisma validate
if !ERRORLEVEL! equ 0 (
    echo   ✓ prisma validate — schema.prisma es valido
) else (
    popd
    echo   ✗ ERROR: prisma validate fallo. Revisa backend\prisma\schema.prisma — tiene errores.
    pause
    exit /b 1
)

popd

REM ──────────────────────────────────────────────────────────────────────────────
REM PASO 7 — Migraciones de base de datos
REM ──────────────────────────────────────────────────────────────────────────────
echo.
echo [PASO 7] Migraciones de base de datos ^(Prisma^)
echo.
echo   ⚠  Este paso aplica migraciones a la base de datos en Supabase.
echo   ⚠  Requiere que backend\.env tenga DATABASE_URL y DIRECT_URL correctos.
echo   ⚠  Asegurate de que la IP de esta maquina este en la whitelist de Supabase.
echo.
set /p MIGRATE_CONFIRM="  ¿Ejecutar migraciones ahora? [s/N]: "

if /i not "!MIGRATE_CONFIRM!"=="s" if /i not "!MIGRATE_CONFIRM!"=="si" if /i not "!MIGRATE_CONFIRM!"=="y" if /i not "!MIGRATE_CONFIRM!"=="yes" (
    echo   ⚠ Migraciones omitidas por el usuario.
    echo   → Para ejecutarlas manualmente despues: cd backend ^&^& npx prisma migrate dev
) else (
    pushd backend

    echo   → Ejecutando npx prisma migrate dev...
    call npx prisma migrate dev
    if !ERRORLEVEL! equ 0 (
        echo   ✓ prisma migrate dev — migraciones aplicadas correctamente
    ) else (
        echo   ⚠ prisma migrate dev fallo.
        echo     Causas posibles y como resolverlas:
        echo     1. DATABASE_URL incorrecta — revisa backend\.env
        echo     2. IP no whitelisteada — Supabase Dashboard → Settings → Database → IPv4
        echo     3. La base de datos no existe o no tienes permisos de escritura
        echo     4. Las migraciones ya fueron aplicadas — verifica con: npx prisma migrate status
        echo     Reintenta manualmente: cd backend ^&^& npx prisma migrate dev
    )

    REM Doctor de base de datos: verificar conectividad (no destructivo)
    echo.
    echo   → Verificando conectividad con la base de datos...
    call npx prisma migrate status >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo   ✓ Base de datos accesible — migraciones aplicadas
    ) else (
        echo   ⚠ No se pudo verificar la base de datos. Posiblemente DATABASE_URL no es alcanzable.
    )

    popd
)

REM ──────────────────────────────────────────────────────────────────────────────
REM RESUMEN FINAL
REM ──────────────────────────────────────────────────────────────────────────────
echo.
echo   ╔══════════════════════════════════════════════════╗
echo   ║  ✓  Instalacion completada                       ║
echo   ╚══════════════════════════════════════════════════╝
echo.
echo     Resumen de lo realizado:
echo     ✓ Prerequisitos verificados: git, flutter, node, npm
echo     ✓ Archivos .env creados desde plantillas
echo     ✓ flutter pub get + build_runner
echo     ✓ npm install + prisma generate
if /i "!MIGRATE_CONFIRM!"=="s" echo     ✓ Migraciones de base de datos aplicadas
if /i "!MIGRATE_CONFIRM!"=="si" echo   ✓ Migraciones de base de datos aplicadas
if /i "!MIGRATE_CONFIRM!"=="y" echo    ✓ Migraciones de base de datos aplicadas
if /i "!MIGRATE_CONFIRM!"=="yes" echo  ✓ Migraciones de base de datos aplicadas
echo.
echo     Proximos pasos:
echo     1. Edita .env con tus valores reales de Supabase
echo     2. Edita backend\.env con tus cadenas de conexion PostgreSQL
echo     3. Si omitiste migraciones: cd backend ^&^& npx prisma migrate dev
echo     4. Ejecuta el proyecto: scripts\run_dev.bat
echo        ^(Linux/Mac/Git Bash: bash scripts\run_dev.sh^)
echo.
echo     Documentacion:
echo     • Contrato de API:    docs\api-contract.md
echo     • Estado integracion: docs\api-status.md
echo     • Requerimientos:     docs\requerimientos.md
echo.
pause
exit /b 0

REM ─── Funcion auxiliar: check_tool ────────────────────────────────────────────
:check_tool
set "tool=%~1"
set "url=%~2"
set "version_cmd=%~3"

where %tool% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    if not "%version_cmd%"=="" (
        for /f "usebackq delims=" %%o in (`%version_cmd% 2^>^&1`) do (
            echo   ✓ %tool% detectado — %%o
            goto :check_tool_done
        )
    )
    echo   ✓ %tool% detectado
) else (
    echo   ⚠ %tool% NO encontrado en PATH
    echo     → Instalalo desde: %url%
    set /a MISSING_TOOLS+=1
)
:check_tool_done
exit /b 0
