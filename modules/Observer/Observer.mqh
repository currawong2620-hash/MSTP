//+------------------------------------------------------------------+
//| Observer.mqh — Observer v1.1 (Lexicon v3.0 compliant)            |
//| modules/Observer/                                                |
//| STRICT MQL5, no #pragma once, no (void)                          |
//+------------------------------------------------------------------+
#ifndef __OBSERVER_MQH__
#define __OBSERVER_MQH__

#include "../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Startup configuration
//--------------------------------------------------------------------
input string OBS_TF_LIST = "M5,M15,H1";

//--------------------------------------------------------------------
// TF parser (safe, enum-exact)
//--------------------------------------------------------------------
bool Observer_ParseTF(const string token, ENUM_TIMEFRAMES &out_tf)
{
  string t = token;
  StringTrimLeft(t);
  StringTrimRight(t);

  out_tf = (ENUM_TIMEFRAMES)0;
  if(t == "")
    return false;

  // Monthly first
  if(t == "MN1")
  {
    out_tf = PERIOD_MN1;
    return true;
  }

  // Minutes: M + digits only
  if(StringGetCharacter(t,0) == 'M' &&
     StringLen(t) >= 2 &&
     StringGetCharacter(t,1) >= '0' &&
     StringGetCharacter(t,1) <= '9')
  {
    int v = (int)StringToInteger(StringSubstr(t,1));
    switch(v)
    {
      case 1:  out_tf = PERIOD_M1;  return true;
      case 2:  out_tf = PERIOD_M2;  return true;
      case 3:  out_tf = PERIOD_M3;  return true;
      case 4:  out_tf = PERIOD_M4;  return true;
      case 5:  out_tf = PERIOD_M5;  return true;
      case 6:  out_tf = PERIOD_M6;  return true;
      case 10: out_tf = PERIOD_M10; return true;
      case 12: out_tf = PERIOD_M12; return true;
      case 15: out_tf = PERIOD_M15; return true;
      case 20: out_tf = PERIOD_M20; return true;
      case 30: out_tf = PERIOD_M30; return true;
      default: return false;
    }
  }

  // Hours: H1..H12 subset supported by MT5 enums
  if(StringGetCharacter(t,0) == 'H' &&
     StringLen(t) >= 2)
  {
    int v = (int)StringToInteger(StringSubstr(t,1));
    switch(v)
    {
      case 1:  out_tf = PERIOD_H1;  return true;
      case 2:  out_tf = PERIOD_H2;  return true;
      case 3:  out_tf = PERIOD_H3;  return true;
      case 4:  out_tf = PERIOD_H4;  return true;
      case 6:  out_tf = PERIOD_H6;  return true;
      case 8:  out_tf = PERIOD_H8;  return true;
      case 12: out_tf = PERIOD_H12; return true;
      default: return false;
    }
  }

  if(t == "D1") { out_tf = PERIOD_D1; return true; }
  if(t == "W1") { out_tf = PERIOD_W1; return true; }

  return false;
}

//--------------------------------------------------------------------
// Trend computation (contract-exact)
//--------------------------------------------------------------------
void Observer_ComputeTrend(
    const string symbol,
    const ENUM_TIMEFRAMES tf,
    TrendInfo &out_ti
)
{
  out_ti.timeframe  = tf;
  out_ti.regime     = UNKNOWN;
  out_ti.direction  = DIR_FLAT;
  out_ti.confidence = 0.0;

  double close_buf[3];
  int copied = CopyClose(symbol, tf, 1, 3, close_buf);

  if(copied < 3)
  {
    out_ti.regime     = UNKNOWN;
    out_ti.direction  = DIR_FLAT;
    out_ti.confidence = 0.0;
    return;
  }

  double c0 = close_buf[0];
  double c1 = close_buf[1];
  double c2 = close_buf[2];

  int s01 = (c1 > c0) ? 1 : ((c1 < c0) ? -1 : 0);
  int s12 = (c2 > c1) ? 1 : ((c2 < c1) ? -1 : 0);

  if(s01 == s12 && s01 != 0)
  {
    out_ti.direction  = (s01 > 0 ? DIR_LONG : DIR_SHORT);
    out_ti.regime     = TREND;
    out_ti.confidence = 1.0;
    return;
  }

  if(s01 != 0 || s12 != 0)
  {
    int s = (s01 != 0 ? s01 : s12);
    out_ti.direction  = (s > 0 ? DIR_LONG : DIR_SHORT);
    out_ti.regime     = TREND;
    out_ti.confidence = 0.5;
    return;
  }

  out_ti.direction  = DIR_FLAT;
  out_ti.regime     = RANGE;
  out_ti.confidence = 0.0;
}

//--------------------------------------------------------------------
// Main entry point
//--------------------------------------------------------------------
void Observer_Run(Snapshot &out_snapshot)
{
  string symbol = Symbol();
  ENUM_TIMEFRAMES base_tf = (ENUM_TIMEFRAMES)Period();

  // ---------------- market ----------------
  out_snapshot.market.symbol     = symbol;
  out_snapshot.market.tf         = base_tf;
  out_snapshot.market.bid        = SymbolInfoDouble(symbol, SYMBOL_BID);
  out_snapshot.market.ask        = SymbolInfoDouble(symbol, SYMBOL_ASK);
  out_snapshot.market.spread     = out_snapshot.market.ask - out_snapshot.market.bid;
  out_snapshot.market.point_size = SymbolInfoDouble(symbol, SYMBOL_POINT);

  out_snapshot.market.open   = iOpen(symbol, base_tf, 0);
  out_snapshot.market.high   = iHigh(symbol, base_tf, 0);
  out_snapshot.market.low    = iLow(symbol, base_tf, 0);
  out_snapshot.market.close  = iClose(symbol, base_tf, 0);
  out_snapshot.market.volume = (double)iVolume(symbol, base_tf, 0);

  // last_closes[3] — closed bars only
  for(int i = 0; i < 3; i++)
    out_snapshot.market.last_closes[i] = iClose(symbol, base_tf, i + 1);

  // ---------------- time ----------------
  out_snapshot.time.timestamp              = TimeCurrent();
  out_snapshot.time.is_new_bar             = false; // baseline
  out_snapshot.time.bars_since_entry       = 0;
  out_snapshot.time.bars_since_last_action = 0;

  // ---------------- constraints ----------------
  double point = out_snapshot.market.point_size;
  int stops_points = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);

  out_snapshot.constraints.min_lot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  out_snapshot.constraints.lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
  out_snapshot.constraints.min_stop = stops_points * point;
  out_snapshot.constraints.is_trading_allowed =
    (SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_DISABLED);

  // ---------------- position ----------------
  out_snapshot.position.has_position        = false;
  out_snapshot.position.direction           = DIR_FLAT;
  out_snapshot.position.volume              = 0.0;
  out_snapshot.position.entry_price         = 0.0;
  out_snapshot.position.floating_pnl        = 0.0;
  out_snapshot.position.trailing_stop_price = 0.0;

  // ---------------- trends ----------------
  out_snapshot.trends.count = 0;
  ArrayResize(out_snapshot.trends.items, 0);

  if(OBS_TF_LIST == "")
    return;

  string parts[];
  int n = StringSplit(OBS_TF_LIST, ',', parts);
  if(n <= 0)
    return;

  ENUM_TIMEFRAMES tf_list[];
  ArrayResize(tf_list, 0);

  for(int i = 0; i < n; i++)
  {
    ENUM_TIMEFRAMES tf;
    if(!Observer_ParseTF(parts[i], tf))
    {
      out_snapshot.trends.count = 0;
      ArrayResize(out_snapshot.trends.items, 0);
      return;
    }

    int sz = ArraySize(tf_list);
    ArrayResize(tf_list, sz + 1);
    tf_list[sz] = tf;
  }

  int tf_count = ArraySize(tf_list);
  ArrayResize(out_snapshot.trends.items, tf_count);
  out_snapshot.trends.count = tf_count;

  for(int i = 0; i < tf_count; i++)
    Observer_ComputeTrend(symbol, tf_list[i], out_snapshot.trends.items[i]);
}

#endif // __OBSERVER_MQH__
