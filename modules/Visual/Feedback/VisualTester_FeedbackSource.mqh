//+------------------------------------------------------------------+
//| VisualTester_FeedbackSource.mqh — VisualTester_FeedbackSource v0.1|
//| Visual Observability / FeedbackSource                             |
//| STRICT MQL5, no #pragma once                                      |
//| Read-only: visualizes ONLY Feedback                               |
//+------------------------------------------------------------------+
#ifndef __VISUAL_TESTER_FEEDBACK_SOURCE_MQH__
#define __VISUAL_TESTER_FEEDBACK_SOURCE_MQH__

#define VT_FS_HISTORY_SIZE 8

//--------------------------------------------------------------------
// Required types (Feedback only)
//--------------------------------------------------------------------
#include "../../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// UI adapter (external module; do not modify)
//--------------------------------------------------------------------
#include "../../UI/InfoPanel.mqh"

//--------------------------------------------------------------------
// VisualTester_FeedbackSource
//--------------------------------------------------------------------
class VisualTester_FeedbackSource
{
private:
   InfoPanel panel;
   bool      initialized;

   // History (display-only)
   Feedback history[VT_FS_HISTORY_SIZE];
   int      history_count;

   // UI constants
   string prefix;

private:
   // Convert feedback_event to enum name
   string eventToString(const feedback_event e) const
   {
      return EnumToString(e);
   }

   // Push feedback into history (no aggregation, no smoothing)
   void pushHistory(const Feedback &fb)
   {
      if(history_count < VT_FS_HISTORY_SIZE)
      {
         history[history_count] = fb;
         history_count++;
         return;
      }

      // Shift left: [1]..[N-1] -> [0]..[N-2]
      for(int i = 1; i < VT_FS_HISTORY_SIZE; i++)
         history[i - 1] = history[i];

      history[VT_FS_HISTORY_SIZE - 1] = fb;
   }

   // Render CURRENT FEEDBACK (Section 0)
   void buildSection0(const Feedback &fb)
   {
      panel.ClearSection(0);

      string line;

      line = "EVENT: " + eventToString(fb.event);
      panel.AddLine(0, line);

      line = "PNL  : " + DoubleToString(fb.pnl, 2);
      panel.AddLine(0, line);

      line = "MSG  : " + fb.message;
      panel.AddLine(0, line);
   }

   // Render FEEDBACK HISTORY (Section 1)
   void buildSection1()
   {
      panel.ClearSection(1);

      // Show newest first: [0] newest
      int idx = 0;
      for(int i = history_count - 1; i >= 0; i--)
      {
         string line = "[" + (string)idx + "] "
                       + eventToString(history[i].event)
                       + " pnl=" + DoubleToString(history[i].pnl, 2);

         panel.AddLine(1, line);
         idx++;
      }
   }

public:
   VisualTester_FeedbackSource()
   {
      initialized   = false;
      history_count = 0;
      prefix        = "VT_FS";
   }

   // Init: create panel, set section titles, do not output data
   bool Init()
   {
      PanelConfig cfg;
      cfg.width            = 360;
      cfg.height           = 220;
      cfg.x                = 10;
      cfg.y                = 250;   // ниже VT_DM, чтобы не перекрывались
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

      panel.SetSectionTitle(0, "FEEDBACK");
      panel.SetSectionTitle(1, "FEEDBACK HISTORY");

      // Section 2 and 3 are not used: leave titles empty, no lines.

      initialized   = true;
      history_count = 0;

      return true;
   }

   // Update: must display EACH feedback, no skipping, no aggregation
   void Update(const Feedback &fb)
   {
      if(!initialized)
         return;

      pushHistory(fb);

      buildSection0(fb);
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

#endif // __VISUAL_TESTER_FEEDBACK_SOURCE_MQH__
