#!/usr/bin/env python3
"""CLI script to run database seeding for Luna AI monorepo."""

import os
import sys

# Ensure repository root and app directory are in sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
API_APP_DIR = os.path.join(ROOT_DIR, "apps", "backend", "api")

sys.path.insert(0, ROOT_DIR)
sys.path.insert(0, API_APP_DIR)

if __name__ == "__main__":
    from app.db.seed import main
    main()
