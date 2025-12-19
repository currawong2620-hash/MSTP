

# 🟥 SPEC — Dummy Strategy v0.1

**Проект:** Trading Platform
**Статус:** ARCHITECTURAL SPEC (non-normative, SSP-compliant)
**Назначение:** Инфраструктурный scaffold
**Аудит:** Master-Chat / Audit-Chat
**Изменения:** только новой версией

---

## 0. Цель документа

Данный документ фиксирует **Dummy Strategy v0.1** —
набор **dummy-реализаций заменяемых ролей**, предназначенный для:

* построения и тестирования инфраструктуры платформы,
* проверки потоков данных,
* проверки Coordinator,
* проверки визуальной наблюдаемости,
* проверки Risk / Policy / Execution веток,

**БЕЗ реализации торговой логики.**

Dummy Strategy **НЕ является стратегией** в трейдерском смысле.

---

## 1. Область применения

Dummy Strategy используется:

* **до** появления реальных стратегий,
* **параллельно** разработке инфраструктуры,
* **как эталон** корректного прохождения архитектурного потока.

Dummy Strategy **должна быть полностью выбрасываемой**.

---

## 2. Роли, реализуемые Dummy Strategy

Dummy Strategy реализует **ТОЛЬКО заменяемые роли**, зафиксированные в SSP:

| Роль                  | Статус |
| --------------------- | ------ |
| DecisionMaker         | Dummy  |
| PositionPolicyManager | Dummy  |
| RiskArbiter           | Dummy  |

Все остальные роли **НЕ входят** в Dummy Strategy и считаются инфраструктурой:

* Observer
* Executor
* FeedbackSource
* Coordinator

---

## 3. Архитектурные ограничения (жёсткие)

### 3.1 Общие запреты

Dummy Strategy **ЗАПРЕЩЕНО**:

* интерпретировать рынок (`Snapshot.market`)
* использовать цены, бары, индикаторы
* адаптироваться к PnL
* оптимизировать поведение
* «учиться»
* содержать заделы под реальную стратегию

Любое из перечисленного считается **архитектурным дефектом**.

---

### 3.2 Принцип изоляции выходов

> **Выходы Dummy Strategy не зависят от входов
> как источника вариативности.**

Входы могут использоваться **ТОЛЬКО** для:

* соблюдения контрактов,
* проверки допустимости состояний,
* перехода фаз сценария.

---

## 4. Источник поведения Dummy Strategy

### 4.1 Допустимый источник разнообразия

Единственный источник разнообразия:

> **Внутренний детерминированный сценарий**

Примеры допустимых механизмов:

* счётчик шагов
* фазовый автомат
* циклическая таблица состояний

### 4.2 Запрещённый источник

Запрещено использовать:

* рынок
* волатильность
* цену
* spread
* PnL
* результат сделок

---

## 5. Dummy DecisionMaker v0.1

### 5.1 Назначение

Генерация **разнообразных `Intent`**, покрывающих все допустимые состояния контракта.

### 5.2 Входы

* `Snapshot` *(ограниченно)*
* `Feedback` *(ограниченно)*

### 5.3 Разрешённое использование входов

* `Snapshot.time.is_new_bar` — как триггер шага
* `Snapshot.position.has_position` — для недопущения логически невозможных Intent
* `Feedback.event` — для перехода фаз сценария

### 5.4 Запрещённое использование входов

* любые поля `Snapshot.market`
* `Feedback.pnl`
* любые адаптивные реакции

---

### 5.5 Выходы

Dummy DecisionMaker **ОБЯЗАН** за цикл сценария породить:

* `NO_ACTION`
* `WANT_OPEN` (direction = +1)
* `WANT_OPEN` (direction = -1)
* `WANT_HOLD`
* `WANT_CLOSE`

`confidence` — фиксированное или сценарное, **не адаптивное**.

---

## 6. Dummy PositionPolicyManager v0.1

### 6.1 Назначение

Доказать архитектурно, что:

* владение позицией живёт вне стратегии,
* один Intent может порождать 0..N выходов.

### 6.2 Входы

* `Intent`
* `Snapshot.position`
* `Feedback` *(ограниченно)*

### 6.3 Поведение (сценарное)

Dummy Policy **ОБЯЗАН** поддерживать сценарии:

* пропуск Intent → 1 `PolicyAdjustedIntent`
* отказ → 0 выходов
* трансформация → изменение volume
* множественный выход → 2+ `PolicyAdjustedIntent`

Все решения:

* не зависят от рынка,
* не содержат рыночной логики.

---

## 7. Dummy RiskArbiter v0.1

### 7.1 Назначение

Смоделировать **ворота допустимости**, не риск-менеджмент.

### 7.2 Входы

* `PolicyAdjustedIntent`
* `Snapshot` *(ограниченно, контрактно)*

### 7.3 Выходы

Dummy RiskArbiter **ОБЯЗАН** породить все статусы `Decision`:

* `ACCEPT`
* `REJECT`
* `MODIFY`

`MODIFY` используется для:

* изменения `volume`
* проверки downstream-веток

Причины (`reason`) — фиксированные, сценарные.

---

---

## Behavioral Guarantees

This section defines **mandatory behavioral guarantees**
for Dummy Strategy v0.1.

These guarantees specify **what architectural states MUST be exercised**
by Dummy Strategy during execution.

They do NOT define:
- role contracts,
- decision logic,
- algorithms,
- timing rules.

All guarantees are strictly **SSP-compliant**.

---

### 1. General Principles

1. Dummy Strategy behavior is **scenario-driven**, not market-driven.
2. Behavior MUST be deterministic under identical call order.
3. Behavior MUST be independent of market conditions.
4. Dummy Strategy MUST NOT introduce any deviation
   from existing SSP role contracts.

---

### 2. DecisionMaker Coverage Guarantees

During scenario execution,
Dummy DecisionMaker MUST produce **all valid Intent categories**
defined in SSP and CONTRACT_LEXICON.

The following Intent states MUST occur at least once:

- `Intent.type = NO_ACTION`
- `Intent.type = WANT_OPEN` with `direction = +1`
- `Intent.type = WANT_OPEN` with `direction = -1`
- `Intent.type = WANT_HOLD`
- `Intent.type = WANT_CLOSE`

No assumptions are made about:
- order,
- frequency,
- triggering conditions.

Only occurrence is guaranteed.

---

### 3. PositionPolicyManager Coverage Guarantees

During scenario execution,
Dummy PositionPolicyManager MUST exercise
all admissible transformation patterns.

The following cases MUST occur at least once:

- single Intent → **zero** `PolicyAdjustedIntent`
- single Intent → **one** `PolicyAdjustedIntent`
- single Intent → **multiple** `PolicyAdjustedIntent`
- modification of `PolicyAdjustedIntent.volume`

No market-based logic is permitted.

---

### 4. RiskArbiter Coverage Guarantees

During scenario execution,
Dummy RiskArbiter MUST produce
all valid `Decision.status` values.

The following Decision states MUST occur at least once:

- `Decision.status = ACCEPT`
- `Decision.status = REJECT`
- `Decision.status = MODIFY`

When `MODIFY` is produced,
it MUST result in a **material change**
to the Decision payload (e.g. volume).

---

### 5. Execution Independence Requirement

Dummy Strategy behavior MUST remain unchanged when:

- symbol is changed,
- timeframe is changed,
- market conditions differ,
- price data is randomized.

If behavior changes under these conditions,
Dummy Strategy is considered **invalid**.

---

### 6. Architectural Purpose

The sole purpose of these guarantees is to ensure that:

- Coordinator logic is fully exercised,
- all architectural data paths are traversed,
- downstream infrastructure can be validated
  independently of strategy logic.

---

### 7. Removal Invariant

Dummy Strategy MUST remain fully removable.

Replacing Dummy Strategy with any real strategy
MUST NOT require changes to:

- Coordinator,
- Executor,
- FeedbackSource,
- architectural contracts.

---

**End of Behavioral Guarantees**

Отлично. Тогда делаем **Вариант A** — аккуратно, нормативно, **без изменения SSP**, как **раздел для `SPEC — Dummy Strategy v0.1`**.

Ниже — **ГОТОВЫЙ ТЕКСТ**, плюс **чёткое указание, куда вставлять**.
Это финальная фиксация модели Coordinator на текущем этапе.

---

## Orchestration Model (Coordinator)

This section defines the **normative orchestration model**
used during Dummy Strategy execution.

The Coordinator described here:
- does NOT define new architecture,
- does NOT modify SSP role contracts,
- does NOT introduce strategy logic.

It specifies the **execution order and invocation rules**
already implied by SSP, made explicit for infrastructure development.

---

### 1. Orchestration Unit

The fundamental unit of orchestration is a **single Snapshot**.

For each produced Snapshot,
Coordinator executes **exactly one orchestration cycle**.

All downstream actions in the cycle
are causally bound to the same Snapshot.

---

### 2. Normative Call Order

For each orchestration cycle,
Coordinator MUST invoke roles
in the following strict order:

(1) Observer
→ produces Snapshot

(2) DecisionMaker
reads: Snapshot, Feedback
→ produces Intent

(3) PositionPolicyManager
reads: Intent, Snapshot.position, Feedback
→ produces PolicyAdjustedIntent (0..N)

(4) RiskArbiter
reads: PolicyAdjustedIntent(s), Snapshot
→ produces Decision (per input)

(5) Executor
reads: Decision
→ produces ExecutionResult

(6) FeedbackSource
reads: ExecutionResult, position state
→ produces Feedback

No reordering, skipping, or merging of steps is permitted.

---

### 3. Invocation Cardinality Rules

#### 3.1 DecisionMaker

- invoked **exactly once** per Snapshot
- MUST produce **exactly one Intent**

---

#### 3.2 PositionPolicyManager

- invoked **exactly once** per Intent
- MAY produce **zero or more PolicyAdjustedIntent**

---

#### 3.3 RiskArbiter

- invoked **once per PolicyAdjustedIntent**
- MUST produce **exactly one Decision** per invocation

RiskArbiter is **not** invoked
if no PolicyAdjustedIntent exists.

---

#### 3.4 Executor

- invoked **once per Decision**
- MUST NOT aggregate, retry, or reorder executions

Executor is **not** invoked
for Decision with status `REJECT`.

---

#### 3.5 FeedbackSource

- invoked **once per orchestration cycle**
- invoked **after all ExecutionResult are finalized**
- MUST produce **exactly one Feedback**

Feedback MUST reflect the factual outcome
of the entire cycle, including cases where no execution occurred.

---

### 4. Empty and Short-Circuit Scenarios

The following scenarios are valid
and MUST be handled by Coordinator:

- `Intent.type = NO_ACTION`
  → PositionPolicyManager, RiskArbiter, Executor are skipped

- `PolicyAdjustedIntent = empty`
  → RiskArbiter and Executor are skipped

- `Decision.status = REJECT`
  → Executor is skipped

In all cases,
FeedbackSource **MUST still be invoked**.

---

### 5. Coordinator Restrictions

Coordinator MUST NOT:

- read or interpret market data
- read or modify architectural data types
- filter or transform Intent
- merge or alter Decisions
- implement retries or heuristics
- embed strategy, policy, or risk logic

Coordinator responsibility is limited to
**ordering and invocation only**.

---

### 6. Strategy Independence Invariant

Coordinator behavior MUST remain unchanged
when Dummy Strategy is replaced
by any real strategy implementation.

Any required modification of Coordinator
to support a strategy
constitutes an architectural violation.

---

### 7. Architectural Role

Coordinator acts as a **pure orchestration mechanism**.

It defines **when** roles are invoked,
never **why** or **how** they behave.

---

**End of Orchestration Model (Coordinator)**

---

## 8. Визуальная наблюдаемость (обязательная)

Для Dummy Strategy **ОБЯЗАТЕЛЬНЫ** следующие визуальные тестеры:

| Роль                  | Тип данных             | Визуализация          |
| --------------------- | ---------------------- | --------------------- |
| DecisionMaker         | `Intent`               | Intent Timeline       |
| PositionPolicyManager | `PolicyAdjustedIntent` | Policy Trace          |
| RiskArbiter           | `Decision`             | Decision Gate Monitor |

Отсутствие визуального покрытия считается **неполнотой реализации**.

---

## Visual Observability Model

This section defines the **mandatory visual observability artifacts**
for Dummy Strategy execution.

Visual observability is used to:
- validate architectural flow,
- verify Coordinator orchestration,
- expose data-path coverage,
- support early debugging of infrastructure.

Visual artifacts are **observational only**.

They MUST NOT:
- influence system behavior,
- contain business logic,
- perform validation or decision making.

---

### 1. General Observability Principles

1. Each orchestration step MUST have
   at least one corresponding visual artifact.
2. Visual artifacts reflect **fact of execution**, not correctness.
3. Absence of a visual artifact
   indicates a broken architectural path.
4. Visual observability is required
   before any real strategy implementation.

---

### 2. Snapshot Observability

**Observed Step:** Observer → Snapshot

**Artifact:** Snapshot Viewer

**Purpose:**
- confirm Snapshot production
- identify orchestration cycle boundaries

**Observed Data:**
- Snapshot timestamp
- symbol
- timeframe
- position.has_position

---

### 3. Intent Observability

**Observed Step:** DecisionMaker → Intent

**Artifact:** Intent Timeline

**Purpose:**
- verify single Intent per Snapshot
- observe Intent diversity over time
- confirm DecisionMaker invocation

**Observed Data:**
- Snapshot identifier
- Intent.type
- Intent.direction
- Intent.confidence

---

### 4. Policy Observability

**Observed Step:** PositionPolicyManager → PolicyAdjustedIntent(s)

**Artifact:** Policy Trace

**Purpose:**
- observe Intent transformation
- verify 0 / 1 / N output cases
- confirm volume modification

**Observed Data:**
- input Intent reference
- number of PolicyAdjustedIntent produced
- PolicyAdjustedIntent.volume
- PolicyAdjustedIntent.tag

---

### 5. Risk Decision Observability

**Observed Step:** RiskArbiter → Decision

**Artifact:** Decision Gate Monitor

**Purpose:**
- observe admissibility outcomes
- verify ACCEPT / REJECT / MODIFY coverage
- confirm Decision propagation rules

**Observed Data:**
- Decision.status
- Decision.volume
- associated PolicyAdjustedIntent

---

### 6. Execution Observability

**Observed Step:** Executor → ExecutionResult

**Artifact:** Execution Log

**Purpose:**
- confirm execution attempts
- observe execution outcomes
- validate Decision → Execution linkage

**Observed Data:**
- ExecutionResult.status
- filled_volume
- price
- associated Decision

---

### 7. Feedback Observability

**Observed Step:** FeedbackSource → Feedback

**Artifact:** Feedback Panel

**Purpose:**
- confirm orchestration cycle closure
- observe system reaction to outcomes
- verify feedback presence in all scenarios

**Observed Data:**
- Feedback.event
- Feedback.pnl
- Feedback.message
- Snapshot reference

---

### 8. Completeness Requirement

Dummy Strategy execution is considered
**architecturally observable**
only if all defined visual artifacts:

- are present,
- are populated during execution,
- update consistently with orchestration cycles.

Missing or inactive artifacts
indicate an incomplete infrastructure implementation.

---

### 9. Strategy Independence Rule

Visual observability MUST remain unchanged
when Dummy Strategy is replaced
by any real strategy.

Any observability logic
that depends on strategy behavior
constitutes an architectural violation.

---

**End of Visual Observability Model**


## 9. Критерии корректности Dummy Strategy

Dummy Strategy считается корректной, если:

* ❏ полный архитектурный поток замыкается
* ❏ все контрактные состояния достигаются
* ❏ поведение детерминировано
* ❏ сценарий воспроизводим
* ❏ рынок не влияет на решения
* ❏ Dummy можно удалить без влияния на архитектуру

---

## SSP Compliance (Mandatory)

Dummy Strategy v0.1 does not define any role interfaces.

All role interactions, allowed inputs, outputs, and prohibitions
are governed exclusively by **SSP v1.0**.

Dummy Strategy implementations MUST strictly comply with
all existing SSP role contracts and data flow rules.

Dummy Strategy introduces no exceptions, extensions,
or reinterpretations of SSP-defined roles.


## 10. Контрольный вопрос (обязательный)

> **Если запустить систему в другой день,
> на другом инструменте,
> при другом рынке —
> последовательность Intent будет той же?**

Если **да** — SPEC соблюдён.
Если **нет** — Dummy Strategy нарушена.

---

**END OF SPEC — Dummy Strategy v0.1**

---

