## `Makefile`

```makefile
.PHONY: start reset stop logs build

start: build
	@./dev-start.sh

reset: build
	@./dev-start.sh --reset

stop:
	@cd transportes-backend && docker compose down

logs:
	@docker logs -f transportes_backend

build:
	@cd transportes-backend && ./gradlew bootJar -x test -q
```

---

## `dev-start.sh`

```bash
#!/bin/bash
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${YELLOW}⏳ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/transportes-backend"
FRONTEND_DIR="$ROOT_DIR/frontend_optima"
SQL_ORIGINAL="$ROOT_DIR/BaseFMPMEX/respaldo_nube.sql"
SQL_CLEAN="$ROOT_DIR/BaseFMPMEX/respaldo_limpio.sql"

RESET=false
for arg in "$@"; do
  [[ $arg == "--reset" ]] && RESET=true
done

echo ""
echo "================================================"
echo "   🚀  Entorno de desarrollo local - Optima"
echo "================================================"
echo ""

info "Compilando backend..."
cd "$BACKEND_DIR"
./gradlew bootJar -x test -q || err "Falló Gradle"
ok "JAR listo"

if [ "$RESET" = true ]; then
  info "Reset: bajando contenedores y volúmenes..."
  docker compose down -v
  sed '5d' "$SQL_ORIGINAL" > "$SQL_CLEAN"
  ok "SQL limpio generado"
else
  docker compose down
fi

info "Levantando Postgres..."
docker compose up -d postgres_db
until docker exec postgres_db pg_isready -U postgres -q 2>/dev/null; do sleep 2; done
ok "Postgres listo"

if [ "$RESET" = true ]; then
  info "Importando base de datos..."
  docker exec -i postgres_db psql -U postgres -d transportes_db \
    < "$SQL_CLEAN" 2>&1 | grep "^ERROR" | grep -v "role .* does not exist" || true
  ok "BD importada"
fi

info "Levantando backend..."
docker compose up -d --build transportes_backend
ok "Backend en http://localhost:8080"

cd "$FRONTEND_DIR"
[ ! -d "node_modules" ] && npm install -q && ok "Dependencias instaladas"

echo ""
echo "================================================"
ok "Entorno listo"
echo ""
echo "  Backend  → http://localhost:8080"
echo "  Frontend → corre: cd frontend_optima && npm run dev"
echo "  Detener  → make stop"
echo "================================================"
echo ""
```

---

## `README.md`

```markdown
# Optima Workspace

Monorepo de desarrollo local para el proyecto Optima Transportes.

## Proyectos

| Proyecto | Descripción |
|---|---|
| `transportes-backend` | API REST Spring Boot |
| `frontend_optima` | Frontend Next.js |
| `BaseFMPMEX` | Respaldo de base de datos |

## Requisitos

- Docker Desktop
- Java 21
- Node.js 22
- Make

## Clonar el workspace completo

```bash
git clone --recurse-submodules git@github.com:ForMyke/optima.git
cd optima
chmod +x dev-start.sh
```

## Comandos

| Comando | Descripción |
|---|---|
| `make start` | Compila y levanta backend + postgres |
| `make reset` | Reset completo: borra BD y reimporta |
| `make stop` | Detiene todos los contenedores |
| `make logs` | Ver logs del backend |
| `make build` | Solo recompila el JAR |

## Levantar el frontend

```bash
cd frontend_optima
npm run dev
# Abre http://localhost:3000
```

## Variables de entorno

Copia el archivo de ejemplo y configura tus variables:

```bash
cp transportes-backend/.env.example transportes-backend/.env
```
```

---

Después de crear los tres archivos:

```bash
chmod +x dev-start.sh
git add .
git commit -m "add: Makefile, dev-start.sh y README"
git push
```
