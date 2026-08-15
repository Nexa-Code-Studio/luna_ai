#!/usr/bin/env bash
set -e

# Resolve repository root relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

if [ ! -d ".venv" ]; then
    echo "Error: Virtual environment '.venv' not found. Please run ./scripts/setup.sh first." >&2
    exit 1
fi

source .venv/bin/activate

PIDS=()

cleanup() {
    echo ""
    echo "==> Shutting down development processes..."
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    wait 2>/dev/null || true
    echo "==> All processes stopped."
}

trap cleanup INT TERM EXIT

echo "==> Starting FastAPI application server (port 8000)..."
(cd "$ROOT_DIR/apps/backend/api" && PYTHONPATH=. uvicorn app.main:app --reload --port 8000) &
PIDS+=($!)

echo "==> Starting FastMCP AI tool server (port 8001)..."
(cd "$ROOT_DIR/apps/backend/mcp" && PYTHONPATH=. python -m app.main) &
PIDS+=($!)

echo "==> Starting ARQ Worker..."
(cd "$ROOT_DIR/apps/backend/workers" && PYTHONPATH=. arq app.workers.settings.WorkerSettings) &
PIDS+=($!)

echo "==> All backend services started concurrently. Press Ctrl+C to stop."

# Wait for background processes
wait
