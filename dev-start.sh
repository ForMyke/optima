#!/bin/bash
set -e

# ─────────────────────────────────────────────
# Colores
# ─────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${YELLOW}⏳ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }

# ─────────────────────────────────────────────
# Rutas
# ─────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/transportes-backend"
FRONTEND_DIR="$ROOT_DIR/frontend_optima"
SQL_ORIGINAL="$ROOT_DIR/BaseFMPMEX/respaldo_nube.sql"
SQL_CLEAN="$ROOT_DIR/BaseFMPMEX/respaldo_limpio.sql"

# ─────────────────────────────────────────────
# Argumentos
# ─────────────────────────────────────────────
RESET=false
for arg in "$@"; do
  case $arg in
    --reset) RESET=true ;;
  esac
done

echo ""
echo "================================================"
echo "   🚀  Entorno de desarrollo local"
echo "================================================"
echo ""

# ─────────────────────────────────────────────
# PASO 1: Limpiar SQL (quitar \restrict)
# ─────────────────────────────────────────────
info "Preparando SQL limpio..."
if [ ! -f "$SQL_ORIGINAL" ]; then
  err "No se encontró el archivo SQL en $SQL_ORIGINAL"
fi
sed '5d' "$SQL_ORIGINAL" > "$SQL_CLEAN"
ok "SQL limpio listo"

# ─────────────────────────────────────────────
# PASO 2: Compilar el backend (JAR)
# ─────────────────────────────────────────────
info "Compilando backend con Gradle..."
cd "$BACKEND_DIR"
./gradlew clean bootJar -x test -q || err "Falló la compilación de Gradle"
ok "JAR compilado en build/libs/"

# ─────────────────────────────────────────────
# PASO 3: Reiniciar Docker (con o sin reset)
# ─────────────────────────────────────────────
if [ "$RESET" = true ]; then
  info "Eliminando contenedores y volúmenes (--reset)..."
  docker compose down -v
  ok "Reset completo"
else
  info "Deteniendo contenedores..."
  docker compose down
  ok "Contenedores detenidos"
fi

# ─────────────────────────────────────────────
# PASO 4: Levantar Postgres
# ─────────────────────────────────────────────
info "Levantando Postgres..."
docker compose up -d postgres_db

info "Esperando a que Postgres esté listo..."
until docker exec postgres_db pg_isready -U postgres -q 2>/dev/null; do
  sleep 2
done
ok "Postgres listo"

# ─────────────────────────────────────────────
# PASO 5: Importar base de datos (solo con --reset)
# ─────────────────────────────────────────────
if [ "$RESET" = true ]; then
  info "Importando base de datos..."
  docker exec -i postgres_db psql -U postgres -d transportes_db \
    < "$SQL_CLEAN" 2>&1 | grep -E "^ERROR" | grep -v "role .* does not exist" || true
  ok "Base de datos importada"
fi

# ─────────────────────────────────────────────
# PASO 6: Levantar Backend
# ─────────────────────────────────────────────
info "Construyendo y levantando backend..."
docker compose up -d --build transportes_backend
ok "Backend corriendo en http://localhost:8080"

# ─────────────────────────────────────────────
# PASO 7: Instalar dependencias del frontend
# ─────────────────────────────────────────────
cd "$FRONTEND_DIR"
if [ ! -d "node_modules" ]; then
  info "Instalando dependencias del frontend..."
  npm install -q
  ok "Dependencias instaladas"
else
  ok "Dependencias del frontend ya existen"
fi

# ─────────────────────────────────────────────
# LISTO
# ─────────────────────────────────────────────
echo ""
echo "================================================"
ok "Entorno listo"
echo ""
echo "  Backend  → http://localhost:8080"
echo "  Frontend → http://localhost:3000"
echo ""
echo "  Para levantar el frontend:"
echo "  cd frontend_optima && npm run dev"
echo ""
echo "  Para detener Docker:"
echo "  cd transportes-backend && docker compose down"
echo "================================================"
echo ""
