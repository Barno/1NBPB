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

  string arrowObjectName = "FilledArrow_" + IntegerToString(GetTickCount());

  // Crea freccia
  bool arrowSuccess = ObjectCreate(0, arrowObjectName, OBJ_TEXT, 0, orarioCandela, price);

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
      ObjectSetString(0, labelObjectName, OBJPROP_TEXT, orarioCandela);
      ObjectSetString(0, labelObjectName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, labelObjectName, OBJPROP_FONTSIZE, fontSize / 2);
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
  int deleted = ObjectsDeleteAll(0); // Elimina tutti gli oggetti dal grafico
  Print("Eliminati ", deleted, " oggetti");
  return deleted > 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
DrawOnChart::~DrawOnChart()
{
}
//+------------------------------------------------------------------+
