# 🟥 TECH SPEC — DecisionMaker **TrendConsensusBreakout v0.1**

**Component:** DecisionMaker
**Strategy:** TrendConsensusBreakout
**Layer:** Strategy
**Stage:** Pre-Decision
**Language:** STRICT MQL5
**Status:** **READY FOR FULL ACCEPT**
**Authority:** Master-Chat
**Architectural basis:** SSP v3.0, CONTRACT_LEXICON v3.0, ROLE_CALL_CONTRACTS_MQL5 v0.1
**Change policy:** versioned only

---

## 0. Назначение

`DecisionMaker TrendConsensusBreakout v0.1` — стратегия принятия решения,
которая формирует `Intent` на вход **по пробою** в направлении тренда,
подтверждённого **multi-timeframe consensus** на основе `TrendAnalyzer`.

Стратегия отвечает **только** на вопрос:

> **«Есть ли сейчас достаточные основания ХОТЕТЬ открыть позицию
> в направлении тренда?»**

---

## 1. Контракт роли DecisionMaker (FIXED)

### 1.1 Сигнатура вызова

```text
DecisionMaker_Run(
    const Snapshot &snapshot,
    const Feedback &feedback,
    Intent &out_intent
)
```

---

### 1.2 Нормативные правила контракта

* DecisionMaker:

  * вызывается **ровно один раз за orchestration cycle**
  * **ОБЯЗАН** сформировать **ровно один `Intent`**
* `out_intent`:

  * всегда инициализируется
  * при отсутствии условий входа:

    ```
    out_intent.type = NO_ACTION
    ```
* DecisionMaker:

  * МОЖЕТ вызывать `TrendAnalyzer_Run(...)`
  * НЕ возвращает массивы или коллекции
  * НЕ хранит состояние между вызовами

---

### 1.3 Источники данных

* `Snapshot` — используется **ТОЛЬКО**:

  ```
  snapshot.market.last_closes[3]
  ```
* `Feedback` — **читается**, но **v0.1 не влияет на логику**
  (зарезервировано для будущих версий)

---

## 2. Temporal Consistency Rule (CRITICAL)

DecisionMaker v0.1 **ОБЯЗАН** соблюдать следующее правило:

```
TrendAnalyzer_Run(...) and Snapshot.market.last_closes
MUST be evaluated within the same closed-bar context.
```

### Нормативная интерпретация

* `Snapshot.market.last_closes[0]`
* и данные, используемые `TrendAnalyzer`

относятся к **одному и тому же закрытому бару**.

### Архитектурное допущение v0.1

```
TrendAnalyzer and Snapshot are assumed
to be synchronized on closed bars.
```

Нарушение этого правила считается источником недетерминизма
и архитектурным дефектом интеграции.

---

## 3. Входные данные

### 3.1 Аналитические данные

Для каждого таймфрейма `tf` из конфигурационного списка:

```
TrendAnalyzer_Run(symbol, tf) → TrendAnalysisResult
```

Используются поля:

```
timeframe
regime
direction   // ∈ {-1, 0, +1}
confidence  // ∈ [0.0 … 1.0]
```

`direction` семантически совместим с enum `direction`
из CONTRACT_LEXICON v3.0.

---

### 3.2 Рыночные данные (Snapshot)

Используются **ТОЛЬКО**:

```
Snapshot.market.last_closes[3]
```

Обозначения:

```
c0 = last_closes[0]   // последний закрытый бар
c1 = last_closes[1]
c2 = last_closes[2]
```

---

## 4. Конфигурация стратегии

### 4.1 Список таймфреймов

```
TF_LIST = [TF0, TF1, TF2, ..., TFn]
```

Где:

* `TF0` — рабочий таймфрейм
* `TF1` — следующий после рабочего
* `TFn` — старший таймфрейм
* порядок **фиксирован и значим**

Если `TF_LIST.length < 2` → стратегия считается некорректной → `NO_INTENT`.

---

### 4.2 Параметры

```
confidence_threshold : double
require_next_tf     : bool   // default = true
require_highest_tf  : bool   // default = false
```

---

## 5. Базовые условия (якорь)

Для рабочего таймфрейма `TF0`:

```
TA(TF0).regime == TREND
TA(TF0).direction != 0
```

Если условие не выполнено → **NO_INTENT**.

Обозначим:

```
BASE_DIR = TA(TF0).direction
```

---

## 6. Confidence-based consensus

### 6.1 Contribution-функция

Для каждого `tf ∈ {TF1 .. TFn}`:

```
if TA(tf).regime != TREND:
    contribution = 0

else if TA(tf).direction == BASE_DIR:
    contribution = +TA(tf).confidence

else if TA(tf).direction == -BASE_DIR:
    contribution = -TA(tf).confidence
```

---

### 6.2 Итоговый score

```
SCORE = Σ contribution(tf)
```

### 6.3 Нормативные правила

```
If SCORE < 0 → NO_INTENT
If SCORE < confidence_threshold → NO_INTENT
```

---

## 7. Breakout-триггер (TF0 ONLY)

> *Breakout trigger is evaluated exclusively on the working timeframe (TF0).*

Используется **3-bar close breakout**.

### BUY (BASE_DIR = +1)

```
c0 > max(c1, c2)
```

### SELL (BASE_DIR = -1)

```
c0 < min(c1, c2)
```

Если условие не выполнено → **NO_INTENT**.

---

## 8. Gate-подтверждения

### 8.1 Следующий таймфрейм (TF1)

Если:

```
require_next_tf == true
```

то обязательно:

```
TA(TF1).regime == TREND
TA(TF1).direction == BASE_DIR
```

Иначе → **NO_INTENT**.

---

### 8.2 Старший таймфрейм (TFn)

Если:

```
require_highest_tf == true
```

то обязательно:

```
TA(TFn).regime == TREND
TA(TFn).direction == BASE_DIR
```

Иначе → **NO_INTENT**.

---

## 9. Формирование Intent

Если **все условия выполнены**:

```
Intent.type       = WANT_OPEN
Intent.direction  = BASE_DIR
Intent.confidence = normalized_score
```

---

### 9.1 Нормализация confidence

```
max_possible_score =
    Σ TA(tf).confidence
    for all tf ∈ {TF1..TFn}
    where TA(tf).regime == TREND
```

```
If max_possible_score == 0 → NO_INTENT
```

```
normalized_score =
    clamp(
        SCORE / max_possible_score,
        0.0, 1.0
    )
```

---

## 10. Edge cases (нормативно)

* `TrendAnalyzer` вернул `UNKNOWN` → TF не участвует в score
* `TF_LIST.length < 2` → `NO_INTENT`
* `confidence_threshold <= 0` → трактуется как 0
* `confidence_threshold > max_possible_score` → вход невозможен

---

## 11. Инварианты DecisionMaker

* ❌ нет состояния
* ❌ нет памяти прошлых баров
* ❌ нет объёма
* ❌ нет SL / TP
* ❌ нет риска
* ❌ нет исполнения
* ✔ чистая детерминированная функция от текущих данных

---

## 12. Визуальная наблюдаемость (REQUIRED)

DecisionMaker v0.1 **ОБЯЗАН** иметь Visual Tester.

Минимальный набор отображаемых данных:

```
TF | Dir | Conf
Score
Breakout: YES / NO
Gate TF1: PASS / FAIL
Gate TFn: PASS / FAIL
Intent: OPEN / NONE
```

Без интерпретации, цветов и логики.

---

## 13. Статус версии

* v0.1 — минимально достаточная
* только breakout-логика
* без pullback
* без анти-мартингейла
* расширения — **v0.2+**

---

**END OF TECH SPEC — DecisionMaker TrendConsensusBreakout v0.1**
