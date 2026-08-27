#!/usr/bin/env bash
set -e

# Resolve repository root relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "==> 🐳 Starting LUNA AI Fast Docker Environment..."

# Ensure .env file exists
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    echo "==> Copying .env.example to .env..."
    cp .env.example .env
  fi
fi

# Enable Docker BuildKit for ultra-fast parallel builds & layer caching
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Spin up containers in detached mode with build & volume mount support
docker compose up -d --build

echo ""
echo "============================================================"
echo "✅ All LUNA AI Docker containers started successfully!"
echo "------------------------------------------------------------"
echo "  • FastAPI Application  : http://localhost:8888"
echo "  • FastMCP Tool Server : http://localhost:8889"
echo "  • PostgreSQL Database  : localhost:5432"
echo "  • Redis Cache / Queue : localhost:6379"
echo "  • Qdrant Vector DB    : http://localhost:6333"
echo "============================================================"
echo ""
echo "💡 Useful commands:"
echo "  • View live logs : docker compose logs -f"
echo "  • Stop containers: docker compose down"
echo ""
