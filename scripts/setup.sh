#!/usr/bin/env bash
# =============================================================================
# SIRE - Instalación automatizada (Linux / macOS / Git Bash)
# =============================================================================
# Uso: bash scripts/setup.sh
#
# Verifica prerequisitos, instala dependencias, configura variables
# de entorno y ejecuta migraciones de base de datos.
# Cada paso se valida antes de continuar; si algo falla, se detiene
# con un diagnóstico detallado para que puedas resolverlo.
# =============================================================================

set -euo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Utilidades de logging ───────────────────────────────────────────────────
step()       { echo -e "\n${BOLD}${CYAN}[PASO $1]${NC} ${2}"; }
success()    { echo -e "  ${GREEN}✓${NC} $1"; }
warn()       { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()       { echo -e "\n${RED}${BOLD}✗ ERROR:${NC} $1"; exit 1; }
info()       { echo -e "  ${CYAN}->${NC} $1"; }

# ─── Banner ──────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║   SIRE - Sistema Integral de Reservas        ║"
echo "  ║          Estratégicas                        ║"
echo "  ║                                              ║"
echo "  ║   Instalación automatizada                   ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ──────────────────────────────────────────────────────────────────────────────
# PASO 1 - Verificar prerequisitos
# ──────────────────────────────────────────────────────────────────────────────
step 1 "Verificando herramientas necesarias"

MISSING_TOOLS=()

check_tool() {
    local tool=$1
    local install_url=$2
    local version_cmd=$3

    if command -v "$tool" &> /dev/null; then
        if [ -n "$version_cmd" ]; then
            local ver
            ver=$(eval "$version_cmd" 2>&1 | head -1)
            success "$tool detectado - $ver"
        else
            success "$tool detectado"
        fi
        return 0
    else
        warn "$tool NO encontrado en PATH"
        info "Instálalo desde: $install_url"
        MISSING_TOOLS+=("$tool")
        return 1
    fi
}

check_tool "git" \
    "https://git-scm.com/downloads" \
    "git --version"

check_tool "flutter" \
    "https://docs.flutter.dev/get-started/install" \
    "flutter --version 2>&1 | head -1"

check_tool "node" \
    "https://nodejs.org/ (v20 LTS recomendada)" \
    "node --version"

check_tool "npm" \
    "https://nodejs.org/ (incluido con Node.js)" \
    "npm --version"

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo ""
    fail "Faltan herramientas: ${MISSING_TOOLS[*]}. Instálalas y vuelve a ejecutar este script."
fi

# Doctor de versiones recomendadas
info "Validando versiones contra los requerimientos del proyecto..."
FLUTTER_VER=$(flutter --version 2>&1 | grep -oP 'Flutter \K[0-9]+\.[0-9]+' | head -1 || echo "0.0")
NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)

if [ "$(echo "$FLUTTER_VER" | cut -d. -f1)" -ge 3 ] 2>/dev/null; then
    success "Flutter $FLUTTER_VER - cumple con ≥3.11 requerido"
else
    warn "Flutter $FLUTTER_VER detectado. El proyecto requiere Flutter SDK ≥3.11.3. Puede fallar al compilar."
fi

if [ "$NODE_MAJOR" -ge 20 ] 2>/dev/null; then
    success "Node.js v$NODE_MAJOR - cumple con ≥20 requerido"
else
    warn "Node.js v$NODE_MAJOR detectado. El proyecto requiere Node.js ≥20 LTS."
fi

# ──────────────────────────────────────────────────────────────────────────────
# PASO 2 - Variables de entorno
# ──────────────────────────────────────────────────────────────────────────────
step 2 "Configurando archivos de variables de entorno"

# ── Flutter .env ──
if [ -f ".env" ]; then
    success ".env (Flutter) ya existe - se conserva intacto"
else
    if [ -f ".env.example" ]; then
        cp .env.example .env
        success ".env (Flutter) creado desde .env.example"
        warn "Edita .env con los valores reales de tu proyecto Supabase antes de ejecutar la app."
        info "  Variables requeridas: SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL"
    else
        fail "No se encontró .env.example en la raíz del proyecto. ¿Clonaste el repositorio completo?"
    fi
fi

# ── Backend .env ──
if [ -f "backend/.env" ]; then
    success "backend/.env ya existe - se conserva intacto"
else
    if [ -f "backend/.env.example" ]; then
        cp backend/.env.example backend/.env
        success "backend/.env creado desde backend/.env.example"
        warn "Edita backend/.env con la cadena de conexión real de Supabase PostgreSQL."
        info "  Obtén DATABASE_URL y DIRECT_URL en: Supabase Dashboard -> Settings -> Database"
    else
        fail "No se encontró backend/.env.example. ¿Está completo el repositorio?"
    fi
fi

# Doctor de variables: detectar placeholders sin reemplazar en .env ya existentes
info "Revisando valores placeholder en archivos .env..."
check_placeholder() {
    local file=$1
    local var=$2
    local value
    value=$(grep "^${var}=" "$file" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d ' ')
    if [ -z "$value" ] || echo "$value" | grep -qiE "tu-proyecto|tu-anon-key|usuario_aqui|password_aqui|ejemplo"; then
        warn "$var en $file - aún tiene valor placeholder, debe ser reemplazado"
        return 1
    else
        success "$var en $file - configurado"
        return 0
    fi
}

# Solo validar si los .env ya existían (no recién copiados, porque esos siempre son placeholder)
if [ -f ".env" ]; then
    check_placeholder ".env" "SUPABASE_URL" || true
    check_placeholder ".env" "SUPABASE_ANON_KEY" || true
    check_placeholder ".env" "API_BASE_URL" || true
fi
if [ -f "backend/.env" ]; then
    check_placeholder "backend/.env" "DATABASE_URL" || true
    check_placeholder "backend/.env" "DIRECT_URL" || true
fi

# ──────────────────────────────────────────────────────────────────────────────
# PASO 3 - Dependencias Flutter/Dart
# ──────────────────────────────────────────────────────────────────────────────
step 3 "Instalando dependencias de Flutter/Dart"

info "Ejecutando flutter pub get..."
if flutter pub get; then
    success "flutter pub get - paquetes Dart instalados"
else
    warn "flutter pub get falló. Iniciando autosanación: reparando caché de pub..."
    flutter pub cache repair
    info "Reintentando flutter pub get..."
    if flutter pub get; then
        success "flutter pub get completado tras reparar caché de pub"
    else
        fail "flutter pub get falló incluso tras reparar caché. Causas posibles:\n  • Sin conexión a internet o pub.dev inalcanzable\n  • Proxy corporativo bloqueando la conexión\n  • Espacio insuficiente en disco"
    fi
fi

# Doctor: integridad del código Dart
info "Ejecutando dart analyze para validar integridad del código..."
DART_ANALYZE_OUT=$(dart analyze lib/ --no-fatal-infos --no-fatal-warnings 2>&1)
DART_ANALYZE_EXIT=$?
echo "$DART_ANALYZE_OUT" | tail -5
if [ $DART_ANALYZE_EXIT -eq 0 ]; then
    success "dart analyze - sin errores de compilación en lib/"
else
    warn "dart analyze reportó advertencias. No impiden ejecutar la app, pero revisa los mensajes anteriores."
fi

# ──────────────────────────────────────────────────────────────────────────────
# PASO 4 - Generación de código (build_runner)
# ──────────────────────────────────────────────────────────────────────────────
step 4 "Ejecutando generador de código con build_runner"

info "Generando archivos .g.dart con dart run build_runner build..."
if dart run build_runner build --delete-conflicting-outputs; then
    success "build_runner - generación completada"
else
    warn "build_runner falló. Iniciando autosanación: limpieza de caché de build_runner..."
    dart run build_runner clean 2>/dev/null || true
    # Eliminar archivos .g.dart corruptos que puedan estar bloqueando
    find lib/ -name "*.g.dart" -delete 2>/dev/null || true
    info "Reintentando build_runner con caché limpia..."
    if dart run build_runner build --delete-conflicting-outputs; then
        success "build_runner - generación completada tras limpieza"
    else
        fail "build_runner falló definitivamente.\n  Causas posibles:\n  • Conflicto de anotaciones (@riverpod) con versiones de dependencias\n  • Archivo .g.dart corrupto que no se pudo eliminar automáticamente\n  • Error de sintaxis en un archivo Dart que impide la generación\n  Acción manual: ejecuta dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs y revisa la salida."
    fi
fi

# Doctor: verificar que los archivos .g.dart existen
info "Verificando archivos generados..."
G_FILES=$(find lib/ -name "*.g.dart" 2>/dev/null | wc -l | tr -d ' ')
if [ "${G_FILES:-0}" -gt 0 ]; then
    success "build_runner - $G_FILES archivo(s) .g.dart generados en lib/"
else
    info "No se detectaron archivos .g.dart. Si el proyecto aún no usa proveedores anotados con @riverpod, esto es normal."
fi

# ──────────────────────────────────────────────────────────────────────────────
# PASO 5 - Dependencias Backend (Node.js)
# ──────────────────────────────────────────────────────────────────────────────
step 5 "Instalando dependencias del backend (Node.js)"

if [ ! -d "backend" ]; then
    fail "No se encontró el directorio backend/. Verifica que el repositorio esté completo."
fi

cd backend

# Detectar y autosanar node_modules corrupto
NEED_CLEAN=false
if [ -d "node_modules" ]; then
    if [ ! -f "node_modules/.package-lock.json" ] && [ -f "package-lock.json" ]; then
        warn "node_modules/ está corrupto (falta .package-lock.json interno). Se reinstalará desde cero."
        NEED_CLEAN=true
    fi
    # Verificar que módulos críticos existan físicamente
    for mod in "fastify" "@prisma/client" "tsx"; do
        if [ ! -d "node_modules/$mod" ]; then
            warn "Módulo '$mod' no encontrado en node_modules/. Se reinstalará desde cero."
            NEED_CLEAN=true
            break
        fi
    done
fi

if [ "$NEED_CLEAN" = true ]; then
    info "Eliminando node_modules/ corrupto..."
    rm -rf node_modules
fi

info "Ejecutando npm install..."
if npm install; then
    success "npm install - dependencias Node.js instaladas"
else
    warn "npm install falló. Iniciando autosanación: reinstalación limpia..."
    rm -rf node_modules package-lock.json
    info "Reintentando npm install desde cero..."
    if npm install; then
        success "npm install completado tras reinstalación limpia"
    else
        cd ..
        fail "npm install falló. Causas posibles:\n  • Sin conexión a internet o registry.npmjs.org inalcanzable\n  • Proxy corporativo - configura npm proxy: npm config set proxy http://...\n  • Permisos insuficientes en el directorio backend/"
    fi
fi

# Doctor: verificar integridad de módulos instalados
info "Verificando integridad de node_modules..."
MISSING_MODS=""
for mod in "fastify" "@prisma/client" "tsx" "@fastify/autoload"; do
    if [ -d "node_modules/$mod" ]; then
        success "$mod - presente"
    else
        warn "$mod - AUSENTE"
        MISSING_MODS="$MISSING_MODS $mod"
    fi
done

if [ -n "$MISSING_MODS" ]; then
    warn "Faltan módulos en node_modules:$MISSING_MODS. El backend puede fallar al iniciar."
    info "Reintenta con: cd backend && rm -rf node_modules && npm install"
fi

# Doctor: compilación TypeScript
info "Verificando compilación TypeScript..."
TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
TSC_EXIT=$?
echo "$TSC_OUTPUT" | tail -3
if [ $TSC_EXIT -eq 0 ]; then
    success "TypeScript - compila sin errores"
else
    warn "TypeScript reportó errores. El backend podría no arrancar correctamente. Revisa los mensajes anteriores."
fi

cd ..

# ──────────────────────────────────────────────────────────────────────────────
# PASO 6 - Prisma: generar cliente
# ──────────────────────────────────────────────────────────────────────────────
step 6 "Generando cliente de Prisma"

cd backend

info "Ejecutando npx prisma generate..."
if npx prisma generate; then
    success "prisma generate - @prisma/client generado"
else
    warn "prisma generate falló. Iniciando autosanación: rebuild de módulos nativos..."
    npm rebuild
    info "Reintentando prisma generate..."
    if npx prisma generate; then
        success "prisma generate completado tras rebuild de módulos"
    else
        cd ..
        fail "prisma generate falló.\n  Causas posibles:\n  • Error de sintaxis en backend/prisma/schema.prisma\n  • Versión de prisma incompatible con @prisma/client\n  • DATABASE_URL en backend/.env vacía o mal formada"
    fi
fi

# Doctor: validar schema de Prisma
info "Validando schema de Prisma..."
if npx prisma validate; then
    success "prisma validate - schema.prisma es válido"
else
    cd ..
    fail "prisma validate falló. Revisa backend/prisma/schema.prisma - el schema tiene errores."
fi

cd ..

# ──────────────────────────────────────────────────────────────────────────────
# PASO 7 - Migraciones de base de datos
# ──────────────────────────────────────────────────────────────────────────────
step 7 "Migraciones de base de datos (Prisma)"

echo -e "  ${YELLOW}⚠${NC}  Este paso aplica migraciones a la base de datos en Supabase."
echo -e "  ${YELLOW}⚠${NC}  Requiere que backend/.env tenga DATABASE_URL y DIRECT_URL correctos."
echo -e "  ${YELLOW}⚠${NC}  Asegúrate de que la IP de esta máquina esté en la whitelist de Supabase."
echo ""
read -r -p "  ¿Ejecutar migraciones ahora? [s/N]: " MIGRATE_CONFIRM

MIGRATE_CONFIRM_LOWER=$(echo "$MIGRATE_CONFIRM" | tr '[:upper:]' '[:lower:]')
if [ "$MIGRATE_CONFIRM_LOWER" != "s" ] && [ "$MIGRATE_CONFIRM_LOWER" != "si" ] && [ "$MIGRATE_CONFIRM_LOWER" != "y" ] && [ "$MIGRATE_CONFIRM_LOWER" != "yes" ]; then
    warn "Migraciones omitidas por el usuario."
    info "Para ejecutarlas manualmente después: cd backend && npx prisma migrate dev"
else
    cd backend

    info "Ejecutando npx prisma migrate dev..."
    if npx prisma migrate dev; then
        success "prisma migrate dev - migraciones aplicadas correctamente"
    else
        warn "prisma migrate dev falló."
        info "Causas posibles y cómo resolverlas:"
        info "  1. DATABASE_URL incorrecta -> revisa backend/.env"
        info "  2. IP no whitelisteada -> Supabase Dashboard -> Settings -> Database -> IPv4"
        info "  3. La base de datos no existe o no tienes permisos de escritura"
        info "  4. Las migraciones ya fueron aplicadas -> verifica con: npx prisma migrate status"
        info "Reintenta manualmente: cd backend && npx prisma migrate dev"
    fi

    # Doctor de base de datos: verificar conectividad (no destructivo)
    info "Verificando conectividad con la base de datos..."
    if npx prisma migrate status 2>/dev/null; then
        success "Base de datos accesible - conexión a PostgreSQL verificada"
    else
        warn "No se pudo verificar la base de datos. Posiblemente DATABASE_URL no es alcanzable."
    fi

    cd ..
fi

# ──────────────────────────────────────────────────────────────────────────────
# RESUMEN FINAL
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  ✓  Instalación completada                       ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Resumen de lo realizado:${NC}"
echo -e "  ✓ Prerequisitos verificados: git, flutter, node, npm"
echo -e "  ✓ Archivos .env creados desde plantillas"
echo -e "  ✓ flutter pub get + build_runner"
echo -e "  ✓ npm install + prisma generate"
MIGRATE_CONFIRM_LOWER_SUMMARY=$(echo "${MIGRATE_CONFIRM:-n}" | tr '[:upper:]' '[:lower:]')
if [ "$MIGRATE_CONFIRM_LOWER_SUMMARY" = "s" ] || [ "$MIGRATE_CONFIRM_LOWER_SUMMARY" = "si" ] || [ "$MIGRATE_CONFIRM_LOWER_SUMMARY" = "y" ] || [ "$MIGRATE_CONFIRM_LOWER_SUMMARY" = "yes" ]; then
    echo -e "  ✓ Migraciones de base de datos aplicadas"
fi
echo ""
echo -e "  ${BOLD}Próximos pasos:${NC}"
echo -e "  1. Edita ${CYAN}.env${NC} con tus valores reales de Supabase"
echo -e "  2. Edita ${CYAN}backend/.env${NC} con tus cadenas de conexión PostgreSQL"
echo -e "  3. Si omitiste migraciones: ${CYAN}cd backend && npx prisma migrate dev${NC}"
echo -e "  4. Ejecuta el proyecto: ${CYAN}bash scripts/run_dev.sh${NC}"
echo -e "     (Windows: ${CYAN}scripts\\run_dev.bat${NC})"
echo ""
echo -e "  ${BOLD}Documentación:${NC}"
echo -e "  • Contrato de API:    ${CYAN}docs/api-contract.md${NC}"
echo -e "  • Estado integración: ${CYAN}docs/api-status.md${NC}"
echo -e "  • Requerimientos:     ${CYAN}docs/requerimientos.md${NC}"
echo ""
