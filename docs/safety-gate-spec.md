# Luna AI - SafetyGate Specification Blueprint (Refined v2.0)

> **Status:** Safety Policy Blueprint Blueprint (Refined Version 2.0)  
> **Target Service:** `SafetyGate` (`packages/ai/services/safety_gate.py`)  
> **Source of Truth:** Luna AI Counseling Business Logic & Architectural Blueprint (`docs/ai_counseling_business_logic.md`), WHO EASE Crisis Protocol.

---

## 1. Executive Summary & Architectural Role

The `SafetyGate` is Luna AI's **Pure Policy Decision Engine**. It evaluates the audit output from `RiskAssessmentService` and decides execution permissions and modes (*"Boleh lewat mana?"*).

```text
RiskAssessmentService ("Seberapa berisiko?")
         │
         ▼
RiskAssessmentOutput (risk_level, risk_type, decision_rule)
         │
         ▼
     SafetyGate ("Aturan/kebijakan apa yang harus diterapkan?")
         │
         ├───► SafetyPolicyDecision (Pure Policy Payload)
         │
         ├── IF mode == NORMAL / COPING ──► Retriever ──► Response Planner ──► LLM (NORMAL)
         │
         └── IF mode == CRISIS ──────────► Crisis SOP Executor ──► ResourceResolver ──► Escalation Protocol
```

### Architectural Separation of Responsibilities:

| Component | Sole Responsibility | What it MUST NOT do |
|---|---|---|
| **`RiskAssessmentService`** | Evaluates risk levels & distress severity. | ❌ Does NOT decide UI actions or execute side effects. |
| **`SafetyGate`** | **Determines policy rules & typed permissions** (*"Boleh lewat mana?"*). | ❌ Does **NOT** query Qdrant directly; does **NOT** hardcode phone numbers; does **NOT** trigger side-effect webhooks. |
| **`ResourceResolver`** | Resolves regional emergency hotline & clinic data. | ❌ Does NOT decide safety policy. |
| **`Crisis SOP Executor`** | Executes escalation side effects & formats crisis responses. | ❌ Does NOT calculate risk levels. |
| **`LLM / Generative`** | Formats natural, empathetic phrasing (if permitted). | ❌ Cannot alter risk levels or crisis policies; strictly bounded under `BOUNDED_CRISIS`. |

---

## 2. Typed Enums & Policy Matrix

### 2.1 Enums Definitions

```python
class ResponseMode(StrEnum):
    NORMAL = "normal"
    COPING = "coping"
    CRISIS = "crisis"


class LLMMode(StrEnum):
    NONE = "none"                     # Freeform LLM is strictly disabled; use verified crisis templates
    BOUNDED_CRISIS = "bounded_crisis" # LLM is restricted to strictly bounded, empathetic phrasing without advice
    NORMAL = "normal"                 # Standard LLM response generation


class SafetyAction(StrEnum):
    NORMAL_RAG = "normal_rag"
    STRUCTURED_COPING = "structured_coping"
    BOUNDED_LLM = "bounded_llm"
    CRISIS_TEMPLATE = "crisis_template"
    RESOURCE_RESOLUTION = "resource_resolution"
    HUMAN_ESCALATION = "human_escalation"
```

### 2.2 Policy Matrix Table

| `risk_level` | `protocol_action` | Execution Mode (`mode`) | `llm_mode` | `allow_normal_rag` | `requires_crisis_sop` | `requires_human_escalation` (Policy Flag) | Allowed Actions (`allowed_actions`) | Prohibited Actions (`prohibited_actions`) | Resource Category |
|---|---|---|---|:---:|:---:|:---:|---|---|---|
| **`none`** | `NORMAL_RAG` | `NORMAL` | `NORMAL` | ✅ True | ❌ False | ❌ False | `[NORMAL_RAG, BOUNDED_LLM]` | `[CRISIS_TEMPLATE, HUMAN_ESCALATION]` | `none` |
| **`low`** | `NORMAL_RAG` / `STRUCTURED_COPING` | `NORMAL` | `NORMAL` | ✅ True | ❌ False | ❌ False | `[NORMAL_RAG, STRUCTURED_COPING, BOUNDED_LLM]` | `[CRISIS_TEMPLATE, HUMAN_ESCALATION]` | `mild_psychoeducation` |
| **`medium`** | `STRUCTURED_COPING` | `COPING` | `NORMAL` | ✅ True | ❌ False | ❌ False | `[STRUCTURED_COPING, BOUNDED_LLM]` | `[CRISIS_TEMPLATE, HUMAN_ESCALATION]` | `structured_coping` |
| **`high`** | `CRISIS_REFERRAL` | `CRISIS` | `BOUNDED_CRISIS` | ❌ **False** | ✅ **True** | ✅ **True** | `[BOUNDED_LLM, CRISIS_TEMPLATE, RESOURCE_RESOLUTION, HUMAN_ESCALATION]` | `[NORMAL_RAG]` | `crisis_referral_directory` |
| **`critical`** | `IMMEDIATE_HOTLINE` | `CRISIS` | `NONE` | ❌ **False** | ✅ **True** | ✅ **True** | `[CRISIS_TEMPLATE, RESOURCE_RESOLUTION, HUMAN_ESCALATION]` | `[NORMAL_RAG, BOUNDED_LLM]` | `emergency_hotline_directory` |

---

## 3. Hard Safety Invariants (Non-Negotiable Guarantees)

1. **No C-SSRS Attribution in Crisis Policy**:
   - Do not autonomously initiate or claim administration of another validated suicide instrument in `SafetyGate`.
   - If structured crisis assessment is required, delegate to the designated **WHO EASE crisis assessment protocol**.
2. **Strict RAG Isolation Invariant**:
   - Turns with `risk_level in ["high", "critical"]` **MUST NOT** execute standard RAG retrieval from Qdrant (`allow_normal_rag = False`).
3. **Explicit `LLMMode` Boundary Invariant**:
   - The LLM **CANNOT** lower a `risk_level`, alter a `SafetyPolicyDecision`, or override a crisis escalation flag.
   - On `critical` turns, freeform LLM generation is strictly prohibited (`llm_mode = NONE`); responses murni use verified crisis templates.
   - On `high` turns, LLM generation is strictly bounded (`llm_mode = BOUNDED_CRISIS`); no self-help advice is permitted.
4. **Policy Flag vs Execution Side Effect**:
   - `requires_human_escalation = True` is a **pure policy flag** (declaration of policy necessity), NOT a side-effect trigger (`requires_human_escalation != perform_human_escalation()`).
   - Side-effect execution is handled downstream by the `Crisis SOP / Escalation Executor`.
5. **Full Auditability**:
   - `SafetyPolicyDecision` **MUST** retain `risk_level`, `risk_type`, and `decision_rule` from `RiskAssessmentOutput` for downstream audit tracking.

---

## 4. Input & Output Schemas

### 4.1 Input Schema (`SafetyGateInput`)

```python
class SafetyGateInput(BaseModel):
    risk_output: RiskAssessmentOutput
    conversation_id: str | None = None
    message_id: str | None = None
```

### 4.2 Output Schema (`SafetyPolicyDecision`)

```python
class SafetyPolicyDecision(BaseModel):
    """
    Pure Policy Decision Payload produced by SafetyGate.
    """
    risk_level: str                 # Retained from RiskAssessmentOutput for downstream audit
    risk_type: str                  # Retained from RiskAssessmentOutput
    decision_rule: str              # Retained from RiskAssessmentOutput (e.g. "PASSIVE_IDEATION_CURRENT")
    mode: ResponseMode              # NORMAL | COPING | CRISIS
    response_policy: ProtocolAction # NORMAL_RAG | STRUCTURED_COPING | SAFETY_REVIEW | CRISIS_REFERRAL | IMMEDIATE_HOTLINE
    llm_mode: LLMMode               # NONE | BOUNDED_CRISIS | NORMAL
    allow_normal_rag: bool
    requires_crisis_sop: bool
    requires_human_escalation: bool # Pure Policy Flag (NOT a side effect call)
    allowed_actions: list[SafetyAction]
    prohibited_actions: list[SafetyAction]
    resource_category: str          # "none", "mild_psychoeducation", "structured_coping", "crisis_referral_directory", "emergency_hotline_directory"
    audit_required: bool = True
```

---

## 5. Implementation Roadmap (Tasks 6 to 12)

```text
[ ✅ Task 6: SafetyGate Specification Blueprint (`docs/safety-gate-spec.md`) ] <-- REFINED COMPLETE
                         │
                         ▼ (Review Specification Blueprint)
[ ⬜ Task 7: Finalize Domain Schemas (`packages/shared/domain_types.py`) ]
                         │
                         ▼
[ ⬜ Task 8: Implement Pure `SafetyGate` Engine (`packages/ai/services/safety_gate.py`) ]
                         │
                         ▼
[ ⬜ Task 9: Implement `SafetyGate` PyTest Suite (`packages/ai/tests/test_safety_gate.py`) ]
                         │
                         ▼
[ ⬜ Task 10: Implement Resource Resolver (`packages/ai/services/resource_resolver.py`) ]
                         │
                         ▼
[ ⬜ Task 11: Implement Crisis SOP / Escalation Executor ]
                         │
                         ▼
[ ⬜ Task 12: Integration with AI Orchestrator Pipeline ]
```
