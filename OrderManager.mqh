#ifndef ORDERMANAGER_MQH
#define ORDERMANAGER_MQH

#include <Arrays\ArrayObj.mqh>

#define CLASS_NAME "ORDER MANAGER"

// === CLASSE TARGET INFO ===
class CTargetInfo : public CObject
{
public:
    MqlTradeRequest request;
    MqlTradeCheckResult check;
    MqlTradeResult result;
    bool isExecuted;
    bool isRunning;
    double riskReward;
    int targetLevel;

    // Costruttore
    CTargetInfo(void)
    {
        ZeroMemory(request);
        ZeroMemory(check);
        ZeroMemory(result);
        isExecuted = false;
        isRunning = false;
        riskReward = 0.0;
        targetLevel = 0;
    }

    // Distruttore
    ~CTargetInfo(void) {}

    // Metodo di utilità per debug
    string ToString(void)
    {
        return StringFormat("Target%d: RR=%.1f, Price=%.5f, TP=%.5f, Vol=%.8f, Executed=%s, Running=%s",
                            targetLevel, riskReward, request.price, request.tp, request.volume,
                            isExecuted ? "YES" : "NO", isRunning ? "YES" : "NO");
    }
};

// === CLASSE ORDER MANAGER ===
class OrderManager
{
private:
    // === VARIABILI PRIVATE ===
    CArrayObj targets; // Array di CTargetInfo
    string strategyName;
    double candleLow;
    double candleHigh;
    double entryPrice;
    int breakevenTriggerLevel;
    bool breakevenActivated;

    // === FIRME METODI PRIVATE ===
    bool CreateSingleBuyTarget(double entryPrice, double volume, double takeProfit, double rr, int level, double stopLossPrice);
    void UpdateTargetStates();
    void CheckBreakevenTrigger();
    void SetRemainingTargetsToBreakeven();

public:
    // === FIRME METODI PUBBLICI ===

    // Costruttore e distruttore
    OrderManager(string name);
    ~OrderManager(void);

    // Configurazione
    void SetBreakevenTrigger(int tpLevel);

    // Creazione target
    bool CreateBuyTargetsBelowCandle(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe,
                                     int offsetPointsEntry, int numeroTarget, double &targetRR[], double &targetVolumePercent[]);

    // Esecuzione
    bool ExecuteAllTargets();

    // Monitoraggio
    void OnTick();
    int GetActiveTargetsCount();
    bool HasActiveTargets();

    // Gestione
    bool CloseAllTargets();
    void PrintAllTargets();
};

// Costruttore
OrderManager::OrderManager(string name)
{
    strategyName = name;
    breakevenTriggerLevel = 1;
    breakevenActivated = false;
    candleLow = 0.0;
    candleHigh = 0.0;
    entryPrice = 0.0;
    targets.Clear();

    LOG_INFO("[" + strategyName + "] OrderManager initialized");
}

// Distruttore
OrderManager::~OrderManager(void)
{
    targets.Clear(); // Cleanup automatico di tutti i CTargetInfo
    LOG_INFO("[" + strategyName + "] OrderManager destroyed");
}

// Configurazione breakeven trigger
void OrderManager::SetBreakevenTrigger(int tpLevel)
{
    breakevenTriggerLevel = tpLevel;
    LOG_INFO(StringFormat("[%s] Breakeven trigger set to TP%d", strategyName, tpLevel));
}

// Creazione target
bool OrderManager::CreateBuyTargetsBelowCandle(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe,
                                               int offsetPointsEntry, int numeroTarget, double &targetRR[], double &targetVolumePercent[])
{
    // === STEP 1: Validazione input ===
    if (numeroTarget <= 0)
    {
        LOG_ERROR("[" + strategyName + "] Invalid numeroTarget: " + IntegerToString(numeroTarget));
        return false;
    }

    // === STEP 2: Ottieni il minimo della candela ===
    candleLow = CandleAnalyzer::GetCandleLow(targetHour, targetMinute, timeframe);
    candleHigh = CandleAnalyzer::GetCandleHigh(targetHour, targetMinute, timeframe);

    if (candleLow == 0.0)
    {
        LOG_ERROR("[" + strategyName + "] Cannot get candle low for " +
                  IntegerToString(targetHour) + ":" + IntegerToString(targetMinute));
        return false;
    }

    /**
    // TEST UK100 Five Percent Online Ltd
    //  candleHigh = 9136.04;
    //  candleLow = 9141.60;
    //  offsetPointsEntry = 0;
    //  EXPECTED_RISK_DISTANCE_POINTS = 556.0
    //  EXPECTED_TAKE_PROFIT_PRICE = 9151.61
    //  EXPECTED_RISK_REWARD_RATIO = 1.8
    **/

    // === CALCOLO ENTRY PRICE ===
    // Entry sotto il minimo della candela di riferimento
    double entryPriceRaw = Utils::GetPriceWithOffset(candleLow, offsetPointsEntry, false);
    LOG_INFO(StringFormat("Prezzo Raw che avremmo voluto: %.5f", entryPriceRaw));
    double entryPrice = UtilsTrade::GetRealEntryPrice(ORDER_TYPE_BUY_LIMIT, candleLow, offsetPointsEntry, false);
    LOG_INFO(StringFormat("Prezzo calcolato - Reale di ingresso: %.5f", entryPrice));

    // === CALCOLO STOP LOSS IN PUNTI ===
    // Stop loss = range completo della candela + offset entry
    // Logica: rischi dalla candela completa + punti aggiuntivi dell'offset
    double riskDistancePoints = Utils::GetDistanceInPoints(candleLow, candleHigh, g_OffsetPointsRisk);

    double stopLossPrice = Utils::GetPriceWithOffset(entryPrice, riskDistancePoints, false);
    LOG_INFO(StringFormat("Prezzo Stop Loss: %.5f (%.2f punti)", stopLossPrice, riskDistancePoints));

    // === CALCOLO LOTTI ===
    // Calcola lotti per target rispettando il risk management divisi per target
    double volume = Utils::getVolume(riskDistancePoints, g_RischioPercentuale);
    LOG_INFO(StringFormat("[%s] Lotti Totali: %.2f", strategyName, volume));

    if (riskDistancePoints <= 0)
    {
        LOG_ERROR("[" + strategyName + "] Invalid risk distance: " + DoubleToString(riskDistancePoints, _Digits));
        return false;
    }

    // === STEP 5: Info iniziale ===
    LOG_INFO(StringFormat("[%s] === Creating %d BUY targets ===", strategyName, numeroTarget));
    LOG_INFO(StringFormat("[%s] Candle Low: %.5f", strategyName, candleLow));
    LOG_INFO(StringFormat("[%s] Entry Price: %.5f (-%d points)", strategyName, entryPrice, offsetPointsEntry));
    LOG_INFO(riskDistancePoints > 0 ? StringFormat("[%s] Risk Distance: %.2f points", strategyName, riskDistancePoints) : "Risk distance is zero");
    LOG_INFO(StringFormat("[%s] Volume totali: %.2f", strategyName, volume));

    // === STEP 6: Pulisci target precedenti ===
    targets.Clear();

    // === STEP 7: Ciclo creazione target ===
    bool allTargetsCreated = true;
    double distrutedVolume = 0.0;
    for (int i = 1; i <= numeroTarget; i++)
    {
        // Calcola RR per questo target
        double currentRR = targetRR[i - 1];
        double volumePercent = Utils::NormalizeVolume(volume * targetVolumePercent[i - 1] / 100.0);

        distrutedVolume += volumePercent;
        // Calcola TP basato su RR
        double takeProfitPrice = Utils::getRR(entryPrice, riskDistancePoints, currentRR);

        // TODO Potenziale perdita, margine richiesto, ecc.

        // Crea il target
        if (!CreateSingleBuyTarget(entryPrice, volumePercent, takeProfitPrice, currentRR, i, stopLossPrice))
        {
            LOG_ERROR(StringFormat("[%s] Failed to create target %d", strategyName, i));
            allTargetsCreated = false;
        }
        else
        {
            LOG_INFO(StringFormat("[%s] Posizione %d di %d Target %d: RR=%.1f, Volume=%.2f di %.2f (TP=%.5f) Entry=%.5f StopLoss=%.5f",
                                  strategyName, i, numeroTarget, i, currentRR, volumePercent, volume, takeProfitPrice, entryPrice, stopLossPrice));
        }
    }

    // === STEP 8: Risultato finale ===
    if (allTargetsCreated)
    {
        LOG_INFO(StringFormat("[%s] Successfully created all %d targets", strategyName, numeroTarget));
        LOG_INFO(StringFormat("[%s] lotti totali %.2f distributi %.2f su %d posizioni", strategyName, volume, distrutedVolume, numeroTarget));
        return true;
    }
    else
    {
        LOG_ERROR("[" + strategyName + "] Some targets failed to create");
        return false;
    }
}

// Esecuzione tutti i target
bool OrderManager::ExecuteAllTargets()
{
    if (targets.Total() == 0)
    {
        LOG_WARN("[" + strategyName + "] No targets to execute");
        return false;
    }

    bool allSuccess = true;
    int executedCount = 0;

    LOG_INFO(StringFormat("[%s] Executing %d targets...", strategyName, targets.Total()));

    for (int i = 0; i < targets.Total(); i++)
    {
        CTargetInfo *target = targets.At(i);
        if (target == NULL)
            continue;

        if (!OrderCheck(target.request, target.check))
        {
            LOG_ERROR("OrderCheck fallito: " + target.check.retcode + " - " + target.check.comment);
            target.ToString();
            continue;
        }

        if (!target.isExecuted)
        {
            if (OrderSend(target.request, target.result))
            {
                if (target.result.retcode == TRADE_RETCODE_DONE ||
                    target.result.retcode == TRADE_RETCODE_PLACED)
                {
                    target.isExecuted = true;
                    target.isRunning = true;
                    executedCount++;

                    LOG_INFO(StringFormat("[%s] Target %d executed: Ticket=%d, RR=%.1f",
                                          strategyName, target.targetLevel,
                                          target.result.order, target.riskReward));
                }
                else
                {
                    LOG_ERROR(StringFormat("[%s] Target %d failed: %s (Code: %d)",
                                           strategyName, target.targetLevel,
                                           target.result.comment, target.result.retcode));
                    allSuccess = false;
                }
            }
            else
            {
                int error = GetLastError();
                LOG_ERROR(StringFormat("[%s] OrderSend failed for target %d. Error: %d",
                                       strategyName, target.targetLevel, error));
                allSuccess = false;
            }
        }
    }

    LOG_INFO(StringFormat("[%s] Execution completed: %d/%d targets executed successfully",
                          strategyName, executedCount, targets.Total()));

    return allSuccess;
}

// Monitoraggio in OnTick
void OrderManager::OnTick()
{
    if (targets.Total() == 0)
        return;

    UpdateTargetStates();

    if (!breakevenActivated)
    {
        CheckBreakevenTrigger();
    }
}

// Conteggio target attivi
int OrderManager::GetActiveTargetsCount()
{
    int count = 0;
    for (int i = 0; i < targets.Total(); i++)
    {
        CTargetInfo *target = targets.At(i);
        if (target != NULL && target.isRunning)
            count++;
    }
    return count;
}

// Controllo se ha target attivi
bool OrderManager::HasActiveTargets()
{
    return (GetActiveTargetsCount() > 0);
}

// Chiusura tutti i target
bool OrderManager::CloseAllTargets()
{
    if (targets.Total() == 0)
    {
        LOG_INFO("[" + strategyName + "] No targets to close");
        return true;
    }

    bool allClosed = true;
    int closedCount = 0;

    for (int i = 0; i < targets.Total(); i++)
    {
        CTargetInfo *target = targets.At(i);
        if (target == NULL)
            continue;

        if (target.isRunning && target.isExecuted)
        {
            MqlTradeRequest request = {};
            MqlTradeResult result = {};

            request.action = TRADE_ACTION_REMOVE;
            request.order = target.result.order;

            // 1. Verifica la validità dell'ordine con OrderCheck
            if (!OrderCheck(target.request, target.check))
            {
                LOG_ERROR("OrderCheck fallito: " + target.check.retcode + " - " + target.check.comment);
                target.ToString();
                continue;
            }

            if (OrderSend(request, result))
            {
                target.isRunning = false;
                closedCount++;
                LOG_INFO("[" + strategyName + "] Target " + IntegerToString(target.targetLevel) +
                         " closed (Ticket: " + IntegerToString(target.result.order) + ")");
            }
            else
            {
                allClosed = false;
                LOG_ERROR("[" + strategyName + "] Failed to close target " +
                          IntegerToString(target.targetLevel));
            }
        }
    }

    LOG_INFO(StringFormat("[%s] Close operation completed: %d targets closed",
                          strategyName, closedCount));

    return allClosed;
}

// Stampa tutti i target per debug
void OrderManager::PrintAllTargets()
{
    int targetCount = targets.Total();

    if (targetCount == 0)
    {
        LOG_INFO("[" + strategyName + "] No targets created yet");
        return;
    }

    LOG_INFO(StringFormat("[%s] === %d Targets Summary ===", strategyName, targetCount));

    for (int i = 0; i < targetCount; i++)
    {
        CTargetInfo *target = targets.At(i);
        if (target != NULL)
        {
            LOG_INFO("[" + strategyName + "] " + target.ToString());
        }
    }

    LOG_INFO("[" + strategyName + "] === End Summary ===");
}

// === IMPLEMENTAZIONI METODI PRIVATI ===

// Creazione singolo target (metodo helper)
// pusha
bool OrderManager::CreateSingleBuyTarget(double entryPrice, double volume, double takeProfit, double rr, int level, double stopLossPrice)
{
    // === Crea nuovo CTargetInfo ===
    CTargetInfo *target = new CTargetInfo();

    if (target == NULL)
    {
        LOG_ERROR("[" + strategyName + "] Failed to create CTargetInfo object");
        return false;
    }

    // === Configura MqlTradeRequest ===
    target.request.action = TRADE_ACTION_PENDING;
    target.request.symbol = Symbol();
    target.request.volume = volume;
    target.request.type = ORDER_TYPE_BUY_LIMIT;
    target.request.price = entryPrice;
    target.request.tp = takeProfit;
    target.request.sl = stopLossPrice; // SL gestito separatamente per breakeven prezzo
    target.request.magic = Utils::GenerateUniqueMagic();
    target.request.comment = StringFormat("%s-T%d-RR%.1f", strategyName, level, rr);
    target.request.deviation = g_Deviation;
    target.request.type_filling = ORDER_FILLING_FOK;

    // === Configura info aggiuntive ===
    target.isExecuted = false;
    target.isRunning = false;
    target.riskReward = rr;
    target.targetLevel = level;

    // === Validazione finale ===
    if (volume <= 0 || entryPrice <= 0 || takeProfit <= entryPrice)
    {
        LOG_ERROR(StringFormat("[%s] Invalid target parameters: Vol=%.2f, Entry=%.5f, TP=%.5f",
                               strategyName, volume, entryPrice, takeProfit));
        delete target;
        return false;
    }

    // === Aggiungi al CArrayObj ===
    if (targets.Add(target) == -1)
    {
        LOG_ERROR("[" + strategyName + "] Failed to add target to array");
        delete target;
        return false;
    }

    LOG_DEBUG(StringFormat("[%s] Target %d prepared: Entry=%.5f, TP=%.5f, Vol=%.2f, RR=%.1f",
                           strategyName, level, entryPrice, takeProfit, volume, rr));

    return true;
}

// Aggiornamento stati target (TODO)
void OrderManager::UpdateTargetStates()
{
    // TODO: Implementare controllo stato ordini
    // Controlla se gli ordini sono ancora attivi o sono stati chiusi
}

// Controllo trigger breakeven (TODO)
void OrderManager::CheckBreakevenTrigger()
{
    // TODO: Implementare controllo trigger breakeven
    // Verifica se il target trigger è stato chiuso
}

// Impostazione breakeven per target rimanenti (TODO)
void OrderManager::SetRemainingTargetsToBreakeven()
{
    // TODO: Implementare impostazione breakeven
    // Modifica SL dei target rimanenti a breakeven
}

#endif ORDERMANAGER_MQH