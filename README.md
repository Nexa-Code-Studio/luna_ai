# Luna AI — Monorepo Architecture

Production-oriented monorepo architecture for Luna AI Phone application backend.

---

## 1. Repository Structure

```text
.
├── apps/
│   ├── luna_mobile/             # Flutter mobile application
│   │
│   └── backend/
│       ├── api/                # FastAPI application server
│       │   ├── app/
│       │   │   ├── api/        # Routes & dependencies
│       │   │   ├── core/       # Logging & config
│       │   │   ├── models/     # SQLAlchemy 2.x models
│       │   │   ├── schemas/    # Pydantic v2 schemas
│       │   │   ├── services/   # Application domain services
│       │   │   └── main.py     # FastAPI entry point
│       │   ├── migrations/     # Alembic database migrations
│       │   ├── tests/          # Pytest suite for API
│       │   ├── pyproject.toml
│       │   └── Dockerfile
│       │
│       ├── mcp/                # FastMCP AI tool/context server
│       │   ├── app/
│       │   │   ├── tools/      # MCP tools exposed to LLM
│       │   │   ├── resources/  # MCP resources
│       │   │   ├── services/   # Internal tool services
│       │   │   └── main.py     # FastMCP entry point
│       │   ├── tests/          # Pytest suite for MCP
│       │   ├── pyproject.toml
│       │   └── Dockerfile
│       │
│       └── workers/            # ARQ async Redis background workers
│           ├── app/
│           │   ├── tasks/      # Background task definitions
│           │   ├── workers/    # ARQ WorkerSettings
│           │   └── main.py     # Worker entry point
│           ├── tests/          # Pytest suite for workers
│           ├── pyproject.toml
│           └── Dockerfile
│
├── packages/
│   ├── shared/                 # Common domain types, config, errors, DB
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── errors.py
│   │   ├── types.py
│   │   └── pyproject.toml
│   │
│   └── ai/                     # AI provider interfaces, RAG, orchestrator
│       ├── interfaces/
│       ├── orchestration/
│       ├── services/
│       ├── vector_store/
│       └── pyproject.toml
│
├── infra/                      # Infrastructure deployment configs
├── docs/                       # Architecture diagrams & documentation
├── .env.example                # Environment variables template
├── docker-compose.yml          # Local multi-service Docker setup
├── ruff.toml                   # Root linting & formatting rules
└── README.md                   # Project overview & documentation
```

---

## 2. Responsibilities of FastAPI
- **Primary Application Backend**: Entry point for all mobile app REST & WebSocket requests.
- **State & Domain Logic**: Handles authentication, user management, call sessions, audio streaming coordination, and database persistence.
- **Background Dispatcher**: Enqueues expensive asynchronous operations to Redis queue.
- **Direct Domain Access**: Accesses PostgreSQL, Redis, and Qdrant directly without routing through MCP.

## 3. Responsibilities of FastMCP
- **AI Tool & Context Interface**: Implements Model Context Protocol (MCP) for LLM tool invocation.
- **Reusable Tool Bridge**: Exposes tools (e.g. `get_system_status`, `search_memory`) to external LLM agents by invoking shared packages instead of duplicating business logic.
- **Non-blocking for App Logic**: FastAPI does *not* depend on FastMCP for standard mobile client interactions.

## 4. Worker Architecture
- **Async Redis Queue (ARQ)**: Backed by Redis for high-performance asyncio job execution.
- **Offloaded Tasks**: Executes non-blocking operations such as conversation summarization, memory extraction, emotion detection, and embedding generation.
- **Decoupled System**: Can be scaled independently from the HTTP API.

## 5. PostgreSQL Role
- **Single Source of Truth**: Relational storage for users, conversations, messages, call session metadata, and persistent state using SQLAlchemy 2.x and Alembic migrations.

## 6. Redis Role
- **Async Job Queue**: Backing store for ARQ workers.
- **Ephemeral State**: Fast temporary caching, active call session state, pub/sub, and real-time coordination.

## 7. Qdrant Role
- **Vector Database**: High-speed vector search engine for storing and retrieving embeddings (semantic long-term memory, knowledge bases, document search).
- **Abstracted Interface**: Used via `BaseVectorStore` and `RAGService` abstractions in `packages/ai`.

---

## 8. How to Start the Development Environment

Make sure Docker and Docker Compose are installed, then run:

```bash
docker compose up --build
```

Services will start with the following local port bindings:
- **FastAPI**: `http://localhost:8888`

- **FastMCP**: `http://localhost:8889`

- **PostgreSQL**: `localhost:5432`
- **Redis**: `localhost:6379`
- **Qdrant**: `http://localhost:6333`

---

## 9. How to Run FastAPI (Standalone)

Create and activate a Python 3.11+ virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate

# Install shared packages and API in editable mode
pip install -e packages/shared
pip install -e packages/ai
pip install -e apps/backend/api

# Run uvicorn server
cd apps/backend/api
uvicorn app.main:app --reload --port 8888
```

Verify health check:
```bash
curl http://localhost:8888/health
```

---

## 10. How to Run FastMCP (Standalone)

```bash
source .venv/bin/activate

pip install -e packages/shared
pip install -e packages/ai
pip install -e apps/backend/mcp

cd apps/backend/mcp
python -m app.main
```

---

## 11. How to Run Tests

Run pytest across all backend apps:

```bash
# Test API
pytest apps/backend/api/tests

# Test MCP
pytest apps/backend/mcp/tests

# Test Workers
pytest apps/backend/workers/tests
```

---

## 12. Service Communication Architecture

1. **Mobile Application → FastAPI**: Direct REST / WebSocket HTTP communication on port 8888.

2. **FastAPI → Database / Cache / Vector**: Direct connections to PostgreSQL (`postgres:5432`), Redis (`redis:6379`), and Qdrant (`qdrant:6333`).
3. **FastAPI → Worker**: FastAPI enqueues jobs to Redis; ARQ Worker process pops and executes jobs asynchronously.
4. **LLM Client → FastMCP**: External LLMs connect to FastMCP on port 8889 to execute registered tools and query knowledge context.

