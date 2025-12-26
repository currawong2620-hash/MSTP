//+------------------------------------------------------------------+
//| TC_ObserverTests.mqh — Observer v1.1 Test Suite (v3, fixed)       |
//| tests/Infrastructure/Observer/                                   |
//| STRICT MQL5, no #pragma once, no (void)                           |
//|                                                                  |
//| NOTE (ARCHITECTURAL):                                            |
//| This file is a COLLECTION OF CONFIG-DEPENDENT TESTS.             |
//| Each OBS-* group is intended to be run in an isolated            |
//| startup configuration (OBS_TF_LIST differs per run).             |
//| TestSuite_Observer() MUST NOT be treated as a single-run suite.  |
//+------------------------------------------------------------------+
#ifndef __TC_OBSERVER_TESTS_MQH__
#define __TC_OBSERVER_TESTS_MQH__

//--------------------------------------------------------------------
// Allowed includes only
//--------------------------------------------------------------------
#include "../helpers/TC_TestHelpers.mqh"
#include "../../modules/Observer/Observer.mqh"
#include "../../modules/Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Forward declarations
//--------------------------------------------------------------------
void TestSuite_Observer();

// OBS-1 — TF parsing
void OBS_1_1_SingleTF();
void OBS_1_2_MultipleTF_OrderPreserved();
void OBS_1_3_WhitespaceTolerant();
void OBS_1_4_InvalidToken_FailFast();
void OBS_1_5_EmptyString();

// OBS-2 — Snapshot.trends structure
void OBS_2_1_TrendInfo_RequiredFields();
void OBS_2_2_LengthInvariant();

// OBS-3 — Semantic invariants (black-box)
void OBS_3_1_TREND_Implies_DirectionNonZero();
void OBS_3_2_DirectionNonZero_Implies_NotRANGE();
void OBS_3_3_RANGE_Implies_DirectionZero_And_ConfidenceZero();
void OBS_3_4_ConfidenceHalf_Implies_TREND();

// OBS-4 — Edge invariants
void OBS_4_1_UNKNOWN_Implies_DirectionZero_And_ConfidenceZero();
void OBS_4_2_TradingDisabled_TrendsStable();

// OBS-5 — Determinism
void OBS_5_1_TrendsDeterministic();
void OBS_5_2_OrderStability();

//--------------------------------------------------------------------
// Assertions (no logging, no side effects)
//--------------------------------------------------------------------
#ifndef TC_ASSERT_TRUE
#define TC_ASSERT_TRUE(cond,msg) do { if(!(cond)) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TC_ASSERT_EQ_INT
#define TC_ASSERT_EQ_INT(a,b,msg) do { if(((int)(a))!=((int)(b))) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TC_ASSERT_EQ_DOUBLE
#define TC_ASSERT_EQ_DOUBLE(a,b,msg) do { if(((double)(a))!=((double)(b))) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TC_ASSERT_GE_DOUBLE
#define TC_ASSERT_GE_DOUBLE(a,b,msg) do { if(((double)(a))<((double)(b))) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TC_ASSERT_LE_DOUBLE
#define TC_ASSERT_LE_DOUBLE(a,b,msg) do { if(((double)(a))>((double)(b))) { TC_Fail(msg); return; } } while(false)
#endif

#ifndef TC_ASSERT_STR_NOT_EMPTY
#define TC_ASSERT_STR_NOT_EMPTY(s,msg) do { if((string)(s)=="") { TC_Fail(msg); return; } } while(false)
#endif

//--------------------------------------------------------------------
// Snapshot structural validity (LEXICON-MINIMAL) + length invariant
//--------------------------------------------------------------------
#define TC_ASSERT_SNAPSHOT_VALID(snp,pfx)                                              \
do {                                                                                   \
  TC_ASSERT_STR_NOT_EMPTY((snp).market.symbol, (pfx)+" market.symbol empty");          \
  TC_ASSERT_TRUE((snp).market.tf > 0,          (pfx)+" market.tf <= 0");               \
                                                                                       \
  TC_ASSERT_TRUE((snp).time.timestamp > 0,     (pfx)+" time.timestamp <= 0");          \
  TC_ASSERT_TRUE((snp).time.bars_since_entry >= 0, (pfx)+" bars_since_entry < 0");     \
  TC_ASSERT_TRUE((snp).time.bars_since_last_action >= 0,                              \
                 (pfx)+" bars_since_last_action < 0");                                \
                                                                                       \
  TC_ASSERT_TRUE((snp).constraints.min_lot >= 0.0, (pfx)+" min_lot < 0");              \
  TC_ASSERT_TRUE((snp).constraints.lot_step > 0.0, (pfx)+" lot_step <= 0");            \
  TC_ASSERT_TRUE((snp).constraints.min_stop >= 0.0,(pfx)+" min_stop < 0");             \
                                                                                       \
  TC_ASSERT_TRUE((snp).position.volume >= 0.0,     (pfx)+" volume < 0");               \
  TC_ASSERT_TRUE((snp).position.entry_price >= 0.0,(pfx)+" entry_price < 0");         \
                                                                                       \
  TC_ASSERT_TRUE((snp).trends.count >= 0,        (pfx)+" trends.count < 0");           \
  TC_ASSERT_EQ_INT(ArraySize((snp).trends.items),                                      \
                   (snp).trends.count, (pfx)+" trends items size!=count");            \
} while(false)

//--------------------------------------------------------------------
// TestSuite runner (CONFIG-DEPENDENT)
//--------------------------------------------------------------------
void TestSuite_Observer()
{
  OBS_1_1_SingleTF();
  OBS_1_2_MultipleTF_OrderPreserved();
  OBS_1_3_WhitespaceTolerant();
  OBS_1_4_InvalidToken_FailFast();
  OBS_1_5_EmptyString();

  OBS_2_1_TrendInfo_RequiredFields();
  OBS_2_2_LengthInvariant();

  OBS_3_1_TREND_Implies_DirectionNonZero();
  OBS_3_2_DirectionNonZero_Implies_NotRANGE();
  OBS_3_3_RANGE_Implies_DirectionZero_And_ConfidenceZero();
  OBS_3_4_ConfidenceHalf_Implies_TREND();

  OBS_4_1_UNKNOWN_Implies_DirectionZero_And_ConfidenceZero();
  OBS_4_2_TradingDisabled_TrendsStable();

  OBS_5_1_TrendsDeterministic();
  OBS_5_2_OrderStability();
}

//--------------------------------------------------------------------
// OBS-1.1 Single TF
//--------------------------------------------------------------------
void OBS_1_1_SingleTF()
{
  if(OBS_TF_LIST != "M5")
    return;

  Snapshot snp;
  Observer_Run(snp);

  TC_ASSERT_SNAPSHOT_VALID(snp,"OBS-1.1");
  TC_ASSERT_EQ_INT(snp.trends.count,1,"OBS-1.1 trends.count != 1");
  if(snp.trends.count > 0)
    TC_ASSERT_TRUE(snp.trends.items[0].timeframe==PERIOD_M5,
                   "OBS-1.1 timeframe != M5");
}

//--------------------------------------------------------------------
// OBS-1.2 Multiple TF (order preserved)
//--------------------------------------------------------------------
void OBS_1_2_MultipleTF_OrderPreserved()
{
  if(OBS_TF_LIST != "M5,M15,H1")
    return;

  Snapshot snp;
  Observer_Run(snp);

  TC_ASSERT_SNAPSHOT_VALID(snp,"OBS-1.2");
  TC_ASSERT_EQ_INT(snp.trends.count,3,"OBS-1.2 trends.count != 3");
  if(snp.trends.count == 3)
  {
    TC_ASSERT_TRUE(snp.trends.items[0].timeframe==PERIOD_M5,"OBS-1.2[0]!=M5");
    TC_ASSERT_TRUE(snp.trends.items[1].timeframe==PERIOD_M15,"OBS-1.2[1]!=M15");
    TC_ASSERT_TRUE(snp.trends.items[2].timeframe==PERIOD_H1,"OBS-1.2[2]!=H1");
  }
}

//--------------------------------------------------------------------
// OBS-1.3 Whitespace tolerant
//--------------------------------------------------------------------
void OBS_1_3_WhitespaceTolerant()
{
  if(OBS_TF_LIST != " M5 ,  H1 ,M15 ")
    return;

  Snapshot snp;
  Observer_Run(snp);

  TC_ASSERT_SNAPSHOT_VALID(snp,"OBS-1.3");
  TC_ASSERT_EQ_INT(snp.trends.count,3,"OBS-1.3 trends.count != 3");
  if(snp.trends.count == 3)
  {
    TC_ASSERT_TRUE(snp.trends.items[0].timeframe==PERIOD_M5,"OBS-1.3[0]!=M5");
    TC_ASSERT_TRUE(snp.trends.items[1].timeframe==PERIOD_H1,"OBS-1.3[1]!=H1");
    TC_ASSERT_TRUE(snp.trends.items[2].timeframe==PERIOD_M15,"OBS-1.3[2]!=M15");
  }
}

//--------------------------------------------------------------------
// OBS-1.4 Invalid token → fail-fast
//--------------------------------------------------------------------
void OBS_1_4_InvalidToken_FailFast()
{
  if(OBS_TF_LIST != "M5,XXX,H1")
    return;

  Snapshot snp;
  Observer_Run(snp);

  TC_ASSERT_SNAPSHOT_VALID(snp,"OBS-1.4");
  TC_ASSERT_EQ_INT(snp.trends.count,0,"OBS-1.4 trends.count != 0");
}

//--------------------------------------------------------------------
// OBS-1.5 Empty string
//--------------------------------------------------------------------
void OBS_1_5_EmptyString()
{
  if(OBS_TF_LIST != "")
    return;

  Snapshot snp;
  Observer_Run(snp);

  TC_ASSERT_SNAPSHOT_VALID(snp,"OBS-1.5");
  TC_ASSERT_EQ_INT(snp.trends.count,0,"OBS-1.5 trends.count != 0");
}

//--------------------------------------------------------------------
// OBS-2.1 TrendInfo required fields
//--------------------------------------------------------------------
void OBS_2_1_TrendInfo_RequiredFields()
{
  Snapshot snp;
  Observer_Run(snp);

  TC_ASSERT_SNAPSHOT_VALID(snp,"OBS-2.1");

  for(int i=0;i<snp.trends.count;i++)
  {
    TrendInfo ti = snp.trends.items[i];

    TC_ASSERT_TRUE(ti.timeframe!=0,"OBS-2.1 timeframe==0");
    TC_ASSERT_TRUE(
      ti.regime==TREND || ti.regime==RANGE || ti.regime==UNKNOWN,
      "OBS-2.1 invalid regime"
    );
    TC_ASSERT_TRUE(
      ti.direction==-1 || ti.direction==0 || ti.direction==1,
      "OBS-2.1 invalid direction"
    );
    TC_ASSERT_GE_DOUBLE(ti.confidence,0.0,"OBS-2.1 confidence<0");
    TC_ASSERT_LE_DOUBLE(ti.confidence,1.0,"OBS-2.1 confidence>1");
  }
}

//--------------------------------------------------------------------
// OBS-2.2 Length invariant
//--------------------------------------------------------------------
void OBS_2_2_LengthInvariant()
{
  Snapshot snp;
  Observer_Run(snp);

  TC_ASSERT_SNAPSHOT_VALID(snp,"OBS-2.2");
}

//--------------------------------------------------------------------
// OBS-3.1 TREND ⇒ direction ≠ 0
//--------------------------------------------------------------------
void OBS_3_1_TREND_Implies_DirectionNonZero()
{
  Snapshot snp;
  Observer_Run(snp);

  for(int i=0;i<snp.trends.count;i++)
  {
    if(snp.trends.items[i].regime==TREND)
      TC_ASSERT_TRUE(snp.trends.items[i].direction!=0,
                     "OBS-3.1 TREND but direction==0");
  }
}

//--------------------------------------------------------------------
// OBS-3.2 direction ≠ 0 ⇒ regime ≠ RANGE
//--------------------------------------------------------------------
void OBS_3_2_DirectionNonZero_Implies_NotRANGE()
{
  Snapshot snp;
  Observer_Run(snp);

  for(int i=0;i<snp.trends.count;i++)
  {
    if(snp.trends.items[i].direction!=0)
      TC_ASSERT_TRUE(snp.trends.items[i].regime!=RANGE,
                     "OBS-3.2 direction!=0 but regime==RANGE");
  }
}

//--------------------------------------------------------------------
// OBS-3.3 RANGE ⇒ direction==0 AND confidence==0
//--------------------------------------------------------------------
void OBS_3_3_RANGE_Implies_DirectionZero_And_ConfidenceZero()
{
  Snapshot snp;
  Observer_Run(snp);

  for(int i=0;i<snp.trends.count;i++)
  {
    if(snp.trends.items[i].regime==RANGE)
    {
      TC_ASSERT_EQ_INT(snp.trends.items[i].direction,0,
                       "OBS-3.3 RANGE but direction!=0");
      TC_ASSERT_EQ_DOUBLE(snp.trends.items[i].confidence,0.0,
                          "OBS-3.3 RANGE but confidence!=0");
    }
  }
}

//--------------------------------------------------------------------
// OBS-3.4 confidence==0.5 AND direction≠0 ⇒ TREND
//--------------------------------------------------------------------
void OBS_3_4_ConfidenceHalf_Implies_TREND()
{
  Snapshot snp;
  Observer_Run(snp);

  for(int i=0;i<snp.trends.count;i++)
  {
    TrendInfo ti = snp.trends.items[i];
    if(ti.direction!=0 && ti.confidence==0.5)
      TC_ASSERT_TRUE(ti.regime==TREND,
                     "OBS-3.4 confidence==0.5 but regime!=TREND");
  }
}

//--------------------------------------------------------------------
// OBS-4.1 UNKNOWN ⇒ direction==0 AND confidence==0
//--------------------------------------------------------------------
void OBS_4_1_UNKNOWN_Implies_DirectionZero_And_ConfidenceZero()
{
  Snapshot snp;
  Observer_Run(snp);

  for(int i=0;i<snp.trends.count;i++)
  {
    if(snp.trends.items[i].regime==UNKNOWN)
    {
      TC_ASSERT_EQ_INT(snp.trends.items[i].direction,0,
                       "OBS-4.1 UNKNOWN but direction!=0");
      TC_ASSERT_EQ_DOUBLE(snp.trends.items[i].confidence,0.0,
                          "OBS-4.1 UNKNOWN but confidence!=0");
    }
  }
}

//--------------------------------------------------------------------
// OBS-4.2 Trading disabled ⇒ trends stable
//--------------------------------------------------------------------
void OBS_4_2_TradingDisabled_TrendsStable()
{
  Snapshot a;
  Observer_Run(a);

  if(!a.constraints.is_trading_allowed)
  {
    Snapshot b;
    Observer_Run(b);

    TC_ASSERT_TRUE(
      Snapshot_Equals_ForDeterminism(a,b),
      "OBS-4.2 trends changed while trading disabled"
    );
  }
}

//--------------------------------------------------------------------
// OBS-5.1 Determinism (trends only)
//--------------------------------------------------------------------
void OBS_5_1_TrendsDeterministic()
{
  Snapshot a;
  Observer_Run(a);

  Snapshot b;
  Observer_Run(b);

  TC_ASSERT_TRUE(
    Snapshot_Equals_ForDeterminism(a,b),
    "OBS-5.1 trends nondeterministic"
  );
}

//--------------------------------------------------------------------
// OBS-5.2 Order stability
//--------------------------------------------------------------------
void OBS_5_2_OrderStability()
{
  const bool cfg_a = (OBS_TF_LIST=="M5,H1");
  const bool cfg_b = (OBS_TF_LIST=="H1,M5");
  if(!cfg_a && !cfg_b)
    return;

  Snapshot snp;
  Observer_Run(snp);

  TC_ASSERT_EQ_INT(snp.trends.count,2,"OBS-5.2 trends.count!=2");
  if(snp.trends.count != 2)
    return;

  if(cfg_a)
  {
    TC_ASSERT_TRUE(snp.trends.items[0].timeframe==PERIOD_M5,"OBS-5.2 A[0]!=M5");
    TC_ASSERT_TRUE(snp.trends.items[1].timeframe==PERIOD_H1,"OBS-5.2 A[1]!=H1");
  }
  if(cfg_b)
  {
    TC_ASSERT_TRUE(snp.trends.items[0].timeframe==PERIOD_H1,"OBS-5.2 B[0]!=H1");
    TC_ASSERT_TRUE(snp.trends.items[1].timeframe==PERIOD_M5,"OBS-5.2 B[1]!=M5");
  }
}

#endif // __TC_OBSERVER_TESTS_MQH__
