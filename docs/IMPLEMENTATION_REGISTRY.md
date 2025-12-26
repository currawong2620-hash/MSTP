# IMPLEMENTATION REGISTRY

## Architecture → Implementation Map

**Status:** NON-NORMATIVE
**Scope:** Informational / Navigational
**Change policy:** Free update
**Authority:** None

---

## 0. Purpose

This document provides a **navigation map** between:

* **architectural entities** (as defined in SSP and CONTRACT_LEXICON)
* and their **current implementation files**

It exists solely to help:

* Master-Chat
* Developer
* Auditor

quickly locate **where a given architectural concept is implemented**.

This document:

❌ does **NOT** define architecture
❌ does **NOT** override contracts
❌ does **NOT** participate in audit decisions

---

## 1. Authority Boundary

This registry has **NO architectural authority**.

It does **NOT**:

* define types
* define fields
* define enums
* define roles
* define data flow
* rename entities
* introduce new semantics

The **only authoritative sources** are:

* `SSP v1.x`
* `CONTRACT_LEXICON v1.x`
* fixed architectural specifications

If any conflict exists, **architectural documents always prevail**.

---

## 2. Nature of Information

Information in this registry:

* may be incomplete
* may be outdated
* may lag behind refactoring
* reflects **implementation state**, not intent

Accuracy is **desirable** but **not guaranteed**.

This is **acceptable by design**.

---

## 3. Dependency Direction

Dependency direction is **strictly one-way**:

```
Architecture (SSP, CONTRACT_LEXICON)
↓
Implementation Registry
```

Architectural documents **MUST NEVER reference this registry**.

---

## 4. Allowed / Forbidden Content

### Allowed

* architectural type → file mappings
* architectural role → module mappings
* factual file locations
* integration notes (informational only)

### Forbidden

* new architectural concepts
* semantic explanations
* rationale / motivation
* “should / intended / planned” language

If a new concept is required, **this document is NOT the place**.

---

## 5. Usage Rule for Master-Chat

Before creating any task or spec, Master-Chat SHOULD:

1. Consult `CONTRACT_LEXICON`
2. Consult this registry
3. Only then proceed

If an architectural type is missing in Lexicon, **work MUST STOP**.

---

# A. Architectural Data Types → Implementation Files

### Snapshot

### Intent

### PolicyAdjustedIntent

### Decision *(v1.1)*

### ExecutionResult

### Feedback

All implemented in:

```
modules/Infrastructure/ArchitectureTypes.mqh
```

---

## Snapshot.trends

**Architectural entity:** `Snapshot.trends`
**Status:** Implemented (v1.1)
**Producer:** Observer

**Defined in (authoritative):**

```
CONTRACT_LEXICON — Snapshot
```

**Projected in implementation:**

```
struct Snapshot
  TrendsSnapshot trends;
```

**Populated by:**

```
modules/Observer/Observer.mqh
```

**Notes:**

* Filled exclusively by Observer
* Order reflects startup configuration
* No downstream role reads market history

---

## Snapshot.market.point_size

**Architectural entity:** `Snapshot.market.point_size`
**Lexicon:** v1.2+
**Status:** Implemented (non-breaking extension)

**Defined in (authoritative):**

```
CONTRACT_LEXICON — Snapshot.market
```

**Projected in implementation:**

```
struct MarketSnapshot
  double point_size;
```

**Populated by:**

```
modules/Observer/Observer.mqh
```

**Consumed by:**

```
modules/Strategy/PositionPolicyManager.mqh
```

**Notes:**

* Captured exclusively by Observer
* Downstream roles MUST NOT access MT5 environment
* Preserves SSP single-source-of-truth invariant

---

## TrendAnalysisResult

**Architectural entity:** `TrendAnalysisResult`
**Status:** Implemented (v0.1)
**Producer:** TrendAnalyzer

**Defined in (authoritative):**

```
CONTRACT_LEXICON — TrendAnalysisResult
```

**Projected in implementation:**

```
struct TrendAnalysisResult
  ENUM_TIMEFRAMES timeframe;
  trend_regime    regime;
  int             direction;
  double          confidence;
```

**Populated by:**

```
modules/TrendAnalyzer/TrendAnalyzer.mqh
```

**Notes:**

* Pure analytical result
* One timeframe per result
* No aggregation
* No trading semantics

---

# B. Architectural Roles → Implementation Modules

---

## Observer

* **Role:** Observer
* **Status:** IMPLEMENTED / ACCEPTED
* **Version:** v1.1 (Release v3.0)
* **Replaceable:** No
* **Language:** MQL5

**Files:**

```
modules/Observer/Observer.mqh
```

**Verification:**

```
tests/Observer/TC_ObserverTests.mqh
```

**Notes (informational):**

Produces full `Snapshot`.
Stateless. Deterministic.
Contains no strategy logic, no indicators.
Sole producer of `Snapshot.trends`.

---

## TrendAnalyzer

* **Role:** TrendAnalyzer
* **Status:** IMPLEMENTED / ACCEPTED
* **Version:** v0.1
* **Replaceable:** Yes
* **Language:** MQL5

**File:**

```
modules/TrendAnalyzer/TrendAnalyzer.mqh
```

**Verification:**

```
tests/TrendAnalyzer/TC_TrendAnalyzerTests.mqh
```

**Notes (informational):**

Pure analytical module.
Analyzes one timeframe per call.
Produces `TrendAnalysisResult`.
No Snapshot access.
No Observer dependency.
No trading logic.
Deterministic.

---

## DecisionMaker

* **Role:** DecisionMaker
* **Status:** IMPLEMENTED (STABLE)
* **Replaceable:** Yes
* **Language:** MQL5

**File:**

```
modules/Strategy/DecisionMaker.mqh
```

Scenario-based deterministic baseline.

---

## 🗂 Component: PositionPolicyManager

### v2.1 — Configurable Virtual SL / TP

* **Layer:** Strategy / Replaceable Roles
* **Stage:** Stage-1
* **Status:** IMPLEMENTED / ACCEPTED / **FROZEN**

**Responsibilities:**

* Virtual SL / TP in points
* Exit priority over intent
* Intent filtering
* Deterministic snapshot-based output

**Configuration:**

```
PPM_SL_POINTS
PPM_TP_POINTS
PPM_BASE_OPEN_VOLUME = 1.0
```

**Verification:**

```
tests/Strategy/TC_PositionPolicyManagerTests.mqh
```

---

### v2.2 — Trailing Stop (Snapshot-based)

* **Layer:** Strategy / Replaceable Roles
* **Stage:** Stage-1 extension
* **Status:** IMPLEMENTED / ACCEPTED / ACTIVE

**Added capability:**

* Virtual **Trailing Stop exit**
* Based on `Snapshot.position.trailing_stop_price`
* LONG / SHORT mirror logic
* Exit only (no update, no storage)

**Declared startup parameters:**

```
PPM_TS_START_POINTS
PPM_TS_DISTANCE_POINTS
PPM_TS_STEP_POINTS
```

*(Declared for architectural completeness; not stateful.)*

**Explicit non-capabilities:**

* No trailing calculation
* No trailing mutation
* No step accumulation
* No snapshot modification

**Verification:**

```
tests/Strategy/TC_PositionPolicyManagerTests.mqh
tests/Strategy/TC_PositionPolicyManager_TrailingTests.mqh
```

---

## RiskArbiter

* **Role:** RiskArbiter
* **Status:** IMPLEMENTED
* **Version:** v1.0
* **Replaceable:** Yes
* **Language:** MQL5

**File:**

```
modules/Strategy/RiskArbiter.mqh
```

**Invariant:**

For `Decision.action = CLOSE`:

```
Decision.direction == snapshot.position.direction
```

---

## Executor

* **Role:** Executor
* **Status:** IMPLEMENTED
* **Version:** v1.0 (**FROZEN**)
* **Replaceable:** No
* **Language:** MQL5

**File:**

```
modules/Execution/Executor.mqh
```

Executes `Decision` literally. No interpretation.

---

## FeedbackSource

* **Role:** FeedbackSource
* **Status:** IMPLEMENTED
* **Version:** v1.0
* **Replaceable:** No
* **Language:** MQL5

**File:**

```
modules/Feedback/FeedbackSource.mqh
```

Produces `Feedback` from `ExecutionResult[]` only.

---

# C. Infrastructure / Orchestration

## Coordinator

* **Component:** Coordinator
* **Version:** v0.2.1
* **Status:** STABLE
* **Language:** MQL5

**File:**

```
modules/Infrastructure/Coordinator.mqh
```

Ensures `PositionPolicyManager` is invoked even when `NO_ACTION`
if a position exists (virtual exits).

---

## Role Call Contracts

* **Component:** RoleCallContracts
* **Version:** v0.1

**File:**

```
modules/Infrastructure/RoleCallContracts.mqh
```

Defines callable signatures only.

---

# D. Visual Observability (Non-Architectural)

Visual testers exist for:

* Observer
* DecisionMaker
* PositionPolicyManager
* RiskArbiter
* FeedbackSource

All are **read-only**, runner-level, non-authoritative.

---

# E. Scenario / Test Runner (Non-Architectural)

## TradingMode_Run

* **Type:** Integration / Verification Runner

**File:**

```
TradingMode_Run.mq5
```

**Responsibilities:**

* Allocate storage
* Invoke Coordinator once per tick
* Invoke visual testers
* No architectural authority

---

## Final Registry Impact Summary

✔️ Observer v1.1 recorded as IMPLEMENTED / ACCEPTED
✔️ Snapshot.trends recorded as implemented
✔️ Correct test path added
✔️ TrendAnalyzer v0.1 recorded as IMPLEMENTED / ACCEPTED
✔️ TrendAnalysisResult mapped to implementation
✔️ TrendAnalyzer test suite path recorded
✔️ No architectural contracts modified
✔️ No new types introduced
✔️ Registry remains purely navigational

---

**END OF IMPLEMENTATION REGISTRY**

