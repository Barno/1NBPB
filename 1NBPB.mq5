//+------------------------------------------------------------------+
//|                                                MyLearningEA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd.sss "
#property link "https://www.mql5.com"
#property version "1.00"

#include "DrawOnChart.mqh"
#include "Utils.mqh"
#include "Account.mqh"
#include "Logger.mqh"

input group "===  ORA CANDELA DI RIFERIMENTO ===" 
input int referenceCandleTimeframe = PERIOD_M5; // Timeframe della candela di riferimento
input int hourInput = 8; // Ora Candela di riferimento
input int minuteInput = 0; // Minuti di riferimento per l'operazione

input group "===  LIVELLO DI LOG ===" 
input Logger::LOG_LEVEL logLevel = Logger::LOG_INFO; // Livello di log
input bool silentMode = true; // Zittisce tutti i print

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

    Logger::SetLogLevel(logLevel);
    Logger::SetSilentMode(silentMode);    
    Logger::Info("EA initialized");
    Logger::Debug("Debug info");

    if (drawOnChart == NULL)
    {
        Logger::LogError("Failed to create DrawOnChart instance");
        return INIT_FAILED;
    }

    if (!drawOnChart.DrawArrow(0, Utils::CreateDateTime(hourInput, minuteInput)))
    {
        Logger::LogError("Failed to draw arrow on chart at " + TimeToString(Utils::CreateDateTime(hourInput, minuteInput), TIME_DATE | TIME_MINUTES));
        return INIT_FAILED;
    }

    if (!Account::Initialize())
    {
        Logger::LogError("Account initialization failed. Check account settings.");
        return INIT_FAILED; // Inizializza l'account e gestisce errori
    } // Inizializza l'account

    Logger::Debug("Account initialized successfully with balance: " + DoubleToString(Account::GetBalance(), 2) + " " + Account::GetCurrency());

    EventSetTimer(60);
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer(); // Cleanup del timer
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
}
//+------------------------------------------------------------------+
void OnTimer()
{
    static datetime lastCheckDay = Utils::GetDateOnly(TimeCurrent()); // Non viene rinizializzato ad ogni OnTimer.
    datetime currentDay = Utils::GetDateOnly(TimeCurrent());

    if (currentDay != lastCheckDay)
    {
        Print(" Nuovo giorno: ", TimeToString(currentDay, TIME_DATE));

        drawOnChart.DeleteAllObjects();
        drawOnChart.DrawArrow(0, Utils::CreateDateTime(hourInput, minuteInput));

        lastCheckDay = currentDay;
    }
}