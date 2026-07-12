#!/usr/bin/env bash
# =============================================================================
# SIRE - Ejecución en desarrollo (Linux / macOS / Git Bash)
# =============================================================================
# Uso: bash scripts/run_dev.sh
#
# Inicia el backend (Fastify) y la app Flutter concurrentemente.
# Al detener Flutter (Ctrl+C), el backend se cierra automáticamente.
# =============================================================================

set -euo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Banner ──────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║   SIRE - Ejecución en desarrollo             ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Verificación previa ─────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -f "backend/.env" ]; then
    echo -e "  ${RED}✗ backend/.env no encontrado.${NC}"
    echo -e "  ${YELLOW}->${NC} Ejecuta primero: ${CYAN}bash scripts/setup.sh${NC}"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo -e "  ${RED}✗ .env (Flutter) no encontrado.${NC}"
    echo -e "  ${YELLOW}->${NC} Ejecuta primero: ${CYAN}bash scripts/setup.sh${NC}"
    exit 1
fi

# Validar que las variables críticas no estén con placeholder
VARS_MISSING=false
for var in SUPABASE_URL SUPABASE_ANON_KEY API_BASE_URL; do
    value=$(grep "^${var}=" .env 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d ' ')
    if [ -z "$value" ] || echo "$value" | grep -qiE "tu-proyecto|tu-anon-key|placeholder|ejemplo"; then
        echo -e "  ${YELLOW}⚠${NC} Variable ${BOLD}$var${NC} en .env - aún tiene valor placeholder"
        VARS_MISSING=true
    fi
done
if [ "$VARS_MISSING" = true ]; then
    echo -e "  ${RED}✗${NC} Edita ${CYAN}.env${NC} con los valores reales de Supabase antes de continuar."
    exit 1
fi

echo -e "  ${GREEN}✓${NC} Archivos .env verificados"
echo ""

# ─── Iniciar Backend ─────────────────────────────────────────────────────────
BACKEND_PID=""

cleanup() {
    echo ""
    echo -e "  ${CYAN}->${NC} Deteniendo servicios..."
    if [ -n "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" 2>/dev/null; then
        echo -e "  ${CYAN}->${NC} Cerrando backend (PID $BACKEND_PID)..."
        kill "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Backend detenido"
    fi
    echo -e "  ${GREEN}✓${NC} Todos los servicios detenidos. ¡Hasta luego!"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

echo -e "  ${BOLD}${MAGENTA}[Backend]${NC} Iniciando Fastify en puerto 3000..."
cd "$REPO_ROOT/backend"
npm run dev &
BACKEND_PID=$!
cd "$REPO_ROOT"

echo -e "  ${MAGENTA}[Backend]${NC} PID $BACKEND_PID - esperando a que el servidor esté listo..."

# Esperar activamente a que el backend responda (hasta 15s)
MAX_WAIT=15
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/api/v1/users/profiles" 2>/dev/null | grep -qE "^(200|401|404)"; then
        echo -e "  ${GREEN}✓${NC} Backend respondiendo - listo"
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "  ${YELLOW}⚠${NC} Backend no respondió en ${MAX_WAIT}s. Puede estar iniciándose aún."
    echo -e "  ${YELLOW}⚠${NC} La app Flutter arrancará igual, pero puede fallar si el backend no está listo."
fi

echo ""

# ─── Iniciar Flutter ─────────────────────────────────────────────────────────
echo -e "  ${BOLD}${MAGENTA}[Flutter]${NC} Iniciando app..."

# Listar dispositivos disponibles y ofrecer selección
echo -e "  ${CYAN}->${NC} Dispositivos disponibles:"
DEVICES=$(flutter devices 2>/dev/null | tail -n +3 || echo "")
if [ -z "$DEVICES" ]; then
    echo -e "    ${YELLOW}⚠${NC} No se detectaron dispositivos. Conecta un dispositivo o inicia un emulador."
    echo -e "  ${YELLOW}->${NC} Ejecutando flutter run con selección automática..."
    flutter run
else
    echo "$DEVICES"
    echo ""
    echo -e "  ${CYAN}->${NC} Selecciona un dispositivo (escribe el ID) o presiona Enter para usar el predeterminado:"
    read -r DEVICE_ID
    if [ -n "$DEVICE_ID" ]; then
        flutter run -d "$DEVICE_ID"
    else
        flutter run
    fi
fi

# El trap en EXIT se encargará de limpiar el backend cuando Flutter termine
