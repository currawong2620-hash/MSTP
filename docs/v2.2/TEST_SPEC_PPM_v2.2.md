# 🟥 TEST SPEC — PositionPolicyManager v2.2 (REV A)

## Trailing Stop (Snapshot-based, Step-driven)

**Status:** READY FOR IMPLEMENTATION
**Component:** PositionPolicyManager
**Role version:** v2.2
**Language:** STRICT MQL5

---

## 0. Test Purpose

This TestSpec validates **ONLY**:

* correctness of Trailing Stop exit decision:

  * activation threshold (START)
  * distance (DISTANCE)
  * step gating (STEP)
  * hit-condition (price crosses trailing stop)
* preservation of v2.1 invariants:

  * output cardinality
  * exit overrides intent
  * determinism
  * feedback inertness

This TestSpec **DOES NOT** validate:

❌ Observer logic (trailing stop maintenance)
❌ mutation/persistence of trailing state
❌ execution layer behavior

---

## 1. Normative References (MANDATORY)

Implementation **MUST comply with**:

1. SSP v1.x
2. **CONTRACT_LEXICON v1.4**
3. ROLE_CALL_CONTRACTS_MQL5 v0.1
4. NAMING_RULES v1.0
5. TECH SPEC — PositionPolicyManager v2.2

---

## 2. Black-box Testing Rule

`PositionPolicyManager_Run` is tested as a pure function:

```text
(Intent, Snapshot, Feedback) → PolicyAdjustedIntent[0..1]
```

Tests MUST NOT:

* inspect internal variables
* assume internal state
* depend on call history

---

## 3. Global Invariants (MUST ASSERT IN EVERY TEST)

Each test MUST verify:

1. `count ∈ {0,1}`
2. `ArraySize(out) == count`
3. output array is cleared (garbage prefill → no garbage remains)
4. Snapshot is not mutated (tested indirectly: same input → same output)
5. Feedback is inert (explicit group test)

---

## 4. Configuration for Test Suite (LEGAL FORM)

### 4.1 Compile-time configuration requirement

Trailing parameters are **startup input parameters** in the implementation.
For acceptance testing, the suite is executed under a **fixed configuration**, provided via terminal inputs / .set file at launch.

This TestSpec assumes the following **fixed input values during test run**:

```text
PPM_TS_START_POINTS    = 20
PPM_TS_DISTANCE_POINTS = 10
PPM_TS_STEP_POINTS     = 5
```

The test harness MUST be configured so that these values are in effect for the test run.

> Tests MUST NOT “override” inputs programmatically.

### 4.2 Price scale

Unless overridden:

```text
snapshot.market.point_size = 0.0001
```

LONG uses `bid`, SHORT uses `ask`.

---

## 5. Explicit Non-Assertions (MANDATORY)

Tests MUST NOT assert:

* any mutation of `Snapshot`
* any mutation of `snapshot.position.trailing_stop_price`
* any persistence of trailing state across calls
* any “new trailing value” computed or stored by PPM

The only observable artifact is the returned `PolicyAdjustedIntent[0..1]`.

---

## 6. Test Fixture Facts (Trailing)

The following Snapshot fact is assumed legal (Lexicon v1.4):

```text
snapshot.position.trailing_stop_price : double
```

Semantics used by tests:

* `0.0` → trailing not active (no stop established by producer)
* `>0.0` → trailing stop level is already established by producer

PPM reads it but must not modify it.

---

## 7. Test Groups and Cases

### Group A — Activation

#### PPM2-TS-1 — Trailing not active before START (LONG)

**Given:**

* LONG position
* `bid < entry + START*ps`
* `trailing_stop_price = 0.0`

**Expect:** `count = 0`

---

#### PPM2-TS-2 — Trailing activation threshold reached (LONG)

**Given:**

* LONG position
* `bid == entry + START*ps`
* `trailing_stop_price = 0.0`

**Expect:** `count = 0`
(Activation alone does not trigger exit.)

---

### Group B — Step gating semantics (NO mutation implied)

> These tests verify **decision behavior** when `trailing_stop_price` is provided as an external fact.
> They do not verify any update/persistence.

#### PPM2-TS-3 — Trailing target exceeds step threshold (LONG, external stop provided)

**Given:**

* LONG position
* trailing is in profit zone (`bid >= entry + START*ps`)
* `trailing_stop_price = ts_prev > 0`
* choose `bid` so that `ts_target = bid - DIST*ps` satisfies:

```text
ts_target >= ts_prev + STEP*ps
```

**Expect:** `count = 0`
(Exit does not occur when price is above stop. This case ensures “step-exceeding” geometry does not itself cause exit.)

---

#### PPM2-TS-4 — Trailing target does NOT exceed step threshold (LONG, external stop provided)

**Given:**

* LONG position
* trailing profit zone satisfied
* `trailing_stop_price = ts_prev > 0`
* choose `bid` so that:

```text
ts_target < ts_prev + STEP*ps
```

**Expect:** `count = 0`

---

#### PPM2-TS-5 — Step gating does not bypass stop hit (LONG)

**Given:**

* LONG position
* `trailing_stop_price = ts_prev > 0`
* choose `bid` so that `bid <= ts_prev` (hit condition)

**Expect:** `count = 1` and output is `WANT_CLOSE` with `tag="POLICY_EXIT"`

---

### Group C — Hit / No-hit (LONG)

#### PPM2-TS-6 — Trailing hit triggers exit (LONG)

**Given:**

* LONG position
* `trailing_stop_price = ts_prev > 0`
* `bid <= ts_prev`

**Expect:**

```text
count == 1
type == WANT_CLOSE
direction == 0
volume == snapshot.position.volume
tag == "POLICY_EXIT"
```

---

#### PPM2-TS-7 — Price above trailing stop does not exit (LONG)

**Given:**

* LONG position
* `trailing_stop_price = ts_prev > 0`
* `bid > ts_prev`

**Expect:** `count = 0`

---

### Group D — SHORT (Mirror)

#### PPM2-TS-8 — Trailing not active before START (SHORT)

**Given:**

* SHORT position
* `ask > entry - START*ps`
* `trailing_stop_price = 0.0`

**Expect:** `count = 0`

---

#### PPM2-TS-9 — Trailing hit triggers exit (SHORT)

**Given:**

* SHORT position
* `trailing_stop_price = ts_prev > 0`
* `ask >= ts_prev`

**Expect:** `count = 1` with `WANT_CLOSE` and `tag="POLICY_EXIT"`

---

#### PPM2-TS-10 — Price below trailing stop does not exit (SHORT)

**Given:**

* SHORT position
* `trailing_stop_price = ts_prev > 0`
* `ask < ts_prev`

**Expect:** `count = 0`

---

### Group E — Exit overrides intent

#### PPM2-TS-11 — Trailing hit overrides WANT_OPEN

**Given:**

* position exists
* trailing hit condition satisfied
* `intent.type = WANT_OPEN`

**Expect:** exit decision (`WANT_CLOSE`), count=1

---

#### PPM2-TS-12 — Trailing hit overrides WANT_CLOSE

Same expectation.

---

### Group F — Interaction with SL/TP (conceptual priority)

> Priority is conceptual; output is identical for any exit trigger.
> These cases ensure no regression: if SL/TP hit, exit must occur regardless of trailing.

#### PPM2-TS-13 — SL hit causes exit even when trailing facts present

**Given:**

* SL condition satisfied
* trailing_stop_price set to any value

**Expect:** `WANT_CLOSE`, `tag="POLICY_EXIT"`

---

#### PPM2-TS-14 — TP hit causes exit even when trailing facts present

Same expectation.

---

### Group G — Determinism & Feedback

#### PPM2-TS-15 — Determinism with trailing facts

Same inputs (including `trailing_stop_price`) across N calls → identical outputs.

---

#### PPM2-TS-16 — Feedback inertness with trailing facts

Same Snapshot/Intent, different Feedback → identical output.

---

## 8. Acceptance Criteria

Suite is accepted if:

* all tests PASS under fixed terminal input configuration
* no MT5 API usage in tests
* no assertions about Snapshot mutation / trailing persistence
* invariants hold in all cases
* Audit-Chat finds no SSP/Lexicon violations

---

## ✅ TEST SPEC STATUS

**AUDIT-RESOLVED / READY FOR IMPLEMENTATION**
