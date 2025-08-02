//+------------------------------------------------------------------+
//|                                                MyLearningEA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd.sss "
#property link "https://www.mql5.com"
#property version "1.00"

// Ordine include è importante anche nelle classi successive, InputConfiguration dichiaro per primo ha tutte variabili globali in tutte le classi
#include "Logger.mqh"
#include "InputConfiguration.mqh"
#include "Utils.mqh"
#include "UtilsTrade.mqh"
#include "TimeUtils.mqh"
#include "DrawOnChart.mqh"
#include "Account.mqh"
#include "Asset.mqh"
#include "CandleAnalyzer.mqh"
#include "OrderManager.mqh"
#include "BrokerInfo.mqh"
#include "TradingExecutor.mqh"

#define CLASS_NAME "1NBPB"
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
DrawOnChart *drawOnChart = NULL; // Istanza della classe per disegnare sul grafico
OrderManager *om = new OrderManager("");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    drawOnChart = new DrawOnChart();
    Logger::SetLogLevel(logLevel);

    // Info di avvio
    // Asset::Initialize();
    // BrokerInfo::Initialize();
    // BrokerInfo::LogTradingInfo();

    if (drawOnChart == NULL)
    {
        Logger::LogError("Failed to create DrawOnChart instance");
        return INIT_FAILED;
    }

    if (!drawOnChart.DrawArrow(0, Utils::CreateDateTime(g_HourInput, g_MinuteInput)))
    {
        Logger::LogError("Failed to draw arrow on chart at " + TimeToString(Utils::CreateDateTime(g_HourInput, g_MinuteInput), TIME_DATE | TIME_MINUTES));
        return INIT_FAILED;
    }

    if (!Account::Initialize())
    {
        Logger::LogError("Account initialization failed. Check account settings.");
        return INIT_FAILED; // Inizializza l'account e gestisce errori
    } // Inizializza l'account

    InitializeTargetArrays();

    LOG_DEBUG("Account initialized successfully with balance: " + DoubleToString(Account::GetBalance(), 2) + " " + Account::GetCurrency());

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
    // LOG_INFO("Current Bid: " + DoubleToString(Asset::GetBid(_Symbol), 5));
    // LOG_INFO("Current Ask: " + DoubleToString(Asset::GetAsk(_Symbol), 5));
    // LOG_INFO("Point Spread: " + IntegerToString(Asset::GetPointSpread(_Symbol)));
    // LOG_INFO("Current Spread: " + DoubleToString(Asset::GetSpread(_Symbol), 5));

    // LOG_INFO("Prezzo Neutrale "+Asset::GetLastPrice(_Symbol));
    // LOG_INFO("Costo BUY "+Asset::GetLotCost(_Symbol, Asset::GetMinLot(_Symbol),Asset::BUY)); // Esempio di chiamata per verificare Asset
    // LOG_INFO("Costo SELL "+Asset::GetLotCost(_Symbol, Asset::GetMinLot(_Symbol),Asset::SELL)); // Esempio di chiamata per verificare Asset
    // LOG_INFO("Margin Richiesto Buy "+Asset::GetMarginRequired(_Symbol, 0.01));
    // LOG_INFO("Margin Richiesto Sell "+Asset::GetMarginRequired(_Symbol, 0.01, Asset::SELL));
    // LOG_INFO("Margine Libero "+Asset::FreeMarginAvailable());

    // Calcola minuti aggiuntivi dal timeframe
    checkCandle();
}
//+------------------------------------------------------------------+
void checkCandle()
{
    static int additionalMinutes = -1; // Inizializza una volta sola

    if (additionalMinutes == -1)
    {
        additionalMinutes = TimeUtils::getMinutesFromPeriod(g_referenceCandleTimeframe);
    }

    if (TradingExecutor::ShouldExecuteTrade(g_HourInput, g_MinuteInput, additionalMinutes, 0, 20))
    {
        LOG_DEBUG("GetExecutedDate: " + TimeToString(TradingExecutor::GetExecutedDate(), TIME_DATE));
        LOG_INFO("ESEGUO TRADE! Ora: " + TimeToString(TimeCurrent(), TIME_SECONDS));
        // Usa gli input invece di valori hardcodati
        CandleAnalyzer::PrintCandleInfo(g_HourInput, g_MinuteInput, g_referenceCandleTimeframe);

        if (CandleAnalyzer::IsBearCandle(g_HourInput, g_MinuteInput, g_referenceCandleTimeframe))
        {
            LOG_INFO("Bear candle detected - placing buy stop below low");

            bool success = om.CreateBuyTargetsBelowCandle(g_HourInput, g_MinuteInput, g_referenceCandleTimeframe, g_OffsetPointsEntry, g_NumeroTarget, g_TargetRR, g_TargetVolumePercent);
            om.PrintAllTargets();
            om.ExecuteAllTargets();
        }
        else
        {
            LOG_INFO("Bull candle detected - placing sell stop above high");
        }
    }

    om.OnTick();
}
void OnTimer()
{
    static datetime lastCheckDay = Utils::GetDateOnly(TimeCurrent()); // Non viene rinizializzato ad ogni OnTimer.
    datetime currentDay = Utils::GetDateOnly(TimeCurrent());

    if (currentDay != lastCheckDay)
    {
        LOG_INFO(" Nuovo giorno: " + TimeToString(currentDay, TIME_DATE));

        drawOnChart.DeleteAllObjects();
        drawOnChart.DrawArrow(0, Utils::CreateDateTime(g_HourInput, g_MinuteInput));
        lastCheckDay = currentDay;
    }
}