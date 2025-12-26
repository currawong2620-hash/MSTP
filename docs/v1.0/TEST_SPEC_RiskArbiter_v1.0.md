# 🟥 TEST SPEC — RiskArbiter v1.0

## **ReferenceTrendBreak (Baseline Gate Tests)**

### **AUDIT-RESOLVED REV A**

**Проект:** Trading Platform (MQL5)
**Подсистема:** Strategy / Replaceable Roles
**Тестируемая роль:** `RiskArbiter`
**Версия роли:** v1.0
**Версия Test Spec:** v1.0
**Статус:** **APPROVED (after audit)**
**Язык:** строго MQL5

**Файл тестов:**

```
tests/Strategy/TC_RiskArbiterTests.mqh
```

---

## 0. Назначение тестов (НОРМАТИВНО)

Данный Test Spec предназначен **ИСКЛЮЧИТЕЛЬНО** для проверки:

* контрактной корректности `RiskArbiter_Run`
* строгого соответствия **TECH SPEC — RiskArbiter v1.0 (REV B)**
* соблюдения **SSP v1.0** и **CONTRACT_LEXICON v1.1**
* отсутствия запрещённой логики
* детерминизма решений

❌ Test Spec **НЕ** проверяет:

* торговый смысл
* рыночную адекватность
* прибыльность
* корректность Observer / Executor / Coordinator

---

## 1. Нормативные основания (ОБЯЗАТЕЛЬНО)

Тесты **ДОЛЖНЫ строго соответствовать**:

1. **SSP v1.0**
2. **CONTRACT_LEXICON v1.1**
3. **NAMING_RULES v1.0**
4. **ROLE_CALL_CONTRACTS_MQL5 v0.1**
5. **TECH SPEC — RiskArbiter v1.0 (REV B)**

---

## 2. Общие правила тестирования

### 2.1 Архитектурные ограничения

* тесты используют **ТОЛЬКО**:

  * `RiskArbiter_Run`
  * типы из `ArchitectureTypes.mqh`
* запрещено:

  * MT5 API
  * глобальное состояние
  * side-effects
  * вызовы других ролей

---

### 2.2 Snapshot в тестах (УТОЧНЕНО)

* `Snapshot` в тестах:

  * заполняется **минимально**
  * используется **ТОЛЬКО** поле:

    * `snapshot.market.symbol`
* остальные поля:

  * **заполняются нулевыми значениями**
  * **НЕ участвуют в логике**
  * **НЕ должны влиять на результат**

---

### 2.3 Decision в тестах

Тесты проверяют:

* `Decision.status`
* `Decision.action`
* `Decision.direction`
* `Decision.volume`
* `Decision.symbol`
* `Decision.reason`

Тесты **НЕ** проверяют:

* исполнение
* side-effects
* взаимодействие с Executor

---

## 3. Обязательные тестовые группы

---

### 🟦 RA-1 — Determinism

**Цель:**
Подтвердить детерминизм `RiskArbiter_Run`.

**Сценарий:**

* одинаковый `PolicyAdjustedIntent`
* одинаковый `Snapshot.market.symbol`
* два последовательных вызова

**Ожидание:**

* `Decision` бит-в-бит одинаковый:

  * `status`
  * `action`
  * `direction`
  * `volume`
  * `symbol`
  * `reason`

---

### 🟦 RA-2 — ACCEPT for WANT_OPEN

**Вход:**

```
policy_intent.type      = WANT_OPEN
policy_intent.direction = +1
policy_intent.volume    > 0
snapshot.market.symbol  = "EURUSD"
```

**Ожидание:**

* `Decision.status   = ACCEPT`
* `Decision.action   = OPEN`
* `Decision.direction= +1`
* `Decision.volume   = policy_intent.volume`
* `Decision.symbol   = snapshot.market.symbol`
* `Decision.reason   = "OK"`

---

### 🟦 RA-3 — ACCEPT for WANT_CLOSE  ✅ (ИСПРАВЛЕНО)

**Вход:**

```
policy_intent.type      = WANT_CLOSE
policy_intent.direction = 0
policy_intent.volume    > 0
snapshot.market.symbol  = "XAUUSD"
```

**Ожидание:**

* `Decision.status    = ACCEPT`
* `Decision.action    = CLOSE`
* `Decision.direction = 0`
* `Decision.volume    = policy_intent.volume`
* `Decision.symbol    = snapshot.market.symbol`
* `Decision.reason    = "OK"`

📌
Фиксируется **лексикон-корректная семантика CLOSE**.

---

### 🟦 RA-4 — REJECT invalid intent type

**Вход:**

```
policy_intent.type = NO_ACTION
```

**Ожидание:**

* `Decision.status = REJECT`
* `Decision.reason = "INVALID_INTENT"`

---

### 🟦 RA-5 — REJECT zero volume

**Вход:**

```
policy_intent.type      = WANT_OPEN
policy_intent.direction = +1
policy_intent.volume    = 0
```

**Ожидание:**

* `Decision.status = REJECT`
* `Decision.reason = "INVALID_VOLUME"`

---

### 🟦 RA-6 — REJECT zero direction (OPEN only)

**Вход:**

```
policy_intent.type      = WANT_OPEN
policy_intent.direction = 0
policy_intent.volume    > 0
```

**Ожидание:**

* `Decision.status = REJECT`
* `Decision.reason = "INVALID_DIRECTION"`

---

### 🟦 RA-7 — Tag must NOT affect decision

**Цель:**
Подтвердить, что `policy_intent.tag` **не влияет** на решение.

**Сценарий:**

* два `PolicyAdjustedIntent`
* различие **ТОЛЬКО** в `tag`

**Ожидание:**

* `Decision` полностью идентичны

---

### 🟦 RA-8 — MODIFY is never used  🟡 (УТОЧНЕНО)

**Цель:**
Зафиксировать запрет `Decision.status = MODIFY`.

**Сценарий:**

* перебор входов **ТОЛЬКО** из:

  * RA-2 … RA-6

**Ожидание:**

* `Decision.status != MODIFY` **всегда**

---

## 4. Отчётность тестов

Тесты **ОБЯЗАНЫ**:

* логировать:

  * `[RA-TEST] START`
  * `[RA-TEST] PASSED`
* при ошибке:

  * `[RA-TEST][FAIL] <message>`

❌ Молчаливый PASS запрещён.

---

## 5. Критерий приёмки

Test Spec считается выполненным, если:

* выполнены RA-1 … RA-8
* отсутствуют `[RA-TEST][FAIL]`
* `RiskArbiter_Run`:

  * не использует `MODIFY`
  * не читает лишние поля
  * не модифицирует входные данные
  * полностью детерминирован

---

## 6. Архитектурный итог

> **Прохождение данного Test Spec
> означает, что `RiskArbiter v1.0`
> является архитектурно корректным baseline-gate
> и допускается к использованию в ReferenceTrendBreak.**

---

## 7. Статус документа

* **TEST SPEC — RiskArbiter v1.0 (REV A)**
* **AUDIT-APPROVED**
* изменения запрещены
* дальнейшее развитие — **ТОЛЬКО v1.1+**

---

