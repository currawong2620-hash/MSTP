Принял. Исправляю и **начинаю заново**, корректно.

Ниже — **TEST SPEC без номеров версий в имени файла**, полностью согласованный с NAMING_RULES и CONTRACT_LEXICON.

---

# 🟥 TEST SPEC — DecisionMaker

## ReferenceTrendBreak (Directional Intent)

**Проект:** Trading Platform (MQL5)
**Подсистема:** Strategy / Replaceable Roles
**Тестируемая роль:** `DecisionMaker`
**Реализация:** `DecisionMaker_ReferenceTrendBreak`
**Статус:** Acceptance / Contract Test Suite
**Язык:** **строго MQL5**

**Файл тестов:**

```
tests/Strategy/TC_DecisionMaker_Tests.mqh
```

---

## 0. Назначение тестов (НОРМАТИВНО)

Данный Test Spec предназначен **ИСКЛЮЧИТЕЛЬНО** для проверки:

* корректности реализации `DecisionMaker_Run`
* строгого соответствия **TECH SPEC — DecisionMaker (ReferenceTrendBreak)**
* соответствия **CONTRACT_LEXICON v1.2**
* отсутствия запрещённой логики
* детерминизма формирования `Intent`
* корректной генерации направленного `WANT_OPEN`

❌ Test Spec **НЕ проверяет**:

* торговый смысл
* прибыльность
* работу PositionPolicyManager
* работу RiskArbiter / Executor
* корректность Observer
* интерпретацию рынка

---

## 1. Нормативные основания (ОБЯЗАТЕЛЬНО)

Тесты **ДОЛЖНЫ строго соответствовать**:

1. **SSP v1.x**
2. **CONTRACT_LEXICON v1.2**
3. **NAMING_RULES v1.0**
4. **ROLE_CALL_CONTRACTS_MQL5 v0.1**
5. **TECH SPEC — DecisionMaker (ReferenceTrendBreak)**
6. **STRATEGY_SPEC — ReferenceTrendBreak v1.1**

---

## 2. Контракт под тестированием (ФИКСИРОВАН)

```mq5
void DecisionMaker_Run(
   const Snapshot &snapshot,
   const Feedback &feedback,
   Intent &out_intent
);
```

---

## 3. Разрешённые данные Snapshot (ЖЁСТКО)

В тестах **заполняются и используются ТОЛЬКО**:

```text
snapshot.time.is_new_bar
snapshot.position.has_position
snapshot.market.last_closes[3]
```

Все остальные поля `Snapshot`:

* заполняются нулевыми значениями
* **НЕ читаются**
* **НЕ влияют** на результат

---

## 4. Общие инварианты (ОБЯЗАТЕЛЬНЫ ДЛЯ ВСЕХ ТЕСТОВ)

В каждом тесте **ОБЯЗАНО** выполняться:

1. Формируется **РОВНО ОДИН** `Intent`
2. `Intent.type ∈ { NO_ACTION, WANT_OPEN }`
3. `Intent.confidence`:

   * `1.0` — при `WANT_OPEN`
   * `0.0` — при `NO_ACTION`
4. `Intent.direction`:

   * `+1` или `-1` — **ТОЛЬКО** при `WANT_OPEN`
   * `0` — **ТОЛЬКО** при `NO_ACTION`
5. `WANT_CLOSE` **НИКОГДА** не формируется
6. `feedback` **НЕ влияет** на результат
7. Одинаковые входы → одинаковый `Intent` (детерминизм)

---

## 5. Тестовые группы (НОРМАТИВНЫЕ)

---

### 🟦 DM-1 — Determinism

**Цель:** подтвердить детерминизм `DecisionMaker_Run`.

**Given:**

* идентичный `Snapshot`
* два различных `Feedback`

**When:**

* `DecisionMaker_Run` вызывается дважды

**Then:**

* `Intent.type`
* `Intent.direction`
* `Intent.confidence`

бит-в-бит идентичны.

---

### 🟦 DM-2 — NO_ACTION if not new bar

**Given:**

```
snapshot.time.is_new_bar        = false
snapshot.position.has_position = false
last_closes = {3.0, 2.0, 1.0}
```

**Then:**

```
Intent.type       = NO_ACTION
Intent.direction  = 0
Intent.confidence = 0.0
```

---

### 🟦 DM-3 — NO_ACTION if position exists

**Given:**

```
snapshot.time.is_new_bar        = true
snapshot.position.has_position = true
last_closes = {3.0, 2.0, 1.0}
```

**Then:** `NO_ACTION`
(все поля как в DM-2)

---

### 🟦 DM-4 — LONG signal on strictly increasing closes

**Given:**

```
snapshot.time.is_new_bar        = true
snapshot.position.has_position = false
last_closes = {3.0, 2.0, 1.0}
```

**Then:**

```
Intent.type       = WANT_OPEN
Intent.direction  = +1
Intent.confidence = 1.0
```

---

### 🟦 DM-5 — SHORT signal on strictly decreasing closes

**Given:**

```
snapshot.time.is_new_bar        = true
snapshot.position.has_position = false
last_closes = {1.0, 2.0, 3.0}
```

**Then:**

```
Intent.type       = WANT_OPEN
Intent.direction  = -1
Intent.confidence = 1.0
```

---

### 🟦 DM-6 — NO_ACTION on non-strict sequences

**Цель:** зафиксировать запрет `>=` / `<=`.

Каждый кейс — **отдельный тест**:

```
{2.0, 2.0, 1.0}
{3.0, 2.0, 2.0}
{2.0, 3.0, 1.0}
{1.0, 3.0, 2.0}
```

**Then (для всех):**

```
Intent.type       = NO_ACTION
Intent.direction  = 0
Intent.confidence = 0.0
```

---

### 🟦 DM-7 — Feedback does not affect output

**Given:**

* одинаковый `Snapshot`
* два разных `Feedback`
  (разные `event / pnl / message`)

**Then:**

* `Intent` полностью идентичен

---

## 6. Запреты (ЖЁСТКО)

В тестах **ЗАПРЕЩЕНО**:

❌ использовать MT5 торговый API
❌ использовать `SymbolInfo*`, `MarketInfo`
❌ использовать индикаторы
❌ хранить состояние между тестами
❌ использовать глобальные mutable данные
❌ проверять логику других ролей

---

## 7. Отчётность тестов

Тесты **ОБЯЗАНЫ**:

* логировать:

  ```
  [DM-TEST] START
  [DM-TEST] PASSED
  ```
* при ошибке:

  ```
  [DM-TEST][FAIL] <message>
  ```

❌ Молчаливый PASS запрещён.

---

## 8. Критерий приёмки

Test Suite считается принятой, если:

* выполнены DM-1 … DM-7
* отсутствуют `[DM-TEST][FAIL]`
* `DecisionMaker_Run`:

  * детерминирован
  * формирует ровно один `Intent`
  * **никогда** не формирует `WANT_CLOSE`
  * использует **только разрешённые поля Snapshot**

---

## 🔒 Фиксация Master-Chat

С этого момента:

* имя файла **без версий** — зафиксировано
* данный Test Spec — **единственный допустимый** для ReferenceTrendBreak
* изменения — **ТОЛЬКО через новую версию документа**, не через имя файла

