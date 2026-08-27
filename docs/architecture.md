# Luna AI Architecture

This document details the system architecture, component boundaries, and data flow for the Luna AI backend monorepo.

## System Topology & Service Flow

```mermaid
flowchart TD
    subgraph Client Layer
        Mobile[Flutter App / Mobile Client]
    end

    subgraph Backend Infrastructure
        API[FastAPI Application Server\n:8888]

        MCP[FastMCP Server\n:8889]

        Worker[ARQ Async Worker]
    end

    subgraph Shared Abstractions
        SharedPkg[packages/shared]
        AIPkg[packages/ai]
    end

    subgraph Data Stores
        PG[(PostgreSQL 16\nStructured Data)]
        Redis[(Redis 7\nQueue / Cache / State)]
        Qdrant[(Qdrant Vector DB\nEmbeddings / RAG)]
    end

    Mobile -->|REST / WebSocket| API
    API --> SharedPkg
    API --> AIPkg
    API -->|Read/Write| PG
    API -->|State / PubSub| Redis
    API -->|Vector Search| Qdrant
    API -->|Enqueue Jobs| Redis

    Worker -->|Consume Jobs| Redis
    Worker -->|Async Ops| PG
    Worker -->|Generate Embeddings| Qdrant

    MCP -->|Tools & Context| AIPkg
    MCP -->|Domain Services| SharedPkg
    MCP -->|Search Vectors| Qdrant
```

## Service Separation & Responsibilities

### 1. Mobile Application (`apps/luna_mobile`)
- Flutter cross-platform mobile interface.
- Communicates directly with FastAPI for authentication, user profiles, conversation management, call sessions, and streaming audio.

### 2. FastAPI Application Server (`apps/backend/api`)
- Primary application gateway.
- Handles user auth, call sessions, WebSockets, streaming audio coordination, relational state persistence.
- Initiates asynchronous background jobs via Redis queues.
- **Note:** FastAPI does *not* depend on MCP for internal operations.

### 3. FastMCP Server (`apps/backend/mcp`)
- Tool and context provider compliant with Model Context Protocol (MCP).
- Exposes tools like `get_system_status`, `search_memory`, `search_knowledge` for LLM agents.
- Invokes shared application services instead of duplicating business logic.

### 4. Asynchronous Workers (`apps/backend/workers`)
- Backed by **ARQ (Async Redis Queue)**.
- Executes background operations (conversation summarization, memory extraction, emotion analysis, embedding generation).

### 5. Shared Domain Packages (`packages/shared` & `packages/ai`)
- `packages/shared`: Common types, environment settings (`BaseConfig`), database session setup, custom exception hierarchy.
- `packages/ai`: Provider-agnostic abstractions (`BaseLLMProvider`, `BaseTTSProvider`, `BaseSTTProvider`, `BaseVectorStore`), `LLMFactory`, `TTSFactory`, `AIOrchestrator`, `RAGService`.
  - Supports dynamic provider switching via `.env` (`LLM_PROVIDER=openai|gemini|mock`, `TTS_PROVIDER=elevenlabs|openai|mock`).
