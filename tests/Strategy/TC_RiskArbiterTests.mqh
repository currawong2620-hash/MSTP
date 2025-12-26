//+------------------------------------------------------------------+
//| TC_RiskArbiterTests.mqh                                           |
//| RiskArbiter v1.0 — Acceptance Test Suite                          |
//| STRICT MQL5                                                       |
//+------------------------------------------------------------------+
#ifndef __TC_RISK_ARBITER_TESTS_MQH__
#define __TC_RISK_ARBITER_TESTS_MQH__

//--------------------------------------------------------------------
// Allowed includes ONLY
//--------------------------------------------------------------------
#include "../../modules/Strategy/RiskArbiter.mqh"
#include "../../modules/Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Local helpers (no global/static mutable state)
//--------------------------------------------------------------------
void RA_Fail(bool &ok, const string msg)
{
   ok = false;
   PrintFormat("[RA-TEST][FAIL] %s", msg);
}

void RA_AssertIntEq(bool &ok, const int got, const int exp, const string msg)
{
   if(got != exp)
      RA_Fail(ok, StringFormat("%s (got=%d expected=%d)", msg, got, exp));
}

void RA_AssertDblEqExact(bool &ok, const double got, const double exp, const string msg)
{
   if(got != exp)
      RA_Fail(ok, StringFormat("%s (got=%.16f expected=%.16f)", msg, got, exp));
}

void RA_AssertStrEq(bool &ok, const string got, const string exp, const string msg)
{
   if(got != exp)
      RA_Fail(ok, StringFormat("%s (got=%s expected=%s)", msg, got, exp));
}

void RA_AssertTrue(bool &ok, const bool cond, const string msg)
{
   if(!cond)
      RA_Fail(ok, msg);
}

void RA_InitSnapshot(Snapshot &s, const string symbol)
{
   // Must zero-fill everything we touch in tests; avoid ZeroMemory due to strings.
   // Snapshot fields not listed here are NOT used by RiskArbiter.
   s.market.symbol         = symbol;

   s.position.has_position = false;
   s.position.direction    = 0;
   s.position.volume       = 0.0;
   s.position.entry_price  = 0.0;
   s.position.floating_pnl = 0.0;
}

void RA_InitPolicyIntent(PolicyAdjustedIntent &pi)
{
   pi.type      = NO_ACTION;
   pi.direction = 0;
   pi.volume    = 0.0;
   pi.tag       = "";
}

void RA_AssertDecisionEq(bool &ok, const Decision &a, const Decision &b, const string msg_prefix)
{
   RA_AssertIntEq(ok, (int)a.status, (int)b.status, msg_prefix + ": status mismatch");
   RA_AssertIntEq(ok, (int)a.action, (int)b.action, msg_prefix + ": action mismatch");
   RA_AssertIntEq(ok, a.direction,   b.direction,   msg_prefix + ": direction mismatch");
   RA_AssertDblEqExact(ok, a.volume, b.volume,      msg_prefix + ": volume mismatch");
   RA_AssertStrEq(ok, a.symbol,      b.symbol,      msg_prefix + ": symbol mismatch");
   RA_AssertStrEq(ok, a.reason,      b.reason,      msg_prefix + ": reason mismatch");
}

//--------------------------------------------------------------------
// Prototypes
//--------------------------------------------------------------------
void RA_Test_Determinism(bool &ok);
void RA_Test_Accept_WantOpen(bool &ok);
void RA_Test_Accept_WantClose(bool &ok);
void RA_Test_Reject_InvalidIntentType(bool &ok);
void RA_Test_Reject_ZeroVolume(bool &ok);
void RA_Test_Reject_ZeroDirectionForOpen(bool &ok);
void RA_Test_TagMustNotAffectDecision(bool &ok);
void RA_Test_ModifyIsNeverUsed(bool &ok);

//--------------------------------------------------------------------
// Suite entry
//--------------------------------------------------------------------
void TestSuite_RiskArbiter()
{
   Print("[RA-TEST] START");

   bool ok = true;

   RA_Test_Determinism(ok);
   RA_Test_Accept_WantOpen(ok);
   RA_Test_Accept_WantClose(ok);
   RA_Test_Reject_InvalidIntentType(ok);
   RA_Test_Reject_ZeroVolume(ok);
   RA_Test_Reject_ZeroDirectionForOpen(ok);
   RA_Test_TagMustNotAffectDecision(ok);
   RA_Test_ModifyIsNeverUsed(ok);

   if(ok)
      Print("[RA-TEST] PASSED");
}

//--------------------------------------------------------------------
// RA-1 — Determinism
//--------------------------------------------------------------------
void RA_Test_Determinism(bool &ok)
{
   PolicyAdjustedIntent pi;
   RA_InitPolicyIntent(pi);

   pi.type      = WANT_OPEN;
   pi.direction = +1;
   pi.volume    = 0.10;
   pi.tag       = "ANY";

   Snapshot s;
   RA_InitSnapshot(s, "EURUSD");

   Decision d1;
   Decision d2;

   RiskArbiter_Run(pi, s, d1);
   RiskArbiter_Run(pi, s, d2);

   RA_AssertDecisionEq(ok, d1, d2, "RA-1 Determinism");

   RA_AssertTrue(ok, d1.status != MODIFY, "RA-1: status must not be MODIFY");
   RA_AssertTrue(ok, d1.symbol != "",     "RA-1: symbol must not be empty");
   RA_AssertStrEq(ok, d1.symbol, s.market.symbol, "RA-1: symbol must match snapshot");
}

//--------------------------------------------------------------------
// RA-2 — ACCEPT for WANT_OPEN
//--------------------------------------------------------------------
void RA_Test_Accept_WantOpen(bool &ok)
{
   PolicyAdjustedIntent pi;
   RA_InitPolicyIntent(pi);

   pi.type      = WANT_OPEN;
   pi.direction = +1;
   pi.volume    = 0.10;
   pi.tag       = "ANY";

   Snapshot s;
   RA_InitSnapshot(s, "EURUSD");

   Decision d;
   RiskArbiter_Run(pi, s, d);

   RA_AssertIntEq(ok, (int)d.status, (int)ACCEPT, "RA-2: status");
   RA_AssertIntEq(ok, (int)d.action, (int)OPEN,   "RA-2: action");
   RA_AssertIntEq(ok, d.direction,   +1,          "RA-2: direction");
   RA_AssertDblEqExact(ok, d.volume, 0.10,        "RA-2: volume");
   RA_AssertStrEq(ok, d.symbol,      "EURUSD",    "RA-2: symbol");
   RA_AssertStrEq(ok, d.reason,      "OK",        "RA-2: reason");

   RA_AssertTrue(ok, d.status != MODIFY, "RA-2: status must not be MODIFY");
}

//--------------------------------------------------------------------
// RA-3 — ACCEPT for WANT_CLOSE
//--------------------------------------------------------------------
void RA_Test_Accept_WantClose(bool &ok)
{
   PolicyAdjustedIntent pi;
   RA_InitPolicyIntent(pi);

   pi.type      = WANT_CLOSE;
   pi.direction = 0;
   pi.volume    = 0.10;
   pi.tag       = "ANY";

   Snapshot s;
   RA_InitSnapshot(s, "XAUUSD");

   Decision d;
   RiskArbiter_Run(pi, s, d);

   RA_AssertIntEq(ok, (int)d.status, (int)ACCEPT, "RA-3: status");
   RA_AssertIntEq(ok, (int)d.action, (int)CLOSE,  "RA-3: action");
   RA_AssertIntEq(ok, d.direction,   0,           "RA-3: direction");
   RA_AssertDblEqExact(ok, d.volume, 0.10,        "RA-3: volume");
   RA_AssertStrEq(ok, d.symbol,      "XAUUSD",    "RA-3: symbol");
   RA_AssertStrEq(ok, d.reason,      "OK",        "RA-3: reason");

   RA_AssertTrue(ok, d.status != MODIFY, "RA-3: status must not be MODIFY");
}

//--------------------------------------------------------------------
// RA-4 — REJECT invalid intent type
//--------------------------------------------------------------------
void RA_Test_Reject_InvalidIntentType(bool &ok)
{
   PolicyAdjustedIntent pi;
   RA_InitPolicyIntent(pi);

   pi.type = NO_ACTION;

   Snapshot s;
   RA_InitSnapshot(s, "EURUSD");

   Decision d;
   RiskArbiter_Run(pi, s, d);

   RA_AssertIntEq(ok, (int)d.status, (int)REJECT, "RA-4: status");
   RA_AssertStrEq(ok, d.reason, "INVALID_INTENT", "RA-4: reason");

   RA_AssertTrue(ok, d.status != MODIFY, "RA-4: status must not be MODIFY");
}

//--------------------------------------------------------------------
// RA-5 — REJECT zero volume
//--------------------------------------------------------------------
void RA_Test_Reject_ZeroVolume(bool &ok)
{
   PolicyAdjustedIntent pi;
   RA_InitPolicyIntent(pi);

   pi.type      = WANT_OPEN;
   pi.direction = +1;
   pi.volume    = 0.0;

   Snapshot s;
   RA_InitSnapshot(s, "EURUSD");

   Decision d;
   RiskArbiter_Run(pi, s, d);

   RA_AssertIntEq(ok, (int)d.status, (int)REJECT, "RA-5: status");
   RA_AssertStrEq(ok, d.reason, "INVALID_VOLUME", "RA-5: reason");

   RA_AssertTrue(ok, d.status != MODIFY, "RA-5: status must not be MODIFY");
}

//--------------------------------------------------------------------
// RA-6 — REJECT zero direction for OPEN
//--------------------------------------------------------------------
void RA_Test_Reject_ZeroDirectionForOpen(bool &ok)
{
   PolicyAdjustedIntent pi;
   RA_InitPolicyIntent(pi);

   pi.type      = WANT_OPEN;
   pi.direction = 0;
   pi.volume    = 0.10;

   Snapshot s;
   RA_InitSnapshot(s, "EURUSD");

   Decision d;
   RiskArbiter_Run(pi, s, d);

   RA_AssertIntEq(ok, (int)d.status, (int)REJECT, "RA-6: status");
   RA_AssertStrEq(ok, d.reason, "INVALID_DIRECTION", "RA-6: reason");

   RA_AssertTrue(ok, d.status != MODIFY, "RA-6: status must not be MODIFY");
}

//--------------------------------------------------------------------
// RA-7 — tag must NOT affect decision
//--------------------------------------------------------------------
void RA_Test_TagMustNotAffectDecision(bool &ok)
{
   PolicyAdjustedIntent a;
   PolicyAdjustedIntent b;
   RA_InitPolicyIntent(a);
   RA_InitPolicyIntent(b);

   a.type      = WANT_OPEN;
   a.direction = +1;
   a.volume    = 0.10;
   a.tag       = "TAG_A";

   b.type      = WANT_OPEN;
   b.direction = +1;
   b.volume    = 0.10;
   b.tag       = "TAG_B";

   Snapshot s;
   RA_InitSnapshot(s, "EURUSD");

   Decision d1;
   Decision d2;

   RiskArbiter_Run(a, s, d1);
   RiskArbiter_Run(b, s, d2);

   RA_AssertDecisionEq(ok, d1, d2, "RA-7 Tag invariance");

   RA_AssertTrue(ok, d1.status != MODIFY, "RA-7: status must not be MODIFY");
}

//--------------------------------------------------------------------
// RA-8 — MODIFY is never used
//--------------------------------------------------------------------
void RA_Test_ModifyIsNeverUsed(bool &ok)
{
   Snapshot s;
   RA_InitSnapshot(s, "EURUSD");

   {
      PolicyAdjustedIntent pi;
      RA_InitPolicyIntent(pi);
      pi.type      = WANT_OPEN;
      pi.direction = +1;
      pi.volume    = 0.10;

      Decision d;
      RiskArbiter_Run(pi, s, d);

      RA_AssertTrue(ok,
         d.status == ACCEPT || d.status == REJECT,
         "RA-8: status must be ACCEPT or REJECT");
      RA_AssertTrue(ok, d.status != MODIFY, "RA-8: MODIFY forbidden");
   }

   {
      PolicyAdjustedIntent pi;
      RA_InitPolicyIntent(pi);
      pi.type = NO_ACTION;

      Decision d;
      RiskArbiter_Run(pi, s, d);

      RA_AssertTrue(ok,
         d.status == ACCEPT || d.status == REJECT,
         "RA-8: status must be ACCEPT or REJECT");
      RA_AssertTrue(ok, d.status != MODIFY, "RA-8: MODIFY forbidden");
   }
}

#endif // __TC_RISK_ARBITER_TESTS_MQH__
