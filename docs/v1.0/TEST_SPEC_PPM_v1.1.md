# 🟥 TEST SPEC — PositionPolicyManager v1.1 (REV B)

## Virtual SL/TP by Price (Points) — Audit-Resolved

**Проект:** Trading Platform (MQL5)
**Подсистема:** Strategy / Replaceable Roles
**Роль:** `PositionPolicyManager`
**Версия роли:** **v1.1**
**Ревизия:** **REV B (AUDIT-RESOLVED)**
**Тип:** Acceptance Test Suite
**Язык:** строго MQL5

**Файл тестов:**

```
tests/Strategy/TC_PositionPolicyManager_v1_1_Tests.mqh
```

---

## 0. Важное уточнение (устранение блокера №1)

### Нормативная семантика `direction` для `WANT_CLOSE`

Для выходного `PolicyAdjustedIntent` при `type = WANT_CLOSE`:

* `direction` **ДОЛЖЕН БЫТЬ = 0**

Причина (фиксируется этим документом как baseline v1.1):

* семантика CLOSE не требует направления на уровне команды закрытия
* RiskArbiter v1.0 и его tests принимают CLOSE с `direction=0`
* это предотвращает расхождения между PPM → RiskArbiter → Decision

**Следствие для тестов:**
в любых exit-кейсах `out[0].type == WANT_CLOSE` ожидаем:

```
out[0].direction == 0
```

---

## 1. Цель тестирования

Тесты проверяют, что `PositionPolicyManager v1.1`:

1. реализует **виртуальные SL/TP по ЦЕНЕ** в **points**
2. использует:

   * **BID** для LONG
   * **ASK** для SHORT
3. при срабатывании exit:

   * формирует ровно **1** `PolicyAdjustedIntent`
   * с `type = WANT_CLOSE`
   * с `direction = 0`
   * и **игнорирует входной Intent**
4. соблюдает one-position rule для `WANT_OPEN`
5. детерминирован
6. очищает `out_policy_intents` на каждом вызове
7. `feedback` не влияет на результат

Тесты НЕ проверяют:

* стратегию
* RiskArbiter/Executor
* MT5 торговые вызовы
* деньги/проценты

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

## 3. Разрешённые данные Snapshot (Path 1 — v1.1)

Тесты **заполняют и используют только**:

```mq5
snapshot.position.has_position
snapshot.position.direction
snapshot.position.volume
snapshot.position.entry_price
snapshot.market.bid
snapshot.market.ask
```

Остальные поля:

* заполняются нулями
* не участвуют в логике

---

## 4. Константы и единицы

### 4.1 Points

`SL/TP` заданы в **points**.

Тесты используют `_Point` **только как размер пункта**.

Запрещено в тестах:

* `SymbolInfoDouble(...)`
* любые `SymbolInfo*`
* любые торговые/рыночные API

### 4.2 Константы v1.1

```
VIRTUAL_SL_POINTS = 100
VIRTUAL_TP_POINTS = 100
```

---

## 5. Общие инварианты (ДОЛЖНЫ проверяться)

В каждом тесте (явно или через общие проверки) должно выполняться:

1. `count ∈ {0,1}`
2. `ArraySize(out_policy_intents) == count`
3. при `count == 1`:

   * `out[0].type` соответствует ожидаемому
   * `out[0].direction` соответствует ожидаемому (для WANT_CLOSE — 0)
4. массив `out_policy_intents` очищается на каждом вызове
5. одинаковые входы → одинаковые выходы (детерминизм)
6. `feedback` не влияет

---

# 6. Тест-кейсы (нормативные)

## PPM-1 — Determinism

**Given:** одинаковые `Intent`, `Snapshot`, `Feedback`
**When:** Run вызывается дважды
**Then:** совпадают:

* `count`
* содержимое `out[0]` (если `count==1`): `type`, `direction`, `volume`, `tag`

---

## PPM-2 — Output array is always cleared

**Given:**

* `out_policy_intents` заранее заполнен мусором:

  * `ArrayResize(out, 1)`
  * `out[0].tag = "JUNK"`
* вход, который должен вернуть `count==0` (например `NO_ACTION` без позиции)

**Then:**

* `count == 0`
* `ArraySize(out) == 0`  (**массива мусора не осталось**)

---

## PPM-3 — Feedback does not affect output

**Given:**

* одинаковые `Intent` и `Snapshot`
* два разных `Feedback` (разные `event/pnl/message`)

**Then:**

* выход идентичен (count и out[0] если есть)

---

## PPM-4 — NO_ACTION → no outputs

**Given:**

* `intent.type = NO_ACTION`
* `snapshot.position.has_position = false`

**Then:** `count == 0`, `out empty`

---

## PPM-5 — WANT_OPEN with no position → 1 output

**Given:**

* `intent.type = WANT_OPEN`
* `intent.direction = +1`
* `snapshot.position.has_position = false`

**Then:**

* `count == 1`
* `out[0].type == WANT_OPEN`
* `out[0].direction == +1`
* `out[0].volume == 0.10`
* `out[0].tag == "POLICY_SINGLE"`

---

## PPM-6 — WANT_OPEN blocked when position exists

**Given:**

* `intent.type = WANT_OPEN`
* `snapshot.position.has_position = true`

**Then:** `count == 0`

---

## PPM-7 — WANT_CLOSE from Intent ignored when position exists

**Given:**

* `intent.type = WANT_CLOSE`
* `snapshot.position.has_position = true`

**Then:** `count == 0`

---

## PPM-8 — WANT_CLOSE from Intent ignored when NO position (added)

**Given:**

* `intent.type = WANT_CLOSE`
* `snapshot.position.has_position = false`

**Then:** `count == 0`

---

# 7. EXIT POLICY — LONG/BID

Во всех EXIT кейсах below: ожидаем **override** (игнор входного intent) и:

* `count == 1`
* `out[0].type == WANT_CLOSE`
* `out[0].direction == 0`
* `out[0].volume == snapshot.position.volume`
* `out[0].tag == "POLICY_EXIT"`

---

## PPM-9 — LONG StopLoss triggers exit (BID)

**Given:**

* `snapshot.position.has_position = true`
* `snapshot.position.direction = +1`
* `snapshot.position.volume = 0.10`
* `snapshot.position.entry_price = 100.0`
* `snapshot.market.bid = 100.0 - 100*_Point`
* `intent.type = NO_ACTION`

**Then:** exit output as above.

---

## PPM-10 — LONG TakeProfit triggers exit (BID)

**Given:**

* то же, но:
* `snapshot.market.bid = 100.0 + 100*_Point`

**Then:** exit output as above.

---

## PPM-11 — LONG No exit inside bounds (BID)

**Given:**

* `snapshot.market.bid = 100.0 + 50*_Point` (меньше порога)

**Then:** `count == 0`

---

## PPM-12 — Exit overrides incoming WANT_OPEN (LONG SL hit)

**Given:**

* `intent.type = WANT_OPEN`
* `snapshot.position.has_position = true`
* условия PPM-9 (SL hit)

**Then:** exit output (WANT_CLOSE), **не WANT_OPEN**.

---

# 8. EXIT POLICY — SHORT/ASK (устранение блокера №2)

## PPM-13S — SHORT StopLoss triggers exit (ASK)

**Given:**

* `snapshot.position.has_position = true`
* `snapshot.position.direction = -1`
* `snapshot.position.volume = 0.10`
* `snapshot.position.entry_price = 100.0`
* Для SHORT StopLoss цена идёт ПРОТИВ позиции вверх:

  * `snapshot.market.ask = 100.0 + 100*_Point`
* `intent.type = NO_ACTION`

**Then:** exit output (WANT_CLOSE, direction=0, volume=0.10, tag=POLICY_EXIT)

---

## PPM-14S — SHORT TakeProfit triggers exit (ASK)

**Given:**

* то же, но прибыль для SHORT — когда цена ниже entry:

  * `snapshot.market.ask = 100.0 - 100*_Point`

**Then:** exit output (как выше)

---

## PPM-15S — SHORT No exit inside bounds (ASK)

**Given:**

* `snapshot.market.ask = 100.0 - 50*_Point`

**Then:** `count == 0`

---

# 9. Инвариант количества выходов (явная фиксация)

## PPM-16 — Output count invariant

**Given:** входы из PPM-4…PPM-15S
**Then:**

* `count == 0 || count == 1`
* `ArraySize(out) == count`

---

## 10. Запреты (жёстко)

Запрещено в тестах:

* MT5 торговый API
* SymbolInfo* / MarketInfo
* любые деньги/проценты
* проверка логики RiskArbiter/Executor
* использование global/static mutable state
* использование `ZeroMemory()` на структурах со `string` (если такие попадутся)

---

## 11. Критерий приёмки

Suite считается принятой, если:

* все тесты проходят
* отсутствуют `[PPM-TEST][FAIL]`
* выполнены инварианты §5

---

## 12. Статус

**TEST SPEC — PositionPolicyManager v1.1 (REV B): READY (AUDIT-RESOLVED)**

---
