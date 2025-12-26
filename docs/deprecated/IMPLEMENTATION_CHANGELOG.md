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
## [UNRELEASED]

### Added
- PositionPolicyManager v1.0 — production implementation.
  - Scenario-based implementation replaced with stateless role logic.
  - Implements PnL-based exit policy using compile-time constants.
  - Emits `WANT_CLOSE` exclusively based on `Snapshot.position.floating_pnl`.
  - Enforces single-position invariant.
  - Blocks `WANT_CLOSE` originating from `Intent`.
  - No MT5 order modification, no price-based SL/TP, no runtime state.

### Added (Tests)
- Acceptance Test Suite for PositionPolicyManager v1.0.
  - Determinism verification.
  - Exit policy priority over incoming intents.
  - Validation of blocking rules (`WANT_OPEN`, `WANT_CLOSE`).
  - Single-output invariant enforcement.

### Changed
- PositionPolicyManager implementation file promoted from scenario-based
  to production-ready role implementation.

### Deprecated
- PositionPolicyManager_Scenario.mqh
  - Retained for historical reference only.

[2025-12-19]
- RiskArbiter v1.0
  * Baseline gate implementation added
  * Acceptance Test Suite passed

---

## 📝 CHANGELOG

### **[v1.1] — PositionPolicyManager & RiskArbiter integration**

**Status:** FIXED / STABILIZED
**Scope:** Strategy / Replaceable Roles
**Date:** 2025-12-19

---

### ✅ Fixed — Virtual SL/TP execution pipeline

**Issue:**
Виртуальные StopLoss / TakeProfit не приводили к фактическому закрытию позиции, несмотря на корректное срабатывание exit-policy в `PositionPolicyManager`.

**Root cause:**
Несоответствие контрактной семантики между:

* `PolicyAdjustedIntent (WANT_CLOSE)`
* `Decision (action = CLOSE)`

`RiskArbiter` передавал `Decision.direction = 0`, что противоречило **CONTRACT_LEXICON v1.0**, где для `Decision.action = CLOSE` направление **обязательно** и обозначает направление позиции, подлежащей закрытию.

**Resolution:**

* ✅ `PositionPolicyManager v1.1`

  * Exit-policy реализована как **виртуальные SL/TP по price (points)**:

    * LONG → `bid`
    * SHORT → `ask`
  * Формирует `PolicyAdjustedIntent(WANT_CLOSE)` с:

    * `direction = 0`
    * `volume = snapshot.position.volume`
    * `tag = POLICY_EXIT`
  * Exit имеет приоритет над любыми входящими `Intent`.

* ✅ `RiskArbiter v1.0`

  * Приведение `Decision` к **лексикон-корректному виду**:

    * `Decision.action = CLOSE`
    * `Decision.direction = snapshot.position.direction`
  * Обеспечена совместимость с `Executor`.

* ✅ Test coverage

  * Добавлены и пройдены acceptance-тесты:

    * LONG / SHORT SL
    * LONG / SHORT TP
    * bid / ask корректность
    * Exit overrides WANT_OPEN
    * Determinism, output invariants, feedback inertness

**Result:**

* 🔒 Виртуальные SL/TP **детерминированно закрывают позицию**
* 🔗 Контракт `PPM → RiskArbiter → Executor` полностью согласован с Lexicon
* 🧪 TestSuite `PositionPolicyManager v1.1` — **PASSED**
* 🧪 TestSuite `RiskArbiter v1.0` — **PASSED**

---

## 📝 IMPLEMENTATION_CHANGELOG — запись

### ✅ Stable snapshot — ReferenceTrendBreak (Contrarian experiment resolved)

**Date:** *(заполни фактическую дату)*
**Scope:** Strategy / Infrastructure
**Status:** **STABLE**

---

### Added

* `DecisionMaker.mqh` — baseline DecisionMaker (ReferenceTrendBreak), детерминированная реализация генерации `Intent` на основе трёх закрытых баров.
* Поддержка поля `Snapshot.market.last_closes[3]` как нормативного источника данных для DecisionMaker.

---

### Changed

* `ArchitectureTypes.mqh` обновлён для поддержки `last_closes[3]` в `MarketSnapshot`.
* `Observer_MarketConstraints.mqh` дополнен заполнением `last_closes[3]` из закрытых баров (`iClose`, shifts 1..3).
* `PositionPolicyManager.mqh`:

  * исправлён расчёт виртуальных SL/TP: `_Point` заменён на `SymbolInfoDouble(snapshot.market.symbol, SYMBOL_POINT)` для корректной символ-специфичной логики.
* `Coordinator.mqh`:

  * скорректирован short-circuit: `PositionPolicyManager` теперь вызывается **даже при `Intent == NO_ACTION`, если позиция существует**, что восстанавливает корректную работу виртуальных стопов.

---

### Fixed

* Восстановлено срабатывание виртуальных SL/TP при наличии открытой позиции.
* Устранён архитектурный блокер, при котором exit-политика не исполнялась из-за раннего short-circuit в Coordinator.
* Устранён рассинхрон размера пункта при расчёте виртуальных стопов.

---

### Notes

* Контртрендовая (инвертированная) логика DecisionMaker использовалась **в экспериментальных целях** и **не зафиксирована** как нормативная.
* Стабильной считается конфигурация с корректно работающими:

  * Observer → Snapshot
  * DecisionMaker → Intent
  * PositionPolicyManager → virtual SL/TP
  * Coordinator → полный оркестрационный цикл

---

### Compatibility

* Совместимо с существующими тестами инфраструктуры.
* DecisionMaker acceptance-тесты валидны для трендовой reference-логики; инверсия требует отдельного набора тестов.

---
Принял. Ниже — **ТОЧНАЯ ЗАПИСЬ В IMPLEMENTATION_CHANGELOG**,
в том стиле и уровне формальности, который у нас уже принят.
Без маркетинга, без интерпретаций, **фиксируем факт**.

---

## 📝 IMPLEMENTATION_CHANGELOG — добавление

### ✅ FeedbackSource v1.0 — normal implementation (baseline)

**Subsystem:** Infrastructure / Feedback
**Status:** **STABLE**
**Impact:** Infrastructure (non-strategic)

---

### Added

* `modules/Feedback/FeedbackSource.mqh`
  Полноценная реализация роли **FeedbackSource v1.0**
  (детерминированный агрегатор `ExecutionResult[] → Feedback`).

---

### Replaced

* `FeedbackSource_Minimal.mqh`
  Минимальный stub **больше не используется** для сценарных прогонов.

---

### Behaviour (factual)

* `Feedback` формируется **исключительно** на основе `ExecutionResult[]`
* Полная перезапись `Feedback` при каждом вызове
* `results_count == 0` агрегируется как:

  * `Feedback.event = ACTION_REJECTED`
  * `Feedback.message = "NO_EXECUTION"`
* Любое наличие `EXECUTED` или `PARTIAL`:

  * агрегируется как **не-ACTION_REJECTED** событие
* `Feedback.pnl` фиксирован как `0.0` (v1.0)

---

### Guarantees

* Полная совместимость с:

  * **SSP v1.1**
  * **CONTRACT_LEXICON v1.2**
  * **ARCHITECTURE_DATA_FLOW_MODEL v1.1**
* Отсутствие:

  * MT5 trade API
  * доступа к `Decision / Snapshot / Intent`
  * скрытого состояния
  * `ZeroMemory` над управляемыми типами

---

### Tests

* Добавлен acceptance test suite:

  ```
  tests/Infrastructure/TC_FeedbackSource_Tests.mqh
  ```
* Все тесты пройдены:

  * overwrite invariant
  * empty execution semantics
  * success aggregation
  * determinism
  * order independence

---

### Notes

* OPEN / CLOSE семантика **намеренно не различается** в v1.0
* Реальный PnL **не вычисляется** (осознанное ограничение версии)
* Любое расширение логики → **FeedbackSource v1.1+**

---

**Change type:** Non-breaking
**Baseline status:** ✅ **FIXED**

---

### [Architecture] Snapshot.market.point_size

**Type:** Architecture / Data Contract
**Status:** Added
**Scope:** System-wide
**Breaking change:** ❌ No
**SSP impact:** ❌ No (compliant extension)

**Description:**

Added new factual market field `Snapshot.market.point_size`
to represent the minimal price step of the trading instrument.

The field is populated exclusively by `Observer`
and is intended for downstream roles (e.g. `PositionPolicyManager`)
to perform price-to-points calculations
without direct access to execution environment data.

**Rationale:**

This change removes the need for downstream roles
to query MT5 environment (`SymbolInfo*`, `_Point`),
thereby restoring strict SSP compliance and preserving
the invariant that `Snapshot` is the single source of truth
for market-related facts.

**Affected components:**

* CONTRACT_LEXICON — `Snapshot.market`
* ArchitectureTypes.mqh — `MarketSnapshot`
* Observer — market snapshot population
* PositionPolicyManager — virtual SL/TP exit policy

**Notes:**

* `point_size` is a factual, immutable market attribute
* no architectural roles, data flows, or contracts were changed
* no new types or enums were introduced

---

## Аудиторский статус

✔️ SSP-compliant
✔️ Data Flow preserved
✔️ Determinism preserved
✔️ Visual observability preserved

---

### [Strategy] PositionPolicyManager — Virtual SL/TP (points, snapshot)

**Type:** Strategy / Replaceable Role
**Status:** Implemented
**Version:** v2.0
**Breaking change:** ❌ No
**SSP impact:** ❌ No

**Description:**

Implemented virtual Stop-Loss / Take-Profit exit policy in `PositionPolicyManager`
based on **price distance in points**, using only factual data provided by `Snapshot`.

The role now performs deterministic exit decisions when the current price
exceeds a fixed point-distance threshold relative to the position entry price.

**Key properties:**

* SL/TP are **virtual** (no MT5 order modification)
* Exit distance is symmetric and measured in **points**
* Calculations rely exclusively on:

  * `Snapshot.position.entry_price`
  * `Snapshot.position.volume`
  * `Snapshot.market.bid / ask`
  * `Snapshot.market.point_size`
* No access to MT5 environment (`_Point`, `SymbolInfo*`, `MarketInfo*`)
* Exit policy has **absolute priority** over incoming `Intent`

**Behavioral rules:**

* LONG position:

  * exit if `bid ≤ entry − N·point_size` or `bid ≥ entry + N·point_size`
* SHORT position:

  * exit if `ask ≥ entry + N·point_size` or `ask ≤ entry − N·point_size`
* Exit emits a single `PolicyAdjustedIntent`:

  * `type = WANT_CLOSE`
  * `direction = 0`
  * `volume = snapshot.position.volume`
  * `tag = "POLICY_EXIT"`
* Incoming `WANT_CLOSE` intents are ignored unless an exit condition fires
* `WANT_OPEN` is allowed only when no position exists

**Configuration:**

* Exit distance is fixed for v2.0 via internal constant
* No runtime or input-based configuration introduced in this version

**Tests:**

* Acceptance test suite added:

  ```
  tests/Strategy/TC_PositionPolicyManagerTests.mqh
  ```
* Covers determinism, invariants, intent filtering, and all SL/TP exit cases
* All tests pass; suite is black-box and SSP-compliant

**Notes:**

* This version establishes the baseline for point-based exit logic
* Future versions may introduce configurable parameters and trailing logic

---

### Аудиторский статус

✔️ SSP-compliant
✔️ CONTRACT_LEXICON-compliant
✔️ Deterministic
✔️ Black-box
✔️ Test-covered

---

## 📝 IMPLEMENTATION_CHANGELOG — запись

### **PositionPolicyManager v2.1 — Configurable Virtual SL / TP (Stage 1)**

**Subsystem:** Strategy / Replaceable Roles
**Component:** PositionPolicyManager
**Version:** v2.1
**Status:** **STABLE / ACCEPTED**
**Date:** *(укажи фактическую дату коммита)*

---

### ✅ Added

* **PositionPolicyManager v2.1**

  * Реализована **конфигурируемая виртуальная exit-политика**:

    * Stop-Loss и Take-Profit в **points**
    * параметры задаются через **startup input parameters**:

      * `PPM_SL_POINTS`
      * `PPM_TP_POINTS`
  * Exit-логика:

    * LONG → `Snapshot.market.bid`
    * SHORT → `Snapshot.market.ask`
    * расчёты выполняются **исключительно** через `Snapshot.market.point_size`
  * Exit имеет **абсолютный приоритет** над любыми входящими `Intent`.

---

### ✅ Fixed / Stabilized

* Устранена зависимость от MT5 environment:

  * ❌ `_Point`
  * ❌ `SymbolInfo*`
* Логика PPM полностью переведена на **Snapshot-based факты**.
* Зафиксирована baseline-семантика открытия позиции:

  * `PPM_BASE_OPEN_VOLUME = 1.0`
  * значение подтверждено Master-Chat как SSoT
* Поведение `WANT_OPEN` приведено к контрактно-корректному виду:

  * допускается только при `has_position == false`
  * `direction ∈ {+1, −1}`
  * `volume = PPM_BASE_OPEN_VOLUME`
  * `tag = "POLICY_PASS"`

---

### 🧪 Tests

* Добавлен и принят **Acceptance Test Suite**:

  ```
  tests/Strategy/TC_PositionPolicyManagerTests.mqh
  ```

* Покрытие включает:

  * LONG / SHORT SL
  * LONG / SHORT TP
  * Exit priority over `WANT_OPEN` / `WANT_CLOSE`
  * Intent filtering rules
  * Determinism (full output comparison)
  * Output invariants
  * Feedback inertness

* Все тесты **PASS**

* Suite детерминирована и не зависит от runtime input значений.

---

### 🧊 Freeze Status

* **PositionPolicyManager v2.1 — FROZEN**
* Любые изменения возможны **только** через:

  * новую версию роли (v2.2+)
  * обновлённый TECH SPEC / TEST SPEC
  * при необходимости — CONTRACT_LEXICON update

---

### 🧠 Notes (Non-Authoritative)

* v2.1 завершает **Stage 1** развития PPM.
* Trailing Stop **осознанно не реализован** и вынесен в следующий этап.
* v2.1 служит **baseline** для дальнейших policy-расширений.

---

# 🧾 CHANGELOG — PositionPolicyManager

## Version **v2.2** — Trailing Stop (Snapshot-based)

**Status:** IMPLEMENTED & TESTED
**Stage:** Strategy / Replaceable Roles
**Language:** STRICT MQL5

---

### ✅ Added

* **Virtual Trailing Stop support** (snapshot-based)

  * Exit on trailing stop hit:

    * **LONG:** `bid <= trailing_stop_price`
    * **SHORT:** `ask >= trailing_stop_price`
  * Trailing treated as **external fact** (`Snapshot.position.trailing_stop_price`)
  * No trailing calculation, update, or persistence inside PPM

* **Startup input parameters declared** (immutable during run):

  * `PPM_TS_START_POINTS`

  * `PPM_TS_DISTANCE_POINTS`

  * `PPM_TS_STEP_POINTS`

  > Parameters are declared for architectural completeness;
  > **PPM v2.2 does not store or update trailing state.**

* **Acceptance Test Suite added**

  * `TC_PositionPolicyManager_TrailingTests.mqh`
  * Covers activation, hit/no-hit, LONG/SHORT symmetry, exit priority, SL/TP interaction, determinism, feedback inertness
  * Environment-coupled inputs explicitly documented

---

### 🔁 Preserved (No Change)

* **Public role contract** `PositionPolicyManager_Run(...)`
* **Stateless behavior**
* **Determinism**
* **Feedback inertness**
* **Exit priority over Intent**
* **Virtual SL / TP logic** from v2.1
* **WANT_OPEN filtering rules**
* **Output cardinality invariant `{0,1}`**

---

### ❌ Explicitly Not Implemented

* No trailing stop calculation
* No trailing update or step-gating logic
* No mutation of `Snapshot`
* No storage of trailing state between calls

> Trailing lifecycle and updates remain responsibility of Snapshot-producer / Observer layer.

---

### 🧪 Validation

* ✅ All **PPM v2.1 Acceptance Tests** — PASS
* ✅ All **PPM v2.2 Trailing Acceptance Tests (REV1)** — PASS
* ✅ SSP / Lexicon / Audit — PASS

---

### 📌 Notes

* `PPM_BASE_OPEN_VOLUME = 1.0` remains unchanged (SSoT)
* `CONTRACT_LEXICON v1.4` required for `trailing_stop_price`

---

