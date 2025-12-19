

# ROLE CALL CONTRACTS — MQL5 v0.1

**Status:** NORMATIVE (implementation-level)  
**Scope:** Coordinator and role implementations  
**Authority:** SSP v1.0, CONTRACT_LEXICON v1.0  
**Language:** MQL5  
**Change policy:** versioned only

---

## 0. Purpose

This document defines the **minimal callable contracts**
for architectural roles, required for Coordinator implementation.

These contracts:

- do NOT define behavior or logic
- do NOT introduce new architectural types
- do NOT modify SSP role responsibilities
- apply equally to dummy and real implementations

They exist solely to make orchestration implementable in code.

---

## 1. General Rules

1. All functions are **pure role entry points**.
2. All inputs and outputs use **ONLY types from CONTRACT_LEXICON**.
3. No function may read or modify global architectural state.
4. No role may call another role directly.
5. Coordinator is the **only orchestrator**.

---

## 2. Observer Call Contract

**Role:** Observer  
**Responsibility:** produce Snapshot

```mq5
void Observer_Run(
    Snapshot &out_snapshot
);
````

Rules:

* fills `out_snapshot`
* does not read any other architectural type
* has no return value

---

## 3. DecisionMaker Call Contract

**Role:** DecisionMaker
**Responsibility:** produce Intent

```mq5
void DecisionMaker_Run(
    const Snapshot &snapshot,
    const Feedback &feedback,
    Intent &out_intent
);
```

Rules:

* writes exactly one `Intent`
* does not read PolicyAdjustedIntent, Decision, ExecutionResult
* does not execute trades

---

## 4. PositionPolicyManager Call Contract

**Role:** PositionPolicyManager
**Responsibility:** transform Intent → 0..N PolicyAdjustedIntent

```mq5
int PositionPolicyManager_Run(
    const Intent &intent,
    const Snapshot &snapshot,
    const Feedback &feedback,
    PolicyAdjustedIntent &out_policy_intents[]
);
```

Rules:

* return value = number of produced policy intents
* may return 0
* must not interpret market data

---

## 5. RiskArbiter Call Contract

**Role:** RiskArbiter
**Responsibility:** produce Decision per PolicyAdjustedIntent

```mq5
void RiskArbiter_Run(
    const PolicyAdjustedIntent &policy_intent,
    const Snapshot &snapshot,
    Decision &out_decision
);
```

Rules:

* produces exactly one Decision
* must not generate Intent
* must not execute trades

---

## 6. Executor Call Contract

**Role:** Executor
**Responsibility:** attempt execution

```mq5
void Executor_Run(
    const Decision &decision,
    ExecutionResult &out_result
);
```

Rules:

* called only if Decision.status != REJECT
* does not read Snapshot or Intent
* does not produce Feedback

---

## 7. FeedbackSource Call Contract

**Role:** FeedbackSource
**Responsibility:** produce Feedback

```mq5
void FeedbackSource_Run(
    const ExecutionResult &results[],
    const int results_count,
    Feedback &out_feedback
);
```

Rules:

* called exactly once per orchestration cycle
* aggregates execution facts only
* does not influence decisions

---

## 8. Coordinator Visibility Rule

Coordinator:

* MAY call all functions defined in this document
* MUST NOT define alternative call paths
* MUST NOT bypass any role
* MUST NOT embed role logic

---

## 9. Stability Rule

Any change to:

* function signatures
* parameter types
* call cardinality

constitutes a **breaking implementation change**
and requires a new version of this document.

---

**END OF ROLE CALL CONTRACTS — v0.1**

