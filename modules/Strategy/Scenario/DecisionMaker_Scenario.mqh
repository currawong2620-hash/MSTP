//+------------------------------------------------------------------+
//| DecisionMaker_Scenario.mqh — DecisionMaker v0.1 (Scenario)        |
//| Strategy / Replaceable Roles                                      |
//| STRICT MQL5, no #pragma once                                      |
//| Scenario source: DummyStrategy_ScenarioCoverage_v0.1              |
//+------------------------------------------------------------------+
#ifndef __DECISION_MAKER_SCENARIO_MQH__
#define __DECISION_MAKER_SCENARIO_MQH__

//--------------------------------------------------------------------
// Allowed includes (contracts only)
//--------------------------------------------------------------------
#include "../../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Internal deterministic scenario state (ONLY this is allowed)
//--------------------------------------------------------------------
static int g_dm_scenario_step = 0;

//--------------------------------------------------------------------
// DecisionMaker_Run — public role contract (DO NOT CHANGE SIGNATURE)
//--------------------------------------------------------------------
void DecisionMaker_Run(
   const Snapshot &snapshot,
   const Feedback &feedback,
   Intent &out_intent
)
{
   // NOTE: feedback is accepted for contract compliance only.
   // It is NOT used for adaptation, pnl, or market logic.
   //(void)feedback;

   // Advance step only on new bar; otherwise repeat previous output.
   if(snapshot.time.is_new_bar)
      g_dm_scenario_step = (g_dm_scenario_step + 1) % 8;

   // Defaults: fixed confidence always
   out_intent.confidence = (double)g_dm_scenario_step + 0.50; // step encoded, keeps .50
   out_intent.direction  = 0;
   out_intent.type       = NO_ACTION;

   // Scenario table (mechanical mapping)
   switch(g_dm_scenario_step)
   {
      case 0:
         out_intent.type      = NO_ACTION;
         out_intent.direction = 0;
         break;

      case 1:
         out_intent.type      = WANT_OPEN;
         out_intent.direction = +1;
         break;

      case 2:
         out_intent.type      = WANT_HOLD;
         out_intent.direction = 0;
         break;

      case 3:
         out_intent.type      = WANT_CLOSE;
         out_intent.direction = 0;
         break;

      case 4:
         out_intent.type      = WANT_OPEN;
         out_intent.direction = -1;
         break;

      case 5:
         out_intent.type      = NO_ACTION;
         out_intent.direction = 0;
         break;

      case 6:
         out_intent.type      = WANT_HOLD;
         out_intent.direction = 0;
         break;

      case 7:
         out_intent.type      = WANT_CLOSE;
         out_intent.direction = 0;
         break;

      default:
         // Defensive: keep NO_ACTION
         out_intent.type      = NO_ACTION;
         out_intent.direction = 0;
         break;
   }

   // Validity rule: prevent logically impossible WANT_OPEN when already in position
   if(snapshot.position.has_position && out_intent.type == WANT_OPEN)
   {
      out_intent.type      = WANT_HOLD;
      out_intent.direction = 0;
   }
}

#endif // __DECISION_MAKER_SCENARIO_MQH__
