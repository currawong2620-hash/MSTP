//+------------------------------------------------------------------+
//| Observer_Minimal.mqh — Observer minimal stub                      |
//| Infrastructure support for scenario build                          |
//| STRICT MQL5, no #pragma once                                      |
//+------------------------------------------------------------------+
#ifndef __OBSERVER_MINIMAL_MQH__
#define __OBSERVER_MINIMAL_MQH__

#include "../../Infrastructure/ArchitectureTypes.mqh"

// Minimal internal toggle for bar simulation
static bool g_observer_toggle_new_bar = false;

void Observer_Run(
   Snapshot &out_snapshot
)
{
   ZeroMemory(out_snapshot);

   // Simulate alternating "new bar" to advance scenario deterministically
   g_observer_toggle_new_bar = !g_observer_toggle_new_bar;
   out_snapshot.time.is_new_bar = g_observer_toggle_new_bar;

   // Timestamp is not required for scenario build; keep 0.
   out_snapshot.time.timestamp = 0;

   // Default position state: no position
   out_snapshot.position.has_position = false;
   out_snapshot.position.direction = 0;
   out_snapshot.position.volume = 0.0;
   out_snapshot.position.entry_price = 0.0;
   out_snapshot.position.floating_pnl = 0.0;

   // Constraints: allow trading by default
   out_snapshot.constraints.min_lot = 0.01;
   out_snapshot.constraints.lot_step = 0.01;
   out_snapshot.constraints.min_stop = 0.0;
   out_snapshot.constraints.is_trading_allowed = true;

   // MarketSnapshot left zero-filled (not used by scenario roles)
}

#endif // __OBSERVER_MINIMAL_MQH__
