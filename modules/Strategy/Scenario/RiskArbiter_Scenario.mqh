//+------------------------------------------------------------------+
//| RiskArbiter_Scenario.mqh — RiskArbiter v0.1 (Scenario)            |
//| Strategy / Replaceable Roles                                      |
//| STRICT MQL5, no #pragma once                                      |
//| Scenario source: DummyStrategy_ScenarioCoverage_v0.1              |
//+------------------------------------------------------------------+
#ifndef __RISK_ARBITER_SCENARIO_MQH__
#define __RISK_ARBITER_SCENARIO_MQH__

//--------------------------------------------------------------------
// Allowed includes (contracts only)
//--------------------------------------------------------------------
#include "../../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// RiskArbiter_Run — public role contract (DO NOT CHANGE SIGNATURE)
//--------------------------------------------------------------------
void RiskArbiter_Run(
   const PolicyAdjustedIntent &policy_intent,
   const Snapshot &snapshot,
   Decision &out_decision
)
{
   // snapshot accepted for signature compliance only
   //(void)snapshot;

   // Default defensive values
   out_decision.status = REJECT;
   out_decision.volume = 0.0;
   out_decision.reason = "UNKNOWN_POLICY_TAG";

   // Scenario dispatch strictly by policy_intent.tag
   if(policy_intent.tag == "POLICY_SINGLE")
   {
      out_decision.status = ACCEPT;
      out_decision.volume = policy_intent.volume;
      out_decision.reason = "OK";
      return;
   }

   if(policy_intent.tag == "POLICY_CLOSE")
   {
      out_decision.status = REJECT;
      out_decision.volume = 0.0;
      out_decision.reason = "REJECT_SCENARIO";
      return;
   }

   if(policy_intent.tag == "POLICY_MULTI_A")
   {
      out_decision.status = MODIFY;
      out_decision.volume = policy_intent.volume * 0.50;
      out_decision.reason = "MODIFY_HALF";
      return;
   }

   if(policy_intent.tag == "POLICY_MULTI_B")
   {
      out_decision.status = ACCEPT;
      out_decision.volume = policy_intent.volume;
      out_decision.reason = "OK_2";
      return;
   }

   if(policy_intent.tag == "POLICY_MOD_VOL")
   {
      out_decision.status = ACCEPT;
      out_decision.volume = policy_intent.volume;
      out_decision.reason = "OK_HOLD";
      return;
   }

   if(policy_intent.tag == "POLICY_CLOSE_2")
   {
      out_decision.status = MODIFY;
      out_decision.volume = 0.01;
      out_decision.reason = "MODIFY_FIXED";
      return;
   }

   // Defensive fallback already set above
}

#endif // __RISK_ARBITER_SCENARIO_MQH__
