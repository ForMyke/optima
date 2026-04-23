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

```bash
cp transportes-backend/.env.example transportes-backend/.env
