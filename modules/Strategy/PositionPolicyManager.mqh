//+------------------------------------------------------------------+
//| PositionPolicyManager.mqh                                         |
//| PositionPolicyManager v2.2 — Trailing Stop (Snapshot-based)       |
//| Stateless, deterministic, STRICT MQL5                             |
//| No #pragma once                                                   |
//+------------------------------------------------------------------+
#ifndef __POSITION_POLICY_MANAGER_MQH__
#define __POSITION_POLICY_MANAGER_MQH__

#include "../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Startup input parameters (immutable during run)
//--------------------------------------------------------------------
input int PPM_SL_POINTS = 0;
input int PPM_TP_POINTS = 0;

input int PPM_TS_START_POINTS    = 0;
input int PPM_TS_DISTANCE_POINTS = 0;
input int PPM_TS_STEP_POINTS     = 0;

//--------------------------------------------------------------------
// Baseline open volume (SSoT фиксировано Master-Chat)
//--------------------------------------------------------------------
static const double PPM_BASE_OPEN_VOLUME = 1.0;

//--------------------------------------------------------------------
// Internal helpers (file-local)
//--------------------------------------------------------------------
bool PPM_ShouldExit_Long(
   const Snapshot &snapshot,
   const double entry,
   const double ps
)
{
   const double bid = snapshot.market.bid;

   // A) SL
   if(PPM_SL_POINTS > 0)
   {
      const double sl = entry - (double)PPM_SL_POINTS * ps;
      if(bid <= sl)
         return(true);
   }

   // B) TP
   if(PPM_TP_POINTS > 0)
   {
      const double tp = entry + (double)PPM_TP_POINTS * ps;
      if(bid >= tp)
         return(true);
   }

   // C) Trailing (external fact; already active if >0)
   if(snapshot.position.trailing_stop_price > 0.0)
   {
      if(bid <= snapshot.position.trailing_stop_price)
         return(true);
   }

   return(false);
}

bool PPM_ShouldExit_Short(
   const Snapshot &snapshot,
   const double entry,
   const double ps
)
{
   const double ask = snapshot.market.ask;

   // A) SL
   if(PPM_SL_POINTS > 0)
   {
      const double sl = entry + (double)PPM_SL_POINTS * ps;
      if(ask >= sl)
         return(true);
   }

   // B) TP
   if(PPM_TP_POINTS > 0)
   {
      const double tp = entry - (double)PPM_TP_POINTS * ps;
      if(ask <= tp)
         return(true);
   }

   // C) Trailing (external fact; already active if >0)
   if(snapshot.position.trailing_stop_price > 0.0)
   {
      if(ask >= snapshot.position.trailing_stop_price)
         return(true);
   }

   return(false);
}

int PPM_EmitExit(
   const Snapshot &snapshot,
   PolicyAdjustedIntent &out_policy_intents[]
)
{
   ArrayResize(out_policy_intents, 1);
   out_policy_intents[0].type      = WANT_CLOSE;
   out_policy_intents[0].direction = 0;
   out_policy_intents[0].volume    = snapshot.position.volume;
   out_policy_intents[0].tag       = "POLICY_EXIT";
   return(1);
}

int PPM_EmitOpen(
   const Intent &intent,
   PolicyAdjustedIntent &out_policy_intents[]
)
{
   ArrayResize(out_policy_intents, 1);
   out_policy_intents[0].type      = WANT_OPEN;
   out_policy_intents[0].direction = intent.direction;
   out_policy_intents[0].volume    = PPM_BASE_OPEN_VOLUME;
   out_policy_intents[0].tag       = "POLICY_PASS";
   return(1);
}

//--------------------------------------------------------------------
// Role contract (FIXED, DO NOT CHANGE)
//--------------------------------------------------------------------
int PositionPolicyManager_Run(
   const Intent      &intent,
   const Snapshot    &snapshot,
   const Feedback    &feedback,
   PolicyAdjustedIntent &out_policy_intents[]
)
{
   // Invariant #1: always clear output
   ArrayResize(out_policy_intents, 0);

   // Invariant: feedback inertness (intentionally unused)

   // ----------------------------------------------------------------
   // 1) EXIT POLICY (absolute priority)
   // ----------------------------------------------------------------
   if(snapshot.position.has_position)
   {
      const int    dir   = snapshot.position.direction;   // +1 / -1
      const double entry = snapshot.position.entry_price;
      const double ps    = snapshot.market.point_size;

      bool exit_now = false;

      if(dir == 1)
         exit_now = PPM_ShouldExit_Long(snapshot, entry, ps);
      else if(dir == -1)
         exit_now = PPM_ShouldExit_Short(snapshot, entry, ps);

      if(exit_now)
         return(PPM_EmitExit(snapshot, out_policy_intents));
   }

   // ----------------------------------------------------------------
   // 2) INTENT FILTERING (only if exit did NOT trigger)
   // ----------------------------------------------------------------
   if(intent.type == NO_ACTION)
      return(0);

   if(intent.type == WANT_OPEN)
   {
      if(!snapshot.position.has_position)
      {
         if(intent.direction == 1 || intent.direction == -1)
            return(PPM_EmitOpen(intent, out_policy_intents));
      }
      return(0);
   }

   if(intent.type == WANT_CLOSE)
      return(0);

   // Defensive fallback: unknown intent suppressed
   return(0);
}

#endif // __POSITION_POLICY_MANAGER_MQH__
