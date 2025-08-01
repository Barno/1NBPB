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
#include "OrderManager.mqh"
#include "BrokerInfo.mqh"
#include "TradingExecutor.mqh"

input group "===  ORA CANDELA DI RIFERIMENTO ===";
input ENUM_TIMEFRAMES referenceCandleTimeframe = PERIOD_M5; // Timeframe per candela di riferimento
input int HourInput = 10;                                   // Ora Candela di riferimento
input int MinuteInput = 0;                                  // Minuti di riferimento per l'operazione

input group "===  LIVELLO DI LOG ===";
input Logger::LOG_LEVEL logLevel = Logger::LOG_DEBUG; // Livello di log

input group "=== OPZIONI DI ENTRATA ===";
input int OffsetPoints = 5; // Punti di offset dal high/low
input int Deviation = 5;    // Quantità di punti di deviazione che si accettano per l'ordine (slippage)

input group "===  TAKE PROFIT PRINCIPALI ===";
input int NumeroTarget = 2;
input double TP1_RiskReward = 1.8;         // TP1: Rapporto Rischio/Rendimento (1:0.5)
input double TP1_PercentualeVolume = 50.0; // TP1: Percentuale volume posizione (%)
input double TP2_RiskReward = 3.0;         // TP2: Rapporto Rischio/Rendimento (1:3.0)
input double TP2_PercentualeVolume = 50.0; // TP2: Percentuale volume posizione (%)
input bool AttivareBreakevenDopoTP = true; // Attiva breakeven automatico dopo TP
input int BreakevenAfterTPNumber = 1;      // Dopo quale TP attivare breakeven (1,2,

input group "===  GESTIONE RISCHIO ===" input double RischioPercentuale = 0.5; // Percentuale rischio per trade (% del capitale) ()
input bool UsaEquityPerRischio = true;                                         // MODALITÀ RISCHIO: false=Balance fisso, true=Equity dinamico

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
DrawOnChart *drawOnChart = NULL; // Istanza della classe per disegnare sul grafico
OrderManager *om = new OrderManager("Morning Strategy");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    drawOnChart = new DrawOnChart();
    Logger::SetLogLevel(logLevel);

    // Info di avvio
    Asset::Initialize();
    // BrokerInfo::Initialize();
    BrokerInfo::LogTradingInfo();

    if (drawOnChart == NULL)
    {
        Logger::LogError("Failed to create DrawOnChart instance");
        return INIT_FAILED;
    }

    if (!drawOnChart.DrawArrow(0, Utils::CreateDateTime(HourInput, MinuteInput)))
    {
        Logger::LogError("Failed to draw arrow on chart at " + TimeToString(Utils::CreateDateTime(HourInput, MinuteInput), TIME_DATE | TIME_MINUTES));
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

    if (TradingExecutor::ShouldExecuteTrade(HourInput, MinuteInput, additionalMinutes, 0, 20))
    {
        Logger::Debug("GetExecutedDate: " + TimeToString(TradingExecutor::GetExecutedDate(), TIME_DATE));
        Print("ESEGUO TRADE!");

        // Usa gli input invece di valori hardcodati
        CandleAnalyzer::PrintCandleInfo(HourInput, MinuteInput, referenceCandleTimeframe);

        if (CandleAnalyzer::IsBearCandle(HourInput, MinuteInput, referenceCandleTimeframe))
        {
            Logger::Info("Bear candle detected - placing buy stop below low");
            bool success = om.CreateBuyTargetsBelowCandle(HourInput, MinuteInput, referenceCandleTimeframe, OffsetPoints, NumeroTarget);
            om.PrintAllTargets();
            om.ExecuteAllTargets();
        }
        else
        {
            Logger::Info("Bull candle detected - placing sell stop above high");
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
        Logger::Info(" Nuovo giorno: " + TimeToString(currentDay, TIME_DATE));

        drawOnChart.DeleteAllObjects();
        drawOnChart.DrawArrow(0, Utils::CreateDateTime(HourInput, MinuteInput));
        lastCheckDay = currentDay;
    }
}