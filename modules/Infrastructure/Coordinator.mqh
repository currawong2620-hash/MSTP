//+------------------------------------------------------------------+
//| Coordinator.mqh — Coordinator v0.2.1                             |
//| Infrastructure / Orchestration Engine                             |
//| STRICT MQL5, no #pragma once                                      |
//| SSP-compliant, no business logic                                  |
//| Visual observability via OUT TRACE ONLY                           |
//+------------------------------------------------------------------+
#ifndef __COORDINATOR_MQH__
#define __COORDINATOR_MQH__

//--------------------------------------------------------------------
// Required contracts (Single Source of Truth)
//--------------------------------------------------------------------
#include "RoleCallContracts.mqh"
#include "ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Allowed internal state: cycle-closure feedback only
//--------------------------------------------------------------------
static Feedback g_coordinator_last_feedback;
static bool     g_coordinator_has_feedback = false;

//--------------------------------------------------------------------
// Reset closure state (no role state touched)
//--------------------------------------------------------------------
void Coordinator_Reset()
{
   g_coordinator_last_feedback.event   = (feedback_event)0;
   g_coordinator_last_feedback.pnl     = 0.0;
   g_coordinator_last_feedback.message = "";
   g_coordinator_has_feedback          = false;
}

//--------------------------------------------------------------------
// Run exactly ONE orchestration cycle for exactly ONE Snapshot
// Trace outputs are provided for visual observability by Runner
//--------------------------------------------------------------------
void Coordinator_RunCycle(
   Snapshot              &out_snapshot,
   Feedback              &out_feedback,

   // --- TRACE OUTPUTS (READ-ONLY FOR RUNNER) ---
   Intent                &out_intent,
   PolicyAdjustedIntent  &out_policy_intents[],
   int                   &out_policy_count
)
{
   //-----------------------------------------------------------------
   // (0) Init trace outputs
   //-----------------------------------------------------------------
   out_intent.type       = NO_ACTION;
   out_intent.direction  = 0;
   out_intent.confidence = 0.0;

   ArrayResize(out_policy_intents, 0);
   out_policy_count = 0;

   //-----------------------------------------------------------------
   // (1) Observer → Snapshot
   //-----------------------------------------------------------------
   Print("[Coordinator] (1) Observer");
   Observer_Run(out_snapshot);

   //-----------------------------------------------------------------
   // Feedback input for this cycle (from previous cycle)
   //-----------------------------------------------------------------
   Feedback feedback_in;
   if(g_coordinator_has_feedback)
      feedback_in = g_coordinator_last_feedback;
   else
   {
      feedback_in.event   = (feedback_event)0;
      feedback_in.pnl     = 0.0;
      feedback_in.message = "";
   }

   //-----------------------------------------------------------------
   // (2) DecisionMaker → Intent
   //-----------------------------------------------------------------
   Print("[Coordinator] (2) DecisionMaker");
   Intent intent;
   intent.type       = NO_ACTION;
   intent.direction  = 0;
   intent.confidence = 0.0;

   DecisionMaker_Run(out_snapshot, feedback_in, intent);

   // Trace
   out_intent = intent;

   // Short-circuit allowed ONLY when there is no position.
   // If a position exists, PPM must still run to enforce virtual SL/TP.
   if(intent.type == NO_ACTION && !out_snapshot.position.has_position)
   {
      Print("[Coordinator] Short-circuit: NO_ACTION (no position)");
   
      ExecutionResult empty_results[];
      ArrayResize(empty_results, 0);
   
      Print("[Coordinator] (6) FeedbackSource");
      out_feedback.event   = (feedback_event)0;
      out_feedback.pnl     = 0.0;
      out_feedback.message = "";
   
      FeedbackSource_Run(empty_results, 0, out_feedback);
   
      g_coordinator_last_feedback = out_feedback;
      g_coordinator_has_feedback  = true;
      return;
   }

   //-----------------------------------------------------------------
   // (3) PositionPolicyManager → 0..N PolicyAdjustedIntent
   //-----------------------------------------------------------------
   Print("[Coordinator] (3) PositionPolicyManager");
   PolicyAdjustedIntent policy_intents[];
   ArrayResize(policy_intents, 0);

   const int policy_count =
      PositionPolicyManager_Run(
         intent,
         out_snapshot,
         feedback_in,
         policy_intents
      );

   // Trace policy output
   if(policy_count > 0)
   {
      ArrayResize(out_policy_intents, policy_count);
      for(int i = 0; i < policy_count; i++)
         out_policy_intents[i] = policy_intents[i];
      out_policy_count = policy_count;
   }

   //-----------------------------------------------------------------
   // Short-circuit: no policy intents
   //-----------------------------------------------------------------
   if(policy_count <= 0)
   {
      Print("[Coordinator] Short-circuit: no PolicyAdjustedIntent");

      ExecutionResult empty_results[];
      ArrayResize(empty_results, 0);

      Print("[Coordinator] (6) FeedbackSource");
      out_feedback.event   = (feedback_event)0;
      out_feedback.pnl     = 0.0;
      out_feedback.message = "";

      FeedbackSource_Run(empty_results, 0, out_feedback);

      g_coordinator_last_feedback = out_feedback;
      g_coordinator_has_feedback  = true;
      return;
   }

   //-----------------------------------------------------------------
   // Storage for executed results only
   //-----------------------------------------------------------------
   ExecutionResult exec_results[];
   int exec_count = 0;
   ArrayResize(exec_results, 0);

   //-----------------------------------------------------------------
   // (4) RiskArbiter → Decision
   // (5) Executor → ExecutionResult (unless REJECT)
   //-----------------------------------------------------------------
   for(int i = 0; i < policy_count; i++)
   {
      PrintFormat("[Coordinator] (4) RiskArbiter [%d]", i);

      Decision decision;
      decision.status    = REJECT;
      decision.action    = (decision_action)0;
      decision.direction = 0;
      decision.volume    = 0.0;
      decision.symbol    = "";
      decision.reason    = "";

      RiskArbiter_Run(policy_intents[i], out_snapshot, decision);

      if(decision.status == REJECT)
      {
         PrintFormat("[Coordinator] Skip Executor (REJECT) [%d]", i);
         continue;
      }

      // REQUIRED: Decision.symbol must be set for Executor
      if(decision.symbol == "")
         decision.symbol = out_snapshot.market.symbol;

      PrintFormat("[Coordinator] (5) Executor [%d]", i);
      ExecutionResult r;
      ZeroMemory(r); // ExecutionResult has no string fields
      Executor_Run(decision, r);

      ArrayResize(exec_results, exec_count + 1);
      exec_results[exec_count] = r;
      exec_count++;
   }

   //-----------------------------------------------------------------
   // (6) FeedbackSource — exactly once per cycle
   //-----------------------------------------------------------------
   PrintFormat("[Coordinator] (6) FeedbackSource (results=%d)", exec_count);
   out_feedback.event   = (feedback_event)0;
   out_feedback.pnl     = 0.0;
   out_feedback.message = "";

   FeedbackSource_Run(exec_results, exec_count, out_feedback);

   //-----------------------------------------------------------------
   // Close loop
   //-----------------------------------------------------------------
   g_coordinator_last_feedback = out_feedback;
   g_coordinator_has_feedback  = true;
}

#endif // __COORDINATOR_MQH__
