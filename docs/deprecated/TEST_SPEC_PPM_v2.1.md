# 🟥 TEST SPEC — PositionPolicyManager v2.1

## Stage 1 — Configurable Virtual SL / TP (Points, Snapshot-based)

**Status:** READY FOR IMPLEMENTATION
**Scope:** Strategy / Replaceable Roles
**Tested role:** `PositionPolicyManager`
**Role version:** v2.1
**Test Spec version:** v2.1
**Language:** STRICT MQL5

---

## 0. Test Purpose

This TestSpec validates **ONLY**:

* correctness of **virtual SL / TP exit policy**
* correctness of **policy-level intent filtering**
* determinism and output invariants
* strict compliance with SSP & CONTRACT_LEXICON

This TestSpec **DOES NOT** validate:

❌ trading profitability
❌ realism of prices
❌ executor behavior
❌ feedback semantics
❌ trailing stop logic

---

## 1. Normative References (MANDATORY)

The implementation **MUST comply with**:

* SSP v1.x
* CONTRACT_LEXICON v1.3
* ARCHITECTURE_DATA_FLOW_MODEL v1.1
* ROLE_CALL_CONTRACTS_MQL5 v0.1
* NAMING_RULES v1.0
* **TECH SPEC — PositionPolicyManager v2.1 (AUDIT-RESOLVED)**

Any deviation → **test failure**.

---

## 2. General Test Rules (GLOBAL)

### 2.1 Black-box testing

Tests treat `PositionPolicyManager` as a **pure function**:

```text
(Intent, Snapshot, Feedback) → PolicyAdjustedIntent[0..1]
```

No test may:

* read internal variables
* rely on implementation details
* assume call ordering outside the contract

---

### 2.2 Output clearing invariant

Before every test:

* `out_policy_intents` is pre-filled with garbage
* after call:

  * output **must be cleared**
  * only valid outputs may exist

---

### 2.3 Determinism rule

For identical inputs:

* output count
* output content

**MUST be identical** across multiple calls.

---

### 2.4 Configuration scope

Tests assume **startup input parameters**:

```text
PPM_SL_POINTS
PPM_TP_POINTS
```

Values are considered **fixed during test execution**.

---

## 3. Common Test Fixtures

Unless overridden, tests use:

```text
snapshot.position.has_position = true
snapshot.position.volume       = 1.0
snapshot.market.point_size     = 0.0001
```

Direction, entry price, bid/ask vary per test.

---

## 4. Exit Policy Tests — LONG Position

### PPM2-1 — LONG Stop-Loss fires

**Given:**

```text
direction = +1
entry     = 1.2000
bid       = 1.1990
PPM_SL_POINTS = 10
PPM_TP_POINTS = 0
```

**Expected:**

* count = 1
* type = WANT_CLOSE
* direction = 0
* volume = snapshot.position.volume
* tag = "POLICY_EXIT"

---

### PPM2-2 — LONG Take-Profit fires

```text
direction = +1
entry     = 1.2000
bid       = 1.2010
PPM_SL_POINTS = 0
PPM_TP_POINTS = 10
```

→ **WANT_CLOSE**

---

### PPM2-3 — LONG No exit inside range

```text
direction = +1
entry     = 1.2000
bid       = 1.2005
PPM_SL_POINTS = 10
PPM_TP_POINTS = 10
```

→ no exit intent

---

## 5. Exit Policy Tests — SHORT Position

### PPM2-4 — SHORT Stop-Loss fires

```text
direction = -1
entry     = 1.2000
ask       = 1.2010
PPM_SL_POINTS = 10
PPM_TP_POINTS = 0
```

→ **WANT_CLOSE**

---

### PPM2-5 — SHORT Take-Profit fires

```text
direction = -1
entry     = 1.2000
ask       = 1.1990
PPM_TP_POINTS = 10
```

→ **WANT_CLOSE**

---

### PPM2-6 — SHORT No exit inside range

→ no output

---

## 6. Exit Priority Tests

### PPM2-7 — Exit overrides WANT_OPEN

**Given:**

* active position
* exit condition met
* `intent.type = WANT_OPEN`

**Expected:**

* count = 1
* type = WANT_CLOSE

---

### PPM2-8 — Exit overrides WANT_CLOSE

**Given:**

* active position
* exit condition met
* `intent.type = WANT_CLOSE`

**Expected:**

* WANT_CLOSE from policy
* not from intent

---

## 7. Intent Filtering Tests (No Exit)

### PPM2-9 — WANT_OPEN allowed when no position

```text
has_position = false
intent.type  = WANT_OPEN
intent.direction = +1
```

**Expected:**

* count = 1
* type = WANT_OPEN
* direction = +1
* volume = PPM_BASE_OPEN_VOLUME
* tag = "POLICY_PASS"

---

### PPM2-10 — WANT_OPEN blocked when position exists

```text
has_position = true
```

→ count = 0

---

### PPM2-11 — WANT_OPEN with invalid direction rejected

```text
intent.direction = 0
```

→ count = 0

---

### PPM2-12 — WANT_CLOSE ignored without exit

```text
intent.type = WANT_CLOSE
no exit condition
```

→ count = 0

---

## 8. Disable Rules Tests

### PPM2-13 — SL disabled

```text
PPM_SL_POINTS <= 0
```

SL must **never fire**.

---

### PPM2-14 — TP disabled

```text
PPM_TP_POINTS <= 0
```

TP must **never fire**.

---

## 9. Determinism & Invariants

### PPM2-15 — Determinism

Same input × N calls → identical output.

---

### PPM2-16 — Output cardinality

Under all conditions:

```text
count ∈ {0,1}
```

---

### PPM2-17 — Feedback inertness

Vary `Feedback` arbitrarily → output unchanged.

---

## 10. Explicit Prohibitions (TEST-ENFORCED)

Tests will **fail** if implementation:

❌ reads `_Point`
❌ uses `SymbolInfo*`
❌ accesses MT5 environment
❌ stores static/global state
❌ emits more than 1 intent
❌ mutates Snapshot

---

## 11. Audit Checklist

✔ Exit logic bid/ask correct
✔ Uses `snapshot.market.point_size`
✔ Contract fields correct
✔ Lexicon semantics preserved
✔ SSP flow preserved

---

## ✅ TEST SPEC STATUS

**APPROVED (after audit)**
Ready for **Coder-Chat implementation**.

---

