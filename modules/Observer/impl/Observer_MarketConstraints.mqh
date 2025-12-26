//+------------------------------------------------------------------+
//| Observer_MarketConstraints.mqh                                    |
//| Observer v1.0 — Stage 1 + Stage 2                                 |
//| STRICT MQL5                                                       |
//| No #pragma once                                                   |
//+------------------------------------------------------------------+

#ifndef __OBSERVER_MARKET_CONSTRAINTS_MQH__
#define __OBSERVER_MARKET_CONSTRAINTS_MQH__

#include "../../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// Internal observer memory (NON-ARCHITECTURAL)
//--------------------------------------------------------------------
static bool     g_prev_has_position = false;
static int      g_prev_direction    = 0;
static double   g_prev_volume       = 0.0;

static datetime g_prev_bar_time     = 0;

static int      g_bars_since_entry       = 0;
static int      g_bars_since_last_action = 0;

//--------------------------------------------------------------------
// Observer public entry point (FIXED CONTRACT)
//--------------------------------------------------------------------
void Observer_Run(
    Snapshot &out_snapshot
)
{
   const string symbol = _Symbol;
   const ENUM_TIMEFRAMES tf = _Period;

   // ===============================================================
   // Stage 1 — Snapshot.market (UNCHANGED)
   // ===============================================================

   out_snapshot.market.symbol = symbol;
   out_snapshot.market.tf     = tf;

   out_snapshot.market.open   = iOpen(symbol, tf, 0);
   out_snapshot.market.high   = iHigh(symbol, tf, 0);
   out_snapshot.market.low    = iLow(symbol, tf, 0);
   out_snapshot.market.close  = iClose(symbol, tf, 0);
   out_snapshot.market.volume = iVolume(symbol, tf, 0);
   
   // --- last closed bars (Lexicon v1.2, FACTUAL, no interpretation)
   out_snapshot.market.last_closes[0] = iClose(symbol, tf, 1);
   out_snapshot.market.last_closes[1] = iClose(symbol, tf, 2);
   out_snapshot.market.last_closes[2] = iClose(symbol, tf, 3);


   out_snapshot.market.bid    = SymbolInfoDouble(symbol, SYMBOL_BID);
   out_snapshot.market.ask    = SymbolInfoDouble(symbol, SYMBOL_ASK);
   out_snapshot.market.spread = out_snapshot.market.ask - out_snapshot.market.bid;
   
   // --- environment fact: minimal price step (Lexicon-compliant)
   out_snapshot.market.point_size =
      SymbolInfoDouble(symbol, SYMBOL_POINT);

   out_snapshot.constraints.min_lot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   out_snapshot.constraints.lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   const long stops_level =
      SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);

   out_snapshot.constraints.min_stop = stops_level * _Point;

   const long trade_mode =
      SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);

   out_snapshot.constraints.is_trading_allowed =
      (trade_mode != SYMBOL_TRADE_MODE_DISABLED);

   // ===============================================================
   // Stage 2 — Snapshot.position (FACTUAL ACCOUNT STATE)
   // ===============================================================

   bool   has_position  = false;
   int    direction     = 0;
   double volume        = 0.0;
   double entry_price   = 0.0;
   double floating_pnl  = 0.0;

   if(PositionSelect(symbol))
   {
      has_position = true;

      const long pos_type =
         PositionGetInteger(POSITION_TYPE);

      if(pos_type == POSITION_TYPE_BUY)
         direction = +1;
      else if(pos_type == POSITION_TYPE_SELL)
         direction = -1;

      volume       = PositionGetDouble(POSITION_VOLUME);
      entry_price  = PositionGetDouble(POSITION_PRICE_OPEN);
      floating_pnl = PositionGetDouble(POSITION_PROFIT);
   }

   out_snapshot.position.has_position = has_position;
   out_snapshot.position.direction    = direction;
   out_snapshot.position.volume       = volume;
   out_snapshot.position.entry_price  = entry_price;
   out_snapshot.position.floating_pnl = floating_pnl;

   // ===============================================================
   // Stage 2 — Snapshot.time
   // ===============================================================

   const datetime now_time = TimeCurrent();
   out_snapshot.time.timestamp = now_time;

   // --- new bar detection (FACTUAL)
   const datetime bar_time = iTime(symbol, tf, 0);
   const bool is_new_bar =
      (bar_time != g_prev_bar_time);

   out_snapshot.time.is_new_bar = is_new_bar;

   // ===============================================================
   // Time counters (NORMATIVE RULES ONLY)
   // ===============================================================

   bool entry_event = false;
   bool action_event = false;

   // entry: false → true
   if(!g_prev_has_position && has_position)
      entry_event = true;

   // any observable action
   if(g_prev_has_position != has_position ||
      g_prev_direction    != direction    ||
      g_prev_volume       != volume)
   {
      action_event = true;
   }

   // --- bars_since_entry
   if(!has_position)
   {
      g_bars_since_entry = 0;
   }
   else if(entry_event)
   {
      g_bars_since_entry = 0;
   }
   else if(is_new_bar)
   {
      g_bars_since_entry++;
   }

   // --- bars_since_last_action
   if(action_event)
   {
      g_bars_since_last_action = 0;
   }
   else if(is_new_bar)
   {
      g_bars_since_last_action++;
   }

   out_snapshot.time.bars_since_entry =
      g_bars_since_entry;

   out_snapshot.time.bars_since_last_action =
      g_bars_since_last_action;

   // ===============================================================
   // Update observer memory (END OF CYCLE)
   // ===============================================================

   g_prev_has_position = has_position;
   g_prev_direction    = direction;
   g_prev_volume       = volume;
   g_prev_bar_time     = bar_time;
}

#endif // __OBSERVER_MARKET_CONSTRAINTS_MQH__
