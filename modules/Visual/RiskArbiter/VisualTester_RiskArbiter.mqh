//+------------------------------------------------------------------+
//| VisualTester_RiskArbiter.mqh — VT-RA v0.1                         |
//| Visual Observability / RiskArbiter                                |
//| STRICT MQL5, no #pragma once                                      |
//| Read-only: visualizes ONLY PolicyAdjustedIntent + Decision         |
//+------------------------------------------------------------------+
#ifndef __VISUAL_TESTER_RISK_ARBITER_MQH__
#define __VISUAL_TESTER_RISK_ARBITER_MQH__

//--------------------------------------------------------------------
// Required architectural types (Lexicon projection)
//--------------------------------------------------------------------
#include "../../Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// UI adapter (external module; do not modify)
//--------------------------------------------------------------------
#include "../../UI/InfoPanel.mqh"

//--------------------------------------------------------------------
// VisualTester_RiskArbiter
//--------------------------------------------------------------------
class VisualTester_RiskArbiter
{
private:
   InfoPanel panel;
   bool      initialized;
   string    prefix;

private:
   string typeToString(const intent_type t) const
   {
      return EnumToString(t);
   }

   string statusToString(const decision_status s) const
   {
      return EnumToString(s);
   }

   string directionToString(const int d) const
   {
      if(d > 0)  return "+1";
      if(d < 0)  return "-1";
      return "0";
   }

   void buildSection0(const PolicyAdjustedIntent &policy_intent)
   {
      panel.ClearSection(0);

      string line;

      line = "TYPE: " + typeToString(policy_intent.type);
      panel.AddLine(0, line);

      line = "DIR : " + directionToString(policy_intent.direction);
      panel.AddLine(0, line);

      line = "VOL : " + DoubleToString(policy_intent.volume, 2);
      panel.AddLine(0, line);
   }

   void buildSection1(const Decision &decision)
   {
      panel.ClearSection(1);

      string line;

      line = "STATUS: " + statusToString(decision.status);
      panel.AddLine(1, line);

      // Optional fields allowed by CONTRACT_LEXICON v1.0 (Decision.volume, Decision.reason)
      line = "VOL   : " + DoubleToString(decision.volume, 2);
      panel.AddLine(1, line);

      line = "REASON: " + decision.reason;
      panel.AddLine(1, line);
   }

public:
   VisualTester_RiskArbiter()
   {
      initialized = false;
      prefix      = "VT_RA";
   }

   bool Init()
   {
      PanelConfig cfg;
      cfg.width            = 360;
      cfg.height           = 220;
      cfg.x                = 10;
      cfg.y                = 480;
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

      panel.SetSectionTitle(0, "RISK ARBITER");
      panel.SetSectionTitle(1, "DECISION");
      // Sections 2 and 3 intentionally unused

      initialized = true;
      return true;
   }

   void Update(
      const PolicyAdjustedIntent &policy_intent,
      const Decision             &decision
   )
   {
      if(!initialized)
         return;

      buildSection0(policy_intent);
      buildSection1(decision);

      panel.Render();
   }

   void Deinit()
   {
      panel.Destroy();
      initialized = false;
   }
};

#endif // __VISUAL_TESTER_RISK_ARBITER_MQH__
