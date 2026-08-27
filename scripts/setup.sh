#!/usr/bin/env bash
set -e

# Resolve repository root relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "==> Setting up local Python monorepo environment in $ROOT_DIR..."

# Create .venv if it does not exist
if [ ! -d ".venv" ]; then
    echo "==> Creating virtual environment at .venv..."
    python3 -m venv .venv
else
    echo "==> Existing virtual environment found at .venv"
fi

# Activate virtual environment
echo "==> Activating .venv..."
source .venv/bin/activate

# Upgrade pip
echo "==> Upgrading pip..."
python -m pip install --upgrade pip

# Install local packages in editable mode
echo "==> Installing local packages using editable installs (pip install -e)..."
pip install -e "$ROOT_DIR/packages/shared"
pip install -e "$ROOT_DIR/packages/ai"
pip install -e "$ROOT_DIR/apps/backend/api"
pip install -e "$ROOT_DIR/apps/backend/mcp"
pip install -e "$ROOT_DIR/apps/backend/workers"


# Create .env from .env.example if it doesn't exist
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "==> Copying .env.example to .env..."
    cp .env.example .env
fi

echo "==> Setup completed successfully!"
