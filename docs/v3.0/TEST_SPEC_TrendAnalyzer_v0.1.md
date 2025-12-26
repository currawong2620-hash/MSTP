# 🟥 TEST SPEC

## TrendAnalyzer v0.1 — Deterministic Black-Box Tests

**Component:** TrendAnalyzer
**Layer:** Strategy / Analytical
**Stage:** Pre-Decision
**Language:** STRICT MQL5
**Test type:** Deterministic, Black-Box
**Status:** READY
**Authority:** Master-Chat

---

## 0. Цель тестирования

Цель данного тест-сьюта — **жёстко зафиксировать контрактное поведение TrendAnalyzer v0.1**, а именно:

1. корректность **вход/выход контракта**
2. соблюдение **семантических инвариантов**
3. детерминизм
4. корректную обработку:

   * недостатка данных
   * отсутствия тренда
   * наличия тренда
5. независимость:

   * от Observer
   * от Snapshot
   * от порядка вызовов

---

## 1. Область тестирования

### Тестируется

✅ один таймфрейм за вызов
✅ выход `TrendAnalysisResult`
✅ поля: `timeframe`, `regime`, `direction`, `confidence`
✅ правила MIN_BARS
✅ правила индексации баров

### НЕ тестируется

❌ качество тренда
❌ торговые решения
❌ агрегация TF
❌ визуализация
❌ производительность

---

## 2. Допустимые зависимости тестов

Тесты МОГУТ включать:

```
TrendAnalyzer.mqh
ArchitectureTypes.mqh
TC_TestHelpers.mqh
```

Тесты НЕ МОГУТ:

❌ читать Observer
❌ читать Snapshot
❌ использовать Trade API
❌ использовать нестабильные источники данных

---

## 3. Тестируемый контракт (фиксировано)

### Вход

```text
(symbol: string, timeframe: ENUM_TIMEFRAMES)
```

### Выход

```text
TrendAnalysisResult
```

---

## 4. Общие инварианты (проверяются В КАЖДОМ тесте)

Для любого результата `res`:

```
res.timeframe == input.timeframe
0.0 ≤ res.confidence ≤ 1.0
```

### Семантические инварианты

```
if res.regime != TREND → res.direction == 0
if res.regime == RANGE → res.confidence == 0.0
if res.regime == UNKNOWN → res.direction == 0 AND res.confidence == 0.0
```

Нарушение любого пункта → **FAIL**.

---

## 5. Нормативные параметры (из TECH SPEC)

Тесты обязаны использовать **ЭТИ значения**:

```
EMA_PERIOD        = 50
ADX_PERIOD        = 14
ATR_PERIOD        = 14
ADX_MIN           = 20
ATR_MULT          = 0.5
SLOPE_LOOKBACK    = 5

MIN_BARS = max(50,14,14) + 5 = 55
```

---

## 6. Группы тестов

---

# 🟦 GROUP TA-1 — Contract & Structure

### TA-1.1 Output structure validity

**Given:** корректный symbol и timeframe
**When:** TrendAnalyzer invoked
**Then:**

* `timeframe` заполнен
* `regime ∈ {TREND, RANGE, UNKNOWN}`
* `direction ∈ {-1,0,+1}`
* `confidence ∈ [0.0 … 1.0]`

---

### TA-1.2 Direction semantic compatibility

**Then:**

```
direction MUST be semantically compatible
with CONTRACT_LEXICON.direction
```

(проверка значений, не enum-типа)

---

# 🟦 GROUP TA-2 — Insufficient Data Handling

### TA-2.1 Less than MIN_BARS → UNKNOWN

**Given:** `available_bars < MIN_BARS`
**When:** TrendAnalyzer invoked
**Then:**

```
regime == UNKNOWN
direction == 0
confidence == 0.0
```

---

### TA-2.2 Exactly MIN_BARS → computable

**Given:** `available_bars == MIN_BARS`
**When:** TrendAnalyzer invoked
**Then:**

* результат **НЕ ОБЯЗАН** быть TREND
* но `regime != UNKNOWN`

---

# 🟦 GROUP TA-3 — RANGE behavior

### TA-3.1 Flat EMA → RANGE

**Condition (observable):**

```
abs(EMA[0] − EMA[N]) < ATR[0] * ATR_MULT
```

**Then:**

```
regime == RANGE
direction == 0
confidence == 0.0
```

---

### TA-3.2 ADX below threshold → RANGE

**Condition:**

```
direction != 0
AND ADX[0] < ADX_MIN
```

**Then:**

```
regime == RANGE
direction == 0
confidence == 0.0
```

---

# 🟦 GROUP TA-4 — TREND behavior

### TA-4.1 Valid uptrend

**Condition:**

```
EMA slope > 0
AND abs(delta) ≥ ATR * ATR_MULT
AND ADX ≥ ADX_MIN
```

**Then:**

```
regime == TREND
direction == +1
confidence > 0.0
```

---

### TA-4.2 Valid downtrend

**Condition:** аналогично, но slope < 0

**Then:**

```
regime == TREND
direction == -1
confidence > 0.0
```

---

# 🟦 GROUP TA-5 — Confidence semantics

### TA-5.1 RANGE confidence is zero

**Given:** `regime == RANGE`
**Then:** `confidence == 0.0`

---

### TA-5.2 TREND confidence strictly positive

**Given:** `regime == TREND`
**Then:** `confidence > 0.0`

---

### TA-5.3 Confidence upper bound

**Then:** `confidence ≤ 1.0`

---

# 🟦 GROUP TA-6 — Determinism

### TA-6.1 Same input → same output

**Given:** same symbol, timeframe, unchanged market
**When:** TrendAnalyzer invoked twice
**Then:** results are **field-by-field equal**

---

### TA-6.2 No hidden state

**Given:** result copied
**When:** no further calls
**Then:** copy unchanged

---

# 🟦 GROUP TA-7 — Independence

### TA-7.1 No dependency on Observer

**Rule:** tests MUST NOT include Observer headers.

Compilation dependency → **FAIL**.

---

### TA-7.2 Call order independence

**Given:** TF A then TF B
**When:** order swapped
**Then:** individual results unchanged

---

## 7. Допустимые тестовые стратегии

Тесты МОГУТ:

* использовать реальный рынок
* быть **conditional** (assert only if condition observed)
* пропускать assertion, если условие не возникло

Тесты НЕ МОГУТ:

❌ форсировать рынок
❌ писать свои индикаторы
❌ вводить новые структуры

---

## 8. Stop-rule (жёстко)

Test-Chat ОБЯЗАН остановиться и вернуть spec с пометкой **BLOCKER**, если:

* отсутствует MIN_BARS
* нарушена индексация баров
* нет deterministic guarantee
* контракт вход/выход нарушен

---

## 9. Критерий приёмки тест-сьюта

Тест-сьют считается валидным, если:

* покрыты все группы TA-1 … TA-7
* нет обращения к Observer / Snapshot
* нет недетерминированных assert’ов
* тесты компилируются в STRICT MQL5

---

**END OF TEST SPEC — TrendAnalyzer v0.1**

