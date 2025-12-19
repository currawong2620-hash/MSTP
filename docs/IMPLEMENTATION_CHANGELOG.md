# IMPLEMENTATION CHANGELOG

All entries reflect **factual implementation events only**.
This document has **no architectural authority**.

---

## [v0.1] — Initial Infrastructure Orchestration

### Added

- Coordinator v0.1
  - SSP-compliant orchestration engine
  - strict role call order and cardinality
  - short-circuit handling (`NO_ACTION`, empty policy, `REJECT`)
  - feedback-based cycle closure
  - language: MQL5

- Role Call Contracts (MQL5) v0.1
  - minimal callable signatures for architectural roles
  - implementation-level only
  - based exclusively on CONTRACT_LEXICON types

---

## [v0.1.1] — Coordinator Compliance Fix & Infrastructure Contracts

### Added

- modules/Infrastructure/ArchitectureTypes.mqh
  - added as physical MQL5 projection of CONTRACT_LEXICON v1.0
  - contains struct and enum definitions only
  - no logic, no helpers, no extensions

- modules/Infrastructure/RoleCallContracts.mqh
  - added as implementation-level ABI for architectural roles
  - defines callable signatures only
  - no role implementations

### Fixed

- Coordinator.mqh
  - enum usage aligned with CONTRACT_LEXICON v1.0
  - replaced non-existent identifiers:
    - INTENT_NO_ACTION → NO_ACTION
    - DECISION_REJECT → REJECT

### Changed

- none

### Removed

- none

## [v0.1.2] — Scenario-based Strategy Roles Implemented

### Added

- DecisionMaker_Scenario.mqh
  - scenario-based implementation of DecisionMaker role
  - deterministic, market-independent
  - compliant with DummyStrategy_ScenarioCoverage_v0.1
  - provides full Intent coverage (NO_ACTION / OPEN / HOLD / CLOSE)

- PositionPolicyManager_Scenario.mqh
  - scenario-based implementation of PositionPolicyManager role
  - deterministic, stateless
  - produces 0 / 1 / 2 PolicyAdjustedIntent outputs as required
  - synchronized via scenario step encoded in Intent.confidence

- RiskArbiter_Scenario.mqh
  - scenario-based implementation of RiskArbiter role
  - fully stateless
  - produces ACCEPT / REJECT / MODIFY decisions
  - decision logic driven strictly by PolicyAdjustedIntent.tag

### Changed

- none

### Removed

- none

## [v0.1.3] — Scenario Baseline Build Verified

### Added

- Scenario-based baseline build for Coordinator verification
  - Coordinator successfully integrated with scenario-based roles:
    - DecisionMaker_Scenario
    - PositionPolicyManager_Scenario
    - RiskArbiter_Scenario
  - Minimal infrastructure implementations added for integration:
    - Observer (minimal)
    - Executor (minimal)
    - FeedbackSource (minimal)

- Binder files for non-replaceable roles
  - Observer.mqh
  - Executor.mqh
  - FeedbackSource.mqh
  These files provide stable role-level include points and allow
  compile-time replacement of concrete implementations without
  changes to Coordinator or strategy code.

- Scenario build runner
  - Minimal `.mq5` entry point used to execute Coordinator_RunCycle
  - Used exclusively for integration verification and observability

### Verified

- Coordinator orchestration flow (1→6) executed correctly
- All short-circuit rules verified:
  - NO_ACTION
  - no PolicyAdjustedIntent
  - Risk REJECT → Executor skipped
- Multi-policy fan-out verified (N Risk / Executor calls, 1 Feedback)
- Feedback loop closed exactly once per cycle
- Deterministic scenario progression confirmed

### Changed

- none

### Removed

- none

## [v0.1.4] — Visual Observability: DecisionMaker

### Added

* VisualTester_DecisionMaker v0.1

  * visual observability component for DecisionMaker role
  * read-only visualization of `Intent` output
  * Intent Timeline with current state + bounded history
  * InfoPanel-based UI adapter (string-only, no logic)
  * SSP-compliant: no role interaction, no data flow impact
  * language: MQL5

### Integrated

* Coordinator v0.1

  * DecisionMaker visual observability hook added
  * `VisualTester_DecisionMaker.Update(intent)` invoked immediately after `DecisionMaker_Run`
  * visual tester declared via `extern` (runner-owned instance)

### Fixed

* Coordinator_RunCycle

  * corrected DecisionMaker feedback input
  * `feedback_in` (previous cycle feedback) passed instead of `out_feedback`

### Changed

* none

### Removed

* none

## [v0.2] — Coordinator Trace-based Visual Observability

### Changed

* **Coordinator v0.2**

  * visual observability refactored from *direct invocation* to **trace-output model**
  * Coordinator no longer references or invokes any VisualTester components
  * no `extern`, no globals, no UI dependencies
  * visual data exposed exclusively via **OUT trace parameters**
  * SSP boundaries strictly preserved

### Added

* **Trace outputs from Coordinator_RunCycle**

  * `Intent out_intent`
  * `PolicyAdjustedIntent[] out_policy_intents`
  * `int out_policy_count`
  * trace is read-only and intended solely for visual observability by Runner

### Fixed

* invalid MQL5 patterns removed:

  * pointer-like parameters
  * `extern`-based coupling
  * forward-declared class method calls
* resolved compiler errors related to incomplete type usage

### Compatibility

* business logic unchanged
* orchestration order unchanged
* determinism preserved
* visual observability fully optional and runner-controlled

---

## v0.2 — Runner-level Visual Observability (Trace-Based)

**Status:** Implemented
**Scope:** Implementation / Verification tooling
**Authority:** None (non-architectural)

---

### Added

* Added **runner-level trace-based visual observability** for strategy roles:

  * `DecisionMaker`
  * `PositionPolicyManager`
  * `RiskArbiter`

* Implemented the following visual tester components:

  * `VisualTester_DecisionMaker v0.1`
  * `VisualTester_PositionPolicyManager v0.1`
  * `VisualTester_RiskArbiter v0.1`

* Integrated visual testers **exclusively in `TradingMode_Run.mq5`**:

  * No visual logic added to `Coordinator`
  * No UI dependencies introduced into infrastructure or strategy roles

---

### Changed

* Updated **Scenario Build Runner** to:

  * allocate explicit trace storage (`Intent`, `PolicyAdjustedIntent[]`)
  * invoke visual testers **after `Coordinator_RunCycle()`**
  * replay `RiskArbiter_Run()` at runner level for decision visualization only

* Updated **Implementation Registry**:

  * clarified Runner responsibilities
  * documented trace-based visual observability pattern
  * added entries for all visual tester components

---

### Verified

* Coordinator remains **UI-agnostic** and **architecture-clean**
* Visual testers are **read-only** and do not affect orchestration or execution
* Disabling all visual testers does not change trading behavior
* Scenario-based strategy remains deterministic under visual replay

---

### Notes (Non-Authoritative)

* Runner-level replay of `RiskArbiter_Run()` is acceptable
  in the current stateless implementation.
* If RiskArbiter acquires state or side effects,
  decision traces must be explicitly exported by Coordinator.

---

## CHANGELOG

### Observer v1.0 — **FROZEN**

**Date:** 2025-12-18
**Component:** Infrastructure / Observer
**Version:** v1.0
**Status:** **FROZEN (NO FURTHER CHANGES)**

---

### Added

* Full implementation of **Observer v1.0** according to:

  * SSP v1.0
  * CONTRACT_LEXICON v1.0
  * TECH SPEC — Observer v1.0 (REVISED)
* Snapshot generation covering **all four sections**:

  * `Snapshot.market`
  * `Snapshot.constraints`
  * `Snapshot.position`
  * `Snapshot.time`
* Deterministic time counters:

  * `bars_since_entry`
  * `bars_since_last_action`
    derived **exclusively from observable position state and bar changes**
* Strict **single-call integration** of `Observer_Run()`:

  * exactly once per orchestration cycle
  * always at the beginning of `Coordinator_RunCycle`

---

### Visual Observability

* Implemented **VisualTester_SnapshotViewer v1.0**

  * read-only
  * Snapshot-only
  * text-based (no UI logic)
* Snapshot Viewer displays:

  * market facts (OHLC, bid/ask, spread)
  * position facts
  * time context and counters
  * broker constraints
* Visual observability integrated **only at Runner level**
* Observer remains completely UI-agnostic

---

### Constraints & Guarantees

* Observer:

  * does **not** read Intent, Decision, ExecutionResult, or Feedback
  * does **not** compute indicators
  * does **not** interpret or “fix” broker data
  * produces **facts only**, as returned by MT5
* Snapshot is treated as **immutable** downstream
* No architectural types, fields, or roles were added or modified

---

### Breaking Changes

* None
  (Observer v1.0 replaces previous minimal stub)

---

### Freeze Rule

> **Observer v1.0 is frozen.**

Any future changes require:

* new version (`Observer v1.1`)
* new TECH SPEC
* explicit architectural approval

---

### Architectural Significance

Observer v1.0 establishes a **single source of truth**
for all downstream strategy, policy, and risk decisions.

If Snapshot is incorrect, **the entire system is invalid**.

---

**End of CHANGELOG entry — Observer v1.0**

---

## 📌 IMPLEMENTATION_CHANGELOG — ADDITION

### Date

2025-12-18

### Scope

Infrastructure / Execution / Architecture Sync

---

### ✅ Added / Updated

**Executor v1.0 (REAL) — IMPLEMENTED & FROZEN**

* Реализован `Executor` с реальным MT5-исполнением.
* Исполнение производится **строго по `Decision v1.1`**.
* Executor:

  * читает **ТОЛЬКО** `Decision`
  * выполняет **ровно одну** попытку `OrderSend`
  * **не** читает `Snapshot`, `Intent`, `PolicyAdjustedIntent`, `Feedback`
  * **не** интерпретирует рынок, позицию или причины отказа
* `ExecutionResult` формируется как **чистый факт**:

  * `EXECUTED / PARTIAL` — по факту `filled_volume`
  * `FAILED` — любой факт неисполнения
* Логика `REJECT` вынесена за пределы Executor (Coordinator responsibility).

---

### 🔁 Architecture Sync

**CONTRACT_LEXICON updated to v1.1 (Decision extended)**

* `Decision` расширен до минимально достаточного контракта для исполнения:

  * `status`
  * `action`
  * `direction`
  * `volume`
  * `symbol`
  * `reason`
* Обновлён `ArchitectureTypes.mqh` для синхронизации с Lexicon v1.1.
* Устранено рассогласование между спецификацией и кодом.

---

### 🧊 Freeze

* `Executor v1.0 (REAL)` — **FROZEN**
* Изменения возможны **только через новую версию Lexicon и Executor**.

---

### 📝 Notes

* Изменения носят **инфраструктурный характер**.
* Архитектурные документы (SSP, Data Flow Model) **не нарушены**.
* Implementation Registry обновлён для отражения фактического состояния.

---

**END OF CHANGELOG ENTRY**

### VisualTester_FeedbackSource v0.1

* Added read-only visual tester for `FeedbackSource`.
* Observed data: `Feedback` (`event`, `pnl`, `message`).
* Purpose: visual observability of feedback flow during orchestration.
* Implemented as non-architectural component (Visual Observability layer).
* Does not read `ExecutionResult`, `Snapshot`, or Coordinator state.
* Does not influence decisions or execution.
* Uses `InfoPanel` UI adapter.
* File:
```

modules/Visual/Feedback/VisualTester_FeedbackSource.mqh

```

---

## 📌 Changelog Entry — Stable Baseline Closure

### **Version:** v0.2.1

### **Status:** **STABLE (Infrastructure Baseline)**

### **Date:** 2025-12-19

### **Scope:** Infrastructure / Orchestration / Runtime

---

### ✅ Fixed

**Coordinator v0.2.1**

* ❌ **Removed illegal `ZeroMemory()` usage** on structures containing managed types (`string`):

  * `Feedback`
  * `Decision`
  * snapshot-related structures
    This eliminates undefined behavior in runtime and execution paths.

* ✅ **Guaranteed `Decision.symbol` initialization** before calling `Executor`:

  * `Decision.symbol` is now set from `Snapshot.market.symbol` when missing.
  * Fixes MT5 execution failure: `Invalid request (price=0.00000, symbol missing)`.

* ✅ **Restored contract correctness between Coordinator → Executor**:

  * `Decision` is now fully self-contained and compliant with `CONTRACT_LEXICON`.
  * `Executor` remains pure and does not infer or patch missing fields.

* ❌ **Removed snapshot pre-clearing** before `Observer_Run`:

  * Snapshot is now populated exclusively by `Observer`, as required by SSP.

---

### ✅ Added

**Production-like Runtime Assembly**

* Introduced **real trading runtime assembly** with:

  * REAL `Observer`
  * REAL `Executor` (MT5 trade API)
  * REAL `FeedbackSource`
  * Dummy Strategy (scenario-based, deterministic)

* Infrastructure is now **strategy-agnostic**:

  * Dummy and real strategies are interchangeable without infrastructure changes.

---

### ✅ Runtime UI

* Added **Runtime InfoPanel v1.0** (Runner-level, non-architectural):

  * Displays **facts only** (system status, position state, last action, execution health).
  * Does **not** expose strategy logic, intents, decisions, or policies.
  * Safe for permanent use in live trading environments.

---

### 🟢 Stability Statement

This version establishes a **stable, production-ready infrastructure baseline**:

* Full SSP-compliant orchestration cycle
* Deterministic behavior under Dummy Strategy
* Real MT5 execution path validated
* No undefined behavior from managed types
* Runtime UI separated from architecture

**This baseline is approved for closure and forward development.**

---
