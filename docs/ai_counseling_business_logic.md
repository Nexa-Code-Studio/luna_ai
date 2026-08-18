# AI Counseling Application --- End-to-End Business Logic

> **Purpose:** This document is the business-logic specification and
> source of truth for an AI counseling / emotional-support application.
> It is intended to guide an AI coding agent when implementing the
> project.
>
> **Scope:** This document focuses on what the system must do and why.
> Framework-specific implementation details are secondary. The current
> technical direction is a monorepo with a FastAPI backend and a
> dedicated FastMCP layer for AI tools.

------------------------------------------------------------------------

## 1. Product Definition

The application is an AI-based counseling and emotional-support system
that allows a user to communicate with an AI through text and voice.

The system is not simply a chatbot. It is an orchestration system
consisting of:

1.  User and session management.
2.  Text and voice conversation.
3.  Speech-to-text and text-to-speech processing.
4.  Emotional-state and risk detection.
5.  Retrieval-Augmented Generation (RAG).
6.  Long-term and short-term memory.
7.  Safety and escalation policies.
8.  Background workers for expensive or asynchronous processing.
9.  Controlled AI tools exposed through FastMCP.
10. Notifications and safety actions.
11. Auditability and observability.

The central business objective is:

> Provide a safe, context-aware AI counseling experience while
> separating normal conversational behavior from safety-critical
> processing.

------------------------------------------------------------------------

# 2. Core Principles

## 2.1 The LLM is not the source of truth

The LLM is responsible for reasoning and generating responses, but it
must not independently determine system state.

Critical states are determined by application logic and dedicated
workers.

Examples:

-   User identity → database.
-   Conversation ownership → database.
-   Risk classification → safety/risk worker.
-   Notification policy → backend policy engine.
-   RAG context → retriever.
-   Memory → memory service.
-   Tool execution → controlled MCP tools.

The LLM can request an action, but the backend decides whether that
action is permitted.

------------------------------------------------------------------------

## 2.2 Safety has priority over conversational quality

When safety-related signals are detected, the system must prioritize
safety over maintaining a normal conversational flow.

Examples of safety-critical signals:

-   Self-harm intent.
-   Suicidal ideation.
-   Immediate danger.
-   Severe psychological distress.
-   Threats toward another person.
-   Requests indicating an emergency.

The system must never rely only on the final LLM response to determine
whether a safety event exists.

------------------------------------------------------------------------

## 2.3 Synchronous and asynchronous work must be separated

The application should not make the user wait for every analysis.

### Synchronous path

Used for operations required to answer the current request:

``` text
User input
→ conversation context
→ safety gate
→ relevant retrieval
→ LLM
→ response
```

### Asynchronous path

Used for operations that can happen after the response:

``` text
Conversation saved
→ emotion analysis
→ risk analysis
→ memory extraction
→ analytics
→ notification evaluation
→ embedding generation
```

The asynchronous path must not block ordinary conversation unless a
safety rule explicitly requires it.

------------------------------------------------------------------------

# 3. High-Level Actors

## 3.1 User

The person interacting with the application.

A user can:

-   Register/login.
-   Start a conversation.
-   Continue an existing conversation.
-   Send text.
-   Send voice.
-   Use AI telephone/voice interaction.
-   Record diary entries.
-   Review conversation history.
-   Review personal memories where applicable.
-   Receive safety-related notifications.

------------------------------------------------------------------------

## 3.2 AI Counselor

The conversational AI.

Responsibilities:

-   Understand the user's message.
-   Use conversation context.
-   Use retrieved knowledge when appropriate.
-   Use safe tools when required.
-   Respond empathetically and naturally.
-   Avoid pretending to be a human therapist.
-   Follow safety policies.
-   Escalate to safety-oriented behavior when required.

The counselor itself does not directly own persistent system state.

------------------------------------------------------------------------

## 3.3 AI Workers

Specialized workers process information independently.

Possible workers include:

-   Emotion Worker.
-   Risk/Safety Worker.
-   Memory Worker.
-   RAG/Embedding Worker.
-   Notification Worker.
-   Analytics Worker.

Workers should have narrow responsibilities rather than one giant AI
worker.

------------------------------------------------------------------------

## 3.4 MCP Tool Layer

FastMCP exposes controlled tools to the AI.

MCP is a tool interface, not the primary business-domain owner.

Examples of possible tools:

-   Retrieve relevant knowledge.
-   Retrieve user memory.
-   Retrieve conversation context.
-   Store an approved memory.
-   Create a diary entry.
-   Request a safety action.
-   Query application information.

Tools must validate authorization and business rules before performing
operations.

------------------------------------------------------------------------

# 4. Main User Journey

The normal end-to-end flow is:

``` text
User opens application
        ↓
Authenticated user
        ↓
Creates conversation
        ↓
User sends voice
        ↓
Input normalization
        ↓
Safety pre-check
        ↓
Load conversation context
        ↓
Retrieve relevant memory
        ↓
Retrieve relevant knowledge
        ↓
AI counselor reasoning
        ↓
Generate response
        ↓
Return response
        ↓
Persist interaction
        ↓
Background workers analyze interaction
        ↓
Update emotion/risk/memory/analytics
        ↓
Evaluate notification policy
```

For voice:

``` text
Microphone
    ↓
VAD
    ↓
Audio streaming
    ↓
STT
    ↓
Conversation input
    ↓
AI orchestration
    ↓
LLM response
    ↓
TTS
    ↓
Audio streaming to user
```

------------------------------------------------------------------------

# 5. User Account Business Logic

## 5.1 Registration

A user must have a unique account identity.

The backend must:

1.  Validate registration data.
2.  Create the user.
3.  Initialize default preferences.
4.  Initialize safety/privacy settings.
5.  Create required application state.

------------------------------------------------------------------------

## 5.2 Authentication

Every protected resource must be associated with the authenticated user.

The system must enforce:

``` text
authenticated_user_id == resource.owner_id
```

unless the operation explicitly allows another authorization
relationship.

A user must never be able to access another user's:

-   Conversations.
-   Diary entries.
-   Memories.
-   Safety events.
-   Personal embeddings.
-   Personal analytics.

------------------------------------------------------------------------

# 6. Conversation Model

A conversation represents a continuous interaction context.

Conceptually:

``` text
User
 └── Conversations
      └── Messages
```

A conversation contains:

-   ID.
-   User ID.
-   Status.
-   Creation time.
-   Last activity.
-   Conversation metadata.

A message contains:

-   ID.
-   Conversation ID.
-   Sender role.
-   Content.
-   Input modality.
-   Timestamp.
-   Processing status.
-   Optional AI metadata.

Sender roles:

``` text
user
assistant
system
tool
```

------------------------------------------------------------------------

# 7. Message Processing

Every incoming user message follows a controlled pipeline.

## 7.1 Step 1 --- Validate

Validate:

-   Authentication.
-   Conversation ownership.
-   Content format.
-   Message size.
-   Modality.
-   Rate limits.

------------------------------------------------------------------------

## 7.2 Step 2 --- Normalize

Convert input into a canonical internal representation.

For example:

``` text
Voice
→ STT transcript
→ normalized user message
```

Text and voice should eventually enter the same conversation pipeline.

------------------------------------------------------------------------

## 7.3 Step 3 --- Safety Pre-Check

The system should perform a fast safety check before normal generation.

The purpose is not necessarily to make the final diagnosis. It is to
identify whether normal generation can continue or whether special
handling is required.

Conceptual states:

``` text
SAFE
LOW_CONCERN
HIGH_CONCERN
CRITICAL
```

The exact classification model can evolve independently.

------------------------------------------------------------------------

# 8. AI Counseling Pipeline

The counselor should receive a structured context rather than the raw
database.

Conceptually:

``` text
System Policy
+
Safety State
+
Recent Conversation
+
Relevant Long-Term Memory
+
Relevant RAG Knowledge
+
Current User Message
+
Available Tool Definitions
```

The model then generates the response.

------------------------------------------------------------------------

## 8.1 Recent Conversation Context

Recent messages provide immediate conversational context.

The system should not send the entire conversation indefinitely.

Context selection should consider:

-   Recency.
-   Token budget.
-   Conversation relevance.
-   Current topic.

------------------------------------------------------------------------

## 8.2 Long-Term Memory

Memory represents durable information that may improve future
conversations.

Examples:

-   User preferences.
-   Recurring concerns.
-   Important personal context.
-   Long-term goals.
-   Previously discussed situations.

Memory must not blindly store every message.

A memory worker determines whether information is worth persisting.

------------------------------------------------------------------------

## 8.3 Memory Lifecycle

``` text
Conversation message
        ↓
Memory Worker
        ↓
Candidate memory
        ↓
Validation / policy
        ↓
Persist memory
        ↓
Generate embedding
        ↓
Store vector
```

Embeddings are generated when memory or knowledge content is
created/updated, not repeatedly for every retrieval.

------------------------------------------------------------------------

# 9. RAG Business Logic

RAG provides external knowledge to the AI.

The system should use RAG when the answer benefits from reliable domain
knowledge.

Examples:

-   Psychological education.
-   Coping techniques.
-   Counseling guidance.
-   Safety procedures.
-   Application-specific knowledge.

RAG must not be treated as a replacement for the model.

It provides evidence/context that the model can use.

------------------------------------------------------------------------

## 9.1 Knowledge Pipeline

``` text
Source document
      ↓
Document ingestion
      ↓
Text extraction
      ↓
Chunking
      ↓
Metadata assignment
      ↓
Embedding generation
      ↓
Vector database
```

------------------------------------------------------------------------

## 9.2 Retrieval Pipeline

``` text
User message
      ↓
Query embedding
      ↓
Vector search
      ↓
Metadata filtering
      ↓
Relevant chunks
      ↓
Context builder
      ↓
LLM
```

Metadata should be used whenever possible to reduce irrelevant
retrieval.

Possible metadata:

``` text
document_id
category
topic
source
language
version
safety_level
created_at
updated_at
```

------------------------------------------------------------------------

# 10. Vector Database

The vector database stores embeddings for semantic retrieval.

Qdrant is the intended vector database for the current architecture.

The vector database should contain logically separated collections or
namespaces where appropriate.

Potential categories:

``` text
knowledge
memories
```

The database should not become the primary relational source of truth.

Relational data remains in PostgreSQL.

Conceptually:

``` text
PostgreSQL
→ source of truth

Qdrant
→ semantic retrieval index
```

If vector data is lost, it should be possible to regenerate it from the
relational/document source.

------------------------------------------------------------------------

# 11. Emotion Detection

Emotion detection is an analytical process rather than the sole source
of conversational truth.

After a message is stored:

``` text
Message
 ↓
Emotion Worker
 ↓
Emotion classification
 ↓
Emotion record
```

Possible outputs may include:

-   Emotion label.
-   Confidence.
-   Intensity.
-   Timestamp.

Emotion data can later support:

-   User trend visualization.
-   Conversation context.
-   Analytics.
-   Safety analysis.

Emotion classification should not automatically be interpreted as a
medical diagnosis.

------------------------------------------------------------------------

# 12. Risk and Safety Detection

Safety detection is separate from emotion detection.

A user can be:

``` text
sad
```

without being suicidal.

Therefore:

``` text
Emotion ≠ Risk
```

The risk worker evaluates safety-related signals.

Possible states:

``` text
NORMAL
CONCERN
HIGH_RISK
CRITICAL
```

The exact model and thresholds may change.

------------------------------------------------------------------------

# 13. Safety Decision Flow

Conceptually:

``` text
Incoming message
      ↓
Safety detection
      ↓
Risk classification
      ↓
Policy engine
      ↓
┌───────────────┬────────────────┬─────────────────┐
│ Normal        │ Concerning     │ Critical        │
│               │                │                 │
│ Normal AI     │ Supportive     │ Safety-first    │
│ response      │ response       │ response        │
│               │ + monitoring   │ + escalation    │
└───────────────┴────────────────┴─────────────────┘
```

The policy engine determines what actions are allowed.

The LLM should not invent escalation behavior.

------------------------------------------------------------------------

# 14. Notification Policy

Notifications should be controlled by backend policy rather than
directly by the LLM.

Conceptually:

``` text
Risk event
   ↓
Notification Policy
   ↓
Check severity
   ↓
Check user settings
   ↓
Check cooldown / duplicate protection
   ↓
Determine action
```

The policy cache can be used to avoid repeatedly calculating static
policy information.

The cache is an optimization, not the source of truth.

------------------------------------------------------------------------

# 15. Safety Escalation

For critical situations, the system may need to trigger a predefined
safety workflow.

The exact workflow depends on the product's legal, ethical, and
operational requirements.

The application should distinguish:

``` text
Detection
→ Decision
→ Action
→ Notification
→ Audit
```

Each stage should be traceable.

Do not collapse all of them into a single LLM call.

------------------------------------------------------------------------

# 16. Diary Feature

The diary is a separate user-generated data source.

The user writes a diary entry.

The system stores the original entry first.

Then asynchronous processing may classify it.

Conceptually:

``` text
Diary Entry
   ↓
Persist original
   ↓
Diary Analysis Worker
   ↓
Classification
```

Potential categories discussed for the project:

``` text
NORMAL_DIARY
MENTAL_HEALTH_CONCERN
SUICIDAL_IDEATION
```

Classification must not overwrite the original diary text.

------------------------------------------------------------------------

# 17. Diary → AI Context

Diary entries can become useful context for future conversations.

However, the system should not automatically expose every diary entry to
the LLM.

Instead:

``` text
Diary
 ↓
Analysis
 ↓
Relevant memory extraction
 ↓
Optional memory storage
 ↓
Embedding
 ↓
Future retrieval
```

This prevents unnecessary exposure of private historical content.

------------------------------------------------------------------------

# 18. Voice / Telephone AI

The application supports voice interaction.

Voice is another interface over the same counseling domain.

The voice pipeline should be:

``` text
User speech
   ↓
VAD
   ↓
Audio stream
   ↓
STT
   ↓
Text message
   ↓
AI counseling pipeline
   ↓
Text response
   ↓
TTS
   ↓
Audio response
```

The core counseling business logic should remain modality-independent.

Therefore:

``` text
Text input ─┐
            ├→ Counseling Orchestrator
Voice input ┘
```

This avoids creating separate counseling logic for text and telephone.

------------------------------------------------------------------------

# 19. VAD Business Logic

VAD detects whether the user is currently speaking.

The purpose is to reduce unnecessary audio processing and improve
conversational latency.

Conceptually:

``` text
Audio
 ↓
VAD
 ├── silence → wait
 └── speech  → stream/process
```

VAD should not decide the meaning of speech.

It only controls audio segmentation/streaming behavior.

------------------------------------------------------------------------

# 20. STT Business Logic

STT converts speech into text.

The result should contain enough metadata to associate it with the
current conversation:

``` text
conversation_id
message_id
transcript
timestamp
confidence (if available)
```

The transcript then enters the same message-processing pipeline as text.

------------------------------------------------------------------------

# 21. TTS Business Logic

TTS converts the assistant response into audio.

The generated text should be persisted independently of the audio
representation.

Therefore:

``` text
Assistant text
   ↓
Persist message
   ↓
TTS
   ↓
Audio stream
```

If TTS fails, the text response should remain valid.

------------------------------------------------------------------------

# 22. AI Orchestrator

The AI orchestrator is the central application service for a counseling
turn.

It coordinates:

1.  Safety state.
2.  Conversation context.
3.  Memory retrieval.
4.  RAG retrieval.
5.  Tool availability.
6.  Prompt construction.
7.  LLM invocation.
8.  Response validation.
9.  Persistence.

Conceptually:

``` text
                 ┌→ Safety
                 │
User Message → Orchestrator ─→ Memory
                 │
                 ├→ RAG
                 │
                 ├→ Tools
                 │
                 └→ LLM
                         ↓
                    AI Response
```

The orchestrator should not contain every worker's internal
implementation.

It coordinates them through clear interfaces.

------------------------------------------------------------------------

# 23. Prompt System

The prompt should be composed from separate concerns rather than one
giant hardcoded string.

Conceptually:

``` text
Base Counselor Policy
+
Safety Policy
+
Conversation Context
+
Memory Context
+
RAG Context
+
Tool Instructions
+
Current User Message
```

The prompt must explicitly define:

-   AI identity.
-   Counseling behavior.
-   Safety boundaries.
-   Tool usage rules.
-   Uncertainty handling.
-   Appropriate response style.
-   Prohibited behavior.

------------------------------------------------------------------------

# 24. FastAPI Responsibility

FastAPI should own the main application/business API.

It should handle:

-   Authentication.
-   Users.
-   Conversations.
-   Messages.
-   Diary.
-   Preferences.
-   Safety events.
-   Worker job submission.
-   Application-level authorization.
-   API responses.

FastAPI is the primary domain boundary.

------------------------------------------------------------------------

# 25. FastMCP Responsibility

FastMCP should expose controlled capabilities to AI agents/models.

It should not become a second unrelated backend.

Example:

``` text
LLM
 ↓
MCP Tool
 ↓
FastMCP
 ↓
Domain service
 ↓
Repository / database
```

FastMCP tools should call domain/application services instead of
duplicating business rules.

------------------------------------------------------------------------

# 26. MCP Tool Rules

Every tool should answer:

1.  Who is calling?
2.  Which user does the operation belong to?
3.  Is the operation allowed?
4.  Is confirmation required?
5.  What data can be returned?
6.  What side effect can happen?
7.  How is the action audited?

Tools that mutate data should have stricter validation than read-only
tools.

------------------------------------------------------------------------

# 27. Worker Architecture

Workers exist for tasks that are:

-   Expensive.
-   Slow.
-   Independent.
-   Retryable.
-   Not required to generate the immediate response.

Possible pipeline:

``` text
Message Created
      ↓
┌─────┼────────────┬─────────────┐
↓     ↓            ↓             ↓
Emotion Risk      Memory       Analytics
Worker  Worker    Worker        Worker
              ↓
       Notification Worker
```

Workers should be idempotent where possible.

If a job executes twice, it should not create duplicate safety
notifications or duplicate memory records.

------------------------------------------------------------------------

# 28. Parallel Processing

Multiple independent analyses may execute concurrently.

For example:

``` text
message
  ├── emotion analysis
  ├── risk analysis
  ├── memory analysis
  └── analytics
```

However, safety-critical dependencies must remain ordered.

Example:

``` text
Risk Detection
      ↓
Safety Policy
      ↓
Notification Decision
```

Do not execute notification decisions before the required risk state
exists.

------------------------------------------------------------------------

# 29. Data Ownership

The system should maintain clear ownership.

### PostgreSQL

Source of truth for:

-   Users.
-   Conversations.
-   Messages.
-   Diary entries.
-   Emotion results.
-   Risk events.
-   Memories.
-   Notification events.
-   Application metadata.

### Qdrant

Semantic index for:

-   Knowledge embeddings.
-   Memory embeddings.
-   Other approved semantic-search data.

### Redis / Queue

Transient infrastructure for:

-   Job queues.
-   Caching.
-   Short-lived state.
-   Worker coordination.

Redis should not become the permanent source of user data.

------------------------------------------------------------------------

# 30. Data Lifecycle

A typical message lifecycle:

``` text
RECEIVED
   ↓
VALIDATED
   ↓
PROCESSED
   ↓
PERSISTED
   ↓
ANALYZED
   ↓
INDEXED / MEMORY UPDATED
```

Failure in a secondary process should not corrupt the original user
message.

For example:

``` text
TTS failure
→ text message still exists

Embedding failure
→ source record still exists

Emotion worker failure
→ conversation still exists
→ worker can retry
```

------------------------------------------------------------------------

# 31. Error Handling

Errors should be classified.

### User/Input Error

Examples:

-   Invalid message.
-   Unauthorized conversation.
-   Invalid audio.

Return an appropriate client error.

### External Service Error

Examples:

-   LLM provider unavailable.
-   STT provider unavailable.
-   TTS provider unavailable.

Use retry/fallback behavior where appropriate.

### Worker Error

Retry asynchronously.

Do not make the user resend the original message merely because an
asynchronous worker failed.

### Safety Processing Error

This is special.

If the system cannot confidently complete required safety processing, it
must fail into the safest predefined behavior rather than silently
treating the message as safe.

------------------------------------------------------------------------

# 32. Idempotency

Important operations should be idempotent.

Examples:

``` text
process_message(message_id)
analyze_risk(message_id)
analyze_emotion(message_id)
extract_memory(message_id)
send_notification(event_id)
generate_embedding(document_id, version)
```

A retry must not create duplicate logical records.

------------------------------------------------------------------------

# 33. Audit Trail

Safety-sensitive actions should be auditable.

Record events such as:

-   Risk detected.
-   Risk state changed.
-   Safety policy triggered.
-   Notification created.
-   Notification sent.
-   Tool mutation executed.
-   Memory created/updated/deleted.

The audit trail should contain enough information to reconstruct what
happened without unnecessarily storing sensitive data multiple times.

------------------------------------------------------------------------

# 34. Privacy Rules

The system handles highly sensitive conversational data.

Business logic must therefore follow data minimization.

Do not send unnecessary user data to:

-   LLM providers.
-   Vector databases.
-   Analytics systems.
-   Notification systems.
-   MCP tools.

Only provide the minimum context required for the operation.

------------------------------------------------------------------------

# 35. Authorization Rules

Every resource operation should follow:

``` text
Authenticate
   ↓
Authorize
   ↓
Validate business rule
   ↓
Execute
```

Never:

``` text
Request
 ↓
Database query
```

without ownership/authorization checks.

------------------------------------------------------------------------

# 36. Conversation Context Strategy

The system should distinguish three kinds of context:

### Immediate Context

Recent messages in the active conversation.

### Long-Term Memory

Stable user information that may be useful across conversations.

### Knowledge Context

External/domain information retrieved through RAG.

Therefore:

``` text
Conversation ≠ Memory ≠ Knowledge
```

They have different lifecycles and should remain separate.

------------------------------------------------------------------------

# 37. Memory Rules

Memory should be:

-   Relevant.
-   Durable.
-   Useful.
-   Non-redundant.
-   User-scoped.
-   Deletable.

Do not store:

-   Every conversation message.
-   Temporary emotional states as permanent facts.
-   Model guesses as user facts.
-   Unsupported medical diagnoses.

A memory should distinguish between:

``` text
observed user statement
vs
AI inference
```

AI inference must not silently become a factual user profile.

------------------------------------------------------------------------

# 38. RAG Rules

RAG documents should have provenance.

Every knowledge chunk should be traceable to:

``` text
source document
→ version
→ chunk
```

When documents are updated:

``` text
new document/version
→ re-chunk
→ re-embed
→ update vector index
```

Embedding generation is therefore primarily an ingestion/update process,
not something that happens only during user conversation.

------------------------------------------------------------------------

# 39. Safety and Medical Boundary

The application should be positioned as AI emotional support/counseling
assistance, not as an autonomous medical diagnostic authority.

The system should avoid:

-   Claiming certainty about mental disorders.
-   Presenting AI classifications as medical diagnoses.
-   Replacing professional medical care.
-   Giving dangerous instructions.

When professional or emergency assistance is appropriate, the system
should follow the predefined safety policy.

------------------------------------------------------------------------

# 40. State Machine for a Conversation Turn

A useful conceptual state machine:

``` text
IDLE
 ↓
INPUT_RECEIVED
 ↓
VALIDATED
 ↓
SAFETY_CHECK
 ↓
CONTEXT_BUILT
 ↓
AI_PROCESSING
 ↓
RESPONSE_GENERATED
 ↓
RESPONSE_PERSISTED
 ↓
BACKGROUND_ANALYSIS
 ↓
COMPLETED
```

Failure states:

``` text
VALIDATION_FAILED
AI_FAILED
SAFETY_PROCESSING_FAILED
PERSISTENCE_FAILED
```

Each state should have clear retry/recovery behavior.

------------------------------------------------------------------------

# 41. Recommended End-to-End Sequence

## Normal Text Conversation

``` text
1. User sends message.
2. API authenticates user.
3. API validates conversation ownership.
4. Message is persisted.
5. Fast safety pre-check runs.
6. Conversation context is loaded.
7. Relevant memory is retrieved.
8. Relevant RAG knowledge is retrieved.
9. Prompt/context is constructed.
10. LLM generates response.
11. Response is safety-validated.
12. Assistant response is persisted.
13. Response is returned to client.
14. Background workers analyze the turn.
15. Memory/embedding/analytics state is updated.
16. Notification policy is evaluated if required.
```

------------------------------------------------------------------------

## Voice Conversation

``` text
1. User speaks.
2. VAD detects speech.
3. Audio is streamed.
4. STT generates transcript.
5. Transcript becomes a user message.
6. The normal counseling pipeline executes.
7. Assistant response is generated.
8. Response text is persisted.
9. TTS converts response to audio.
10. Audio is streamed to the user.
11. Background workers analyze the interaction.
```

------------------------------------------------------------------------

## Diary

``` text
1. User creates diary entry.
2. Entry is persisted unchanged.
3. Analysis job is queued.
4. Diary worker classifies the entry.
5. Risk worker evaluates safety signals when required.
6. Memory worker determines whether durable memory exists.
7. Relevant memory may be embedded.
8. Notification policy runs for safety-relevant events.
```

------------------------------------------------------------------------

# 42. Business Logic Boundaries

The project should preserve these boundaries:

``` text
API Layer
    ↓
Application / Domain Services
    ↓
Repositories / Infrastructure

AI Orchestrator
    ↓
LLM / RAG / Memory / Tools

Workers
    ↓
Specialized asynchronous processing

FastMCP
    ↓
Controlled AI capabilities
```

Do not put all logic inside:

-   FastAPI routes.
-   MCP tools.
-   LLM prompts.
-   Database models.
-   One giant worker.

------------------------------------------------------------------------

# 43. Suggested Monorepo Responsibilities

The current project is intended to use a monorepo.

Conceptually:

``` text
apps/
├── api/
├── mcp/
└── mobile/

packages/
└── shared/
```

### `apps/api`

Primary backend and business API.

### `apps/mcp`

FastMCP server and AI-facing tools.

### `apps/mobile`

Flutter client.

### `packages/shared`

Shared contracts/types/utilities that genuinely need to be shared.

Do not put domain logic into `shared` merely because multiple
applications can technically import it.

------------------------------------------------------------------------

# 44. Implementation Order for the Coding Agent

The agent should implement the project in this order.

## Phase 1 --- Foundation

-   Monorepo structure.
-   Environment configuration.
-   PostgreSQL connection.
-   Redis/queue infrastructure.
-   Base application configuration.
-   Logging.
-   Error handling.

## Phase 2 --- Core Domain

-   User.
-   Conversation.
-   Message.
-   Diary.
-   Preferences.
-   Basic authorization.

## Phase 3 --- AI Service

-   LLM provider abstraction.
-   Prompt system.
-   AI orchestrator.
-   Conversation context builder.

## Phase 4 --- RAG

-   Document model.
-   Ingestion.
-   Chunking.
-   Embedding generator.
-   Qdrant integration.
-   Retriever.
-   Metadata filtering.

## Phase 5 --- Memory

-   Memory model.
-   Memory extraction worker.
-   Memory retrieval.
-   Memory embeddings.
-   Memory lifecycle rules.

## Phase 6 --- Safety

-   Risk classification.
-   Safety policy engine.
-   Safety events.
-   Notification policy.
-   Audit trail.

## Phase 7 --- Workers

-   Emotion worker.
-   Risk worker.
-   Memory worker.
-   Notification worker.
-   Analytics worker.

## Phase 8 --- FastMCP

-   MCP server.
-   Read-only tools.
-   Context tools.
-   Controlled mutation tools.
-   Authorization and audit integration.

## Phase 9 --- Voice

-   VAD.
-   STT.
-   Audio streaming.
-   TTS.
-   Voice session lifecycle.

## Phase 10 --- Mobile Integration

-   Authentication.
-   Conversation UI.
-   Streaming.
-   Voice interface.
-   Diary.
-   History.
-   Safety-related UX.

------------------------------------------------------------------------

# 45. Definition of Done

A feature is not complete merely because its endpoint works.

A feature is complete when:

-   Authentication is enforced.
-   Authorization is enforced.
-   Business rules are implemented outside controllers where
    appropriate.
-   Data ownership is clear.
-   Errors are handled.
-   Retries are considered.
-   Background processing is idempotent.
-   Sensitive data is minimized.
-   Relevant audit events exist.
-   AI behavior has explicit boundaries.
-   Tests cover important business rules.
-   The feature integrates with the existing domain model.

------------------------------------------------------------------------

# 46. Non-Negotiable Rules for the Coding Agent

The coding agent must follow these rules:

1.  Do not invent business behavior that contradicts this document.
2.  Do not move critical business logic into prompts.
3.  Do not allow the LLM to directly access the database.
4.  Do not allow MCP tools to bypass authorization.
5.  Do not treat emotion classification as medical diagnosis.
6.  Do not treat vector databases as the source of truth.
7.  Do not make asynchronous analysis block normal conversation unless
    safety policy explicitly requires it.
8.  Do not duplicate domain logic between FastAPI and FastMCP.
9.  Do not store every conversation message as long-term memory.
10. Do not expose unnecessary private data to external AI services.
11. Do not silently discard the original user message.
12. Make worker operations retryable and preferably idempotent.
13. Safety-critical processing must have explicit failure behavior.
14. Keep text and voice interfaces on the same counseling domain
    pipeline.
15. Prefer clear domain services over giant controllers, workers, or
    prompts.
16. When implementing a new feature, identify which domain entity,
    service, worker, policy, or tool owns the behavior before writing
    code.
17. When business behavior is ambiguous, preserve existing behavior and
    ask for clarification rather than inventing a policy.
18. Keep infrastructure replaceable through interfaces where practical,
    especially LLM, STT, TTS, embedding, and vector database
    integrations.

------------------------------------------------------------------------

# 47. Canonical Mental Model

The entire system can be understood as five layers:

``` text
┌─────────────────────────────────────────────┐
│                  CLIENT                     │
│       Mobile / Text / Voice / Phone         │
└──────────────────────┬──────────────────────┘
                       ↓
┌─────────────────────────────────────────────┐
│                  API                        │
│            FastAPI / Auth / Domain          │
└──────────────────────┬──────────────────────┘
                       ↓
┌─────────────────────────────────────────────┐
│              AI ORCHESTRATION               │
│ Safety + Context + RAG + Memory + LLM       │
└───────────────┬─────────────────┬───────────┘
                ↓                 ↓
┌────────────────────────┐  ┌─────────────────┐
│      MCP TOOLS         │  │    WORKERS      │
│ FastMCP / controlled   │  │ Emotion / Risk  │
│ AI capabilities        │  │ Memory / etc.   │
└────────────┬───────────┘  └────────┬────────┘
             ↓                       ↓
┌─────────────────────────────────────────────┐
│              DATA / INFRASTRUCTURE          │
│ PostgreSQL + Qdrant + Redis + External AI   │
└─────────────────────────────────────────────┘
```

The most important architectural principle is:

> **The LLM is a reasoning component inside the application, not the
> application itself.**

The backend owns identity, state, authorization, safety policy,
persistence, and business rules. The AI layer provides reasoning and
natural-language interaction. Workers provide asynchronous analysis. RAG
and memory provide controlled context. FastMCP provides controlled
tools.

This separation should remain intact as the project grows.
