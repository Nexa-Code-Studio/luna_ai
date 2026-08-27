import os
import subprocess
import sys

# Ensure repository root and app directory are in sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
API_APP_DIR = os.path.join(ROOT_DIR, "apps", "backend", "api")

# Auto-switch to .venv python if running under global/system python without packages
VENV_PYTHON = os.path.join(ROOT_DIR, ".venv", "bin", "python")
if os.name == "nt":
    VENV_PYTHON = os.path.join(ROOT_DIR, ".venv", "Scripts", "python.exe")

if os.path.exists(VENV_PYTHON) and sys.executable != VENV_PYTHON and "VIRTUAL_ENV" not in os.environ:
    os.execv(VENV_PYTHON, [VENV_PYTHON] + sys.argv)

sys.path.insert(0, ROOT_DIR)
sys.path.insert(0, API_APP_DIR)

if __name__ == "__main__":
    from app.db.seed import main
    main()
