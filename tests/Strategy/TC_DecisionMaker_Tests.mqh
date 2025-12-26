//+------------------------------------------------------------------+
//| TC_DecisionMaker_Tests.mqh                                        |
//| DecisionMaker — ReferenceTrendBreak — Acceptance Tests            |
//| STRICT MQL5                                                       |
//+------------------------------------------------------------------+
#ifndef __TC_DECISIONMAKER_TESTS_MQH__
#define __TC_DECISIONMAKER_TESTS_MQH__

#include "../../modules/Strategy/DecisionMaker.mqh"
#include "../../modules/Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Helpers
//--------------------------------------------------------------------
void DM_Fail(bool &ok, const string msg)
{
   ok = false;
   PrintFormat("[DM-TEST][FAIL] %s", msg);
}

void DM_AssertTrue(bool &ok, const bool cond, const string msg)
{
   if(!cond)
      DM_Fail(ok, msg);
}

void DM_AssertIntEq(bool &ok, const int got, const int exp, const string msg)
{
   if(got != exp)
      DM_Fail(ok, StringFormat("%s (got=%d expected=%d)", msg, got, exp));
}

void DM_AssertDblEq(bool &ok, const double got, const double exp, const string msg)
{
   if(got != exp)
      DM_Fail(ok, StringFormat("%s (got=%.10f expected=%.10f)", msg, got, exp));
}

//--------------------------------------------------------------------
// FULL Snapshot initialization (no ZeroMemory; safe for strings)
//--------------------------------------------------------------------
void DM_InitSnapshot(Snapshot &s)
{
   // --- market ---
   s.market.symbol      = "";
   s.market.tf          = 0;
   s.market.open        = 0.0;
   s.market.high        = 0.0;
   s.market.low         = 0.0;
   s.market.close       = 0.0;
   s.market.volume      = 0.0;
   s.market.bid         = 0.0;
   s.market.ask         = 0.0;
   s.market.spread      = 0.0;

   s.market.last_closes[0] = 0.0;
   s.market.last_closes[1] = 0.0;
   s.market.last_closes[2] = 0.0;

   // --- position ---
   s.position.has_position = false;
   s.position.direction    = 0;
   s.position.volume       = 0.0;
   s.position.entry_price  = 0.0;
   s.position.floating_pnl = 0.0;

   // --- time ---
   s.time.is_new_bar              = false;
   s.time.timestamp               = 0;
   s.time.bars_since_entry        = 0;
   s.time.bars_since_last_action  = 0;

   // --- constraints ---
   s.constraints.min_lot            = 0.0;
   s.constraints.lot_step           = 0.0;
   s.constraints.min_stop           = 0.0;
   s.constraints.is_trading_allowed = false;
}

//--------------------------------------------------------------------
// Junk Intent init — enforces full overwrite by DecisionMaker
//--------------------------------------------------------------------
void DM_InitIntentJunk(Intent &i)
{
   i.type       = WANT_CLOSE;   // forbidden output for DM
   i.direction  = 123;
   i.confidence = -1.0;
}

//--------------------------------------------------------------------
// Feedback
//--------------------------------------------------------------------
void DM_InitFeedbackA(Feedback &f)
{
   f.event   = ACTION_REJECTED;
   f.pnl     = 0.0;
   f.message = "";
}

void DM_InitFeedbackB(Feedback &f)
{
   f.event   = POSITION_OPENED;
   f.pnl     = 123.45;
   f.message = "DIFF";
}

//--------------------------------------------------------------------
// Intent invariants (checked in EVERY test)
//--------------------------------------------------------------------
void DM_AssertIntentInvariant(bool &ok, const Intent &i)
{
   DM_AssertTrue(ok,
      (i.type == NO_ACTION || i.type == WANT_OPEN),
      "Intent.type must be NO_ACTION or WANT_OPEN");

   DM_AssertTrue(ok,
      (i.type != WANT_CLOSE),
      "WANT_CLOSE must never be used");

   if(i.type == WANT_OPEN)
   {
      DM_AssertTrue(ok,
         (i.direction == +1 || i.direction == -1),
         "WANT_OPEN direction must be +1 or -1");

      DM_AssertDblEq(ok, i.confidence, 1.0, "WANT_OPEN confidence must be 1.0");
   }
   else
   {
      DM_AssertIntEq(ok, i.direction, 0, "NO_ACTION direction must be 0");
      DM_AssertDblEq(ok, i.confidence, 0.0, "NO_ACTION confidence must be 0.0");
   }
}

//--------------------------------------------------------------------
// Prototypes
//--------------------------------------------------------------------
void DM_1_Determinism(bool &ok);
void DM_2_NoAction_NotNewBar(bool &ok);
void DM_3_NoAction_PositionExists(bool &ok);
void DM_4_LongSignal(bool &ok);
void DM_5_ShortSignal(bool &ok);
void DM_6_NoAction_NonStrict(bool &ok);
void DM_7_FeedbackInert(bool &ok);

//--------------------------------------------------------------------
// Suite entry
//--------------------------------------------------------------------
void TestSuite_DecisionMaker()
{
   Print("[DM-TEST] START");

   bool ok = true;

   DM_1_Determinism(ok);
   DM_2_NoAction_NotNewBar(ok);
   DM_3_NoAction_PositionExists(ok);
   DM_4_LongSignal(ok);
   DM_5_ShortSignal(ok);
   DM_6_NoAction_NonStrict(ok);
   DM_7_FeedbackInert(ok);

   if(ok)
      Print("[DM-TEST] PASSED");
}

//--------------------------------------------------------------------
// DM-1 — Determinism
//--------------------------------------------------------------------
void DM_1_Determinism(bool &ok)
{
   Snapshot s;
   Feedback f1, f2;
   Intent i1, i2;

   DM_InitSnapshot(s);
   s.time.is_new_bar        = true;
   s.position.has_position = false;
   s.market.last_closes[0] = 3.0;
   s.market.last_closes[1] = 2.0;
   s.market.last_closes[2] = 1.0;

   DM_InitFeedbackA(f1);
   DM_InitFeedbackB(f2);

   DM_InitIntentJunk(i1);
   DM_InitIntentJunk(i2);

   DecisionMaker_Run(s, f1, i1);
   DecisionMaker_Run(s, f2, i2);

   DM_AssertIntentInvariant(ok, i1);
   DM_AssertIntentInvariant(ok, i2);

   DM_AssertIntEq(ok, i1.type, i2.type, "DM-1 type determinism");
   DM_AssertIntEq(ok, i1.direction, i2.direction, "DM-1 direction determinism");
   DM_AssertDblEq(ok, i1.confidence, i2.confidence, "DM-1 confidence determinism");
}

//--------------------------------------------------------------------
// DM-2 — NO_ACTION if not new bar
//--------------------------------------------------------------------
void DM_2_NoAction_NotNewBar(bool &ok)
{
   Snapshot s;
   Feedback f;
   Intent i;

   DM_InitSnapshot(s);
   s.time.is_new_bar        = false;
   s.position.has_position = false;
   s.market.last_closes[0] = 3.0;
   s.market.last_closes[1] = 2.0;
   s.market.last_closes[2] = 1.0;

   DM_InitFeedbackA(f);
   DM_InitIntentJunk(i);

   DecisionMaker_Run(s, f, i);
   DM_AssertIntentInvariant(ok, i);
   DM_AssertIntEq(ok, i.type, NO_ACTION, "DM-2 must be NO_ACTION");
}

//--------------------------------------------------------------------
// DM-3 — NO_ACTION if position exists
//--------------------------------------------------------------------
void DM_3_NoAction_PositionExists(bool &ok)
{
   Snapshot s;
   Feedback f;
   Intent i;

   DM_InitSnapshot(s);
   s.time.is_new_bar        = true;
   s.position.has_position = true;
   s.market.last_closes[0] = 3.0;
   s.market.last_closes[1] = 2.0;
   s.market.last_closes[2] = 1.0;

   DM_InitFeedbackA(f);
   DM_InitIntentJunk(i);

   DecisionMaker_Run(s, f, i);
   DM_AssertIntentInvariant(ok, i);
   DM_AssertIntEq(ok, i.type, NO_ACTION, "DM-3 must be NO_ACTION");
}

//--------------------------------------------------------------------
// DM-4 — LONG signal
//--------------------------------------------------------------------
void DM_4_LongSignal(bool &ok)
{
   Snapshot s;
   Feedback f;
   Intent i;

   DM_InitSnapshot(s);
   s.time.is_new_bar        = true;
   s.position.has_position = false;
   s.market.last_closes[0] = 3.0;
   s.market.last_closes[1] = 2.0;
   s.market.last_closes[2] = 1.0;

   DM_InitFeedbackA(f);
   DM_InitIntentJunk(i);

   DecisionMaker_Run(s, f, i);
   DM_AssertIntentInvariant(ok, i);

   DM_AssertIntEq(ok, i.type, WANT_OPEN, "DM-4 type");
   DM_AssertIntEq(ok, i.direction, +1, "DM-4 direction");
   DM_AssertDblEq(ok, i.confidence, 1.0, "DM-4 confidence");
}

//--------------------------------------------------------------------
// DM-5 — SHORT signal
//--------------------------------------------------------------------
void DM_5_ShortSignal(bool &ok)
{
   Snapshot s;
   Feedback f;
   Intent i;

   DM_InitSnapshot(s);
   s.time.is_new_bar        = true;
   s.position.has_position = false;
   s.market.last_closes[0] = 1.0;
   s.market.last_closes[1] = 2.0;
   s.market.last_closes[2] = 3.0;

   DM_InitFeedbackA(f);
   DM_InitIntentJunk(i);

   DecisionMaker_Run(s, f, i);
   DM_AssertIntentInvariant(ok, i);

   DM_AssertIntEq(ok, i.type, WANT_OPEN, "DM-5 type");
   DM_AssertIntEq(ok, i.direction, -1, "DM-5 direction");
   DM_AssertDblEq(ok, i.confidence, 1.0, "DM-5 confidence");
}

//--------------------------------------------------------------------
// DM-6 — NO_ACTION on non-strict sequences
//--------------------------------------------------------------------
void DM_6_NoAction_NonStrict(bool &ok)
{
   double cases[4][3] =
   {
      {2.0, 2.0, 1.0},
      {3.0, 2.0, 2.0},
      {2.0, 3.0, 1.0},
      {1.0, 3.0, 2.0}
   };

   for(int k=0; k<4; k++)
   {
      Snapshot s;
      Feedback f;
      Intent i;

      DM_InitSnapshot(s);
      s.time.is_new_bar        = true;
      s.position.has_position = false;
      s.market.last_closes[0] = cases[k][0];
      s.market.last_closes[1] = cases[k][1];
      s.market.last_closes[2] = cases[k][2];

      DM_InitFeedbackA(f);
      DM_InitIntentJunk(i);

      DecisionMaker_Run(s, f, i);
      DM_AssertIntentInvariant(ok, i);
      DM_AssertIntEq(ok, i.type, NO_ACTION, "DM-6 must be NO_ACTION");
   }
}

//--------------------------------------------------------------------
// DM-7 — Feedback inert
//--------------------------------------------------------------------
void DM_7_FeedbackInert(bool &ok)
{
   Snapshot s;
   Feedback f1, f2;
   Intent i1, i2;

   DM_InitSnapshot(s);
   s.time.is_new_bar        = true;
   s.position.has_position = false;
   s.market.last_closes[0] = 3.0;
   s.market.last_closes[1] = 2.0;
   s.market.last_closes[2] = 1.0;

   DM_InitFeedbackA(f1);
   DM_InitFeedbackB(f2);

   DM_InitIntentJunk(i1);
   DM_InitIntentJunk(i2);

   DecisionMaker_Run(s, f1, i1);
   DecisionMaker_Run(s, f2, i2);

   DM_AssertIntentInvariant(ok, i1);
   DM_AssertIntentInvariant(ok, i2);

   DM_AssertIntEq(ok, i1.type, i2.type, "DM-7 type");
   DM_AssertIntEq(ok, i1.direction, i2.direction, "DM-7 direction");
   DM_AssertDblEq(ok, i1.confidence, i2.confidence, "DM-7 confidence");
}

#endif // __TC_DECISIONMAKER_TESTS_MQH__
