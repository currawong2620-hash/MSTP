//+------------------------------------------------------------------+
//| ArchitectureTypes.mqh — Architecture Data Types v1.0             |
//| Infrastructure / Contract Projection                              |
//| STRICT MQL5, no #pragma once                                      |
//| Single Source: CONTRACT_LEXICON v1.0                              |
//+------------------------------------------------------------------+
#ifndef __ARCHITECTURE_TYPES_MQH__
#define __ARCHITECTURE_TYPES_MQH__

//--------------------------------------------------------------------
// ENUMS (exactly as in CONTRACT_LEXICON)
//--------------------------------------------------------------------

// Intent categories
enum intent_type
{
   NO_ACTION = 0,
   WANT_OPEN,
   WANT_CLOSE,
   WANT_HOLD
};

// Decision status
enum decision_status
{
   ACCEPT = 0,
   REJECT,
   MODIFY
};

enum decision_action
{
   OPEN = 0,
   CLOSE
};

// Execution status
enum execution_status
{
   EXECUTED = 0,
   REJECTED,
   PARTIAL,
   FAILED
};

// Feedback events
enum feedback_event
{
   POSITION_OPENED = 0,
   POSITION_CLOSED,
   STOP_HIT,
   TARGET_HIT,
   ACTION_REJECTED
};

//--------------------------------------------------------------------
// SNAPSHOT SUBSTRUCTURES
//--------------------------------------------------------------------

// Snapshot.market
struct MarketSnapshot
{
   string symbol;
   int    tf;
   double open;
   double high;
   double low;
   double close;
   double volume;
   double bid;
   double ask;
   double spread;
};

// Snapshot.position
struct PositionSnapshot
{
   bool   has_position;
   int    direction;        // -1 / +1
   double volume;
   double entry_price;
   double floating_pnl;
};

// Snapshot.time
struct TimeContext
{
   long timestamp;
   bool is_new_bar;
   int  bars_since_entry;
   int  bars_since_last_action;
};

// Snapshot.constraints
struct MarketConstraints
{
   double min_lot;
   double lot_step;
   double min_stop;
   bool   is_trading_allowed;
};

//--------------------------------------------------------------------
// ARCHITECTURAL ROOT TYPES
//--------------------------------------------------------------------

// Snapshot
struct Snapshot
{
   MarketSnapshot    market;
   PositionSnapshot  position;
   TimeContext       time;
   MarketConstraints constraints;
};

// Intent
struct Intent
{
   intent_type type;
   int         direction;   // -1 / 0 / +1
   double      confidence;  // 0.0 .. 1.0
};

// PolicyAdjustedIntent
struct PolicyAdjustedIntent
{
   intent_type type;
   int         direction;
   double      volume;
   string      tag;
};

// direction semantic type already used in your system: -1 / 0 / +1
// (type name must match your existing Lexicon / ArchitectureTypes conventions)

struct Decision
{
   decision_status status;
   decision_action action;
   int             direction;  // -1 / 0 / +1
   double          volume;
   string          symbol;
   string          reason;
};

// ExecutionResult
struct ExecutionResult
{
   execution_status status;
   double           filled_volume;
   double           price;
};

// Feedback
struct Feedback
{
   feedback_event event;
   double         pnl;
   string         message;
};

#endif // __ARCHITECTURE_TYPES_MQH__
