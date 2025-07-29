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
#include "TimeUtils.mqh"
#include "Account.mqh"
#include "Logger.mqh"
#include "Asset.mqh"
#include "CandleAnalyzer.mqh"
#include "TradingExecutor.mqh"

input group "===  ORA CANDELA DI RIFERIMENTO ===";
input ENUM_TIMEFRAMES referenceCandleTimeframe = PERIOD_M5; // Timeframe per candela di riferimento
input int hourInput = 8;                                    // Ora Candela di riferimento
input int minuteInput = 0;                                  // Minuti di riferimento per l'operazione

input group "===  LIVELLO DI LOG ===";
input Logger::LOG_LEVEL logLevel = Logger::LOG_DEBUG; // Livello di log

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
DrawOnChart *drawOnChart = NULL; // Istanza della classe per disegnare sul grafico
datetime currentTime;            // Variabile per tenere traccia del tempo corrente
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    drawOnChart = new DrawOnChart();
    Logger::SetLogLevel(logLevel);
    Logger::Debug("DrawOnChart instance created");
    Logger::Info("EA initialized");
    Logger::Info("MIN LOT " + Asset::GetMinLot(_Symbol)); // Esempio di chiamata per verificare Asset
    Logger::Info("STEP " + Asset::GetLotStep(_Symbol));
    Logger::Info("Dimensione di un contratto " + Asset::GetContractSize(_Symbol));

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
    // Logger::Info("Current Bid: " + DoubleToString(Asset::GetBid(_Symbol), 5));
    // Logger::Info("Current Ask: " + DoubleToString(Asset::GetAsk(_Symbol), 5));
    // Logger::Info("Point Spread: " + IntegerToString(Asset::GetPointSpread(_Symbol)));
    // Logger::Info("Current Spread: " + DoubleToString(Asset::GetSpread(_Symbol), 5));

    // Logger::Info("Prezzo Neutrale "+Asset::GetLastPrice(_Symbol));
    // Logger::Info("Costo BUY "+Asset::GetLotCost(_Symbol, Asset::GetMinLot(_Symbol),Asset::BUY)); // Esempio di chiamata per verificare Asset
    // Logger::Info("Costo SELL "+Asset::GetLotCost(_Symbol, Asset::GetMinLot(_Symbol),Asset::SELL)); // Esempio di chiamata per verificare Asset
    // Logger::Info("Margin Richiesto Buy "+Asset::GetMarginRequired(_Symbol, 0.01));
    // Logger::Info("Margin Richiesto Sell "+Asset::GetMarginRequired(_Symbol, 0.01, Asset::SELL));
    // Logger::Info("Margine Libero "+Asset::FreeMarginAvailable());

    // Calcola minuti aggiuntivi dal timeframe
    checkCandle();
}
//+------------------------------------------------------------------+
void checkCandle()
{
    static int additionalMinutes = -1; // Inizializza una volta sola

    if (additionalMinutes == -1)
    {
        additionalMinutes = TimeUtils::getMinutesFromPeriod(referenceCandleTimeframe);
    }

    if (TradingExecutor::ShouldExecuteTrade(hourInput, minuteInput, additionalMinutes, 0, 20))
    {
        Logger::Debug("GetExecutedDate: " + TimeToString(TradingExecutor::GetExecutedDate(), TIME_DATE));
        Print("ESEGUO TRADE!");

        // Usa gli input invece di valori hardcodati
        CandleAnalyzer::PrintCandleInfo(hourInput, minuteInput, referenceCandleTimeframe);

        // La tua logica di trading
        if (CandleAnalyzer::IsBearCandle(hourInput, minuteInput, referenceCandleTimeframe))
        {
            double low = CandleAnalyzer::GetCandleLow(hourInput, minuteInput, referenceCandleTimeframe);
            Logger::Info("Bear candle - placing buy stop below: " + DoubleToString(low, 5));
            // OrderManager::PlaceBuyStop(low - 5*Point, ...);
        }
        else
        {
            double high = CandleAnalyzer::GetCandleHigh(hourInput, minuteInput, referenceCandleTimeframe);
            Logger::Info("Bull candle - placing sell stop above: " + DoubleToString(high, 5));
            // OrderManager::PlaceSellStop(high + 5*Point, ...);
        }
    }
}
void OnTimer()
{
    static datetime lastCheckDay = Utils::GetDateOnly(TimeCurrent()); // Non viene rinizializzato ad ogni OnTimer.
    datetime currentDay = Utils::GetDateOnly(TimeCurrent());

    if (currentDay != lastCheckDay)
    {
        Logger::Info(" Nuovo giorno: " + TimeToString(currentDay, TIME_DATE));

        drawOnChart.DeleteAllObjects();
        drawOnChart.DrawArrow(0, Utils::CreateDateTime(hourInput, minuteInput));
        lastCheckDay = currentDay;
    }
}