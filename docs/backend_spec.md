# Luna AI Backend Specification (`apps/backend`)

> **Purpose:** Technical specification for the FastAPI application server, FastMCP tool layer, ARQ async background workers, PostgreSQL database schemas, and Qdrant vector database collections.

---

## 1. System Architecture & Tech Stack

- **Framework:** FastAPI (Python 3.12+ with async/await)
- **Database:** PostgreSQL 16 + SQLAlchemy 2.0 (Async ORM) + Alembic migrations
- **Vector DB:** Qdrant (Semantic search & RAG)
- **Cache & Message Broker:** Redis 7 (ARQ Async Worker Queue & Cache)
- **MCP Framework:** FastMCP (Model Context Protocol server on port `:8889`)


---

## 2. Authentication & Security

- **Scheme:** JWT Bearer Token (Access Token + Refresh Token via HTTP `Authorization: Bearer <token>`)
- **Password Hashing:** Bcrypt / Passlib
- **Authorization Rule:** `authenticated_user_id == resource.owner_id` for all private endpoints (conversations, diaries, memories, safety events).

---

## 3. Database Schema (PostgreSQL Models)

Key domain entities in `apps/backend/api/app/models`:

1. **User (`User`, `UserPreferences`, `EmergencyContact`)**:
   - `id` (UUID), `name`, `email`, `hashed_password`, `is_active`, `created_at`, `updated_at`.
   - `EmergencyContact`: `id`, `user_id`, `name`, `relationship`, `phone`, `is_primary`.

2. **Conversation & Message (`Conversation`, `Message`)**:
   - `Conversation`: `id`, `user_id`, `title`, `status` (`active`, `archived`, `deleted`), `created_at`, `updated_at`.
   - `Message`: `id`, `conversation_id`, `sender_role` (`user`, `assistant`, `system`), `content`, `modality` (`text`, `voice`), `created_at`.

3. **Memory (`UserMemory`)**:
   - `id`, `user_id`, `memory_type` (`preference`, `personal_fact`, `important_event`, `relationship`, `goal`, `recurring_issue`, `emotional_pattern`), `content`, `confidence`, `qdrant_point_id`, `created_at`.

4. **Safety & Risk (`SafetyEvent`, `RiskAnalysis`)**:
   - `SafetyEvent`: `id`, `user_id`, `conversation_id`, `event_type` (`suicide_risk`, `self_harm`, `violence`, `emergency`), `risk_level` (`none`, `low`, `medium`, `high`, `critical`), `status` (`open`, `acknowledged`, `resolved`), `summary`.

5. **Notification (`Notification`, `NotificationPolicy`)**:
   - `Notification`: `id`, `user_id`, `safety_event_id`, `channel` (`push`, `in_app`), `status` (`pending`, `sent`, `read`), `title`, `body`.

6. **Voice Session (`VoiceSession`, `VoiceTranscript`)**:
   - `VoiceSession`: `id`, `user_id`, `status` (`active`, `completed`, `failed`), `duration_seconds`, `summary`.

7. **Diary (`DiaryEntry`)**:
   - `DiaryEntry`: `id`, `user_id`, `entry_date` (1 entry per date per user), `title`, `summary`, `content`, `mood_tag`, `mood_emoji`, `ai_insight`, `emotional_reflection`, `important_events`, `safety_event_id` (optional FK to `SafetyEvent`).

---

## 4. API Routes Overview (`apps/backend/api/app/api/routes`)

- `POST /api/v1/auth/register` - Create user account
- `POST /api/v1/auth/login` - Authenticate & obtain JWT tokens
- `GET /api/v1/auth/me` - Fetch current user profile
- `GET /api/v1/conversations` - List active user conversations
- `POST /api/v1/conversations` - Create new conversation
- `GET /api/v1/conversations/{id}` - Fetch conversation detail with messages
- `POST /api/v1/conversations/{id}/messages` - Send text/voice message
- `GET /api/v1/diaries` - List journal entries (supports `mood` and `search` query parameters)
- `POST /api/v1/diaries` - Create manual or voice-synthesized diary entry
- `GET /api/v1/recommendations` - Fetch personalized daily recommendations
- `POST /api/v1/voice/calls/start` - Initiate AI voice counseling session
- `POST /api/v1/voice/calls/{id}/end` - Terminate call and trigger async summarization
- `GET /api/v1/analytics/monitoring` - Fetch emotional center & mood trends (`today`, `week`, `month`)

---

## 5. FastMCP Tool Layer (`apps/backend/mcp`)

FastMCP runs on port `:8889` exposing controlled tools to LLM agents:


- `search_knowledge(query: str, category: str = None)`: Vector search on RAG psychoeducation articles.
- `search_memory(user_id: str, query: str)`: Semantic search over user's long-term memory embeddings.
- `store_memory(user_id: str, memory_type: str, content: str)`: Persist verified user memory into PostgreSQL & Qdrant.
- `create_diary_entry(user_id: str, content: str, mood_tag: str)`: Save diary entry & queue analysis job.
- `trigger_safety_alert(user_id: str, risk_level: str, details: str)`: Escalate critical risk signal to safety workflow.

---

## 6. Vector DB Collections (Qdrant)

1. **`knowledge` Collection**:
   - Vector dimension: 1536 (or model embedding size)
   - Distance metric: Cosine
   - Metadata payload: `document_id`, `category`, `topic`, `source`, `safety_level`.

2. **`memories` Collection**:
   - Vector dimension: 1536
   - Distance metric: Cosine
   - Metadata payload: `user_id`, `memory_type`, `memory_id`, `created_at`.

---

## 7. Async Background Workers (ARQ)

Supported ARQ tasks in `apps/backend/workers`:

- `analyze_emotion_task(message_id)`: Classify emotion breakdown & update emotional trend index.
- `evaluate_risk_task(message_id)`: Execute safety classifier and create `SafetyEvent` if risk $\ge$ `HIGH`.
- `extract_memory_task(conversation_id)`: Extract candidate memories using LLM & store vectors.
- `synthesize_diary_task(user_id, date)`: Synthesize daily voice sessions into structured diary entries.

---

## 8. Mobile DTO to Backend DB Mapping Contract

This contract maps Flutter Mobile Clean Architecture models (`luna_mobile`) to backend SQLAlchemy models & FastAPI endpoints:

| Feature / Modul | Mobile DTO Model | FastAPI Endpoint | Backend SQLAlchemy Model(s) |
| :--- | :--- | :--- | :--- |
| **Auth** | `UserModel` | `GET /auth/me` | `User`, `UserPreferences` |
| **Emergency** | `EmergencyContactModel` | `GET /users/emergency-contacts` | `EmergencyContact` |
| **Chat** | `ConversationModel` | `GET /conversations/{id}` | `Conversation`, `ConversationSummary` |
| **Messages** | `ChatMessageModel` | `POST /conversations/{id}/messages` | `Message`, `EmotionAnalysis` |
| **Diary** | `DiaryEntryModel` | `GET /diaries` | `ConversationSummary`, `Memory` |
| **Risk Warning**| `RiskWarningModel` | `GET /diaries/{id}` | `SafetyEvent`, `SafetyAnalysis` |
| **Saran** | `RecommendationModel` | `GET /recommendations` | `KnowledgeChunk` (`rag.py`) |
| **Voice Call** | `VoiceSessionModel` | `POST /voice/calls/start` | `VoiceSession`, `VoiceTurn` |
| **Monitoring** | `MonitoringDataModel` | `GET /analytics/monitoring` | `EmotionAnalysis`, `SafetyAnalysis` (Aggregated) |
