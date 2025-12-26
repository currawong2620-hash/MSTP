//+------------------------------------------------------------------+
//| TC_TrendAnalyzerTests.mqh — TrendAnalyzer v0.1 Test Suite         |
//| tests/TrendAnalyzer/                                              |
//| STRICT MQL5, no #pragma once, no (void)                           |
//+------------------------------------------------------------------+
#ifndef __TC_TRENDANALYZER_TESTS_MQH__
#define __TC_TRENDANALYZER_TESTS_MQH__

//--------------------------------------------------------------------
// Allowed includes only (STRICT)
//--------------------------------------------------------------------
#include "../helpers/TC_TestHelpers.mqh"
#include "../../modules/TrendAnalyzer/TrendAnalyzer.mqh"
#include "../../modules/Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Normative parameters (fixed; do not change)
//--------------------------------------------------------------------
#define TA_EMA_PERIOD      50
#define TA_ADX_PERIOD      14
#define TA_ATR_PERIOD      14
#define TA_ADX_MIN         20
#define TA_ATR_MULT        0.5
#define TA_SLOPE_LOOKBACK  5
#define TA_MIN_BARS        55

//--------------------------------------------------------------------
// Assertions (no logging, no side effects)
//--------------------------------------------------------------------
#ifndef TA_ASSERT_TRUE
#define TA_ASSERT_TRUE(cond,msg) do { if(!(cond)) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TA_ASSERT_EQ_INT
#define TA_ASSERT_EQ_INT(a,b,msg) do { if(((int)(a))!=((int)(b))) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TA_ASSERT_EQ_DOUBLE
#define TA_ASSERT_EQ_DOUBLE(a,b,msg) do { if(((double)(a))!=((double)(b))) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TA_ASSERT_GE_DOUBLE
#define TA_ASSERT_GE_DOUBLE(a,b,msg) do { if(((double)(a))<((double)(b))) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TA_ASSERT_LE_DOUBLE
#define TA_ASSERT_LE_DOUBLE(a,b,msg) do { if(((double)(a))>((double)(b))) { TC_Fail(msg); return; } } while(false)
#endif

//--------------------------------------------------------------------
// Local helpers (no new types; no static functions)
//--------------------------------------------------------------------
bool TA_Result_Equals(TrendAnalysisResult &a, TrendAnalysisResult &b)
{
  if(a.timeframe != b.timeframe) return false;
  if(a.regime    != b.regime)    return false;
  if(a.direction != b.direction) return false;
  if(a.confidence!= b.confidence)return false;
  return true;
}

void TA_Assert_Common_Invariants(
    const ENUM_TIMEFRAMES input_tf,
    TrendAnalysisResult &out,
    const string pfx
)
{
  TA_ASSERT_TRUE(out.timeframe == input_tf, pfx + " out.timeframe != input");

  TA_ASSERT_GE_DOUBLE(out.confidence, 0.0, pfx + " confidence < 0.0");
  TA_ASSERT_LE_DOUBLE(out.confidence, 1.0, pfx + " confidence > 1.0");

  // regime set
  TA_ASSERT_TRUE(
    out.regime == TREND || out.regime == RANGE || out.regime == UNKNOWN,
    pfx + " invalid regime"
  );

  // direction domain: {-1,0,+1} (semantic compatible with Lexicon direction)
  TA_ASSERT_TRUE(
    out.direction == -1 || out.direction == 0 || out.direction == 1,
    pfx + " invalid direction"
  );

  // semantic invariants
  if(out.regime != TREND)
    TA_ASSERT_EQ_INT(out.direction, 0, pfx + " regime!=TREND but direction!=0");

  if(out.regime == RANGE)
    TA_ASSERT_EQ_DOUBLE(out.confidence, 0.0, pfx + " RANGE but confidence!=0.0");

  if(out.regime == UNKNOWN)
  {
    TA_ASSERT_EQ_INT(out.direction, 0, pfx + " UNKNOWN but direction!=0");
    TA_ASSERT_EQ_DOUBLE(out.confidence, 0.0, pfx + " UNKNOWN but confidence!=0.0");
  }
}

//--------------------------------------------------------------------
// TestSuite runner
//--------------------------------------------------------------------
void TestSuite_TrendAnalyzer();

// TA-1 Contract
void TA_1_1_ContractDomains();

// TA-2 Insufficient data
void TA_2_1_InsufficientData_UNKNOWN();

// TA-3 RANGE behavior (conditional)
void TA_3_1_RANGE_Semantics();

// TA-4 TREND behavior (conditional)
void TA_4_1_TREND_Semantics();

// TA-5 Confidence bounds
void TA_5_1_Confidence_UpperBound();

// TA-6 Determinism
void TA_6_1_Determinism_SameInputs_SameOutputs();

// TA-7 Independence
void TA_7_1_Independence_CompileTime();

//--------------------------------------------------------------------
// TestSuite implementation
//--------------------------------------------------------------------
void TestSuite_TrendAnalyzer()
{
  TA_1_1_ContractDomains();

  TA_2_1_InsufficientData_UNKNOWN();

  TA_3_1_RANGE_Semantics();
  TA_4_1_TREND_Semantics();

  TA_5_1_Confidence_UpperBound();

  TA_6_1_Determinism_SameInputs_SameOutputs();

  TA_7_1_Independence_CompileTime();
}

//--------------------------------------------------------------------
// TA-1.1 Contract domains
//--------------------------------------------------------------------
void TA_1_1_ContractDomains()
{
  const string sym = Symbol();
  const ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();

  TrendAnalysisResult out;
  const bool ok = TrendAnalyzer_Run(sym, tf, out);

  // If analyzer signals critical failure, treat as test failure (rare per spec)
  TA_ASSERT_TRUE(ok, "TA-1.1 TrendAnalyzer_Run returned false");

  TA_Assert_Common_Invariants(tf, out, "TA-1.1");
}

//--------------------------------------------------------------------
// TA-2.1 Insufficient Data
//--------------------------------------------------------------------
void TA_2_1_InsufficientData_UNKNOWN()
{
  const string sym = Symbol();
  const ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();

  const int bars = Bars(sym, tf);

  TrendAnalysisResult out;
  const bool ok = TrendAnalyzer_Run(sym, tf, out);
  TA_ASSERT_TRUE(ok, "TA-2.1 TrendAnalyzer_Run returned false");

  TA_Assert_Common_Invariants(tf, out, "TA-2.1");

  if(bars >= 0 && bars < TA_MIN_BARS)
  {
    TA_ASSERT_TRUE(out.regime == UNKNOWN, "TA-2.1 Bars<MIN_BARS but regime!=UNKNOWN");
    TA_ASSERT_EQ_INT(out.direction, 0,    "TA-2.1 Bars<MIN_BARS but direction!=0");
    TA_ASSERT_EQ_DOUBLE(out.confidence,0.0,"TA-2.1 Bars<MIN_BARS but confidence!=0.0");
  }
}

//--------------------------------------------------------------------
// TA-3.1 RANGE semantics (conditional)
//--------------------------------------------------------------------
void TA_3_1_RANGE_Semantics()
{
  const string sym = Symbol();
  const ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();

  TrendAnalysisResult out;
  const bool ok = TrendAnalyzer_Run(sym, tf, out);
  TA_ASSERT_TRUE(ok, "TA-3.1 TrendAnalyzer_Run returned false");

  TA_Assert_Common_Invariants(tf, out, "TA-3.1");

  if(out.regime == RANGE)
  {
    TA_ASSERT_EQ_INT(out.direction, 0,     "TA-3.1 RANGE but direction!=0");
    TA_ASSERT_EQ_DOUBLE(out.confidence,0.0,"TA-3.1 RANGE but confidence!=0.0");
  }
}

//--------------------------------------------------------------------
// TA-4.1 TREND semantics (conditional)
//--------------------------------------------------------------------
void TA_4_1_TREND_Semantics()
{
  const string sym = Symbol();
  const ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();

  TrendAnalysisResult out;
  const bool ok = TrendAnalyzer_Run(sym, tf, out);
  TA_ASSERT_TRUE(ok, "TA-4.1 TrendAnalyzer_Run returned false");

  TA_Assert_Common_Invariants(tf, out, "TA-4.1");

  if(out.regime == TREND)
  {
    TA_ASSERT_TRUE(out.direction != 0, "TA-4.1 TREND but direction==0");
    TA_ASSERT_TRUE(out.confidence > 0.0, "TA-4.1 TREND but confidence<=0.0");
  }
}

//--------------------------------------------------------------------
// TA-5.1 Confidence bounds
//--------------------------------------------------------------------
void TA_5_1_Confidence_UpperBound()
{
  const string sym = Symbol();
  const ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();

  TrendAnalysisResult out;
  const bool ok = TrendAnalyzer_Run(sym, tf, out);
  TA_ASSERT_TRUE(ok, "TA-5.1 TrendAnalyzer_Run returned false");

  TA_Assert_Common_Invariants(tf, out, "TA-5.1");
  TA_ASSERT_LE_DOUBLE(out.confidence, 1.0, "TA-5.1 confidence > 1.0");
}

//--------------------------------------------------------------------
// TA-6.1 Determinism: same inputs -> field-by-field equal
//--------------------------------------------------------------------
void TA_6_1_Determinism_SameInputs_SameOutputs()
{
  const string sym = Symbol();
  const ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();

  // To reduce nondeterminism risk from bar rollover, guard by Bars count.
  const int bars_before = Bars(sym, tf);

  TrendAnalysisResult a;
  TrendAnalysisResult b;

  const bool ok_a = TrendAnalyzer_Run(sym, tf, a);
  TA_ASSERT_TRUE(ok_a, "TA-6.1 first TrendAnalyzer_Run returned false");

  const bool ok_b = TrendAnalyzer_Run(sym, tf, b);
  TA_ASSERT_TRUE(ok_b, "TA-6.1 second TrendAnalyzer_Run returned false");

  TA_Assert_Common_Invariants(tf, a, "TA-6.1(A)");
  TA_Assert_Common_Invariants(tf, b, "TA-6.1(B)");

  const int bars_after = Bars(sym, tf);

  // Conditional determinism assert: only if bar context unchanged.
  if(bars_before == bars_after)
  {
    TA_ASSERT_TRUE(TA_Result_Equals(a, b), "TA-6.1 nondeterministic output for same inputs");
  }
}

//--------------------------------------------------------------------
// TA-7.1 Independence (compile-time)
//--------------------------------------------------------------------
void TA_7_1_Independence_CompileTime()
{
  // This test is satisfied by compilation:
  // - No Observer include
  // - No Snapshot usage
  // - No trade API usage
  // Nothing to execute.
}

#endif // __TC_TRENDANALYZER_TESTS_MQH__
