# IMPLEMENTATION REGISTRY

## Architecture → Implementation Map

**Status:** NON-NORMATIVE
**Scope:** Informational only
**Change policy:** Free update
**Authority:** None (informational document)

---

## 0. Purpose

This document provides a **navigation map**
between **architectural entities**
(as defined in **SSP v1.x** and **CONTRACT_LEXICON v1.x**)
and their **current implementation files**.

It exists solely to help:

* Master-Chat
* Developer
* Auditor

understand **where architectural concepts are currently implemented**.

This document **does NOT define architecture**
and **MUST NOT be used for architectural decisions**.

---

## 1. Authority Boundary

This document has **NO architectural authority**.

It does NOT:

* define types
* define fields
* define enums
* define roles
* define data flow
* override contracts
* participate in architectural audit

The **only authoritative sources** for architecture are:

* `SSP v1.x`
* `CONTRACT_LEXICON v1.x`
* related FIXED architectural documents

If any conflict exists,
**architectural documents always prevail**.

---

## 2. Nature of Information

Information in this registry:

* may be incomplete
* may be outdated
* may lag behind refactoring
* reflects **implementation state**, not intent

Accuracy is **desirable**
but **not guaranteed**.

This is **acceptable by design**.

---

## 3. Direction of Dependency

Dependency direction is **strictly one-way**:

```
Architecture (SSP, CONTRACT_LEXICON)
↓
Implementation Registry
```

Architectural documents
**MUST NEVER reference this registry**.

---

## 4. Allowed Content

This document MAY contain:

* architectural type → file mappings
* architectural role → implementation module mappings
* factual notes about file locations
* integration patterns (**informational only**)

All content must be **purely factual**.

---

## 5. Forbidden Content

This document MUST NOT contain:

* new architectural types
* new fields
* renamed entities
* semantic explanations
* design rationale
* “should”, “intended”, or “planned” behavior

If a new concept is required,
**this document is NOT the place**.

---

## 6. Usage Rule for Master-Chat

Before creating any technical task or specification,
Master-Chat SHOULD:

1. Consult `CONTRACT_LEXICON`
2. Consult this Implementation Registry
3. Only then proceed to task formulation

If an architectural type is missing in the Lexicon,
**work MUST STOP** until the Lexicon is updated.

---

**End of Implementation Registry Preface**

---

## A. Architectural Data Types → Implementation Files

(без изменений по структуре, но **Decision теперь v1.1 по факту**)

### Snapshot

* `modules/Infrastructure/ArchitectureTypes.mqh`

### Intent

* `modules/Infrastructure/ArchitectureTypes.mqh`

### PolicyAdjustedIntent

* `modules/Infrastructure/ArchitectureTypes.mqh`

### Decision

* `modules/Infrastructure/ArchitectureTypes.mqh`
  *(Decision v1.1: status/action/direction/volume/symbol/reason)*

### ExecutionResult

* `modules/Infrastructure/ArchitectureTypes.mqh`

### Feedback

* `modules/Infrastructure/ArchitectureTypes.mqh`

---

## B. Architectural Roles → Implementation Modules

---

### Observer

* Role: Observer

* Status: **IMPLEMENTED**

* Version: **v1.0 (FROZEN)**

* Replaceable: **No** (infrastructure role)

* Language: MQL5

* Binder:

  ```
  modules/Observer/Observer.mqh
  ```

* Implementation:

  ```
  modules/Observer/impl/Observer_MarketConstraints.mqh
  ```

Notes (informational only):
Produces full `Snapshot` (market, constraints, position, time).
Contains **no logic**, **no strategy**, **no indicators**.

---

### DecisionMaker

* Role: DecisionMaker

* Implementation type: Scenario-based

* Status: Implemented

* Replaceable: Yes

* Language: MQL5

* File:

  ```
  modules/Strategy/Scenario/DecisionMaker_Scenario.mqh
  ```

Notes:
Deterministic scenario-based implementation for
Coordinator integration and contract verification.

---

### PositionPolicyManager

* Role: PositionPolicyManager

* Implementation type: Scenario-based

* Status: Implemented

* Replaceable: Yes

* Language: MQL5

* File:

  ```
  modules/Strategy/Scenario/PositionPolicyManager_Scenario.mqh
  ```

Notes:
Produces 0 / 1 / multiple `PolicyAdjustedIntent`
based on scenario input.

---

### RiskArbiter

* Role: RiskArbiter

* Implementation type: Scenario-based

* Status: Implemented

* Replaceable: Yes

* Language: MQL5

* File:

  ```
  modules/Strategy/Scenario/RiskArbiter_Scenario.mqh
  ```

Notes:
Stateless scenario-based implementation producing
`ACCEPT / REJECT / MODIFY` `Decision` (v1.1).

---

### Executor

* Role: Executor

* Status: **IMPLEMENTED**

* Version: **v1.0 (REAL, FROZEN)**

* Replaceable: **No** (infrastructure role)

* Language: MQL5

* File:

  ```
  modules/Execution/Executor.mqh
  ```

Notes (informational only):
Executes `Decision v1.1` **literally**, performs exactly one MT5 execution attempt,
produces `ExecutionResult` as **pure fact** (`EXECUTED / PARTIAL / FAILED`).
Does **not** read Snapshot, Intent, PolicyAdjustedIntent, Feedback.
Contains **no retry**, **no validation**, **no interpretation**.

---

### FeedbackSource

* Role: FeedbackSource

* Status: Minimal stub

* Replaceable: No (infrastructure role)

* Language: MQL5

* Binder:

  ```
  modules/Feedback/FeedbackSource.mqh
  ```

* Implementation:

  ```
  modules/Feedback/impl/FeedbackSource_Minimal.mqh
  ```

---

## C. Infrastructure Modules

---

### Coordinator

* Component: Coordinator

* Version: **v0.2.1 (STABLE)**

* Layer: Infrastructure / Orchestration

* Language: MQL5

* File:

```

modules/Infrastructure/Coordinator.mqh

```

Notes (informational only):
Performs exactly one full orchestration cycle per tick.
Invokes Observer, DecisionMaker, PositionPolicyManager, RiskArbiter, Executor.
Ensures `Decision.symbol` is populated before execution.
Free of undefined behavior related to managed types (`string`).
UI-agnostic.

---

### Role Call Contracts

* Component: RoleCallContracts

* Version: v0.1

* Status: Defined

* Language: MQL5

* File:

  ```
  modules/Infrastructure/RoleCallContracts.mqh
  ```

Notes:
Defines callable contracts for architectural roles.
Uses **only** types from `CONTRACT_LEXICON v1.x`.
Contains **no behavior**.

---

## D. Visual Observability Components (Non-Architectural)

---

### VisualTester_SnapshotViewer

* Observed role: Observer

* Observed data: Snapshot

* Status: Implemented

* Version: v1.0

* Language: MQL5

* File:

  ```
  modules/Visual/Observer/VisualTester_SnapshotViewer.mqh
  ```

---

### VisualTester_DecisionMaker

* Observed role: DecisionMaker

* Observed data: Intent

* Status: Implemented

* Version: v0.1

* Language: MQL5

* File:

  ```
  modules/Visual/DecisionMaker/VisualTester_DecisionMaker.mqh
  ```

---

### VisualTester_PositionPolicyManager

* Observed role: PositionPolicyManager

* Observed data: Intent, PolicyAdjustedIntent[]

* Status: Implemented

* Version: v0.1

* Language: MQL5

* File:

  ```
  modules/Visual/PositionPolicyManager/VisualTester_PositionPolicyManager.mqh
  ```

---

### VisualTester_RiskArbiter

* Observed role: RiskArbiter

* Observed data: PolicyAdjustedIntent, Decision

* Status: Implemented

* Version: v0.1

* Language: MQL5

* File:

  ```
  modules/Visual/RiskArbiter/VisualTester_RiskArbiter.mqh
  ```

---

### VisualTester_FeedbackSource

* Observed role: FeedbackSource

* Observed data: Feedback

* Status: Implemented

* Version: v0.1

* Language: MQL5

* File:

```

modules/Visual/Feedback/VisualTester_FeedbackSource.mqh

```

Notes (informational only):
Read-only visual tester.
Displays `Feedback.event`, `Feedback.pnl`, `Feedback.message`
and visual history for observability.
Does **not** read `ExecutionResult`, `Snapshot`,
or participate in orchestration logic.

---

### Runtime_InfoPanel

* Component: Runtime InfoPanel

* Type: Operational UI (Runner-level)

* Status: Implemented

* Version: v1.0

* Language: MQL5

* File:

```

UI/InfoPanel.mqh

```

Notes (informational only):
Runner-level operational status panel.
Displays facts only:
system status, position state, last action, execution health.
Does not expose Intent, Decision, PolicyAdjustedIntent, or strategy logic.
Does not participate in orchestration.
Safe for permanent use in live trading runtime.

---

## E. Visual Observability Integration Pattern

**Status:** Informational
**Authority:** None

**Pattern:**

* Coordinator produces outputs via OUT parameters
* Runner allocates storage
* Runner invokes visual testers
* Coordinator remains UI-agnostic

Observed trace data:

* Snapshot
* Intent
* PolicyAdjustedIntent[]
* policy_count

---

## F. Scenario Build Runner (Non-Architectural)

---

### TradingMode_Run

* Type: Integration / Verification Runner
* Role: Orchestration Driver (non-architectural)
* Status: Integrated & Active
* Language: MQL5
* File:

  ```
  TradingMode_Run.mq5
  ```

**Purpose:**
Executes exactly one full orchestration cycle per tick
using `Coordinator_RunCycle(...)`
and provides **runner-level visual observability**.

---

### Responsibilities (Implementation-Level)

The runner is responsible for:

* allocating storage for all Coordinator outputs:

  * `Snapshot`
  * `Feedback`
  * `Intent`
  * `PolicyAdjustedIntent[]`
  * `policy_count`
* invoking `Coordinator_RunCycle(...)` exactly once per tick
* invoking visual testers **only at runner level**
* ensuring visual observability is **read-only**

The runner has **NO architectural authority**.

---

### Invocation Pattern (Informational)

```mq5
Coordinator_RunCycle(
   snapshot,
   feedback,
   intent,
   policy_out,
   policy_count
);

// Visual observability — runner level only
g_vt_sv.Update(snapshot);
g_vt_dm.Update(intent);
g_vt_ppm.Update(intent, policy_out, policy_count);
```

---

### Notes (Non-Authoritative)

* The runner may invoke `RiskArbiter_Run()` a second time
  **solely for visual replay**.
* This is acceptable only while `RiskArbiter` is stateless.
* If `RiskArbiter` gains state or side effects,
  trace data must be exported by Coordinator instead.

---

### Architectural Boundary Reminder

* `TradingMode_Run.mq5` is **NOT** part of system architecture
* it may be modified or removed freely
* SSP and `CONTRACT_LEXICON` remain unaffected

---

**END OF IMPLEMENTATION REGISTRY**

