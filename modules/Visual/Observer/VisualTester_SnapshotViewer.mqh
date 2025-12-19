//+------------------------------------------------------------------+
//| VisualTester_SnapshotViewer.mqh                                   |
//| Visual Observability — Observer (Snapshot Viewer)                 |
//| STRICT MQL5, no #pragma once                                      |
//+------------------------------------------------------------------+
#ifndef __VISUAL_TESTER_SNAPSHOT_VIEWER_MQH__
#define __VISUAL_TESTER_SNAPSHOT_VIEWER_MQH__

#include "../../Infrastructure/ArchitectureTypes.mqh"

class VisualTester_SnapshotViewer
{
public:
   void Update(const Snapshot &snapshot)
   {
      string text = "";

      text += "=== Snapshot Viewer (Observer) ===\n";

      // market
      text += "MARKET\n";
      text += "symbol=" + snapshot.market.symbol + "\n";
      text += "tf=" + IntegerToString((int)snapshot.market.tf) + "\n";
      text += StringFormat("O=%.5f H=%.5f L=%.5f C=%.5f V=%.0f\n",
                           snapshot.market.open,
                           snapshot.market.high,
                           snapshot.market.low,
                           snapshot.market.close,
                           snapshot.market.volume);
      text += StringFormat("bid=%.5f ask=%.5f spread=%.5f\n",
                           snapshot.market.bid,
                           snapshot.market.ask,
                           snapshot.market.spread);

      // position
      text += "\nPOSITION\n";
      text += StringFormat("has_position=%s\n", snapshot.position.has_position ? "true" : "false");
      text += StringFormat("direction=%d\n", snapshot.position.direction);
      text += StringFormat("volume=%.2f entry_price=%.5f floating_pnl=%.2f\n",
                           snapshot.position.volume,
                           snapshot.position.entry_price,
                           snapshot.position.floating_pnl);

      // time
      text += "\nTIME\n";
      text += StringFormat("timestamp=%s\n", TimeToString(snapshot.time.timestamp, TIME_DATE|TIME_SECONDS));
      text += StringFormat("is_new_bar=%s\n", snapshot.time.is_new_bar ? "true" : "false");
      text += StringFormat("bars_since_entry=%d bars_since_last_action=%d\n",
                           snapshot.time.bars_since_entry,
                           snapshot.time.bars_since_last_action);

      // constraints
      text += "\nCONSTRAINTS\n";
      text += StringFormat("is_trading_allowed=%s\n", snapshot.constraints.is_trading_allowed ? "true" : "false");
      text += StringFormat("min_lot=%.2f lot_step=%.2f min_stop=%.5f\n",
                           snapshot.constraints.min_lot,
                           snapshot.constraints.lot_step,
                           snapshot.constraints.min_stop);

      Comment(text);
   }
};

#endif // __VISUAL_TESTER_SNAPSHOT_VIEWER_MQH__
