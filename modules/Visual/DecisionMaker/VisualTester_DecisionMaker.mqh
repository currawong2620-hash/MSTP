//+------------------------------------------------------------------+
//| VisualTester_DecisionMaker.mqh — VisualTester_DecisionMaker v0.1 |
//| Visual Observability / DecisionMaker                             |
//| STRICT MQL5, no #pragma once                                      |
//| Read-only: visualizes ONLY Intent                                 |
//+------------------------------------------------------------------+
#ifndef __VISUAL_TESTER_DECISION_MAKER_MQH__
#define __VISUAL_TESTER_DECISION_MAKER_MQH__
#define VT_DM_HISTORY_SIZE 8

//--------------------------------------------------------------------
// Required types (Intent only)
//--------------------------------------------------------------------
#include "../../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// UI adapter (external module; do not modify)
//--------------------------------------------------------------------
#include "../../UI/InfoPanel.mqh"

//--------------------------------------------------------------------
// VisualTester_DecisionMaker
//--------------------------------------------------------------------
class VisualTester_DecisionMaker
{
private:
   InfoPanel panel;
   bool      initialized;

   // History (display-only)
   Intent history[VT_DM_HISTORY_SIZE];
   int    history_count;

   // UI constants
   string prefix;

private:
   // Convert intent_type to enum name
   string typeToString(const intent_type t) const
   {
      return EnumToString(t);
   }

   // Convert direction to "+1"/"0"/"-1" (with sign for +1)
   string directionToString(const int d) const
   {
      if(d > 0)  return "+1";
      if(d < 0)  return "-1";
      return "0";
   }

   // Push intent into history (no aggregation, no smoothing)
   void pushHistory(const Intent &intent)
   {
      if(history_count < VT_DM_HISTORY_SIZE)
      {
         history[history_count] = intent;
         history_count++;
         return;
      }

      // Shift left: [1]..[N-1] -> [0]..[N-2]
      for(int i = 1; i < VT_DM_HISTORY_SIZE; i++)
         history[i - 1] = history[i];

      history[VT_DM_HISTORY_SIZE - 1] = intent;
   }

   // Render CURRENT INTENT (Section 0)
   void buildSection0(const Intent &intent)
   {
      panel.ClearSection(0);

      string line;

      line = "TYPE: " + typeToString(intent.type);
      panel.AddLine(0, line);
      
      line = "DIR : " + directionToString(intent.direction);
      panel.AddLine(0, line);
      
      line = "CONF: " + DoubleToString(intent.confidence, 2);
      panel.AddLine(0, line);

   }

   // Render INTENT HISTORY (Section 1)
   void buildSection1()
   {
      panel.ClearSection(1);

      // Show newest first: [0] newest
      int idx = 0;
      for(int i = history_count - 1; i >= 0; i--)
      {
         string line = "[" + (string)idx + "] " + typeToString(history[i].type)
                       + "  dir=" + directionToString(history[i].direction)
                       + " conf=" + DoubleToString(history[i].confidence, 2);

         panel.AddLine(1, line);
         idx++;
      }
   }

public:
   VisualTester_DecisionMaker()
   {
      initialized   = false;
      history_count = 0;
      prefix        = "VT_DM";
   }

   // Init: create panel, set section titles, do not output data
   bool Init()
   {
      PanelConfig cfg;
      cfg.width            = 360;
      cfg.height           = 220;
      cfg.x                = 10;
      cfg.y                = 20;
      cfg.row_height       = 16;
      cfg.header_height    = 18;
      cfg.background_color = (color)0x202020;
      cfg.header_color     = (color)0xFFFFFF;
      cfg.text_color       = (color)0xD0D0D0;
      cfg.draw_border      = true;

      if(!panel.Init(cfg, prefix))
      {
         initialized = false;
         return false;
      }

      panel.SetSectionTitle(0, "DECISION MAKER");
      panel.SetSectionTitle(1, "INTENT HISTORY");

      // Section 2 and 3 are not used: leave titles empty, no lines.

      initialized   = true;
      history_count = 0;

      return true;
   }

   // Update: must display EACH intent, no skipping, no aggregation
   void Update(const Intent &intent)
   {
      if(!initialized)
         return;

      pushHistory(intent);

      buildSection0(intent);
      buildSection1();

      panel.Render();
   }

   // Deinit: destroy panel objects
   void Deinit()
   {
      panel.Destroy();
      initialized   = false;
      history_count = 0;
   }
};

#endif // __VISUAL_TESTER_DECISION_MAKER_MQH__
