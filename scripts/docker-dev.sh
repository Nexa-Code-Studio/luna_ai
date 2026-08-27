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

# Trap Ctrl+C (SIGINT) to automatically shut down containers cleanly
cleanup() {
  echo ""
  echo "🛑 [STOPPING DOCKER]: Shutting down all LUNA AI containers..."
  docker compose down
  echo "✅ All containers stopped cleanly."
  exit 0
}
trap cleanup SIGINT SIGTERM

echo ""
echo "============================================================"
echo "🚀 Starting LUNA AI Interactive Docker Environment"
echo "------------------------------------------------------------"
echo "  • FastAPI Application  : http://localhost:8888"
echo "  • FastMCP Tool Server : http://localhost:8889"
echo "  • PostgreSQL Database  : localhost:5432"
echo "  • Redis Cache / Queue : localhost:6379"
echo "  • Qdrant Vector DB    : http://localhost:6333"
echo "============================================================"
echo "💡 Press Ctrl+C at any time to stop all services automatically."
echo ""

# Run docker compose in foreground to stream colored logs and auto-down on Ctrl+C
docker compose up "$@"
