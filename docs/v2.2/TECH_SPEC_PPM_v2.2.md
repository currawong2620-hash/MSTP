# 🟥 TECH SPEC — PositionPolicyManager v2.2

## Trailing Stop (Snapshot-based, Step-driven)

---

## 0. Статус документа

**Component:** PositionPolicyManager
**Version:** **v2.2**
**Stage:** Stage 2 — Trailing Stop
**Status:** PROPOSED (for Audit)
**Language:** STRICT MQL5

---

## 1. Назначение

**PositionPolicyManager v2.2** расширяет v2.1, добавляя
**policy-level trailing stop**, управляемый параметрами и основанный **исключительно на Snapshot**, без состояния и без MT5 API.

Trailing Stop:

* является **дополнительным exit-триггером**
* не заменяет SL / TP
* не хранит состояние внутри PPM
* детерминирован для одинаковых входов

---

## 2. Нормативные основания

PPM v2.2 соответствует:

1. SSP v1.x
2. CONTRACT_LEXICON v1.3 (расширенный)
3. ROLE_CALL_CONTRACTS_MQL5 v0.1
4. ARCHITECTURE_DATA_FLOW_MODEL v1.1
5. NAMING_RULES v1.0
6. IMPLEMENTATION_REGISTRY (PPM v2.1 frozen)

---

## 3. Область изменений относительно v2.1

### ❌ Не изменяется

* сигнатура `PositionPolicyManager_Run`
* логика SL / TP
* `PPM_BASE_OPEN_VOLUME`
* intent filtering
* snapshot-only модель
* отсутствие состояния
* отсутствие MT5 API

### ✅ Добавляется

* Trailing Stop как policy-level exit
* три параметра trailing
* чтение trailing-факта из Snapshot

---

## 4. Конфигурационные параметры Trailing Stop

PPM v2.2 объявляет следующие **startup input parameters**:

```mq5
input int PPM_TS_START_POINTS    = 0;
input int PPM_TS_DISTANCE_POINTS = 0;
input int PPM_TS_STEP_POINTS     = 0;
```

### Семантика параметров

| Параметр                 | Назначение                                                          |
| ------------------------ | ------------------------------------------------------------------- |
| `PPM_TS_START_POINTS`    | минимальная прибыль (в points), после которой trailing активируется |
| `PPM_TS_DISTANCE_POINTS` | расстояние trailing stop от текущей цены                            |
| `PPM_TS_STEP_POINTS`     | минимальное смещение цены для обновления trailing                   |

### Правило включения

Trailing Stop **активен только если**:

```text
PPM_TS_START_POINTS > 0
AND PPM_TS_DISTANCE_POINTS > 0
AND PPM_TS_STEP_POINTS > 0
```

В противном случае trailing полностью отключён.

---

## 5. Snapshot dependency (НОРМАТИВНО)

Snapshot **СОДЕРЖИТ** следующий факт позиции:

```text
snapshot.position.trailing_stop_price : double
```

### Семантика

* `0.0` → trailing не активирован
* `> 0.0` → последний подтверждённый trailing stop
* значение:

  * обновляется внешним наблюдателем (Observer)
  * **НЕ** модифицируется PositionPolicyManager

PPM v2.2 **ТОЛЬКО ЧИТАЕТ** это поле.

---

## 6. Источник цены и шкалы

Как и в v2.1:

* `point_size = snapshot.market.point_size`
* LONG → `price = snapshot.market.bid`
* SHORT → `price = snapshot.market.ask`

❌ `_Point`, `SymbolInfo*`, MT5 API — запрещены.

---

## 7. Trailing Stop — LONG (`direction == +1`)

### Обозначения

```text
entry   = snapshot.position.entry_price
price   = snapshot.market.bid
ps      = snapshot.market.point_size

start   = PPM_TS_START_POINTS    * ps
dist    = PPM_TS_DISTANCE_POINTS * ps
step    = PPM_TS_STEP_POINTS     * ps

ts_prev = snapshot.position.trailing_stop_price
```

---

### 7.1 Условие активации

Trailing **считается активным**, если:

```text
price >= entry + start
```

Если условие не выполнено → trailing не влияет.

---

### 7.2 Целевой trailing stop

```text
ts_target = price - dist
```

---

### 7.3 Правило обновления (STEP)

Trailing stop **обновляется**, если выполнено:

```text
ts_prev == 0
OR ts_target >= ts_prev + step
```

В противном случае считается, что trailing уровень остаётся прежним.

---

### 7.4 Exit-condition (Trailing hit)

Если trailing активен (`ts_prev > 0` после применения правила обновления) и:

```text
price <= ts_prev
```

→ trailing считается сработавшим exit-триггером.

---

## 8. Trailing Stop — SHORT (`direction == -1`)

Зеркально LONG.

### Обозначения

```text
price = snapshot.market.ask
```

### Активация

```text
price <= entry - start
```

### Target

```text
ts_target = price + dist
```

### Update rule

```text
ts_prev == 0
OR ts_target <= ts_prev - step
```

### Exit

```text
price >= ts_prev
```

---

## 9. Приоритет exit-триггеров

Если `snapshot.position.has_position == true`, PPM проверяет exit-триггеры **в следующем порядке**:

1. Stop-Loss (если включён)
2. Take-Profit (если включён)
3. Trailing Stop (если включён и активен)

⚠️ Порядок **не влияет на результат**, так как любой exit ведёт к одинаковому выходу.

---

## 10. Exit Output (НЕИЗМЕННО)

При любом exit-триггере:

```text
type       = WANT_CLOSE
direction  = 0
volume     = snapshot.position.volume
tag        = "POLICY_EXIT"
count      = 1
```

Intent полностью игнорируется.

---

## 11. Intent Filtering (если exit не сработал)

**Без изменений относительно v2.1**.

---

## 12. Инварианты

PPM v2.2 гарантирует:

* stateless
* deterministic
* snapshot-only
* output cardinality ∈ {0,1}
* feedback inert
* отсутствие MT5 environment

---

## 13. Явные запреты

PPM v2.2 **НЕ ИМЕЕТ ПРАВА**:

❌ хранить trailing состояние
❌ обновлять trailing stop
❌ мутировать Snapshot
❌ использовать `(void)`
❌ использовать `#pragma once`
❌ использовать MT5 API

---

## 14. Совместимость

* v2.1 поведение **сохраняется**, если trailing отключён
* v2.2 backward-compatible по контракту

---

## 15. Forward notes (не нормативные)

* Trailing реализован **строго policy-level**
* Хранение trailing-факта вынесено за пределы PPM
* Возможное расширение v2.3:

  * ATR-based trailing
  * time-based trailing

---

**END OF TECH SPEC — PositionPolicyManager v2.2**
