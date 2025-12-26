# 🟥 TEST SPEC — PositionPolicyManager

## Virtual Exit Policy by Price Distance (Points)

**Проект:** Trading Platform (MQL5)
**Подсистема:** Strategy / Replaceable Roles
**Тестируемая роль:** `PositionPolicyManager`
**Версия роли:** v2.0
**Статус:** **REV A — AUDIT-READY**
**Тип тестов:** Acceptance / Contract Compliance
**Язык:** **STRICT MQL5**

**Файл тестов (ФИКСИРОВАН):**

```text
tests/Strategy/TC_PositionPolicyManagerTests.mqh
```

---

## 0. Назначение тестов (НОРМАТИВНО)

Данный Test Spec предназначен **ИСКЛЮЧИТЕЛЬНО** для проверки, что
`PositionPolicyManager v2.0`:

1. реализует **price-based virtual exit-policy** в **points**
2. использует **ТОЛЬКО Snapshot** как источник рыночных фактов
3. корректно применяет `Snapshot.market.point_size`
4. соблюдает все инварианты роли v1.1
5. детерминирован
6. не использует execution-environment API

❌ Test Spec **НЕ проверяет**:

* механизм конфигурации SL / TP
* стратегию
* RiskArbiter / Executor
* реальное исполнение
* деньги / проценты / PnL

---

## 1. Нормативные основания (ОБЯЗАТЕЛЬНО)

Тесты **ДОЛЖНЫ строго соответствовать**:

1. **SSP v1.x**
2. **CONTRACT_LEXICON v1.3**
3. **ARCHITECTURE_DATA_FLOW_MODEL v1.1**
4. **ROLE_CALL_CONTRACTS_MQL5 v0.1**
5. **NAMING_RULES v1.0**
6. **TECH SPEC — PositionPolicyManager v2.0**

---

## 2. Контракт под тестированием (ФИКСИРОВАН)

```mq5
int PositionPolicyManager_Run(
   const Intent &intent,
   const Snapshot &snapshot,
   const Feedback &feedback,
   PolicyAdjustedIntent &out_policy_intents[]
);
```

---

## 3. Разрешённые данные Snapshot (ЖЁСТКО)

В тестах **допускается зависимость ТОЛЬКО от**:

```mq5
snapshot.position.has_position
snapshot.position.direction
snapshot.position.volume
snapshot.position.entry_price
snapshot.market.bid
snapshot.market.ask
snapshot.market.point_size
```

Все остальные поля Snapshot:

* могут иметь произвольные значения
* **НЕ ДОЛЖНЫ влиять** на результат

---

## 4. Общие инварианты (ПРОВЕРЯЮТСЯ В КАЖДОМ ТЕСТЕ)

В каждом тесте **ОБЯЗАНО** выполняться:

1. `count ∈ {0,1}`
2. `ArraySize(out_policy_intents) == count`
3. при `count == 1`:

   * `out[0].type ∈ {WANT_OPEN, WANT_CLOSE}`
   * при `type == WANT_CLOSE` → `direction == 0`
4. `out_policy_intents` **полностью очищается** на каждом вызове
5. `feedback` **НЕ влияет** на результат
6. одинаковые входы → одинаковые выходы (детерминизм)

---

## 5. Базовые тестовые группы (НОРМАТИВНЫЕ)

---

### 🟦 PPM2-1 — Determinism

**Given:** идентичные `Intent`, `Snapshot`, `Feedback`
**When:** `PositionPolicyManager_Run` вызывается дважды
**Then:** выход идентичен (count + содержимое)

---

### 🟦 PPM2-2 — Output array is always cleared

**Given:**
`out_policy_intents` заранее заполнен мусором
и вход, который должен вернуть `count == 0`

**Then:**
`count == 0`, `ArraySize(out) == 0`

---

### 🟦 PPM2-3 — Feedback does not affect output

**Given:**
одинаковые `Intent` и `Snapshot`, но разные `Feedback`

**Then:**
выход идентичен

---

### 🟦 PPM2-4 — Snapshot extra fields do not affect output

**Given:**

* два `Snapshot`
* различие **ТОЛЬКО** в одном поле, не входящем в разрешённый список

**Then:**
выход идентичен

---

### 🟦 PPM2-5 — NO_ACTION produces no output

**Given:**

```text
intent.type = NO_ACTION
snapshot.position.has_position = false
```

**Then:**
`count == 0`

---

### 🟦 PPM2-6 — WANT_OPEN allowed only when no position

**Given:**

```text
intent.type = WANT_OPEN
snapshot.position.has_position = false
```

**Then:**
`count == 1`, `out[0].type == WANT_OPEN`

---

### 🟦 PPM2-7 — WANT_OPEN blocked when position exists

**Given:**

```text
intent.type = WANT_OPEN
snapshot.position.has_position = true
```

**Then:**
`count == 0`

---

### 🟦 PPM2-8 — Intent WANT_CLOSE ignored when no exit condition

**Given:**

* `intent.type == WANT_CLOSE`
* и:

  * `snapshot.position.has_position == false`
  * **ИЛИ**
  * `has_position == true`, но цена внутри exit-границ

**Then:**
`count == 0`

---

## 6. EXIT POLICY — LONG (BID, point_size)

Во всех EXIT-кейсах:

* `count == 1`
* `out[0].type == WANT_CLOSE`
* `out[0].direction == 0`
* `out[0].volume == snapshot.position.volume`
* `out[0].tag == "POLICY_EXIT"`

---

### 🟦 PPM2-9 — LONG Stop-Loss triggers exit

**Given:**

```text
has_position = true
direction = +1
entry_price = 100.0
point_size = 0.01
bid = 100.0 - N * 0.01
```

**Then:** exit output

---

### 🟦 PPM2-10 — LONG Take-Profit triggers exit

```text
bid = 100.0 + N * 0.01
```

**Then:** exit output

---

### 🟦 PPM2-11 — LONG no exit inside bounds

```text
bid = 100.0 ± (N-1) * 0.01
```

**Then:**
`count == 0`

---

## 7. EXIT POLICY — SHORT (ASK, point_size)

---

### 🟦 PPM2-12 — SHORT Stop-Loss triggers exit

```text
direction = -1
ask = entry_price + N * point_size
```

---

### 🟦 PPM2-13 — SHORT Take-Profit triggers exit

```text
ask = entry_price - N * point_size
```

---

### 🟦 PPM2-14 — SHORT no exit inside bounds

```text
ask = entry_price ± (N-1) * point_size
```

---

## 8. Инвариант количества выходов

### 🟦 PPM2-15 — Output count invariant

Для всех тестов выше:

```text
count == 0 || count == 1
ArraySize(out) == count
```

---

## 9. Запреты (ЖЁСТКО)

В тестах **ЗАПРЕЩЕНО**:

❌ MT5 trade API
❌ SymbolInfo* / MarketInfo*
❌ `_Point`
❌ любые helper’ы, использующие вышеперечисленное
❌ global / static mutable state
❌ side-effects

---

## 10. Критерий приёмки

Test Suite считается принятой, если:

* выполнены PPM2-1 … PPM2-15
* отсутствуют `[PPM-TEST][FAIL]`
* реализация:

  * использует `Snapshot.market.point_size`
  * не читает execution-environment
  * полностью детерминирована

---

## 🔒 Архитектурная фиксация

Прохождение данного Test Spec означает, что:

* `PositionPolicyManager v2.0`

  * SSP-compliant
  * Snapshot-driven
  * пригоден как baseline для **v2.1 (trailing stop)**

---

## 📌 Статус

🟢 **READY FOR AUDIT APPROVAL**
🟢 **READY FOR CODER-CHAT TASK**

