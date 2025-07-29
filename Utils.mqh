
#include "Enums.mqh"

class Utils
{

private:
    static int baseMagic;
    static int counter;

public:
    // Crea un datetime a partire da ora e minuti
    // Se pHour e pMinute sono 0, usa l'ora corrente
    static datetime CreateDateTime(int pHour = 0, int pMinute = 0)
    {
        MqlDateTime timeStruct;
        TimeToStruct(TimeCurrent(), timeStruct);
        timeStruct.hour = pHour;
        timeStruct.min = pMinute;
        datetime useTime = StructToTime(timeStruct);
        return (useTime);
    }

    static datetime Utils::GetDateOnly(datetime fullDateTime)
    {
        // UNIX TIMESTAMP RESET
        // MQL5 datetime = Unix timestamp (secondi dal 1 Jan 1970 UTC)
        // Trucco: dividere per secondi/giorno elimina ore/minuti/secondi

        long days = fullDateTime / SECONDS_PER_DAY; // Giorni completi dall'Unix Epoch
        return (datetime)(days * SECONDS_PER_DAY);  // Mezzanotte dello stesso giorno
    }

    static datetime Utils::GetTime(datetime fullDateTime)
    {
        // UNIX TIMESTAMP RESET
        // MQL5 datetime = Unix timestamp (secondi dal 1 Jan 1970 UTC)
        // Trucco: dividere per secondi/giorno elimina ore/minuti/secondi

        long days = fullDateTime / SECONDS_PER_DAY; // Giorni completi dall'Unix Epoch
        return (datetime)(days * SECONDS_PER_DAY);  // Mezzanotte dello stesso giorno
    }

    static bool checkTime(datetime checkTime, int startHour, int startMin, int endHour, int endMin)
    {
        MqlDateTime dt;
        TimeToStruct(checkTime, dt);

        int currentMinutes = dt.hour * 60 + dt.min;
        int startMinutes = startHour * 60 + startMin;
        int endMinutes = endHour * 60 + endMin;

        return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
    }

    static bool IsExactTime(int targetHour, int targetMinute)
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return (dt.hour == targetHour && dt.min == targetMinute);
    }

    static bool IsExactTimeOnce(int targetHour, int targetMinute)
    {
        static int lastExecutedHour = -1;
        static int lastExecutedMinute = -1;

        if (IsExactTime(targetHour, targetMinute))
        {
            if (lastExecutedHour != targetHour || lastExecutedMinute != targetMinute)
            {
                lastExecutedHour = targetHour;
                lastExecutedMinute = targetMinute;
                return true;
            }
        }
        else
        {
            // Reset quando cambia l'orario
            if (lastExecutedHour == targetHour && lastExecutedMinute == targetMinute)
            {
                lastExecutedHour = -1;
                lastExecutedMinute = -1;
            }
        }
        return false;
    }

    static int GetCurrentHour()
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return dt.hour;
    }

    static int GetCurrentMinute()
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return dt.min;
    }

    static int GenerateUniqueMagic()
    {
        counter++;
        return baseMagic + counter;
    }

    static double getRR(double entryPrice, double stopLossPrice, double rr = 1.8)
    {
        double riskDistance = entryPrice - stopLossPrice;
        double takeProfit = entryPrice + (riskDistance * rr);
        return NormalizeDouble(takeProfit, _Digits);
    }

    /**
     * Calcola il numero massimo di lotti acquistabili rispettando il risk management
     *
     * Implementa la formula: Lotti = RiskAmount / (RiskDistance × UnitCost + Commissioni)
     * Gestisce automaticamente la conversione valuta quando l'asset è quotato in valuta
     * diversa da quella dell'account (es: UK100 in GBP, account in USD).
     *
     * @param riskPercent   Percentuale del balance da rischiare (default 0.5%)
     * @param entryPrice    Prezzo di entrata della posizione
     * @param stopLossPrice Prezzo di stop loss
     *
     * @return Numero di lotti normalizzati secondo il volume step del broker
     *
     * @note Per asset cross-currency, ricostruisce il tick value usando:
     *       UnitCost = TickSize × ContractSize × ExchangeRate
     * @note Il risultato è normalizzato secondo SYMBOL_VOLUME_STEP del broker
     * @note Restituisce 0.0 se i parametri sono invalidi o se il rischio è zero
     *
     * @example
     *   double lots = Utils::getLots(9144.00, 9152.97,1.0, ); // Rischia 1% con entry-stop
     */
    static double getLots(double entryPrice, double stopLossPrice, double riskPercent = 0.5)
    {

        // Distanza in punti
        double riskDistance = MathAbs(entryPrice - stopLossPrice) / _Point;
        if (riskDistance <= 0)
            return 0.0;

        string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
        string assetCurrency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);

        double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * (riskPercent / 100.0);
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double commission = 0.0; // TODO

        if (accountCurrency != assetCurrency)
        {
            double exchangeRate = Utils::GetAssetToAccountRate(_Symbol);
            double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
            double unitCost = _Point * contractSize * exchangeRate;
            tickValue = unitCost;
        }

        if (riskAmount <= 0 || tickValue <= 0)
            return 0.0;

        double maxLots = riskAmount / (riskDistance * tickValue + 2 * commission);

        // Normalizza secondo il volume step del broker
        double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        maxLots = MathFloor(maxLots / volumeStep) * volumeStep;
        return NormalizeDouble(maxLots, 2);
    }

    static double GetExchangeRate(string fromCurrency, string toCurrency)
    {
        if (fromCurrency == toCurrency)
            return 1.0; // Stessa valuta

        // Trova il simbolo di conversione
        string conversionSymbol = FindConversionSymbol(fromCurrency, toCurrency);

        if (conversionSymbol == "")
        {
            Logger::Error("Cannot find conversion pair for " + fromCurrency + "/" + toCurrency);
            return 1.0; // Fallback
        }

        double rate = GetConversionRate(conversionSymbol, fromCurrency, toCurrency);

        // Logger::Info(StringFormat("Exchange rate %s/%s: %.5f (via %s)",
        //                           fromCurrency, toCurrency, rate, conversionSymbol));

        return rate;
    }

    // Metodo specifico per il tuo caso
    static double GetAssetToAccountRate(string symbol)
    {
        string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
        string assetCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);

        return GetExchangeRate(assetCurrency, accountCurrency);
    }

private:
    static string FindConversionSymbol(string fromCurrency, string toCurrency)
    {
        // Prova simbolo diretto: GBPUSD
        string directSymbol = fromCurrency + toCurrency;
        if (SymbolSelect(directSymbol, false) || IsSymbolAvailable(directSymbol))
        {
            return directSymbol;
        }

        // Prova simbolo inverso: USDGBP
        string inverseSymbol = toCurrency + fromCurrency;
        if (SymbolSelect(inverseSymbol, false) || IsSymbolAvailable(inverseSymbol))
        {
            return inverseSymbol;
        }

        // Prova con suffissi comuni del broker
        string suffixes[5] = {"", ".m", ".i", ".c", ".raw"}; // ← CORRETTO

        for (int i = 0; i < ArraySize(suffixes); i++)
        {
            string testDirect = directSymbol + suffixes[i];
            string testInverse = inverseSymbol + suffixes[i];

            if (IsSymbolAvailable(testDirect))
                return testDirect;

            if (IsSymbolAvailable(testInverse))
                return testInverse;
        }

        return ""; // Non trovato
    }

    static bool IsSymbolAvailable(string symbol)
    {
        // Controlla se il simbolo esiste nel Market Watch
        return (SymbolInfoInteger(symbol, SYMBOL_SELECT) ||
                SymbolSelect(symbol, true));
    }

    static double GetConversionRate(string symbol, string fromCurrency, string toCurrency)
    {
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double rate = (bid + ask) / 2.0;

        string symbolBase = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
        string symbolProfit = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);

        // Logica di conversione usando SYMBOL_CURRENCY_PROFIT
        if (symbolBase == fromCurrency && symbolProfit == toCurrency)
        {
            return rate; // Diretto: FROM -> TO
        }
        else if (symbolBase == toCurrency && symbolProfit == fromCurrency)
        {
            return 1.0 / rate; // Inverso: TO -> FROM
        }

        return rate; // Fallback
    }
};

// Definizioni statiche
int Utils::baseMagic = 1000;
int Utils::counter = 0;