# Project Rules & Token Optimization Guidelines for Luna AI

> **Purpose:** Guidelines for AI agents (Antigravity) to maintain high code quality while minimizing token consumption.

---

## 1. Documentation & Lazy Reading (Just-In-Time Context)

- **Do NOT read large doc files upfront**: Do not pre-load entire documentation files (e.g. `docs/ai_counseling_business_logic.md`) unless specifically required for the task.
- **Selective Reading**: Read `docs/` files strictly on demand when working on relevant features:
  - Working on overall system topology/monorepo setup? Read `docs/architecture.md`.
  - Working on counseling logic, safety gates, risk worker, or diary synthesis? Read specific line ranges of `docs/ai_counseling_business_logic.md`.
  - Working on FastAPI, PostgreSQL models, FastMCP tools, ARQ workers, or Qdrant vector DB? Read `docs/backend_spec.md`.
  - Working on Flutter mobile, Riverpod providers, Clean Architecture layers, or `AppConfig.useMockData` toggle? Read `docs/mobile_spec.md`.
- **Use Line Ranges**: When inspecting large documents or files, always supply `StartLine` and `EndLine` parameters to read only the target section instead of dumping 800+ lines.

---

## 2. Search & Code Inspection (Targeted Retrieval)

- **Grep Before Reading**: Use `grep_search` or `list_dir` to pinpoint exact filenames, class names, or function definitions before using `view_file`.
- **No Blind Inferences**: Inspect actual type signatures and definitions before calling functions or instantiating classes.
- **Surgical Edits**: Make precise, targeted modifications. Do not rewrite unaffected files or duplicate standard boilerplate.

---

## 3. Codebase Standards & Architecture Constraints

- **Clean Architecture (`luna_mobile`)**:
  - Follow the established layer structure: `domain/` (entities & repository contracts), `data/` (models, datasources, repo impls), and `presentation/` (Riverpod providers & widgets).
  - Use `AppConfig.useMockData` flag to toggle between `MockDataSource` and `RemoteDataSource`.
  - Prefer pure Dart models with manual `fromJson`, `toJson`, and `copyWith`.
- **Backend Standard (`apps/backend`)**:
  - Keep models in `app/models`, schemas in `app/schemas`, routes in `app/api/routes`, services in `app/services`.
  - Decouple FastMCP tools from core API handlers.
- **State & Code Style**:
  - Write concise, clean, typed code without verbose redundant comments.
  - Do not introduce heavy dependencies without user confirmation.

---

## 4. Response & Output Efficiency

- **Concise Summaries**: Keep natural language explanations clear, direct, and compact.
- **No Redundant Re-summarizations**: After creating/editing artifacts, provide a high-level summary and direct link without duplicating the full content in chat prose.
