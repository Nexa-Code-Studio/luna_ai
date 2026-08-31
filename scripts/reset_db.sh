#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔄 Resetting Luna AI Database & Re-seeding..."

if [ -f "$ROOT_DIR/.venv/bin/python" ]; then
    "$ROOT_DIR/.venv/bin/python" "$SCRIPT_DIR/reset_db.py"
elif command -v docker &> /dev/null && docker compose ps --services 2>/dev/null | grep -q "^api$"; then
    docker compose exec api python -m app.db.reset
else
    python3 "$SCRIPT_DIR/reset_db.py"
fi

echo "✅ Database reset & re-seeding completed successfully!"
