## Scenario Coverage Plan — Dummy Strategy v0.1

**Project:** Trading Platform
**Status:** IMPLEMENTATION SUPPORT (non-normative)
**Compliance:** SSP v1.0, CONTRACT_LEXICON v1.0
**Change policy:** versioned only
**Authority:** none (implementation-level)

---

## 0. Purpose

This document defines a **deterministic scenario coverage plan**
used to implement a scenario-based strategy compliant with:

* **SPEC — Dummy Strategy v0.1**
* **SSP v1.0**

The purpose of this plan is to **guarantee full coverage of all mandatory
architectural contract states** during execution.

This document:

* does NOT define architecture
* does NOT define role contracts
* does NOT introduce new concepts
* does NOT constrain real strategies

It exists solely to support **implementation correctness, auditability,
and reproducibility**.

---

## 1. General Scenario Rules

1. The **only source of variability** is an internal deterministic
   counter `scenario_step`.
2. `scenario_step` advances **only** when
   `Snapshot.time.is_new_bar == true`.
3. When `is_new_bar == false`, roles MUST repeat their previous output.
4. Scenario length is **8 steps**, looping cyclically:

   ```
   scenario_step = (scenario_step + 1) % 8
   ```
5. Roles MUST NOT:

   * read `Snapshot.market.*`
   * use prices, volatility, spread, or volume
   * use `Feedback.pnl`
   * adapt behavior over time

---

## 2. DecisionMaker Coverage Plan

### Output Type

* `Intent`

### Fixed Parameters

* `confidence = 0.50` for all steps

### Scenario Table

| Step | Intent.type | direction |
| ---: | ----------- | --------- |
|    0 | NO_ACTION   | 0         |
|    1 | WANT_OPEN   | +1        |
|    2 | WANT_HOLD   | 0         |
|    3 | WANT_CLOSE  | 0         |
|    4 | WANT_OPEN   | -1        |
|    5 | NO_ACTION   | 0         |
|    6 | WANT_HOLD   | 0         |
|    7 | WANT_CLOSE  | 0         |

### Validity Rule

If `Snapshot.position.has_position == true` and the table specifies
`WANT_OPEN`, the output MUST be replaced with:

```
Intent.type = WANT_HOLD
direction   = 0
```

This rule exists solely to prevent logically impossible intents and does
not constitute market logic.

### Coverage Guarantees

This table guarantees occurrence of:

* NO_ACTION
* WANT_OPEN (+1)
* WANT_OPEN (-1)
* WANT_HOLD
* WANT_CLOSE

---

## 3. PositionPolicyManager Coverage Plan

### Output Type

* `PolicyAdjustedIntent` (0..N)

### General Rules

* Input `NO_ACTION` → zero outputs
* Output depends only on:

  * input `Intent`
  * `scenario_step`
* `tag` values are fixed identifiers for traceability only

### Scenario Table

| Step | Input Intent | Count | Outputs                                                                |
| ---: | ------------ | ----: | ---------------------------------------------------------------------- |
|    0 | NO_ACTION    |     0 | —                                                                      |
|    1 | WANT_OPEN    |     1 | type=WANT_OPEN, dir=+1, vol=0.10, tag="POLICY_SINGLE"                  |
|    2 | WANT_HOLD    |     0 | —                                                                      |
|    3 | WANT_CLOSE   |     1 | type=WANT_CLOSE, dir=0, vol=0.00, tag="POLICY_CLOSE"                   |
|    4 | WANT_OPEN    |     2 | [0] vol=0.05 tag="POLICY_MULTI_A"<br>[1] vol=0.15 tag="POLICY_MULTI_B" |
|    5 | NO_ACTION    |     0 | —                                                                      |
|    6 | WANT_HOLD    |     1 | vol=0.20 tag="POLICY_MOD_VOL"                                          |
|    7 | WANT_CLOSE   |     1 | vol=0.00 tag="POLICY_CLOSE_2"                                          |

### Coverage Guarantees

This plan guarantees:

* 1 → 0 outputs
* 1 → 1 output
* 1 → multiple outputs
* material modification of `volume`

---

## 4. RiskArbiter Coverage Plan

### Output Type

* `Decision`

### General Rules

* Exactly one `Decision` per `PolicyAdjustedIntent`
* `Decision.reason` values are fixed scenario codes

### Scenario Decisions

#### Step 1

* status = ACCEPT
* volume = input.volume
* reason = "OK"

#### Step 3

* status = REJECT
* volume = 0.00
* reason = "REJECT_SCENARIO"

#### Step 4

* intent[0]:

  * status = MODIFY
  * volume = input.volume * 0.50
  * reason = "MODIFY_HALF"
* intent[1]:

  * status = ACCEPT
  * volume = input.volume
  * reason = "OK_2"

#### Step 6

* status = ACCEPT
* volume = input.volume
* reason = "OK_HOLD"

#### Step 7

* status = MODIFY
* volume = 0.01
* reason = "MODIFY_FIXED"

### Coverage Guarantees

This plan guarantees occurrence of:

* ACCEPT
* REJECT
* MODIFY with material payload change

---

## 5. Coordinator-Level Effects

This scenario guarantees execution of:

* `NO_ACTION` short-circuit
* empty PolicyAdjustedIntent short-circuit
* `Decision = REJECT` executor skip
* multiple execution results
* feedback generation in all cases

---

## 6. Determinism & Independence

Behavior defined in this document MUST remain unchanged when:

* symbol changes
* timeframe changes
* market data is altered
* execution results differ

Any deviation invalidates the implementation.

---

## 7. Removal Invariant

All implementations based on this scenario MUST be fully removable.

Removing them MUST NOT require changes to:

* Coordinator
* SSP
* CONTRACT_LEXICON
* Infrastructure modules

---

**End of Scenario Coverage Plan — Dummy Strategy v0.1**

