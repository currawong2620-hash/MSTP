# 🧪 TEST SPEC — DecisionMaker **TrendConsensusBreakout v0.1**

**Component:** DecisionMaker
**Strategy:** TrendConsensusBreakout
**Layer:** Strategy
**Stage:** Pre-Decision
**Language:** STRICT MQL5
**Status:** READY FOR IMPLEMENTATION
**Authority:** Audit-Chat / Master-Chat
**Based on:**

* TECH SPEC — DecisionMaker TrendConsensusBreakout v0.1
* SSP v3.0
* CONTRACT_LEXICON v3.0
* ROLE_CALL_CONTRACTS_MQL5 v0.1

---

## 0. Цели тестирования

Тесты должны **жёстко зафиксировать**, что DecisionMaker:

1. Формирует **ровно один Intent за цикл**
2. Работает **детерминированно**
3. Строго следует:

   * confidence-based consensus
   * breakout-триггеру
   * gate-правилам TF1 / TFn
4. **НЕ использует**:

   * состояние
   * историю
   * риск / объёмы / исполнение
5. Корректно обрабатывает **edge cases**

---

## 1. Область тестирования

### 1.1 Тестируем

* `DecisionMaker_Run(...)`
* логику формирования `Intent`

### 1.2 НЕ тестируем

* внутреннюю логику `TrendAnalyzer`
* корректность market data
* исполнение ордеров
* риск-менеджмент
* PositionPolicy

---

## 2. Тестовая инфраструктура

### 2.1 Моки

Обязательны следующие mock-компоненты:

#### 🔹 MockTrendAnalyzer

Позволяет задать для каждого TF:

```
regime
direction
confidence
```

#### 🔹 MockSnapshot

Используется ТОЛЬКО:

```
snapshot.market.last_closes[3]
```

#### 🔹 MockFeedback

Передаётся, но **не влияет** на результат (v0.1).

---

## 3. Общие инварианты (применяются ко ВСЕМ тестам)

Каждый тест обязан проверить:

* `Intent` **всегда инициализирован**
* `Intent.type` ∈ { `NO_ACTION`, `WANT_OPEN` }
* если `Intent.type == WANT_OPEN`:

  * `Intent.direction != 0`
  * `Intent.confidence ∈ [0.0, 1.0]`

---

## 4. Набор тестов

---

### 🧪 DM-01 — Нет тренда на TF0 → NO_INTENT

**Setup:**

```
TF0.regime = RANGE
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-02 — TF0.direction == 0 → NO_INTENT

**Setup:**

```
TF0.regime = TREND
TF0.direction = 0
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-03 — SCORE < 0 → NO_INTENT

**Setup:**

```
TF0: TREND, +1
TF1: TREND, -1, conf = 0.8
TF2: TREND, +1, conf = 0.3
SCORE = -0.5
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-04 — SCORE < confidence_threshold → NO_INTENT

**Setup:**

```
confidence_threshold = 1.0
SCORE = 0.6
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-05 — Breakout отсутствует → NO_INTENT

**Setup (BUY):**

```
c0 <= max(c1, c2)
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-06 — BUY breakout + consensus → WANT_OPEN(+1)

**Setup:**

```
TF0: TREND, +1
TF1: TREND, +1, conf = 0.6
TF2: TREND, +1, conf = 0.7
confidence_threshold = 1.0

c0 > max(c1, c2)
```

**Expectation:**

```
Intent.type = WANT_OPEN
Intent.direction = +1
Intent.confidence ∈ (0,1]
```

---

### 🧪 DM-07 — SELL breakout + consensus → WANT_OPEN(-1)

**Setup:**

```
TF0: TREND, -1
TF1: TREND, -1, conf = 0.5
TF2: TREND, -1, conf = 0.6
confidence_threshold = 0.8

c0 < min(c1, c2)
```

**Expectation:**

```
Intent.type = WANT_OPEN
Intent.direction = -1
```

---

### 🧪 DM-08 — require_next_tf = true, TF1 не совпал → NO_INTENT

**Setup:**

```
require_next_tf = true
TF1.direction != BASE_DIR
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-09 — require_highest_tf = true, TFn не совпал → NO_INTENT

**Setup:**

```
require_highest_tf = true
TFn.direction != BASE_DIR
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-10 — require_next_tf=false, TF1 против, но consensus прошёл → WANT_OPEN

**Setup:**

```
require_next_tf = false
TF1.direction != BASE_DIR
SCORE >= threshold
Breakout OK
```

**Expectation:**

```
Intent.type = WANT_OPEN
```

---

### 🧪 DM-11 — max_possible_score == 0 → NO_INTENT

**Setup:**

```
TF1..TFn: RANGE or UNKNOWN
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-12 — TF_LIST.length < 2 → NO_INTENT

**Setup:**

```
TF_LIST = [TF0]
```

**Expectation:**

```
Intent.type = NO_ACTION
```

---

### 🧪 DM-13 — Determinism test

**Setup:**

```
Same Snapshot
Same TrendAnalyzer outputs
Same parameters
```

**Action:**

```
Run DecisionMaker_Run twice
```

**Expectation:**

```
Intent_1 == Intent_2
```

---

## 5. Критерии приёмки

DecisionMaker **ПРИНИМАЕТСЯ**, если:

* ✔ все тесты DM-01 … DM-13 проходят
* ✔ ни один тест не требует состояния
* ✔ ни один тест не обращается к MT5 API
* ✔ все данные подаются через mock’и
* ✔ результат воспроизводим

---

## 6. Выходы тестирования

* Лог тестов
* PASS / FAIL по каждому DM-XX
* Подтверждение:

  ```
  DecisionMaker TrendConsensusBreakout v0.1
  is compliant with TECH SPEC
  ```

---

**END OF TEST SPEC — DecisionMaker TrendConsensusBreakout v0.1**
