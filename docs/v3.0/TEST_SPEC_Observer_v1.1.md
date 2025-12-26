# 🟥 TEST SPEC — Observer **v1.1**

## Multi-Timeframe Snapshot Producer

**Status:** READY FOR IMPLEMENTATION
**Component:** Observer
**Version:** v1.1
**Language:** STRICT MQL5
**Authority:** SSP v3.0, CONTRACT_LEXICON v3.0
**Methodology:** Black-box, deterministic

---

## 0. Цель тестирования

Тесты **валидируют ТОЛЬКО**:

* корректность формирования `Snapshot`
* корректность парсинга multi-TF строки
* корректность заполнения `Snapshot.trends`
* соблюдение ownership / immutability правил
* сохранение поведения Observer v1.0 для market/position/time/constraints

Тесты **НЕ проверяют**:

* торговую логику
* стратегические свойства трендов
* производительность
* визуальные тестеры

---

## 1. Общие инварианты (ОБЯЗАТЕЛЬНЫ ДЛЯ ВСЕХ ТЕСТОВ)

Для любого вызова `Observer_Run(Snapshot&)`:

1. `Snapshot` полностью заполнен
2. `Snapshot` immutable после возврата
3. **НИКАКИХ** чтений:

   * `Intent`
   * `Feedback`
4. `Snapshot.trends.items.length == Snapshot.trends.count`
5. порядок `Snapshot.trends.items[]` = порядок input-строки
6. отсутствие hidden state между вызовами

---

## 2. Test Environment Assumptions

* MT5 API **разрешён** (инфраструктурная роль)
* Источники данных могут быть:

  * live market
  * mock MT5 layer (если есть)
* Тесты **НЕ зависят от реальных сделок**

---

## 3. Test Groups Overview

| Group | Назначение                |
| ----- | ------------------------- |
| OBS-1 | Парсинг TF строки         |
| OBS-2 | Snapshot.trends структура |
| OBS-3 | TrendInfo вычисление      |
| OBS-4 | Ошибки и edge cases       |
| OBS-5 | Determinism               |
| OBS-6 | Backward compatibility    |

---

# 🧪 OBS-1 — TF STRING PARSING

### OBS-1.1 Single TF

**Input:**
`OBS_TF_LIST = "M5"`

**Expected:**

* `trends.count == 1`
* `items[0].timeframe == PERIOD_M5`

---

### OBS-1.2 Multiple TF ordered

**Input:**
`"M5,M15,H1"`

**Expected:**

* `count == 3`
* order: `M5 → M15 → H1`

---

### OBS-1.3 Whitespace tolerance

**Input:**
`" M5 ,  H1 ,M15 "`

**Expected:**

* `count == 3`
* order preserved

---

### OBS-1.4 Invalid token → fail-fast

**Input:**
`"M5,XXX,H1"`

**Expected:**

* `trends.count == 0`
* `trends.items.length == 0`
* остальные секции Snapshot валидны

---

### OBS-1.5 Empty string

**Input:**
`""`

**Expected:**

* `trends.count == 0`
* Snapshot валиден

---

# 🧪 OBS-2 — Snapshot.trends STRUCTURE

### OBS-2.1 Mandatory fields present

**Expected for each TrendInfo:**

* `timeframe` is set
* `regime` ∈ {TREND, RANGE, UNKNOWN}
* `direction` ∈ {-1,0,+1}
* `confidence` ∈ [0.0,1.0]

---

### OBS-2.2 Items length matches count

**Invariant:**
`items.length == count`

---

# 🧪 OBS-3 — TrendInfo COMPUTATION (BASELINE)

### OBS-3.1 Strict upward trend

**Market condition:**
`close[2] > close[1] > close[0]`

**Expected:**

* `direction = +1`
* `regime = TREND`
* `confidence = 1.0`

---

### OBS-3.2 Strict downward trend

**Market condition:**
`close[2] < close[1] < close[0]`

**Expected:**

* `direction = -1`
* `regime = TREND`
* `confidence = 1.0`

---

### OBS-3.3 Non-monotonic closes

**Market condition:**
`close = {1.1000, 1.1010, 1.1005}`

**Expected:**

* `direction = 0`
* `regime = RANGE`
* `confidence = 0.0`

---

### OBS-3.4 Partial monotonicity

**Market condition:**
2 из 3 движутся в одном направлении

**Expected:**

* `direction ≠ 0`
* `confidence = 0.5`

---

# 🧪 OBS-4 — EDGE CASES

### OBS-4.1 Insufficient bars

**Condition:**
меньше 3 закрытых баров доступно

**Expected:**

* `regime = UNKNOWN`
* `direction = 0`
* `confidence = 0.0`

---

### OBS-4.2 Trading disabled

**Condition:**
`Snapshot.constraints.is_trading_allowed == false`

**Expected:**

* `Snapshot.trends` всё равно заполнен
* поведение не меняется

---

# 🧪 OBS-5 — DETERMINISM

### OBS-5.1 Same input → same output

**Condition:**
два вызова `Observer_Run` без изменения рынка

**Expected:**

* `Snapshot` идентичен (field-by-field)

---

### OBS-5.2 TF order stability

**Condition:**
`"M5,H1"` vs `"H1,M5"`

**Expected:**

* одинаковые значения TrendInfo
* **разный порядок элементов**

---

# 🧪 OBS-6 — BACKWARD COMPATIBILITY

### OBS-6.1 Single TF equivalence

**Input:**
`OBS_TF_LIST = "<market.tf>"`

**Expected:**

* `Snapshot.market` идентичен Observer v1.0
* `Snapshot.trends.count == 1`

---

### OBS-6.2 trends ignored by other roles

**Condition:**
PPM / RiskArbiter consuming Snapshot

**Expected:**

* отсутствие доступа к `Snapshot.trends`
* no compile-time / runtime dependency

---

## 4. Pass / Fail Criteria

Тест-сьют **ПРОЙДЕН**, если:

* все OBS-1 … OBS-6 выполняются
* ни один SSP-инвариант не нарушен

Любой провал = **REJECT Observer v1.1**.

---

## 5. Статус

* ✅ Test Spec зафиксирован
* ▶️ готов для **Test-Chat**
* ▶️ готов для **Coder-Chat implementation**

---

**END OF TEST SPEC — Observer v1.1**
