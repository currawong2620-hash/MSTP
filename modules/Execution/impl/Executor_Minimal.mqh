//+------------------------------------------------------------------+
//| Executor_Minimal.mqh — Executor minimal stub                      |
//| Infrastructure support for scenario build                          |
//| STRICT MQL5, no #pragma once                                      |
//+------------------------------------------------------------------+
#ifndef __EXECUTOR_MINIMAL_MQH__
#define __EXECUTOR_MINIMAL_MQH__

#include "../../Infrastructure/ArchitectureTypes.mqh"

void Executor_Run(
   const Decision &decision,
   ExecutionResult &out_result
)
{
   ZeroMemory(out_result);

   if(decision.status == ACCEPT || decision.status == MODIFY)
   {
      out_result.status = EXECUTED;
      out_result.filled_volume = decision.volume;
      out_result.price = 0.0;
      return;
   }

   // REJECT or unknown -> rejected execution
   out_result.status = REJECTED;
   out_result.filled_volume = 0.0;
   out_result.price = 0.0;
}

#endif // __EXECUTOR_MINIMAL_MQH__
