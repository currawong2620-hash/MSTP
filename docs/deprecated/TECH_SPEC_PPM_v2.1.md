# 🟥 TECH SPEC — PositionPolicyManager v2.1

## Stage 1 — Configurable Virtual SL / TP (Points, Snapshot-based)

### **AUDIT-RESOLVED REV A**

**Status:** READY FOR IMPLEMENTATION
**Scope:** Strategy / Replaceable Roles
**Role:** `PositionPolicyManager`
**Version:** v2.1
**Language:** STRICT MQL5
**Supersedes:** v2.0 (fixed exit points baseline)

---

## 0. Purpose

Introduce **configurable virtual Stop-Loss / Take-Profit** parameters
while preserving:

* SSP compliance
* CONTRACT_LEXICON compliance
* stateless deterministic behavior
* fixed role contract
* black-box testability

**Trailing stop is explicitly out of scope** for v2.1.

---

## 1. Normative Constraints (MANDATORY)

Implementation **MUST comply with**:

* SSP v1.x
* **CONTRACT_LEXICON v1.3** (Snapshot.market.point_size present)
* ARCHITECTURE_DATA_FLOW_MODEL v1.1
* ROLE_CALL_CONTRACTS_MQL5 v0.1
* NAMING_RULES v1.0

### Explicit prohibitions

❌ No new roles
❌ No new architectural types
❌ No **additional** Snapshot extensions
(beyond already introduced `Snapshot.market.point_size`)
❌ No state between calls
❌ No MT5 environment access (`_Point`, `SymbolInfo*`, etc.)

---

## 2. Role Contract (FIXED)

Signature **MUST NOT change**:

```mq5
int PositionPolicyManager_Run(
   const Intent      &intent,
   const Snapshot    &snapshot,
   const Feedback    &feedback,
   PolicyAdjustedIntent &out_policy_intents[]
);
```

---

## 3. Configuration Parameters (UPDATED TERMINOLOGY)

### 3.1 Startup Input Parameters

`PositionPolicyManager` defines **terminal startup input parameters**
(**immutable during run**):

```mq5
input int PPM_SL_POINTS = 0;
input int PPM_TP_POINTS = 0;
```

### Semantics

| Parameter       | Meaning                            |
| --------------- | ---------------------------------- |
| `PPM_SL_POINTS` | Stop-Loss distance in **points**   |
| `PPM_TP_POINTS` | Take-Profit distance in **points** |

### Enable / Disable Rules

* `PPM_SL_POINTS <= 0` → SL disabled
* `PPM_TP_POINTS <= 0` → TP disabled
* SL and TP are independent

---

## 4. Price Distance Model (NORMATIVE)

All price-distance calculations **MUST use**:

```mq5
snapshot.market.point_size
```

❌ `_Point` — forbidden
❌ `SymbolInfo*` — forbidden

This rule is **normative** in v2.1.

---

## 5. Exit Policy Logic (UNCHANGED CORE)

Exit policy has **absolute priority** over any incoming `Intent`.

### Preconditions

Exit policy evaluated **ONLY IF**:

```text
snapshot.position.has_position == true
```

---

### 5.1 LONG Position (`direction == +1`)

Let:

* `entry = snapshot.position.entry_price`
* `bid   = snapshot.market.bid`
* `ps    = snapshot.market.point_size`

**Stop-Loss (if enabled):**

```text
bid <= entry − SL * ps
```

**Take-Profit (if enabled):**

```text
bid >= entry + TP * ps
```

---

### 5.2 SHORT Position (`direction == −1`)

Let:

* `entry = snapshot.position.entry_price`
* `ask   = snapshot.market.ask`
* `ps    = snapshot.market.point_size`

**Stop-Loss (if enabled):**

```text
ask >= entry + SL * ps
```

**Take-Profit (if enabled):**

```text
ask <= entry − TP * ps
```

---

## 6. Exit Action (MANDATORY)

When **any** enabled exit condition fires:

Produce **exactly one** `PolicyAdjustedIntent`:

```text
type       = WANT_CLOSE
direction  = 0
volume     = snapshot.position.volume
tag        = "POLICY_EXIT"
```

Return value:

```text
count = 1
```

All incoming `Intent` values are ignored.

---

## 7. Intent Filtering (CORRECTED)

Applied **only if no exit condition fired**.

---

### 7.1 `NO_ACTION`

```text
→ return 0
```

---

### 7.2 `WANT_OPEN`

**Validation:**

```text
intent.direction ∈ {+1, −1}
```

If invalid → `return 0`.

**Policy rules:**

* Allowed **only if** `snapshot.position.has_position == false`

**Output:**

```text
type       = WANT_OPEN
direction  = intent.direction
volume     = PPM_BASE_OPEN_VOLUME   (fixed constant, baseline-compatible)
tag        = "POLICY_PASS"
```

> `PPM_BASE_OPEN_VOLUME` is a **fixed compile-time constant**,
> identical to baseline behavior (v1.1 / v2.0).

---

### 7.3 `WANT_CLOSE`

Ignored unless exit policy fires.

---

## 8. Determinism & Output Invariants

Implementation **MUST guarantee**:

* output cleared at entry
* output count ∈ `{0,1}`
* no hidden state
* no dependence on tick rate
* identical input → identical output

---

## 9. Explicit Non-Goals (UNCHANGED)

❌ Trailing stop
❌ Partial close
❌ Scale-out
❌ Time-based exits
❌ Bar-based exits
❌ Runtime-mutable configuration
❌ Snapshot mutation
❌ Feedback-driven exit logic

---

## 10. Versioning Notes

* v2.1 replaces **fixed-point baseline** of v2.0
* v2.0 behavior reproducible via:

```text
PPM_SL_POINTS = N
PPM_TP_POINTS = N
```

---

## 11. Audit Status (FINAL)

✔ SSP-compliant
✔ CONTRACT_LEXICON v1.3 compliant
✔ Deterministic
✔ Stateless
✔ Black-box
✔ Testable

---

## ✅ MASTER-CHAT DECISION (UPDATED)

* All Audit-Chat remarks addressed
* No architectural changes introduced
* Spec is now **APPROVABLE**
* Ready for:

  * **TEST SPEC — PPM v2.1**
  * **Coder-Chat implementation task**

---
