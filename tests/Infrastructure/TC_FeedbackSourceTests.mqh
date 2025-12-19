//+------------------------------------------------------------------+
//| TC_FeedbackSourceTests.mqh — FeedbackSource v1.0 Test Suite       |
//| Contract & Invariant tests (FS-TEST-0.1, AUDIT-FIXED)             |
//| STRICT MQL5, no #pragma once                                      |
//+------------------------------------------------------------------+
#ifndef __TC_FEEDBACK_SOURCE_TESTS_MQH__
#define __TC_FEEDBACK_SOURCE_TESTS_MQH__

//--------------------------------------------------------------------
// Includes (NO MT5 TRADE / NO Snapshot / NO Coordinator)
//--------------------------------------------------------------------
#include "../../modules/Feedback/FeedbackSource.mqh"
#include "../../modules/Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Minimal local test helpers (self-contained)
//--------------------------------------------------------------------
static int g_fs_tests_total  = 0;
static int g_fs_tests_failed = 0;

void FS_AssertTrue(const bool cond, const string msg)
{
   g_fs_tests_total++;
   if(!cond)
   {
      g_fs_tests_failed++;
      PrintFormat("[FS-TEST][FAIL] %s", msg);
   }
}

void FS_AssertIntEq(const int a, const int b, const string msg)
{
   g_fs_tests_total++;
   if(a != b)
   {
      g_fs_tests_failed++;
      PrintFormat("[FS-TEST][FAIL] %s | got=%d expected=%d", msg, a, b);
   }
}

void FS_AssertDoubleEq(const double a, const double b, const string msg)
{
   g_fs_tests_total++;
   if(a != b)
   {
      g_fs_tests_failed++;
      PrintFormat("[FS-TEST][FAIL] %s | got=%.10f expected=%.10f", msg, a, b);
   }
}

void FS_AssertStringEq(const string a, const string b, const string msg)
{
   g_fs_tests_total++;
   if(a != b)
   {
      g_fs_tests_failed++;
      PrintFormat("[FS-TEST][FAIL] %s | got='%s' expected='%s'", msg, a, b);
   }
}

// Compare FULL Feedback (used only where explicitly allowed)
void FS_AssertFeedbackEq(const Feedback &a, const Feedback &b, const string tag)
{
   FS_AssertIntEq((int)a.event, (int)b.event, tag + ": event");
   FS_AssertDoubleEq(a.pnl, b.pnl, tag + ": pnl");
   FS_AssertStringEq(a.message, b.message, tag + ": message");
}

// Compare only event + pnl (safer, avoids message overfitting)
void FS_AssertFeedbackCoreEq(const Feedback &a, const Feedback &b, const string tag)
{
   FS_AssertIntEq((int)a.event, (int)b.event, tag + ": event");
   FS_AssertDoubleEq(a.pnl, b.pnl, tag + ": pnl");
}

//--------------------------------------------------------------------
// Required test identifiers (DO NOT RENAME)
//--------------------------------------------------------------------
void FS_Test_Determinism();
void FS_Test_ZeroExecutionResult();
void FS_Test_SingleExecutionResult();
void FS_Test_MultipleExecutionResult();
void FS_Test_ForbiddenEvent();

//--------------------------------------------------------------------
// Suite entry
//--------------------------------------------------------------------
void TestSuite_FeedbackSource()
{
   Print("------------------------------------------------------------");
   Print("[RUN ] FeedbackSource FS-TEST-0.1");

   FS_Test_Determinism();
   FS_Test_ZeroExecutionResult();
   FS_Test_SingleExecutionResult();
   FS_Test_MultipleExecutionResult();
   FS_Test_ForbiddenEvent();

   PrintFormat("[DONE] FeedbackSource FS-TEST-0.1 | total=%d failed=%d",
               g_fs_tests_total, g_fs_tests_failed);
   Print("------------------------------------------------------------");
}

//--------------------------------------------------------------------
// Helper: safe Feedback initialization (NO ZeroMemory on string)
//--------------------------------------------------------------------
void FS_InitFeedback(Feedback &f)
{
   f.event = 0;
   f.pnl     = 0.0;
   f.message = "";
}

//--------------------------------------------------------------------
// FS-1 — Determinism
//--------------------------------------------------------------------
void FS_Test_Determinism()
{
   ExecutionResult results[];
   ArrayResize(results, 3);

   ZeroMemory(results[0]);
   results[0].status        = EXECUTED;
   results[0].filled_volume = 1.0;
   results[0].price         = 100.0;

   ZeroMemory(results[1]);
   results[1].status        = PARTIAL;
   results[1].filled_volume = 0.5;
   results[1].price         = 101.0;

   ZeroMemory(results[2]);
   results[2].status        = FAILED;
   results[2].filled_volume = 0.0;
   results[2].price         = 0.0;

   Feedback f1; FS_InitFeedback(f1);
   Feedback f2; FS_InitFeedback(f2);

   FeedbackSource_Run(results, 3, f1);
   FeedbackSource_Run(results, 3, f2);

   // Full determinism is required here
   FS_AssertFeedbackEq(f1, f2, "FS-1 Determinism");
}

//--------------------------------------------------------------------
// FS-2 — Zero ExecutionResult
//--------------------------------------------------------------------
void FS_Test_ZeroExecutionResult()
{
   ExecutionResult empty_results[];
   ArrayResize(empty_results, 0);

   Feedback f1; FS_InitFeedback(f1);
   Feedback f2; FS_InitFeedback(f2);

   FeedbackSource_Run(empty_results, 0, f1);
   FeedbackSource_Run(empty_results, 0, f2);

   // Determinism on core fields
   FS_AssertFeedbackCoreEq(f1, f2, "FS-2 ZeroExecutionResult (deterministic)");
   FS_AssertDoubleEq(f1.pnl, 0.0, "FS-2 ZeroExecutionResult: pnl == 0");
}

//--------------------------------------------------------------------
// FS-3 — Single ExecutionResult
//--------------------------------------------------------------------
void FS_Test_SingleExecutionResult()
{
   ExecutionResult results[];
   ArrayResize(results, 1);

   ZeroMemory(results[0]);
   results[0].status        = EXECUTED;
   results[0].filled_volume = 1.0;
   results[0].price         = 100.0;

   Feedback f1; FS_InitFeedback(f1);
   Feedback f2; FS_InitFeedback(f2);

   FeedbackSource_Run(results, 1, f1);
   FeedbackSource_Run(results, 1, f2);

   // Determinism without forcing message semantics
   FS_AssertFeedbackCoreEq(f1, f2, "FS-3 SingleExecutionResult");
}

//--------------------------------------------------------------------
// FS-4 — Multiple ExecutionResult (NO order-independence assumptionT
//--------------------------------------------------------------------
void FS_Test_MultipleExecutionResult()
{
   ExecutionResult results[];
   ArrayResize(results, 3);

   ZeroMemory(results[0]);
   results[0].status        = EXECUTED;
   results[0].filled_volume = 1.0;
   results[0].price         = 100.0;

   ZeroMemory(results[1]);
   results[1].status        = PARTIAL;
   results[1].filled_volume = 0.5;
   results[1].price         = 101.0;

   ZeroMemory(results[2]);
   results[2].status        = FAILED;
   results[2].filled_volume = 0.0;
   results[2].price         = 0.0;

   Feedback f1; FS_InitFeedback(f1);
   Feedback f2; FS_InitFeedback(f2);

   FeedbackSource_Run(results, 3, f1);
   FeedbackSource_Run(results, 3, f2);

   // Only determinism on identical input is required by TestSpec
   FS_AssertFeedbackCoreEq(f1, f2, "FS-4 MultipleExecutionResult (deterministic)");
}

//--------------------------------------------------------------------
// FS-5 — Forbidden Event Emission
//--------------------------------------------------------------------
void FS_Test_ForbiddenEvent()
{
   ExecutionResult results[];
   ArrayResize(results, 2);

   ZeroMemory(results[0]);
   results[0].status        = FAILED;
   results[0].filled_volume = 0.0;
   results[0].price         = 0.0;

   ZeroMemory(results[1]);
   results[1].status        = EXECUTED;
   results[1].filled_volume = 1.0;
   results[1].price         = 100.0;

   Feedback f; FS_InitFeedback(f);

   FeedbackSource_Run(results, 2, f);

   FS_AssertTrue((int)f.event != (int)ACTION_REJECTED,
                 "FS-5 ForbiddenEvent: Feedback.event != ACTION_REJECTED");
}

//--------------------------------------------------------------------
// FS-N1 — No External Reads (STATIC AUDIT ONLY)
//--------------------------------------------------------------------
// This is intentionally not a runtime test.
// Verified by static audit:
// FeedbackSource must not read Snapshot, MT5 state, Coordinator,
// or any hidden globals.

#endif // __TC_FEEDBACK_SOURCE_TESTS_MQH__
