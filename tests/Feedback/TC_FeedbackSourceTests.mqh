//+------------------------------------------------------------------+
//| TC_FeedbackSource_Tests.mqh                                       |
//| FeedbackSource v1.0 — Acceptance Test Suite                       |
//| STRICT MQL5                                                       |
//+------------------------------------------------------------------+

#ifndef __TC_FEEDBACK_SOURCE_TESTS_MQH__
#define __TC_FEEDBACK_SOURCE_TESTS_MQH__

#include "../../modules/Infrastructure/ArchitectureTypes.mqh"
#include "../../modules/Feedback/FeedbackSource.mqh"

//--------------------------------------------------------------------
// Internal helpers (local to test file)
//--------------------------------------------------------------------
bool FS_CheckEventEnum(const feedback_event ev)
{
   return (ev == POSITION_OPENED ||
           ev == POSITION_CLOSED ||
           ev == STOP_HIT ||
           ev == TARGET_HIT ||
           ev == ACTION_REJECTED);
}

bool FS_FeedbackEqual(const Feedback &a, const Feedback &b)
{
   if(a.event   != b.event)   return false;
   if(a.pnl     != b.pnl)     return false;
   if(a.message != b.message) return false;
   return true;
}

//--------------------------------------------------------------------
// FS-1 — Memory overwrite invariant
//--------------------------------------------------------------------
bool FS_1_MemoryOverwrite()
{
   Feedback f;
   f.event   = POSITION_CLOSED;
   f.pnl     = 999.99;
   f.message = "JUNK";

   ExecutionResult results[];
   ArrayResize(results, 0);

   FeedbackSource_Run(results, 0, f);

   if(f.event != ACTION_REJECTED)  return false;
   if(f.pnl != 0.0)                return false;
   if(f.message != "NO_EXECUTION") return false;
   if(!FS_CheckEventEnum(f.event)) return false;

   return true;
}

//--------------------------------------------------------------------
// FS-2 — Empty execution set (semantic)
//--------------------------------------------------------------------
bool FS_2_EmptySet()
{
   Feedback f;
   f.event   = STOP_HIT;
   f.pnl     = -123.45;
   f.message = "XXX";

   ExecutionResult results[];
   ArrayResize(results, 0);

   FeedbackSource_Run(results, 0, f);

   if(f.event != ACTION_REJECTED)  return false;
   if(f.message != "NO_EXECUTION") return false;
   if(!FS_CheckEventEnum(f.event)) return false;

   return true;
}

//--------------------------------------------------------------------
// FS-3 — Single EXECUTED result
//--------------------------------------------------------------------
bool FS_3_SingleExecuted()
{
   Feedback f;
   f.event   = ACTION_REJECTED;
   f.pnl     = 777.0;
   f.message = "GARBAGE";

   ExecutionResult results[];
   ArrayResize(results, 1);
   results[0].status = EXECUTED;

   FeedbackSource_Run(results, 1, f);

   if(f.event == ACTION_REJECTED)  return false;
   if(f.message == "")             return false;
   if(!FS_CheckEventEnum(f.event)) return false;

   return true;
}

//--------------------------------------------------------------------
// FS-4 — Mixed results (EXECUTED + FAILED)
//--------------------------------------------------------------------
bool FS_4_MixedResults()
{
   Feedback f;
   f.event   = ACTION_REJECTED;
   f.pnl     = 1.0;
   f.message = "TMP";

   ExecutionResult results[];
   ArrayResize(results, 2);
   results[0].status = FAILED;
   results[1].status = EXECUTED;

   FeedbackSource_Run(results, 2, f);

   if(f.event == ACTION_REJECTED)  return false;
   if(f.message == "")             return false;
   if(!FS_CheckEventEnum(f.event)) return false;

   return true;
}

//--------------------------------------------------------------------
// FS-5 — All FAILED / REJECTED
//--------------------------------------------------------------------
bool FS_5_AllFailed()
{
   Feedback f;
   f.event   = POSITION_OPENED;
   f.pnl     = 55.5;
   f.message = "OLD";

   ExecutionResult results[];
   ArrayResize(results, 2);
   results[0].status = FAILED;
   results[1].status = REJECTED;

   FeedbackSource_Run(results, 2, f);

   if(f.event != ACTION_REJECTED)  return false;
   if(f.message == "")             return false; // invariant: message overwritten
   if(!FS_CheckEventEnum(f.event)) return false;

   return true;
}

//--------------------------------------------------------------------
// FS-6 — Determinism
//--------------------------------------------------------------------
bool FS_6_Determinism()
{
   ExecutionResult results[];
   ArrayResize(results, 1);
   results[0].status = EXECUTED;

   Feedback f1;
   f1.event   = STOP_HIT;
   f1.pnl     = 1.1;
   f1.message = "AAA";

   Feedback f2;
   f2.event   = POSITION_CLOSED;
   f2.pnl     = -9.9;
   f2.message = "BBB";

   FeedbackSource_Run(results, 1, f1);
   FeedbackSource_Run(results, 1, f2);

   if(f1.event == ACTION_REJECTED)  return false;
   if(f1.message == "")             return false;
   if(!FS_CheckEventEnum(f1.event)) return false;

   return FS_FeedbackEqual(f1, f2);
}

//--------------------------------------------------------------------
// FS-7 — Order independence
//--------------------------------------------------------------------
bool FS_7_OrderIndependence()
{
   ExecutionResult r1[];
   ArrayResize(r1, 3);
   r1[0].status = FAILED;
   r1[1].status = EXECUTED;
   r1[2].status = REJECTED;

   ExecutionResult r2[];
   ArrayResize(r2, 3);
   r2[0].status = EXECUTED;
   r2[1].status = REJECTED;
   r2[2].status = FAILED;

   Feedback f1;
   f1.event   = STOP_HIT;
   f1.pnl     = 10.0;
   f1.message = "X";

   Feedback f2;
   f2.event   = TARGET_HIT;
   f2.pnl     = -10.0;
   f2.message = "Y";

   FeedbackSource_Run(r1, 3, f1);
   FeedbackSource_Run(r2, 3, f2);

   if(f1.event == ACTION_REJECTED)  return false;
   if(f1.message == "")             return false;
   if(!FS_CheckEventEnum(f1.event)) return false;

   return FS_FeedbackEqual(f1, f2);
}

//--------------------------------------------------------------------
// Test runner
//--------------------------------------------------------------------
bool TestSuite_FeedbackSource()
{
   Print("[FS-TEST] START");

   if(!FS_1_MemoryOverwrite())   { Print("[FS-TEST][FAIL] FS-1"); return false; }
   if(!FS_2_EmptySet())          { Print("[FS-TEST][FAIL] FS-2"); return false; }
   if(!FS_3_SingleExecuted())    { Print("[FS-TEST][FAIL] FS-3"); return false; }
   if(!FS_4_MixedResults())      { Print("[FS-TEST][FAIL] FS-4"); return false; }
   if(!FS_5_AllFailed())         { Print("[FS-TEST][FAIL] FS-5"); return false; }
   if(!FS_6_Determinism())       { Print("[FS-TEST][FAIL] FS-6"); return false; }
   if(!FS_7_OrderIndependence()) { Print("[FS-TEST][FAIL] FS-7"); return false; }

   Print("[FS-TEST] PASSED");
   return true;
}

#endif // __TC_FEEDBACK_SOURCE_TESTS_MQH__
