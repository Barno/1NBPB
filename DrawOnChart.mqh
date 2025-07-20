//+------------------------------------------------------------------+
//|                                                 DrawOnChart.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link "https://www.mql5.com"

#include "ErrorLogger.mqh"
//+------------------------------------------------------------------+
//| DrawOnChart class                                                |
//+------------------------------------------------------------------+
class DrawOnChart
{
private:
public:
  DrawOnChart();
  bool DrawArrow(double price = 0, datetime orarioCandela = 0, int fontSize = 32);
  bool DeleteAllObjects();
  ~DrawOnChart();
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
DrawOnChart::DrawOnChart()
{
  Print("DrawOnChart class initialized");
}

bool DrawOnChart::DrawArrow(double price, datetime orarioCandela, int fontSize)
{
  if (price == 0)
    price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

  if (orarioCandela == 0)
    orarioCandela = TimeCurrent();

  string arrowObjectName = "VerticalLine_" + IntegerToString(GetTickCount());

  // Crea freccia
  bool arrowSuccess = ObjectCreate(0, arrowObjectName, OBJ_VLINE, 0, orarioCandela, price);

  if (arrowSuccess)
  {
    // Configura freccia
    ObjectSetString(0, arrowObjectName, OBJPROP_TEXT, "▲");
    ObjectSetString(0, arrowObjectName, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, arrowObjectName, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, arrowObjectName, OBJPROP_COLOR, clrGreen);
    ObjectSetInteger(0, arrowObjectName, OBJPROP_ANCHOR, ANCHOR_CENTER);

    // ✅ CREA LABEL CON GESTIONE ERRORI COMPLETA
    double arrowPrice = ObjectGetDouble(0, arrowObjectName, OBJPROP_PRICE);
    double offset = 50 * _Point;
    double labelPrice = arrowPrice - offset;

    string labelObjectName = arrowObjectName + "_Label";
    bool labelSuccess = ObjectCreate(0, labelObjectName, OBJ_TEXT, 0, orarioCandela, labelPrice);

    if (labelSuccess)
    {
      ObjectSetString(0, labelObjectName, OBJPROP_TEXT, TimeToString(orarioCandela, TIME_MINUTES));
      ObjectSetString(0, labelObjectName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, labelObjectName, OBJPROP_FONTSIZE, fontSize / 4);
      ObjectSetInteger(0, labelObjectName, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, labelObjectName, OBJPROP_ANCHOR, ANCHOR_CENTER);
    }
    else
    {
      ErrorLogger::LogError("ERRORE creazione label: " + labelObjectName);
      return false;
    }

    return true;
  }
  else
  {
    ErrorLogger::LogError("ERRORE creazione Arrow: " + arrowObjectName);
    return false;
  }
}

bool DrawOnChart::DeleteAllObjects()
{

  // 1. Conta oggetti PRIMA della cancellazione
  int totalBefore = ObjectsTotal(0);

  // 2. Lista tutti gli oggetti presenti
  for (int i = 0; i < totalBefore; i++)
  {
    string objName = ObjectName(0, i);
    ENUM_OBJECT objType = (ENUM_OBJECT)ObjectGetInteger(0, objName, OBJPROP_TYPE);
    Print("Oggetto #", i, ": ", objName, " (Tipo: ", EnumToString(objType), ")");
  }

  // 3. Prova la cancellazione
  int deleted = ObjectsDeleteAll(0);

  // 4. Conta oggetti DOPO
  int totalAfter = ObjectsTotal(0);

  // 5. Se qualcosa rimane, prova cancellazione manuale
  if (totalAfter > 0)
  {

    for (int i = totalAfter - 1; i >= 0; i--) // Dal fondo verso l'alto
    {
      string objName = ObjectName(0, i);
      bool success = ObjectDelete(0, objName);

      if (!success)
      {
        // Forza proprietà e riprova
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
        success = ObjectDelete(0, objName);
      }
    }
  }

  // 6. Forza refresh
  ChartRedraw(0);

  return deleted > 0 || totalBefore > totalAfter;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
DrawOnChart::~DrawOnChart()
{
}
//+------------------------------------------------------------------+
