//+------------------------------------------------------------------+
//| TC_TestHelpers.mqh                                               |
//| Minimal test helpers for infrastructure test suites              |
//| STRICT MQL5, no #pragma once, no (void)                           |
//+------------------------------------------------------------------+
#ifndef __TC_TEST_HELPERS_MQH__
#define __TC_TEST_HELPERS_MQH__

#include "../../modules/Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Test failure signal
//--------------------------------------------------------------------
// NORMATIVE:
// - single exit point for test failure
// - no logging to production output
// - no global state modification
// - deterministic behaviour
//--------------------------------------------------------------------
void TC_Fail(const string message)
{
  // MetaTrader has no exception mechanism.
  // We deliberately use Alert + Experts log as test harness signal.
  Alert("TEST FAILED: ", message);
}

//--------------------------------------------------------------------
// Snapshot equality for determinism tests ONLY
//--------------------------------------------------------------------
// NORMATIVE CONTRACT:
// - compares ONLY Snapshot.trends
// - used ONLY by OBS-4 / OBS-5
// - NOT a general Snapshot equality
// - double compared via '=='
//--------------------------------------------------------------------
bool Snapshot_Equals_ForDeterminism(
    Snapshot &a,
    Snapshot &b
)
{
  if(a.trends.count != b.trends.count)
    return false;

  if(ArraySize(a.trends.items) != ArraySize(b.trends.items))
    return false;

  int n = a.trends.count;
  for(int i = 0; i < n; i++)
  {
    TrendInfo ta = a.trends.items[i];
    TrendInfo tb = b.trends.items[i];

    if(ta.timeframe  != tb.timeframe)  return false;
    if(ta.regime     != tb.regime)     return false;
    if(ta.direction  != tb.direction)  return false;
    if(ta.confidence != tb.confidence) return false;
  }

  return true;
}

#endif // __TC_TEST_HELPERS_MQH__
