# Implementation Plan: Local Development Environment Setup for Python Monorepo

Configure the repository so the backend services (FastAPI, FastMCP, ARQ Worker) and local packages (`shared`, `ai`, `api`, `mcp`, `workers`) can be set up and run locally without Docker using a single root `.venv` virtual environment.

## User Review Required

> [!IMPORTANT]
> - External infrastructure services (PostgreSQL on port `5432` and Redis on port `6379`) must be running locally on your machine for the backend services to function fully.
> - FastMCP runs on port `8001` and FastAPI runs on port `8000`.

## Open Questions

None. All design choices were clarified:
- `.env` auto-creation from `.env.example` during setup with `localhost` defaults.
- Windows `dev.ps1` launching individual processes in separate PowerShell windows for readable logs.

## Proposed Changes

### Scripts & Automation

#### [NEW] [setup.sh](file:///home/mashupsoat/Project/luna_ai/scripts/setup.sh)
- Set bash options `set -e` for immediate exit on error.
- Resolve repository root directory dynamically relative to `BASH_SOURCE[0]`.
- Create `.venv` if it doesn't exist (`python3 -m venv .venv`).
- Activate `.venv` (`source .venv/bin/activate`).
- Upgrade pip (`python -m pip install --upgrade pip`).
- Install editable local packages (`pip install -e packages/shared`, `pip install -e packages/ai`, `pip install -e apps/backend/api`, `pip install -e apps/backend/mcp`, `pip install -e apps/backend/workers`).
- Copy `.env.example` to `.env` if `.env` does not exist.

#### [NEW] [setup.ps1](file:///home/mashupsoat/Project/luna_ai/scripts/setup.ps1)
- Set `$ErrorActionPreference = 'Stop'`.
- Resolve repository root directory dynamically relative to `$PSScriptRoot`.
- Create `.venv` if it doesn't exist (`python -m venv .venv`).
- Activate `.venv`.
- Upgrade pip (`python -m pip install --upgrade pip`).
- Install editable local packages (`pip install -e packages/shared`, `pip install -e packages/ai`, `pip install -e apps/backend/api`, `pip install -e apps/backend/mcp`, `pip install -e apps/backend/workers`).
- Copy `.env.example` to `.env` if `.env` does not exist.

#### [NEW] [dev.sh](file:///home/mashupsoat/Project/luna_ai/scripts/dev.sh)
- Set bash options `set -e`.
- Resolve repository root directory dynamically.
- Verify `.venv` exists (exit with clear message if missing).
- Activate `.venv`.
- Start 3 background child processes concurrently:
  - FastAPI: `(cd apps/backend/api && PYTHONPATH=. uvicorn app.main:app --reload --port 8000)`
  - FastMCP: `(cd apps/backend/mcp && PYTHONPATH=. python -m app.main)`
  - ARQ Worker: `(cd apps/backend/workers && PYTHONPATH=. arq app.workers.settings.WorkerSettings)`
- Trap `SIGINT`, `SIGTERM`, and `EXIT` signals to cleanly terminate all background child processes when script exits or Ctrl+C is pressed.

#### [NEW] [dev.ps1](file:///home/mashupsoat/Project/luna_ai/scripts/dev.ps1)
- Set `$ErrorActionPreference = 'Stop'`.
- Resolve repository root directory dynamically.
- Verify `.venv` exists.
- Launch 3 separate PowerShell process windows for FastAPI, FastMCP, and ARQ worker with working directory, `PYTHONPATH=.`, and `.venv` activation.

---

### Root Configuration

#### [NEW] [Makefile](file:///home/mashupsoat/Project/luna_ai/Makefile)
- Define targets:
  - `make setup`: Runs `./scripts/setup.sh`
  - `make dev`: Runs `./scripts/dev.sh`
- Set `.PHONY: setup dev`

#### [MODIFY] [.env.example](file:///home/mashupsoat/Project/luna_ai/.env.example)
- Update default connection strings (`DATABASE_URL`, `REDIS_URL`, `QDRANT_URL`) to use `localhost` so local dev works out of the box without Docker networking.
- Include comments showing Docker internal service names for reference.

## Verification Plan

### Automated Tests
- Validate shell script syntax using `bash -n scripts/setup.sh` and `bash -n scripts/dev.sh`.
- Validate PowerShell script syntax using `pwsh -Command "Get-Command -Syntax ..."` or python/pwsh parser if available.
- Validate Makefile syntax using `make -n setup` and `make -n dev`.

### Manual Verification
- Test running `./scripts/setup.sh` to confirm virtual environment activation and editable installs of all 5 packages.
- Test running `./scripts/dev.sh` (or `make dev`) and verify FastAPI, FastMCP, and ARQ worker start up concurrently.
- Test sending Ctrl+C to `./scripts/dev.sh` and verify all 3 child processes terminate cleanly.
