//+------------------------------------------------------------------+
//| Executor.mqh — Executor v1.0 (REAL)                               |
//| Stage 2: Real MT5 Execution (Decision v1.1)                       |
//| STRICT MQL5, no #pragma once                                      |
//+------------------------------------------------------------------+
#ifndef __EXECUTOR_MQH__
#define __EXECUTOR_MQH__

#include "../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Executor public entry point (FIXED CONTRACT)
//--------------------------------------------------------------------
void Executor_Run(
    const Decision &decision,
    ExecutionResult &out_result
)
{
   // Coordinator MUST NOT call Executor when decision.status == REJECT.
   // Executor uses Decision literally, without interpretation.

   MqlTradeRequest req;
   MqlTradeResult  res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_DEAL;
   req.symbol = decision.symbol;
   req.volume = decision.volume;

   // --- action + direction are used literally ---
   if(decision.action == OPEN)
   {
      if(decision.direction > 0)
         req.type = ORDER_TYPE_BUY;
      else
         req.type = ORDER_TYPE_SELL;
   }
   else // CLOSE
   {
      // CLOSE is executed literally.
      // No position inspection, no semantic correction.
      if(decision.direction > 0)
         req.type = ORDER_TYPE_BUY;
      else
         req.type = ORDER_TYPE_SELL;
   }

   // --- no price selection ---
   req.price = 0.0;

   // --- one attempt, no retry ---
   const bool ok = OrderSend(req, res);

   // Default factual state: not executed
   out_result.status        = FAILED;
   out_result.filled_volume = 0.0;
   out_result.price         = 0.0;

   if(!ok)
      return;

   const double filled = res.volume;
   const double price  = res.price;

   if(filled > 0.0)
   {
      out_result.filled_volume = filled;
      out_result.price         = price;

      if(filled == decision.volume)
         out_result.status = EXECUTED;
      else
         out_result.status = PARTIAL;
   }
   // else: remains FAILED
}

#endif // __EXECUTOR_MQH__
