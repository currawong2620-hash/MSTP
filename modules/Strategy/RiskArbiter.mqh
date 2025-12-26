//+------------------------------------------------------------------+
//| RiskArbiter.mqh                                                   |
//| RiskArbiter v1.0 — Baseline Gate                                  |
//| STRICT MQL5                                                       |
//+------------------------------------------------------------------+
#ifndef __RISK_ARBITER_MQH__
#define __RISK_ARBITER_MQH__

#include "../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Public role contract (DO NOT CHANGE)
//--------------------------------------------------------------------
void RiskArbiter_Run(
   const PolicyAdjustedIntent &policy_intent,
   const Snapshot &snapshot,
   Decision &out_decision
)
{
   // Step 0 — Default decision
   out_decision.status    = REJECT;
   out_decision.action    = NO_ACTION;
   out_decision.direction = 0;
   out_decision.volume    = 0.0;
   out_decision.symbol    = snapshot.market.symbol;
   out_decision.reason    = "UNKNOWN";

   // Step 1 — Invalid intent type
   if(policy_intent.type == NO_ACTION)
   {
      out_decision.status = REJECT;
      out_decision.reason = "INVALID_INTENT";
      return;
   }

   // Step 2 — Invalid volume
   if(policy_intent.volume <= 0.0)
   {
      out_decision.status = REJECT;
      out_decision.reason = "INVALID_VOLUME";
      return;
   }

   // Step 3 — Direction check
   if(policy_intent.type == WANT_OPEN)
   {
      if(policy_intent.direction == 0)
      {
         out_decision.status = REJECT;
         out_decision.reason = "INVALID_DIRECTION";
         return;
      }

      // Step 4 — ACCEPT WANT_OPEN
      out_decision.status    = ACCEPT;
      out_decision.action    = OPEN;
      out_decision.direction = policy_intent.direction;
      out_decision.volume    = policy_intent.volume;
      out_decision.symbol    = snapshot.market.symbol;
      out_decision.reason    = "OK";
      return;
   }

   if(policy_intent.type == WANT_CLOSE)
   {
      out_decision.status    = ACCEPT;
      out_decision.action    = CLOSE;
   
      // Lexicon: Decision.direction for CLOSE must be position direction
      out_decision.direction = snapshot.position.direction;
   
      out_decision.volume    = policy_intent.volume;
      out_decision.symbol    = snapshot.market.symbol;
      out_decision.reason    = "OK";
      return;
   }


   // Fallback (should be unreachable)
   out_decision.status = REJECT;
   out_decision.reason = "INVALID_INTENT";
}

#endif // __RISK_ARBITER_MQH__
