#!/usr/bin/env bash
set -e

# Resolve repository root relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

# Enable Docker BuildKit for ultra-fast parallel builds & layer caching
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

COMPOSE_FILE="docker-compose.prod.yml"

# Ensure .env file exists
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    echo "==> Creating .env from .env.example with secure permissions..."
    cp .env.example .env
    chmod 600 .env
  else
    echo "==> ERROR: .env file missing and .env.example not found!"
    exit 1
  fi
fi

ACTION="${1:-up}"
shift || true

case "$ACTION" in
  up)
    echo "============================================================"
    echo "🚀 Starting LUNA AI Production Environment (Lean & Fast)"
    echo "------------------------------------------------------------"
    echo "  • Compose File : ${COMPOSE_FILE}"
    echo "  • Mode         : Production (no reload / refresh)"
    echo "  • Local API    : http://127.0.0.1:8888"
    echo "  • FastMCP      : http://127.0.0.1:8889"
    echo "  • PostgreSQL   : 127.0.0.1:5433 (internal isolated)"
    echo "  • Redis        : 127.0.0.1:6380 (internal isolated)"
    echo "  • Qdrant       : 127.0.0.1:6333 (internal isolated)"
    echo "============================================================"
    
    docker compose -f "${COMPOSE_FILE}" up -d --build "$@"
    
    echo ""
    echo "==> Waiting for services to become healthy..."
    sleep 5
    docker compose -f "${COMPOSE_FILE}" ps
    echo ""
    echo "✅ LUNA AI Production stack is up and running."
    ;;

  down)
    echo "🛑 Stopping LUNA AI Production stack..."
    docker compose -f "${COMPOSE_FILE}" down "$@"
    echo "✅ Containers stopped."
    ;;

  restart)
    echo "🔄 Re-applying configuration and restarting LUNA AI Production stack..."
    docker compose -f "${COMPOSE_FILE}" up -d "$@"
    echo ""
    echo "==> Waiting for services..."
    sleep 3
    docker compose -f "${COMPOSE_FILE}" ps
    echo "✅ Containers updated."
    ;;

  logs)
    docker compose -f "${COMPOSE_FILE}" logs -f "$@"
    ;;

  ps|status)
    docker compose -f "${COMPOSE_FILE}" ps "$@"
    ;;

  seed)
    echo "🌱 Running database seeder/migration inside api container..."
    docker compose -f "${COMPOSE_FILE}" exec api python -m app.db.seed
    ;;

  *)
    echo "Usage: $0 {up|down|restart|logs|ps|seed} [extra docker compose args]"
    exit 1
    ;;
esac
