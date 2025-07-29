#include <Arrays\ArrayObj.mqh>
#include "Utils.mqh"

// === CLASSE TARGET INFO ===
class CTargetInfo : public CObject
{
public:
    MqlTradeRequest request;
    MqlTradeResult result;
    bool isExecuted;
    bool isRunning;
    double riskReward;
    int targetLevel;

    // Costruttore
    CTargetInfo(void)
    {
        ZeroMemory(request);
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
        return StringFormat("Target%d: RR=%.1f, Price=%.5f, TP=%.5f, Vol=%.2f, Executed=%s, Running=%s",
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
                                     double offsetPoints, int numeroTarget, double totalVolume);

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

    Logger::Info("[" + strategyName + "] OrderManager initialized");
}

// Distruttore
OrderManager::~OrderManager(void)
{
    targets.Clear(); // Cleanup automatico di tutti i CTargetInfo
    Logger::Info("[" + strategyName + "] OrderManager destroyed");
}

// Configurazione breakeven trigger
void OrderManager::SetBreakevenTrigger(int tpLevel)
{
    breakevenTriggerLevel = tpLevel;
    Logger::Info(StringFormat("[%s] Breakeven trigger set to TP%d", strategyName, tpLevel));
}

// Creazione target
bool OrderManager::CreateBuyTargetsBelowCandle(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe,
                                               double offsetPoints, int numeroTarget, double totalVolume)
{
    // === STEP 1: Validazione input ===
    if (numeroTarget <= 0)
    {
        Logger::Error("[" + strategyName + "] Invalid numeroTarget: " + IntegerToString(numeroTarget));
        return false;
    }

    if (totalVolume <= 0)
    {
        Logger::Error("[" + strategyName + "] Invalid totalVolume: " + DoubleToString(totalVolume, 2));
        return false;
    }

    // === STEP 2: Ottieni il minimo della candela ===
    candleLow = CandleAnalyzer::GetCandleLow(targetHour, targetMinute, timeframe);
    candleHigh = CandleAnalyzer::GetCandleHigh(targetHour, targetMinute, timeframe);

    if (candleLow == 0.0)
    {
        Logger::Error("[" + strategyName + "] Cannot get candle low for " +
                      IntegerToString(targetHour) + ":" + IntegerToString(targetMinute));
        return false;
    }

    // === STEP 3: Calcola prezzo di entry ===
    // entryPrice = candleLow - (offsetPoints * _Point);
    // entryPrice = NormalizeDouble(entryPrice, _Digits);
    double entryPrice = NormalizeDouble(candleLow - (offsetPoints * _Point), _Digits);

    double candleRangePoints = MathAbs(candleHigh - candleLow) / _Point;
    double stopLossPrice = NormalizeDouble(entryPrice - (candleRangePoints * _Point), _Digits);
    double riskDistance = stopLossPrice / _Point;

    double lotti = Utils::getLots(0.5, entryPrice, stopLossPrice); // Esempio di calcolo lotti
    Logger::Info(StringFormat("Calculated lots: %.2f", lotti));

    if (riskDistance <= 0)
    {
        Logger::Error("[" + strategyName + "] Invalid risk distance: " + DoubleToString(riskDistance, _Digits));
        return false;
    }

    // === STEP 4: Calcola volume per target ===
    double volumePerTarget = totalVolume / numeroTarget;
    volumePerTarget = NormalizeDouble(volumePerTarget, 2);

    // === STEP 5: Info iniziale ===
    Logger::Info(StringFormat("[%s] === Creating %d BUY targets ===", strategyName, numeroTarget));
    Logger::Info(StringFormat("[%s] Candle Low: %.5f", strategyName, candleLow));
    Logger::Info(StringFormat("[%s] Entry Price: %.5f (-%d points)", strategyName, entryPrice, (int)offsetPoints));
    Logger::Info(StringFormat("[%s] Risk Distance: %.5f", strategyName, riskDistance));
    Logger::Info(StringFormat("[%s] Volume per target: %.2f", strategyName, volumePerTarget));

    // === STEP 6: Pulisci target precedenti ===
    targets.Clear();

    // === STEP 7: Ciclo creazione target ===
    bool allTargetsCreated = true;

    for (int i = 1; i <= numeroTarget; i++)
    {
        // Calcola RR per questo target
        double currentRR = 1.8 + ((i - 1) * 0.2); // 1.8, 2.0, 2.2, 2.4, 2.6...

        // Calcola TP basato su RR
        double takeProfitPrice = Utils::getRR(entryPrice, stopLossPrice, currentRR);

        // Crea il target
        if (CreateSingleBuyTarget(entryPrice, volumePerTarget, takeProfitPrice, currentRR, i, stopLossPrice))
        {
            Logger::Info(StringFormat("[%s] Target %d created: RR=%.1f, TP=%.5f",
                                      strategyName, i, currentRR, takeProfitPrice));
        }
        else
        {
            Logger::Error(StringFormat("[%s] Failed to create target %d", strategyName, i));
            allTargetsCreated = false;
        }
    }

    // === STEP 8: Risultato finale ===
    if (allTargetsCreated)
    {
        Logger::Info(StringFormat("[%s] Successfully created all %d targets", strategyName, numeroTarget));
        Logger::Info(StringFormat("[%s] Total volume: %.2f distributed across targets", strategyName, totalVolume));
        return true;
    }
    else
    {
        Logger::Error("[" + strategyName + "] Some targets failed to create");
        return false;
    }
}

// Esecuzione tutti i target
bool OrderManager::ExecuteAllTargets()
{
    if (targets.Total() == 0)
    {
        Logger::Warn("[" + strategyName + "] No targets to execute");
        return false;
    }

    bool allSuccess = true;
    int executedCount = 0;

    Logger::Info(StringFormat("[%s] Executing %d targets...", strategyName, targets.Total()));

    for (int i = 0; i < targets.Total(); i++)
    {
        CTargetInfo *target = targets.At(i);
        if (target == NULL)
            continue;

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

                    Logger::Info(StringFormat("[%s] Target %d executed: Ticket=%d, RR=%.1f",
                                              strategyName, target.targetLevel,
                                              target.result.order, target.riskReward));
                }
                else
                {
                    Logger::Error(StringFormat("[%s] Target %d failed: %s (Code: %d)",
                                               strategyName, target.targetLevel,
                                               target.result.comment, target.result.retcode));
                    allSuccess = false;
                }
            }
            else
            {
                int error = GetLastError();
                Logger::Error(StringFormat("[%s] OrderSend failed for target %d. Error: %d",
                                           strategyName, target.targetLevel, error));
                allSuccess = false;
            }
        }
    }

    Logger::Info(StringFormat("[%s] Execution completed: %d/%d targets executed successfully",
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
        Logger::Info("[" + strategyName + "] No targets to close");
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

            if (OrderSend(request, result))
            {
                target.isRunning = false;
                closedCount++;
                Logger::Info("[" + strategyName + "] Target " + IntegerToString(target.targetLevel) +
                             " closed (Ticket: " + IntegerToString(target.result.order) + ")");
            }
            else
            {
                allClosed = false;
                Logger::Error("[" + strategyName + "] Failed to close target " +
                              IntegerToString(target.targetLevel));
            }
        }
    }

    Logger::Info(StringFormat("[%s] Close operation completed: %d targets closed",
                              strategyName, closedCount));

    return allClosed;
}

// Stampa tutti i target per debug
void OrderManager::PrintAllTargets()
{
    int targetCount = targets.Total();

    if (targetCount == 0)
    {
        Logger::Info("[" + strategyName + "] No targets created yet");
        return;
    }

    Logger::Info(StringFormat("[%s] === %d Targets Summary ===", strategyName, targetCount));

    for (int i = 0; i < targetCount; i++)
    {
        CTargetInfo *target = targets.At(i);
        if (target != NULL)
        {
            Logger::Info("[" + strategyName + "] " + target.ToString());
        }
    }

    Logger::Info("[" + strategyName + "] === End Summary ===");
}

// === IMPLEMENTAZIONI METODI PRIVATI ===

// Creazione singolo target (metodo helper)
bool OrderManager::CreateSingleBuyTarget(double entryPrice, double volume, double takeProfit, double rr, int level, double stopLossPrice)
{
    // === Crea nuovo CTargetInfo ===
    CTargetInfo *target = new CTargetInfo();

    if (target == NULL)
    {
        Logger::Error("[" + strategyName + "] Failed to create CTargetInfo object");
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
    target.request.deviation = 3;
    target.request.type_filling = ORDER_FILLING_FOK;

    // === Configura info aggiuntive ===
    target.isExecuted = false;
    target.isRunning = false;
    target.riskReward = rr;
    target.targetLevel = level;

    // === Validazione finale ===
    if (volume <= 0 || entryPrice <= 0 || takeProfit <= entryPrice)
    {
        Logger::Error(StringFormat("[%s] Invalid target parameters: Vol=%.2f, Entry=%.5f, TP=%.5f",
                                   strategyName, volume, entryPrice, takeProfit));
        delete target;
        return false;
    }

    // === Aggiungi al CArrayObj ===
    if (targets.Add(target) == -1)
    {
        Logger::Error("[" + strategyName + "] Failed to add target to array");
        delete target;
        return false;
    }

    Logger::Debug(StringFormat("[%s] Target %d prepared: Entry=%.5f, TP=%.5f, Vol=%.2f, RR=%.1f",
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
