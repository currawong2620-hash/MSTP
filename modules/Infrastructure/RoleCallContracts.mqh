//+------------------------------------------------------------------+
//| RoleCallContracts.mqh — Role Call Contracts v0.1                 |
//| Infrastructure / Orchestration ABI                                |
//| STRICT MQL5, no #pragma once                                      |
//| Authority: SSP v1.0, CONTRACT_LEXICON v1.0                        |
//+------------------------------------------------------------------+
#ifndef __ROLE_CALL_CONTRACTS_MQH__
#define __ROLE_CALL_CONTRACTS_MQH__

//--------------------------------------------------------------------
// Required architectural types
//--------------------------------------------------------------------
#include "ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Observer
// Produces: Snapshot
//--------------------------------------------------------------------
void Observer_Run(
   Snapshot &out_snapshot
);

//--------------------------------------------------------------------
// DecisionMaker
// Produces: Intent
//--------------------------------------------------------------------
void DecisionMaker_Run(
   const Snapshot &snapshot,
   const Feedback &feedback,
   Intent &out_intent
);

//--------------------------------------------------------------------
// PositionPolicyManager
// Produces: 0..N PolicyAdjustedIntent
//--------------------------------------------------------------------
int PositionPolicyManager_Run(
   const Intent &intent,
   const Snapshot &snapshot,
   const Feedback &feedback,
   PolicyAdjustedIntent &out_policy_intents[]
);

//--------------------------------------------------------------------
// RiskArbiter
// Produces: Decision
//--------------------------------------------------------------------
void RiskArbiter_Run(
   const PolicyAdjustedIntent &policy_intent,
   const Snapshot &snapshot,
   Decision &out_decision
);

//--------------------------------------------------------------------
// Executor
// Produces: ExecutionResult
//--------------------------------------------------------------------
void Executor_Run(
   const Decision &decision,
   ExecutionResult &out_result
);

//--------------------------------------------------------------------
// FeedbackSource
// Produces: Feedback
//--------------------------------------------------------------------
void FeedbackSource_Run(
   const ExecutionResult &results[],
   const int results_count,
   Feedback &out_feedback
);

#endif // __ROLE_CALL_CONTRACTS_MQH__
