//+------------------------------------------------------------------+
//| VisualTester_PositionPolicyManager.mqh — VT-PPM v0.1              |
//| Visual Observability / PositionPolicyManager                      |
//| STRICT MQL5, no #pragma once                                      |
//| Read-only: visualizes ONLY Intent + PolicyAdjustedIntent[]         |
//+------------------------------------------------------------------+
#ifndef __VISUAL_TESTER_POSITION_POLICY_MANAGER_MQH__
#define __VISUAL_TESTER_POSITION_POLICY_MANAGER_MQH__

//--------------------------------------------------------------------
// Required architectural types
//--------------------------------------------------------------------
#include "../../../modules/Infrastructure/ArchitectureTypes.mqh"

//--------------------------------------------------------------------
// UI adapter (external module; do not modify)
//--------------------------------------------------------------------
#include "../../UI/InfoPanel.mqh"

//--------------------------------------------------------------------
// VisualTester_PositionPolicyManager
//--------------------------------------------------------------------
class VisualTester_PositionPolicyManager
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

   string directionToString(const int d) const
   {
      if(d > 0)  return "+1";
      if(d < 0)  return "-1";
      return "0";
   }

   void buildSection0(const Intent &intent)
   {
      panel.ClearSection(0);

      string line;

      line = "SRC TYPE: " + typeToString(intent.type);
      panel.AddLine(0, line);

      line = "SRC DIR : " + directionToString(intent.direction);
      panel.AddLine(0, line);
   }

   void buildSection1(PolicyAdjustedIntent &policy_intents[],
                      const int policy_count)
   {
      panel.ClearSection(1);

      string line;

      if(policy_count <= 0)
        {
         line = "(no policy intents)";
         panel.AddLine(1, line);
         return;
        }

      for(int i = 0; i < policy_count; i++)
        {
         line = "[#" + (string)i + "] " + typeToString(policy_intents[i].type)
                + " dir=" + directionToString(policy_intents[i].direction)
                + " vol=" + DoubleToString(policy_intents[i].volume, 2);

         panel.AddLine(1, line);
        }
   }

public:
   VisualTester_PositionPolicyManager()
   {
      initialized = false;
      prefix      = "VT_PPM";
   }

   bool Init()
   {
      PanelConfig cfg;
      cfg.width            = 360;
      cfg.height           = 220;
      cfg.x                = 10;
      cfg.y                = 250;
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

      panel.SetSectionTitle(0, "POSITION POLICY");
      panel.SetSectionTitle(1, "POLICY OUTPUT");
      // Sections 2 and 3 intentionally unused

      initialized = true;
      return true;
   }

   void Update(
      const Intent &intent,
      PolicyAdjustedIntent &policy_intents[],
      const int policy_count
   )
   {
      if(!initialized)
         return;

      buildSection0(intent);
      buildSection1(policy_intents, policy_count);

      panel.Render();
   }

   void Deinit()
   {
      panel.Destroy();
      initialized = false;
   }
};

#endif // __VISUAL_TESTER_POSITION_POLICY_MANAGER_MQH__
