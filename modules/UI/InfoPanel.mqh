//+------------------------------------------------------------------+
//| InfoPanel.mqh — InfoPanel 2.0 (UI Output Module)                 |
//| Строго MQL5, без #pragma once, без MT4-синтаксиса                |
//| Непрозрачная панель на базе OBJ_BUTTON + 4 секции текста         |
//+------------------------------------------------------------------+

// ------------------------------------------------------------
// Конфигурация панели
// ------------------------------------------------------------
struct PanelConfig
  {
   int   width;             // ширина панели
   int   height;            // высота панели
   int   x;                 // позиция X (пиксели)
   int   y;                 // позиция Y (пиксели)

   int   row_height;        // высота строки
   int   header_height;     // высота заголовка

   color background_color;  // цвет фона панели
   color header_color;      // цвет заголовков
   color text_color;        // цвет строк

   bool  draw_border;       // рисовать рамку панели
  };

// ------------------------------------------------------------
// Секция панели
// ------------------------------------------------------------
struct PanelSection
  {
   string title;
   string rows[];
  };

//+------------------------------------------------------------------+
//| Класс InfoPanel                                                  |
//+------------------------------------------------------------------+
class InfoPanel
  {
private:
   PanelConfig  cfg;
   PanelSection sections[4];
   string       prefix;
   int          last_row_counts[4];
   bool         initialized;

   // ---------------------------------------------------------
   // Проверка индекса секции
   // ---------------------------------------------------------
   bool IsValidIndex(const int index) const
     {
      return (index >= 0 && index < 4);
     }

   // ---------------------------------------------------------
   // Создание/обновление фона на OBJ_BUTTON (непрозрачный)
   // ---------------------------------------------------------
   bool CreateOrUpdateBackground()
     {
      string name = prefix + "_BG";

      if(ObjectFind(0, name) == -1)
        {
         if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
            return false;
        }

      // Позиционирование в пикселях, поверх графика
      ObjectSetInteger(0, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  cfg.x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  cfg.y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE,      cfg.width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE,      cfg.height);

      ObjectSetInteger(0, name, OBJPROP_BACK,       false); // перед графиком
      ObjectSetInteger(0, name, OBJPROP_ZORDER,     9999);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,     false);

      // Полная непрозрачность
      ObjectSetString (0, name, OBJPROP_TEXT,       ""); // без текста
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR,    cfg.background_color);
      ObjectSetInteger(0, name, OBJPROP_COLOR,      cfg.background_color);

      // Рамка панели
      color border = cfg.draw_border ? cfg.header_color : cfg.background_color;
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);

      return true;
     }

   // ---------------------------------------------------------
   // Создание / обновление текстового лейбла
   // ---------------------------------------------------------
   bool CreateOrUpdateLabel(const string name,
                            const int    x,
                            const int    y,
                            const color  clr,
                            const string text)
     {
      if(ObjectFind(0, name) == -1)
        {
         if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
            return false;
        }

      ObjectSetInteger(0, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(0, name, OBJPROP_BACK,       false);   // поверх графика
      ObjectSetInteger(0, name, OBJPROP_ZORDER,     10000);   // выше фона
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,     false);

      ObjectSetString (0, name, OBJPROP_TEXT,       text);
      ObjectSetString (0, name, OBJPROP_FONT,       "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   10);
      ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);

      return true;
     }

public:
   // ---------------------------------------------------------
   // Конструктор
   // ---------------------------------------------------------
   InfoPanel(void)
     {
      initialized = false;
      prefix      = "";

      for(int i=0; i<4; i++)
        {
         sections[i].title = "";
         ArrayResize(sections[i].rows, 0);
         last_row_counts[i] = 0;
        }
     }

   // ---------------------------------------------------------
   // Инициализация панели
   // ---------------------------------------------------------
   bool Init(const PanelConfig &config, const string &pref)
     {
      // На всякий случай чистим старые объекты
      Destroy();

      cfg        = config;
      prefix     = pref;
      initialized = true;

      for(int i=0; i<4; i++)
        {
         sections[i].title = "";
         ArrayResize(sections[i].rows, 0);
         last_row_counts[i] = 0;
        }

      if(!CreateOrUpdateBackground())
        {
         initialized = false;
         return false;
        }

      return true;
     }

   // ---------------------------------------------------------
   // Установка заголовка секции (без Render)
   // ---------------------------------------------------------
   void SetSectionTitle(const int index, const string &title)
     {
      if(!initialized || !IsValidIndex(index))
         return;

      sections[index].title = title;
     }

   // ---------------------------------------------------------
   // Очистка секции (строки, без Render)
   // ---------------------------------------------------------
   void ClearSection(const int index)
     {
      if(!initialized || !IsValidIndex(index))
         return;

      ArrayResize(sections[index].rows, 0);
     }

   // ---------------------------------------------------------
   // Добавление строки в секцию (без Render)
   // ---------------------------------------------------------
   void AddLine(const int index, const string &text)
     {
      if(!initialized || !IsValidIndex(index))
         return;

      int n = ArraySize(sections[index].rows);
      ArrayResize(sections[index].rows, n + 1);
      sections[index].rows[n] = text;
     }

   // ---------------------------------------------------------
   // Полная перерисовка панели
   // ---------------------------------------------------------
   void Render()
     {
      if(!initialized)
         return;

      // Фон
      if(!CreateOrUpdateBackground())
         return;

      int y_cur = cfg.y + 6; // небольшой внутренний отступ сверху

      for(int s=0; s<4; s++)
        {
         // ----------------------
         // 1. Заголовок секции
         // ----------------------
         string hdr_name = prefix + "_S" + (string)s + "_HDR";

         if(!CreateOrUpdateLabel(hdr_name,
                                 cfg.x + 8,
                                 y_cur,
                                 cfg.header_color,
                                 sections[s].title))
            return;

         y_cur += cfg.header_height;

         // ----------------------
         // 2. Строки секции
         // ----------------------
         int rows_new = ArraySize(sections[s].rows);

         for(int r=0; r<rows_new; r++)
           {
            string row_name = prefix + "_S" + (string)s + "_R" + (string)r;

            if(!CreateOrUpdateLabel(row_name,
                                    cfg.x + 14,
                                    y_cur,
                                    cfg.text_color,
                                    sections[s].rows[r]))
               return;

            y_cur += cfg.row_height;
           }

         // ----------------------
         // 3. Удаление лишних строк
         // ----------------------
         int rows_prev = last_row_counts[s];
         if(rows_prev > rows_new)
           {
            for(int k=rows_new; k<rows_prev; k++)
              {
               string oldname = prefix + "_S" + (string)s + "_R" + (string)k;
               if(ObjectFind(0, oldname) != -1)
                  ObjectDelete(0, oldname);
              }
           }

         last_row_counts[s] = rows_new;

         // ----------------------
         // 4. Межсекционный отступ
         // ----------------------
         y_cur += 6;
        }
     }

   // ---------------------------------------------------------
   // Уничтожение панели и всех её объектов
   // ---------------------------------------------------------
   void Destroy()
     {
      if(prefix != "")
         ObjectsDeleteAll(0, prefix);

      initialized = false;

      for(int i=0; i<4; i++)
        {
         sections[i].title = "";
         ArrayResize(sections[i].rows, 0);
         last_row_counts[i] = 0;
        }
     }
  };
