//+------------------------------------------------------------------+
//| ArchitectureTypes.mqh — Architecture Contracts v3.0              |
//| SSP v3.0 / CONTRACT_LEXICON v3.0 compliant                        |
//| STRICT MQL5                                                      |
//| NO #pragma once                                                  |
//+------------------------------------------------------------------+
#ifndef __ARCHITECTURE_TYPES_MQH__
#define __ARCHITECTURE_TYPES_MQH__

//--------------------------------------------------------------------
// Direction (shared semantic enum)
//--------------------------------------------------------------------
enum direction
{
   DIR_SHORT = -1,
   DIR_FLAT  =  0,
   DIR_LONG  =  1
};

//--------------------------------------------------------------------
// Trend regime (multi-timeframe dataset)
//--------------------------------------------------------------------
enum trend_regime
{
   TREND   = 0,
   RANGE   = 1,
   UNKNOWN = 2
};

//--------------------------------------------------------------------
// TrendInfo — single timeframe trend descriptor
//--------------------------------------------------------------------
struct TrendInfo
{
   ENUM_TIMEFRAMES timeframe;   // timeframe of this record
   trend_regime    regime;      // TREND / RANGE / UNKNOWN
   direction       direction;   // -1 / 0 / +1
   double          confidence;  // 0.0 .. 1.0
};

//--------------------------------------------------------------------
// Snapshot.trends container
//--------------------------------------------------------------------
struct SnapshotTrends
{
   int       count;     // number of timeframe records
   TrendInfo items[];   // ordered array (input order)
};

//--------------------------------------------------------------------
// Snapshot.market
//--------------------------------------------------------------------
struct SnapshotMarket
{
   string           symbol;
   ENUM_TIMEFRAMES  tf;

   double open;
   double high;
   double low;
   double close;

   double volume;

   double bid;
   double ask;
   double spread;

   double last_closes[3];   // closed bars only

   double point_size;
};

//--------------------------------------------------------------------
// Snapshot.position
//--------------------------------------------------------------------
struct SnapshotPosition
{
   bool      has_position;
   direction direction;
   double    volume;
   double    entry_price;
   double    floating_pnl;
   double    trailing_stop_price;
};

//--------------------------------------------------------------------
// Snapshot.time
//--------------------------------------------------------------------
struct SnapshotTime
{
   datetime timestamp;
   bool     is_new_bar;
   int      bars_since_entry;
   int      bars_since_last_action;
};

//--------------------------------------------------------------------
// Snapshot.constraints
//--------------------------------------------------------------------
struct SnapshotConstraints
{
   double min_lot;
   double lot_step;
   double min_stop;
   bool   is_trading_allowed;
};

//--------------------------------------------------------------------
// Snapshot — root architecture type
//--------------------------------------------------------------------
struct Snapshot
{
   SnapshotMarket      market;
   SnapshotPosition    position;
   SnapshotTime        time;
   SnapshotConstraints constraints;
   SnapshotTrends      trends;
};

//--------------------------------------------------------------------
// Intent
//--------------------------------------------------------------------
enum intent_type
{
   NO_ACTION = 0,
   WANT_OPEN,
   WANT_CLOSE,
   WANT_HOLD
};

struct Intent
{
   intent_type type;
   direction   direction;
   double      confidence;
};

//--------------------------------------------------------------------
// PolicyAdjustedIntent
//--------------------------------------------------------------------
struct PolicyAdjustedIntent
{
   intent_type type;
   direction   direction;
   double      volume;
   string      tag;
};

//--------------------------------------------------------------------
// Decision
//--------------------------------------------------------------------
enum decision_status
{
   DECISION_ACCEPT = 0,
   DECISION_REJECT,
   DECISION_MODIFY
};

enum decision_action
{
   ACTION_OPEN = 0,
   ACTION_CLOSE
};

struct Decision
{
   decision_status status;
   decision_action action;
   direction       direction;
   double          volume;
   string          symbol;
   string          reason;
};

//--------------------------------------------------------------------
// ExecutionResult
//--------------------------------------------------------------------
enum execution_status
{
   EXECUTED = 0,
   REJECTED,
   PARTIAL,
   FAILED
};

struct ExecutionResult
{
   execution_status status;
   double           filled_volume;
   double           price;
};

//--------------------------------------------------------------------
// Feedback
//--------------------------------------------------------------------
enum feedback_event
{
   POSITION_OPENED = 0,
   POSITION_CLOSED,
   STOP_HIT,
   TARGET_HIT,
   ACTION_REJECTED
};

struct Feedback
{
   feedback_event event;
   double         pnl;
   string         message;
};

struct TrendAnalysisResult
{
  ENUM_TIMEFRAMES timeframe;
  trend_regime    regime;
  int             direction;   // semantically compatible with CONTRACT_LEXICON.direction
  double          confidence;
};


#endif // __ARCHITECTURE_TYPES_MQH__
