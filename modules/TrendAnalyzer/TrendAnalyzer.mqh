//+------------------------------------------------------------------+
//| TrendAnalyzer.mqh — TrendAnalyzer v0.1                            |
//| modules/TrendAnalyzer/                                            |
//| STRICT MQL5, no #pragma once, no (void), no static functions      |
//+------------------------------------------------------------------+
#ifndef __TRENDANALYZER_MQH__
#define __TRENDANALYZER_MQH__

#include "../Infrastructure/ArchitectureTypes.mqh"

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
// The ONLY public API (fixed)
//--------------------------------------------------------------------
bool TrendAnalyzer_Run(
    const string symbol,
    const ENUM_TIMEFRAMES timeframe,
    TrendAnalysisResult &out_result
)
{
  // ---------------- baseline output ----------------
  out_result.timeframe  = timeframe;
  out_result.regime     = UNKNOWN;
  out_result.direction  = 0;
  out_result.confidence = 0.0;

  // ---------------- MIN_BARS gate ------------------
  const int bars = Bars(symbol, timeframe);
  if(bars < TA_MIN_BARS)
  {
    // Normative behavior
    return true;
  }

  // ---------------- handles ------------------------
  int h_ema = INVALID_HANDLE;
  int h_atr = INVALID_HANDLE;
  int h_adx = INVALID_HANDLE;

  bool ok = true;

  // ---------------- create handles -----------------
  h_ema = iMA(symbol, timeframe, TA_EMA_PERIOD, 0, MODE_EMA, PRICE_CLOSE);
  if(h_ema == INVALID_HANDLE)
    ok = false;

  if(ok)
  {
    h_atr = iATR(symbol, timeframe, TA_ATR_PERIOD);
    if(h_atr == INVALID_HANDLE)
      ok = false;
  }

  if(ok)
  {
    h_adx = iADX(symbol, timeframe, TA_ADX_PERIOD);
    if(h_adx == INVALID_HANDLE)
      ok = false;
  }

  // ---------------- indicator read -----------------
  double ema0_arr[1];
  double emaL_arr[1];
  double atr0_arr[1];
  double adx0_arr[1];

  double delta = 0.0;
  double threshold = 0.0;
  double adx0 = 0.0;

  if(ok)
  {
    if(CopyBuffer(h_ema, 0, 1, 1, ema0_arr) != 1)
      ok = false;
    if(CopyBuffer(h_ema, 0, 1 + TA_SLOPE_LOOKBACK, 1, emaL_arr) != 1)
      ok = false;
    if(CopyBuffer(h_atr, 0, 1, 1, atr0_arr) != 1)
      ok = false;
    if(CopyBuffer(h_adx, 0, 1, 1, adx0_arr) != 1)
      ok = false;
  }

  if(ok)
  {
    delta     = ema0_arr[0] - emaL_arr[0];
    threshold = atr0_arr[0] * TA_ATR_MULT;
    adx0      = adx0_arr[0];

    if(threshold <= 0.0)
      ok = false;
  }

  // ---------------- analysis -----------------------
  if(ok)
  {
    int direction_val = 0;

    if(delta > threshold)
      direction_val = +1;
    else if(delta < -threshold)
      direction_val = -1;

    trend_regime regime_val = RANGE;

    if(direction_val == 0)
      regime_val = RANGE;
    else if(adx0 < (double)TA_ADX_MIN)
      regime_val = RANGE;
    else
      regime_val = TREND;

    if(regime_val != TREND)
      direction_val = 0;

    double confidence_val = 0.0;

    if(regime_val == TREND)
    {
      double ema_score = MathAbs(delta) / threshold;
      if(ema_score < 0.0) ema_score = 0.0;
      if(ema_score > 1.0) ema_score = 1.0;

      double adx_score = (adx0 - (double)TA_ADX_MIN) / (double)TA_ADX_MIN;
      if(adx_score < 0.0) adx_score = 0.0;
      if(adx_score > 1.0) adx_score = 1.0;

      confidence_val = 0.5 * ema_score + 0.5 * adx_score;
      if(confidence_val < 0.0) confidence_val = 0.0;
      if(confidence_val > 1.0) confidence_val = 1.0;
    }

    out_result.regime     = regime_val;
    out_result.direction  = direction_val;
    out_result.confidence = confidence_val;

    // invariant safety
    if(out_result.regime != TREND)
      out_result.direction = 0;
    if(out_result.regime == RANGE)
      out_result.confidence = 0.0;
    if(out_result.regime == UNKNOWN)
    {
      out_result.direction  = 0;
      out_result.confidence = 0.0;
    }
  }

  // ---------------- cleanup ------------------------
  if(h_adx != INVALID_HANDLE) IndicatorRelease(h_adx);
  if(h_atr != INVALID_HANDLE) IndicatorRelease(h_atr);
  if(h_ema != INVALID_HANDLE) IndicatorRelease(h_ema);

  return ok;
}

#endif // __TRENDANALYZER_MQH__
