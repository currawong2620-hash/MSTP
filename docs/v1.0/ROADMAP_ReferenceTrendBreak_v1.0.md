# 🟥 ROADMAP — ReferenceTrendBreak v1.0

## **Normative Implementation Plan (AUDIT-REVISED)**

**Цель:**
внедрить `ReferenceTrendBreak v1.0` как **baseline end-to-end стратегию**,
валидирующую архитектуру **без расширения SSP / Lexicon**.

**Принцип:**
мы **НЕ строим торговую стратегию**,
мы **проверяем жизнеспособность архитектуры**.

---

## 🟦 0. Gate 0 — Preconditions (BLOCKING)

### ДОЛЖНО БЫТЬ ЗАФИКСИРОВАНО

* SSP v1.0 — принят
* CONTRACT_LEXICON v1.x — зафиксирован
* NAMING_RULES v1.0 — зафиксированы
* ROLE_CALL_CONTRACTS_MQL5 v0.1 — зафиксированы
* Architecture Data Flow Model v1.0 — принят
* Visual Observability Model v1.0 — принят
* Coordinator — реализует поток строго по SSP
* Executor — market-only, без SL/TP/modify
* FeedbackSource — v1.0, audit-approved

❌
Если любой пункт не выполнен — **ROADMAP НЕ СТАРТУЕТ**.

---

## 🟦 1. Observer — Verification Only (NO CHANGE)

### Модуль

```
modules/Infrastructure/Observer.mqh
```

### Статус

🟢 **НЕ ИЗМЕНЯЕТСЯ**

### Проверяется

* `Snapshot` формируется строго по CONTRACT_LEXICON
* корректно заполняются:

  * `Snapshot.market.close`
  * `Snapshot.position.*`
  * `Snapshot.time.is_new_bar`
* отсутствуют индикаторы и производные поля

### Результат шага

✔ Snapshot пригоден для ReferenceStrategy
✔ Никаких изменений в Observer не требуется

---

## 🟦 2. DecisionMaker — Reference Implementation

### Модуль

```
modules/Strategy/DecisionMaker_ReferenceTrendBreak.mqh
```

### Статус

🟡 **НОВАЯ РЕАЛИЗАЦИЯ РОЛИ**
(контракт и типы НЕ меняются)

### Реализуется

* логика из Strategy Spec §4:

  * проверка `Snapshot.time.is_new_bar`
  * проверка `Snapshot.position.has_position == false`
  * генерация `WANT_OPEN`
* `confidence = 1.0`
* `NO_ACTION` во всех остальных случаях

### Запрещено

❌ индикаторы
❌ память между циклами
❌ интерпретация рынка

### Результат шага

✔ Intent стабилен и прост
✔ VisualTester_DecisionMaker показывает линейную ленту

---

## 🟦 3. PositionPolicyManager — Single Position + PnL Exit

### Модуль

```
modules/Strategy/PositionPolicyManager_Reference.mqh
```

### Статус

🟡 **НОВАЯ РЕАЛИЗАЦИЯ**
(в рамках существующей роли)

---

### 3.1 Инварианты владения позицией (НОРМАТИВНО)

* одновременно **НЕ БОЛЕЕ одной позиции**
* если `Snapshot.position.has_position == true`:

  * любые `WANT_OPEN` **НЕ транслируются**
* если `Snapshot.position.has_position == false`:

  * любые `WANT_CLOSE` **НЕ транслируются**
  * PositionPolicyManager возвращает **0 выходов**

---

### 3.2 PnL-based virtual exit policy

#### Virtual Stop-Loss

```
IF has_position
AND floating_pnl <= -max_loss
→ WANT_CLOSE
```

#### Virtual Take-Profit

```
IF has_position
AND floating_pnl >= take_profit
→ WANT_CLOSE
```

---

### 3.3 Конфигурационные параметры (константы стратегии)

* `max_loss`
* `take_profit`

❗
**PositionPolicyManager НЕ хранит runtime state между циклами.**
Политика полностью выводится из текущего `Snapshot.position`.

---

### Результат шага

✔ Жизненный цикл позиции корректен
✔ Нет пустых CLOSE
✔ Exit policy не утекает в другие роли

---

## 🟦 4. RiskArbiter — Pass-through Gate

### Модуль

```
modules/Strategy/RiskArbiter_Pass.mqh
```

### Статус

🟢 **МИНИМАЛЬНАЯ реализация**

### Поведение

* `ACCEPT` — для всех допустимых `PolicyAdjustedIntent`
* `REJECT` используется **ТОЛЬКО** если входные данные
  нарушают контракт CONTRACT_LEXICON
  (например: invalid direction / volume)

❗
В рамках ReferenceStrategy такие случаи **НЕ ОЖИДАЮТСЯ**.

### Результат шага

✔ Проверяется корректность ворот
✔ RiskArbiter не “умничает”

---

## 🟦 5. Executor — Reuse (NO CHANGE)

### Модуль

```
modules/Execution/Executor.mqh
```

### Статус

🟢 **НЕ ИЗМЕНЯЕТСЯ**

### Проверяется

* market open / market close
* отсутствие SL/TP
* отсутствие modify
* отсутствие логики

### Результат шага

✔ Исполнение строго буквальное
✔ ExecutionResult формируется корректно

---

## 🟦 6. FeedbackSource — Reuse (NO CHANGE)

### Модуль

```
modules/Infrastructure/FeedbackSource.mqh
```

### Статус

🟢 **НЕ ИЗМЕНЯЕТСЯ**

### Проверяется

* корректная агрегация `ExecutionResult[]`
* допустимые события:

  * `POSITION_OPENED`
  * `POSITION_CLOSED`
  * `ACTION_REJECTED`

### Результат шага

✔ Feedback чистый
✔ Без скрытой логики

---

## 🟦 7. Visual Observability (MANDATORY)

### Задействованные компоненты

```
VisualTester_DecisionMaker
VisualTester_PositionPolicyManager
VisualTester_RiskArbiter
VisualTester_Executor
VisualTester_FeedbackSource
```

### Требование

Каждый VisualTester:

* читает **ТОЛЬКО выход своей роли**
* read-only
* не влияет на поток данных

❗
Если ключевой выход роли невозможно визуализировать,
это считается **дефектом observability**
и подлежит разбору.

---

## 🟦 8. Coordinator / Runner Wiring

### Модули

```
Coordinator.mqh
Runner.mq5
```

### Проверяется

* порядок вызовов строго по SSP
* один orchestration cycle
* exit policy проявляется **ТОЛЬКО как WANT_CLOSE**

---

## 🟦 9. Acceptance Checklist (Gate v1.0)

Стратегия считается внедрённой, если:

* ❏ появляется `WANT_OPEN`
* ❏ позиция открывается
* ❏ PnL-based exit policy закрывает позицию
* ❏ `Feedback` корректен
* ❏ Executor не знает про exit policy
* ❏ Snapshot не расширялся
* ❏ ни один контракт SSP / Lexicon не нарушен

---

## 🧭 Итоговая карта модулей

| Роль                  | Модуль                                     | Статус    |
| --------------------- | ------------------------------------------ | --------- |
| Observer              | Infrastructure/Observer                    | reuse     |
| DecisionMaker         | Strategy/DecisionMaker_ReferenceTrendBreak | new impl  |
| PositionPolicyManager | Strategy/PPM_Reference                     | new impl  |
| RiskArbiter           | Strategy/RiskArbiter_Pass                  | minimal   |
| Executor              | Execution/Executor                         | reuse     |
| FeedbackSource        | Infrastructure/FeedbackSource              | reuse     |
| Visual Testers        | Visual/*                                   | mandatory |
| Coordinator           | Core/Coordinator                           | reuse     |

---

## 🟢 Итоговый статус

> **ROADMAP — APPROVED
