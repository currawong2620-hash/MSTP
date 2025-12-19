//+------------------------------------------------------------------+
//| FeedbackSource_Minimal.mqh — FeedbackSource minimal stub          |
//| Infrastructure support for scenario build                          |
//| STRICT MQL5, no #pragma once                                      |
//+------------------------------------------------------------------+
#ifndef __FEEDBACK_SOURCE_MINIMAL_MQH__
#define __FEEDBACK_SOURCE_MINIMAL_MQH__

#include "../../Infrastructure/ArchitectureTypes.mqh"

void FeedbackSource_Run(
   const ExecutionResult &results[],
   const int results_count,
   Feedback &out_feedback
)
{
   ZeroMemory(out_feedback);

   if(results_count > 0)
   {
      // Any executed attempt -> opened (simplified)
      out_feedback.event = POSITION_OPENED;
      out_feedback.pnl = 0.0;
      out_feedback.message = "RESULTS_PRESENT";
      return;
   }

   // No results -> rejected/empty (simplified)
   out_feedback.event = ACTION_REJECTED;
   out_feedback.pnl = 0.0;
   out_feedback.message = "NO_RESULTS";
}

#endif // __FEEDBACK_SOURCE_MINIMAL_MQH__
