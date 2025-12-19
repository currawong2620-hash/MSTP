//+------------------------------------------------------------------+
//| PositionPolicyManager_Scenario.mqh — PPM v0.1 (Scenario)          |
//| Strategy / Replaceable Roles                                      |
//| STRICT MQL5, no #pragma once                                      |
//| Scenario source: DummyStrategy_ScenarioCoverage_v0.1              |
//+------------------------------------------------------------------+
#ifndef __POSITION_POLICY_MANAGER_SCENARIO_MQH__
#define __POSITION_POLICY_MANAGER_SCENARIO_MQH__

//--------------------------------------------------------------------
// Allowed includes (contracts only)
//--------------------------------------------------------------------
#include "../../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// PositionPolicyManager_Run — public role contract (DO NOT CHANGE)
//--------------------------------------------------------------------
int PositionPolicyManager_Run(
   const Intent &intent,
   const Snapshot &snapshot,
   const Feedback &feedback,
   PolicyAdjustedIntent &out_policy_intents[]
)
{
   // feedback accepted for contract compliance only
   //(void)feedback;
   //(void)snapshot; // snapshot not used except for signature compliance

   // ALWAYS clear outputs first
   ArrayResize(out_policy_intents, 0);

   // Rule: NO_ACTION → 0 outputs
   if(intent.type == NO_ACTION)
      return 0;

   // Canonical scenario step:
   // encoded by DecisionMaker in Intent.confidence
   const int scenario_step = (int)(intent.confidence);

   // Scenario table (mechanical mapping)
   switch(scenario_step)
   {
      case 0:
         // NO_ACTION
         return 0;

      case 1:
         // WANT_OPEN → 1 output
         ArrayResize(out_policy_intents, 1);
         out_policy_intents[0].type      = intent.type;
         out_policy_intents[0].direction = intent.direction;
         out_policy_intents[0].volume    = 0.10;
         out_policy_intents[0].tag       = "POLICY_SINGLE";
         return 1;

      case 2:
         // WANT_HOLD → 0 outputs
         return 0;

      case 3:
         // WANT_CLOSE → 1 output
         ArrayResize(out_policy_intents, 1);
         out_policy_intents[0].type      = intent.type;
         out_policy_intents[0].direction = intent.direction;
         out_policy_intents[0].volume    = 0.00;
         out_policy_intents[0].tag       = "POLICY_CLOSE";
         return 1;

      case 4:
         // WANT_OPEN → 2 outputs
         ArrayResize(out_policy_intents, 2);

         out_policy_intents[0].type      = intent.type;
         out_policy_intents[0].direction = intent.direction;
         out_policy_intents[0].volume    = 0.05;
         out_policy_intents[0].tag       = "POLICY_MULTI_A";

         out_policy_intents[1].type      = intent.type;
         out_policy_intents[1].direction = intent.direction;
         out_policy_intents[1].volume    = 0.15;
         out_policy_intents[1].tag       = "POLICY_MULTI_B";

         return 2;

      case 5:
         // NO_ACTION
         return 0;

      case 6:
         // WANT_HOLD → 1 output
         ArrayResize(out_policy_intents, 1);
         out_policy_intents[0].type      = intent.type;
         out_policy_intents[0].direction = intent.direction;
         out_policy_intents[0].volume    = 0.20;
         out_policy_intents[0].tag       = "POLICY_MOD_VOL";
         return 1;

      case 7:
         // WANT_CLOSE → 1 output
         ArrayResize(out_policy_intents, 1);
         out_policy_intents[0].type      = intent.type;
         out_policy_intents[0].direction = intent.direction;
         out_policy_intents[0].volume    = 0.00;
         out_policy_intents[0].tag       = "POLICY_CLOSE_2";
         return 1;

      default:
         // Defensive fallback (out-of-range step)
         return 0;
   }
}

#endif // __POSITION_POLICY_MANAGER_SCENARIO_MQH__
