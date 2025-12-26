//+------------------------------------------------------------------+
//| DecisionMaker.mqh                                                 |
//| DecisionMaker — ReferenceTrendBreak (Directional Intent)          |
//| STRICT MQL5                                                       |
//+------------------------------------------------------------------+
#ifndef __DECISIONMAKER_MQH__
#define __DECISIONMAKER_MQH__

#include "../Infrastructure/ArchitectureTypes.mqh"

void DecisionMaker_Run(
   const Snapshot &snapshot,
   const Feedback &feedback,
   Intent &out_intent
)
{
   // Fully overwrite output (default = NO_ACTION)
   out_intent.type       = NO_ACTION;
   out_intent.direction  = 0;
   out_intent.confidence = 0.0;

   // feedback is contract-only; must not be read

   // Base gate: only act on new bar and only when no position exists
   if(!snapshot.time.is_new_bar)
      return;

   if(snapshot.position.has_position)
      return;

   const double c0 = snapshot.market.last_closes[0];
   const double c1 = snapshot.market.last_closes[1];
   const double c2 = snapshot.market.last_closes[2];

   // CONTRARIAN logic:
   // 3 bars up   → SELL
   // 3 bars down → BUY
   
   if(c0 > c1 && c1 > c2)
   {
      out_intent.type       = WANT_OPEN;
      out_intent.direction  = -1; // SELL against up-move
      out_intent.confidence = 1.0;
      return;
   }
   
   if(c0 < c1 && c1 < c2)
   {
      out_intent.type       = WANT_OPEN;
      out_intent.direction  = +1; // BUY against down-move
      out_intent.confidence = 1.0;
      return;
   }


   // Otherwise remain NO_ACTION (already set)
}

#endif // __DECISIONMAKER_MQH__
