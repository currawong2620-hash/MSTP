## Scenario-Based Strategy — Build & Wiring Guide

**Project:** Trading Platform
**Scope:** Implementation / Integration
**Status:** NON-NORMATIVE
**Authority:** none
**Change policy:** versioned
**Removable:** yes

---

## 0. Purpose

This document describes a **minimal build and wiring procedure**
for running a **scenario-based strategy baseline** together with the
**Coordinator**.

Its sole purpose is to ensure:

* reproducible integration
* deterministic execution
* visual observability of the orchestration flow

This document:

* does NOT define architecture
* does NOT define contracts
* does NOT constrain real strategies
* does NOT modify SSP or Lexicon

It is an **implementation-only guide** and can be removed without
affecting system architecture.

---

## 1. Context

At this stage of the project, the following components already exist
and are approved:

### 1.1 Infrastructure

* `ArchitectureTypes.mqh`
* `RoleCallContracts.mqh`
* `Coordinator.mqh`

### 1.2 Scenario-based Strategy Roles

These roles are **replaceable** and **implementation-specific**:

* `DecisionMaker_Scenario.mqh`
* `PositionPolicyManager_Scenario.mqh`
* `RiskArbiter_Scenario.mqh`

They implement a deterministic scenario defined in:

* `DummyStrategy_ScenarioCoverage_v0.1.md`

---

## 2. Goal of the Build

The goal of this build is **NOT trading**.

The goal is to verify that:

1. Coordinator can be compiled and linked
2. All role calls are executed in correct order
3. Short-circuit rules are respected
4. Feedback loop closes correctly
5. Scenario advances deterministically over cycles

Only **one orchestration cycle** is required.

---

## 3. Build Principle (Critical)

### 3.1 Coordinator Independence

Coordinator:

* includes **contracts only**
* does NOT include concrete implementations
* does NOT know which strategy is used

Strategy selection happens **at build time**, not at runtime.

---

### 3.2 Single Implementation Rule

For each role contract, **exactly one implementation**
must be present in the build.

Multiple implementations of the same role
in a single build are forbidden.

---

## 4. Required Minimal Non-Strategy Roles

To allow execution, the following non-replaceable roles
require **minimal stub implementations**:

### 4.1 Observer

Purpose:

* produce a `Snapshot`

Minimal requirements:

* populate `Snapshot.time.is_new_bar`
* all other fields may be zero-filled

No market logic is required.

---

### 4.2 Executor

Purpose:

* transform `Decision` into `ExecutionResult`

Minimal requirements:

* if decision status is `ACCEPT` or `MODIFY`
  → return a successful execution result
* price may be zero
* no MT5 trade API calls

---

### 4.3 FeedbackSource

Purpose:

* close the orchestration loop

Minimal requirements:

* accept array of `ExecutionResult`
* produce a valid `Feedback` object
* feedback content may be simplified

---

## 5. Entry Point (Runner)

A minimal `.mq5` runner is required to:

1. include all required modules
2. invoke `Coordinator_RunCycle`
3. optionally print log output

The runner:

* is NOT part of architecture
* exists only to trigger execution
* may be deleted after verification

---

## 6. Recommended File Structure

```
/TradingMode_Run.mq5

/modules
  /Infrastructure
    ArchitectureTypes.mqh
    RoleCallContracts.mqh
    Coordinator.mqh

  /Strategy
    /Scenario
      DecisionMaker_Scenario.mqh
      PositionPolicyManager_Scenario.mqh
      RiskArbiter_Scenario.mqh

  /Observer
    Observer_Minimal.mqh

  /Execution
    Executor_Minimal.mqh

  /Feedback
    FeedbackSource_Minimal.mqh
```

This structure is **recommended**, not mandatory.

---

## 7. Include Order (Important)

In the runner `.mq5` file, the include order should be:

1. `ArchitectureTypes.mqh`
2. `RoleCallContracts.mqh`
3. Scenario-based role implementations
4. Minimal non-strategy role implementations
5. `Coordinator.mqh`

This guarantees correct symbol resolution
and a single implementation per role.

---

## 8. What Is Verified by This Build

This build verifies:

* role call order
* scenario determinism
* short-circuit handling
* feedback closure
* orchestration stability

---

## 9. What Is NOT Verified

This build does NOT verify:

* trading profitability
* market correctness
* risk management
* execution realism
* performance

Those aspects belong to later stages.

---

## 10. Removal Invariant

All components introduced for this build:

* scenario-based roles
* minimal stubs
* runner

MUST be removable without changes to:

* SSP
* CONTRACT_LEXICON
* Coordinator
* architectural models

---

**End of Scenario-Based Strategy — Build & Wiring Guide**

