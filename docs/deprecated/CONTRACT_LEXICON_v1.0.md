# CONTRACT LEXICON
## Architecture Data Dictionary v1.0

**Status:** NORMATIVE  
**Scope:** All system contracts and modules  
**Change policy:** versioned only  
**Authority:** SSP-referenced document

---

## -1. ARCHITECTURE TYPE GOVERNANCE

**Status:** NORMATIVE  
**Scope:** All architecture data contracts  
**Change policy:** versioned only  
**Authority:** SSP-referenced document

---

### -1.1. Single Source of Truth

Настоящий документ является **ЕДИНСТВЕННЫМ источником истины**
о допустимых архитектурных типах данных и их полях.

Любой тип, поле или enum-значение,
отсутствующие в данном документе,
считаются **ЗАПРЕЩЁННЫМИ**.

---

### -1.2. Ownership of Types

Архитектурные типы данных:

- **НЕ определяются** в исполняемом коде
- **НЕ определяются** в технических заданиях
- **НЕ принадлежат** отдельным модулям или ролям

Архитектурные типы принадлежат
**архитектуре системы в целом**, а не реализации.

---

### -1.3. Rule for Master-Chat

Ни один Master-Chat **НЕ ИМЕЕТ ПРАВА**:

- вводить новый архитектурный тип,
- вводить новое поле существующего типа,
- вводить новый enum или enum-значение,
- переименовывать существующие элементы,

если соответствующее изменение
**НЕ зафиксировано в новой версии данного документа**.

При отсутствии подходящего типа
**работа должна быть остановлена**.

---

### -1.4. Separation from Implementation

Код **МОЖЕТ ТОЛЬКО ИСПОЛЬЗОВАТЬ**
архитектурные типы, определённые в данном документе.

Код **НЕ ИМЕЕТ ПРАВА**:

- определять структуру типов,
- расширять поля,
- интерпретировать типы «по смыслу».

---

### -1.5. Audit Enforcement

Любой Audit-Chat обязан:

- отклонить код,
- отклонить техническое задание,
- отклонить обсуждение,

если используется тип, поле или enum,
отсутствующие в настоящем документе.

---

### -1.6. Interpretative Prohibition

Если возникает сомнение,
соответствует ли существующий тип
требуемой сущности,

интерпретация считается **НЕДОПУСТИМОЙ**.

В этом случае:
1. код не пишется,
2. ТЗ не формируется,
3. сначала обновляется Lexicon.

---

**End of Architecture Type Governance**

---

## 0. Назначение

Этот документ фиксирует **ЕДИНСТВЕННЫЕ допустимые имена**
архитектурных типов и их полей.

Любое имя, отсутствующее здесь, считается **запрещённым**.

---

## 1. Общие правила

- Имена типов и полей **буквально обязательны**
- Регистр обязателен
- Синонимы запрещены
- Контекст задаётся структурой, а не именем поля

---

## 2. Архитектурные типы (root)

В системе существуют **ТОЛЬКО** следующие архитектурные типы:

- `Snapshot`
- `Intent`
- `PolicyAdjustedIntent`
- `Decision`
- `ExecutionResult`
- `Feedback`

---

## 3. Snapshot

### 3.1. Назначение
Снимок наблюдаемого состояния мира в один момент времени.

### 3.2. Структура

```

Snapshot
├── market
├── position
├── time
└── constraints

```

---

### 3.3. Snapshot.market

**Тип:** MarketSnapshot

| Поле | Семантический тип | Примечание |
|----|----|----|
| symbol | symbol | торговый инструмент |
| tf | timeframe | таймфрейм |
| open | price | цена открытия бара |
| high | price | максимум бара |
| low | price | минимум бара |
| close | price | цена закрытия бара |
| volume | volume | объём бара |
| bid | price | текущий bid |
| ask | price | текущий ask |
| spread | price | ask - bid |

---

### 3.4. Snapshot.position

**Тип:** PositionSnapshot

| Поле | Семантический тип | Примечание |
|----|----|----|
| has_position | bool | факт наличия позиции |
| direction | direction | +1 / -1 |
| volume | volume | текущий объём |
| entry_price | price | цена входа |
| floating_pnl | money | плавающий результат |

---

### 3.5. Snapshot.time

**Тип:** TimeContext

| Поле | Семантический тип | Примечание |
|----|----|----|
| timestamp | timestamp | текущее время |
| is_new_bar | bool | флаг нового бара |
| bars_since_entry | count | баров с момента входа |
| bars_since_last_action | count | баров с последнего действия |

---

### 3.6. Snapshot.constraints

**Тип:** MarketConstraints

| Поле | Семантический тип | Примечание |
|----|----|----|
| min_lot | volume | минимальный лот |
| lot_step | volume | шаг лота |
| min_stop | price | минимальный стоп |
| is_trading_allowed | bool | торговля разрешена |

---

## 4. Intent

### 4.1. Назначение
Выражение желания действия без гарантии исполнения.

### 4.2. Структура

```

Intent
├── type
├── direction
└── confidence

```

### 4.3. Поля

| Поле | Тип | Примечание |
|----|----|----|
| type | intent_type | категория намерения |
| direction | direction | +1 / -1 / 0 |
| confidence | ratio | 0.0 .. 1.0 |

### 4.4. intent_type (enum)

- `NO_ACTION`
- `WANT_OPEN`
- `WANT_CLOSE`
- `WANT_HOLD`

---

## 5. PolicyAdjustedIntent

### 5.1. Назначение
Намерение после применения политики владения позицией.

### 5.2. Структура

```

PolicyAdjustedIntent
├── type
├── direction
├── volume
└── tag

```

### 5.3. Поля

| Поле | Тип | Примечание |
|----|----|----|
| type | intent_type | категория |
| direction | direction | направление |
| volume | volume | допустимый объём |
| tag | string | идентификатор политики |

---

## 6. Decision

### 6.1. Назначение
Результат арбитража допустимости действия.

### 6.2. Структура

```

Decision
├── status
├── volume
└── reason

```

### 6.3. Поля

| Поле | Тип | Примечание |
|----|----|----|
| status | decision_status | итог |
| volume | volume | разрешённый объём |
| reason | string | код причины |

### 6.4. decision_status (enum)

- `ACCEPT`
- `REJECT`
- `MODIFY`

---

## 7. ExecutionResult

### 7.1. Назначение
Факт результата попытки исполнения.

### 7.2. Структура

```

ExecutionResult
├── status
├── filled_volume
└── price

```

### 7.3. Поля

| Поле | Тип | Примечание |
|----|----|----|
| status | execution_status | итог |
| filled_volume | volume | исполненный объём |
| price | price | фактическая цена |

### 7.4. execution_status (enum)

- `EXECUTED`
- `REJECTED`
- `PARTIAL`
- `FAILED`

---

## 8. Feedback

### 8.1. Назначение
Агрегированная обратная связь для адаптации поведения.

### 8.2. Структура

```

Feedback
├── event
├── pnl
└── message

```

### 8.3. Поля

| Поле | Тип | Примечание |
|----|----|----|
| event | feedback_event | тип события |
| pnl | money | результат |
| message | string | описание |

### 8.4. feedback_event (enum)

- `POSITION_OPENED`
- `POSITION_CLOSED`
- `STOP_HIT`
- `TARGET_HIT`
- `ACTION_REJECTED`

---

## 9. Семантические типы (reference)

| Тип | Описание |
|----|----|
| price | ценовое значение |
| volume | объём |
| money | денежное значение |
| ratio | 0.0 .. 1.0 |
| count | целочисленный счётчик |
| timestamp | время |
| direction | -1 / 0 / +1 |
| timeframe | таймфрейм |
| symbol | торговый инструмент |

---

## 10. Запреты

- ❌ добавление полей без обновления Lexicon
- ❌ переименование полей в коде
- ❌ использование синонимов
- ❌ добавление версий в имена типов

---

**END OF CONTRACT LEXICON v1.0**
```
