//+------------------------------------------------------------------+
//|                                                MyLearningEA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd.sss "
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "DrawOnChart.mqh"

input group "===  ORA CANDELA DI RIFERIMENTO ===" 
input int referenceCandleTimeframe = PERIOD_M5; // Timeframe della candela di riferimento
input int hourInput = 8; // Ora di riferimento per l'operazione
input int minuteInput = 0; // Minuti di riferimento per l'operazione

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

DrawOnChart *drawOnChart = NULL; // Istanza della classe per disegnare sul grafico

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
 {    
    drawOnChart = new DrawOnChart();    
    if (drawOnChart == NULL)
    {
        Print("Failed to create DrawOnChart instance");
        return INIT_FAILED;
    }

    drawOnChart.DrawArrow(); 
    
    
  return(INIT_SUCCEEDED);
 }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
 {
  
 }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {


 }
//+------------------------------------------------------------------+