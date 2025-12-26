//+------------------------------------------------------------------+
//| TC_PositionPolicyManager_TrailingTests.mqh                        |
//| Acceptance Tests — PositionPolicyManager v2.2 (Trailing Stop)     |
//| Snapshot-based (REV1, Audit-approved)                             |
//| STRICT MQL5, no #pragma once                                      |
//+------------------------------------------------------------------+
#ifndef __TC_POSITION_POLICY_MANAGER_TRAILING_TESTS_MQH__
#define __TC_POSITION_POLICY_MANAGER_TRAILING_TESTS_MQH__

#include "../../modules/Infrastructure/ArchitectureTypes.mqh"
#include "../../modules/Strategy/PositionPolicyManager.mqh"

//--------------------------------------------------------------------
// Explicit Non-Assertions (MANDATORY)
//
// Tests MUST NOT:
// - assert modification of Snapshot
// - assert mutation or persistence of trailing_stop_price
// - assume storage or update of trailing state inside PPM
// - assume Observer / Snapshot-producer behavior
//--------------------------------------------------------------------

//--------------------------------------------------------------------
// Fixed input assumptions (environment-coupled, per Master-Chat)
//
// PPM_TS_START_POINTS    = 20
// PPM_TS_DISTANCE_POINTS = 10
// PPM_TS_STEP_POINTS     = 5
//
// Tests MUST be run with the fixed .set / runner configuration.
//--------------------------------------------------------------------
static const int TS_START_POINTS = 20;

void InitLongPosition(
   Snapshot &s,
   const double entry,
   const double bid,
   const double ps,
   const double trailing_price
)
{
   s.position.has_position        = true;
   s.position.direction           = 1;
   s.position.volume              = 1.0;
   s.position.entry_price         = entry;
   s.position.trailing_stop_price = trailing_price;

   s.market.point_size = ps;
   s.market.bid        = bid;
   s.market.ask        = bid + ps;
}

void InitShortPosition(
   Snapshot &s,
   const double entry,
   const double ask,
   const double ps,
   const double trailing_price
)
{
   s.position.has_position        = true;
   s.position.direction           = -1;
   s.position.volume              = 1.0;
   s.position.entry_price         = entry;
   s.position.trailing_stop_price = trailing_price;

   s.market.point_size = ps;
   s.market.ask        = ask;
   s.market.bid        = ask - ps;
}


//====================================================================
// TESTS — PositionPolicyManager v2.2 Trailing (REV1)
//====================================================================

//--------------------------------------------------------------------
// Group A — Activation (LONG)
//--------------------------------------------------------------------
bool PPM2_TS_1_TrailingNotActiveBeforeStart_LONG()
{
   const string id = "PPM2-TS-1"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double bid   = entry + (TS_START_POINTS - 1) * ps;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitLongPosition(s, entry, bid, ps, 0.0);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!PPM_Assert(id, c == 0, "Expected no output before trailing activation"))
      return(false);

   PPM_Test_Pass(id);
   return(true);
}

bool PPM2_TS_2_ActivationThresholdReached_LONG()
{
   const string id = "PPM2-TS-2"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double bid   = entry + TS_START_POINTS * ps;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitLongPosition(s, entry, bid, ps, 0.0);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!PPM_Assert(id, c == 0,
                  "Expected no output at activation threshold without trailing fact"))
      return(false);

   PPM_Test_Pass(id);
   return(true);
}

//--------------------------------------------------------------------
// Group B — Hit / No-hit (LONG)
//--------------------------------------------------------------------
bool PPM2_TS_3_TrailingHitExits_LONG()
{
   const string id = "PPM2-TS-3"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double ts    = 1.1990;
   const double bid   = ts;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitLongPosition(s, entry, bid, ps, ts);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!CheckExit(id, s, out, c)) return(false);

   PPM_Test_Pass(id);
   return(true);
}

bool PPM2_TS_4_AboveTrailingNoExit_LONG()
{
   const string id = "PPM2-TS-4"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double ts    = 1.1990;
   const double bid   = ts + ps;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitLongPosition(s, entry, bid, ps, ts);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!PPM_Assert(id, c == 0,
                  "Expected no output when price above trailing stop"))
      return(false);

   PPM_Test_Pass(id);
   return(true);
}

//--------------------------------------------------------------------
// Group C — SHORT mirror
//--------------------------------------------------------------------
bool PPM2_TS_5_TrailingNotActiveBeforeStart_SHORT()
{
   const string id = "PPM2-TS-5"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double ask   = entry - (TS_START_POINTS - 1) * ps;
   // profit = entry - ask < TS_START_POINTS => trailing not active

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitShortPosition(s, entry, ask, ps, 0.0);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!PPM_Assert(id, c == 0,
                  "Expected no output before trailing activation (SHORT)"))
      return(false);

   PPM_Test_Pass(id);
   return(true);
}

bool PPM2_TS_6_TrailingHitExits_SHORT()
{
   const string id = "PPM2-TS-6"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double ts    = 1.2010;
   const double ask   = ts;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitShortPosition(s, entry, ask, ps, ts);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!CheckExit(id, s, out, c)) return(false);

   PPM_Test_Pass(id);
   return(true);
}

bool PPM2_TS_7_BelowTrailingNoExit_SHORT()
{
   const string id = "PPM2-TS-7"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double ts    = 1.2010;
   const double ask   = ts - ps;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitShortPosition(s, entry, ask, ps, ts);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!PPM_Assert(id, c == 0,
                  "Expected no output when price below trailing stop (SHORT)"))
      return(false);

   PPM_Test_Pass(id);
   return(true);
}

//--------------------------------------------------------------------
// Group D — Exit overrides intent
//--------------------------------------------------------------------
bool PPM2_TS_8_TrailingHitOverridesOpen()
{
   const string id = "PPM2-TS-8"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double ts    = 1.1990;
   const double bid   = ts;

   InitIntent(WANT_OPEN, 1, i);
   InitFeedback(f);
   InitLongPosition(s, entry, bid, ps, ts);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!CheckExit(id, s, out, c)) return(false);

   PPM_Test_Pass(id);
   return(true);
}

bool PPM2_TS_9_TrailingHitOverridesClose()
{
   const string id = "PPM2-TS-9"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double ts    = 1.1990;
   const double bid   = ts;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitLongPosition(s, entry, bid, ps, ts);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);
   if(!CheckExit(id, s, out, c)) return(false);

   PPM_Test_Pass(id);
   return(true);
}

//--------------------------------------------------------------------
// Group E — Interaction with SL / TP (regression)
//--------------------------------------------------------------------
bool PPM2_TS_10_SLHitExitsWithTrailingFacts()
{
   const string id = "PPM2-TS-10"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double bid   = entry - (double)PPM_SL_POINTS * ps;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitLongPosition(s, entry, bid, ps, 1.1995);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);

   if(PPM_SL_POINTS > 0)
   {
      if(!CheckExit(id, s, out, c)) return(false);
   }
   else
   {
      if(!PPM_Assert(id, c == 0,
                     "SL disabled: expected no output"))
         return(false);
   }

   PPM_Test_Pass(id);
   return(true);
}

bool PPM2_TS_11_TPHitExitsWithTrailingFacts()
{
   const string id = "PPM2-TS-11"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f; PolicyAdjustedIntent out[];
   const double ps    = 0.0001;
   const double entry = 1.2000;
   const double bid   = entry + (double)PPM_TP_POINTS * ps;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitLongPosition(s, entry, bid, ps, 1.1995);
   PPM_FillGarbage(out);

   const int c = PositionPolicyManager_Run(i, s, f, out);
   if(!PPM_CheckInvariant(id, out, c)) return(false);

   if(PPM_TP_POINTS > 0)
   {
      if(!CheckExit(id, s, out, c)) return(false);
   }
   else
   {
      if(!PPM_Assert(id, c == 0,
                     "TP disabled: expected no output"))
         return(false);
   }

   PPM_Test_Pass(id);
   return(true);
}

//--------------------------------------------------------------------
// Group F — Determinism & Feedback
//--------------------------------------------------------------------
bool PPM2_TS_12_DeterminismWithTrailingFacts()
{
   const string id = "PPM2-TS-12"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f;
   PolicyAdjustedIntent o1[], o2[];
   const double ps = 0.0001;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f);
   InitLongPosition(s, 1.2000, 1.1990, ps, 1.1990);

   PPM_FillGarbage(o1);
   PPM_FillGarbage(o2);

   const int c1 = PositionPolicyManager_Run(i, s, f, o1);
   const int c2 = PositionPolicyManager_Run(i, s, f, o2);

   if(!PPM_CheckInvariant(id, o1, c1)) return(false);
   if(!PPM_CheckInvariant(id, o2, c2)) return(false);

   if(!PPM_Assert(id, c1 == c2,
                  "Determinism: count mismatch"))
      return(false);

   if(c1 == 1)
   {
      if(!PPM_Assert(id, OutputsEqual(o1[0], o2[0]),
                     "Determinism: out[0] mismatch"))
         return(false);
   }

   PPM_Test_Pass(id);
   return(true);
}

bool PPM2_TS_13_FeedbackInertnessWithTrailingFacts()
{
   const string id = "PPM2-TS-13"; PPM_Test_Start(id);

   Snapshot s; Intent i; Feedback f1, f2;
   PolicyAdjustedIntent o1[], o2[];
   const double ps = 0.0001;

   InitIntent(WANT_CLOSE, 0, i);
   InitFeedback(f1);
   InitFeedback(f2);
   f2.pnl     = 777.0;
   f2.message = "DIFF";

   InitLongPosition(s, 1.2000, 1.1990, ps, 1.1990);

   PPM_FillGarbage(o1);
   PPM_FillGarbage(o2);

   const int c1 = PositionPolicyManager_Run(i, s, f1, o1);
   const int c2 = PositionPolicyManager_Run(i, s, f2, o2);

   if(!PPM_CheckInvariant(id, o1, c1)) return(false);
   if(!PPM_CheckInvariant(id, o2, c2)) return(false);

   if(!PPM_Assert(id, c1 == c2,
                  "Feedback inertness: count mismatch"))
      return(false);

   if(c1 == 1)
   {
      if(!PPM_Assert(id, OutputsEqual(o1[0], o2[0]),
                     "Feedback inertness: out[0] mismatch"))
         return(false);
   }

   PPM_Test_Pass(id);
   return(true);
}

//--------------------------------------------------------------------
// Suite entry
//--------------------------------------------------------------------
bool TestSuite_PositionPolicyManager_Trailing()
{
   bool ok = true;

   ok = (PPM2_TS_1_TrailingNotActiveBeforeStart_LONG()  && ok);
   ok = (PPM2_TS_2_ActivationThresholdReached_LONG()    && ok);

   ok = (PPM2_TS_3_TrailingHitExits_LONG()              && ok);
   ok = (PPM2_TS_4_AboveTrailingNoExit_LONG()           && ok);

   ok = (PPM2_TS_5_TrailingNotActiveBeforeStart_SHORT() && ok);
   ok = (PPM2_TS_6_TrailingHitExits_SHORT()             && ok);
   ok = (PPM2_TS_7_BelowTrailingNoExit_SHORT()          && ok);

   ok = (PPM2_TS_8_TrailingHitOverridesOpen()           && ok);
   ok = (PPM2_TS_9_TrailingHitOverridesClose()          && ok);

   ok = (PPM2_TS_10_SLHitExitsWithTrailingFacts()       && ok);
   ok = (PPM2_TS_11_TPHitExitsWithTrailingFacts()       && ok);

   ok = (PPM2_TS_12_DeterminismWithTrailingFacts()      && ok);
   ok = (PPM2_TS_13_FeedbackInertnessWithTrailingFacts()&& ok);

   return(ok);
}

#endif // __TC_POSITION_POLICY_MANAGER_TRAILING_TESTS_MQH__
