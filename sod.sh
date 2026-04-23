#!/bin/bash
set -e

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


info "Preparando SQL limpio..."
[ ! -f "$SQL_ORIGINAL" ] && err "No se encontró el SQL en $SQL_ORIGINAL"
sed '5d' "$SQL_ORIGINAL" > "$SQL_CLEAN"
ok "SQL limpio listo"

info "Compilando backend con Gradle..."
cd "$BACKEND_DIR"
./gradlew clean bootJar -x test -q || err "Falló la compilación de Gradle"

if [ "$RESET" = true ]; then
  info "Eliminando contenedores y volúmenes (--reset)..."
  docker compose down -v
  ok "Reset completo"
else
  info "Deteniendo contenedores..."
  docker compose down
  ok "Contenedores detenidos"
fi

info "Levantando Postgres..."
docker compose up -d postgres_db
info "Esperando a que Postgres esté listo..."
until docker exec postgres_db pg_isready -U postgres -q 2>/dev/null; do
  sleep 2
done
ok "Postgres listo"

if [ "$RESET" = true ]; then
  info "Importando base de datos..."
  docker exec -i postgres_db psql -U postgres -d transportes_db \
    < "$SQL_CLEAN" 2>&1 | grep "^ERROR" | grep -v "role .* does not exist" || true
  ok "Base de datos importada"
fi

info "Construyendo y levantando backend..."
docker compose up -d --build transportes_backend
ok "Backend corriendo en http://localhost:8080"

cd "$FRONTEND_DIR"
if [ ! -d "node_modules" ]; then
  info "Instalando dependencias del frontend..."
  npm install -q
  ok "Dependencias instaladas"
else
  ok "Dependencias del frontend ya existen"
fi

echo "  Levantar frontend:  cd frontend_optima && npm run dev"
echo "  Detener Docker:     cd transportes-backend && docker compose down"
