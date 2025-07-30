
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

    /**
     * Calcola la distanza in punti tra due prezzi
     *
     * @param fromPrice        Prezzo di partenza
     * @param toPrice          Prezzo di arrivo
     * @param additionalPoints Punti aggiuntivi da sommare (default 0)
     * @param useAbsolute      Se true usa valore assoluto, se false mantiene il segno (default true)
     *
     * @return Distanza in punti
     */
    static double GetDistanceInPoints(double fromPrice, double toPrice, double additionalPoints = 0.0, bool useAbsolute = true)
    {
        // toPrice = 9140.88;
        // fromPrice = 9143.19;
        //  risultato 231 UK100 ompany: Five Percent Online Ltd

        double distance = (toPrice - fromPrice) / _Point;

        if (useAbsolute)
            distance = MathAbs(distance);

        return distance + additionalPoints;
    }

    /**
     * Calcola prezzo con offset direzionale
     *
     * @param basePrice    Prezzo di base di riferimento
     * @param offsetPoints Punti di offset (sempre valore positivo)
     * @param above        true = prezzo finale SOPRA il base (base + offset)
     *                     false = prezzo finale SOTTO il base (base - offset)
     *
     * @return Prezzo normalizzato secondo _Digits
     *
     * @example
     *   // Entry sotto il candleLow per LONG
     *   double entryPrice = GetPriceWithOffset(candleLow, 5, false);  // candleLow - 5 punti
     *
     *   // Take profit sopra l'entry
     *   double takeProfit = GetPriceWithOffset(entryPrice, 100, true); // entryPrice + 100 punti
     */
    static double GetPriceWithOffset(double basePrice, double offsetPoints, bool above = true)
    {
        double offset = above ? offsetPoints : -offsetPoints;
        double newPrice = basePrice + (offset * _Point);
        return NormalizeDouble(newPrice, _Digits);
    }

    static double getRR(double entryPrice, double riskDistancePoints, double rr = 1.8)
    {
        double takeProfit = entryPrice + (riskDistancePoints * _Point * rr);
        return NormalizeDouble(takeProfit, _Digits);
    }

    // riskDistancePoints = distanza in punti tra entry e stop loss
    // riskPercent = percentuale di rischio sul saldo del conto
    static double getLots(double riskDistancePoints, double riskPercent = 0.5)
    {

        string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
        string assetCurrency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);

        double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * (riskPercent / 100.0);
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double commission = 0.0; // TODO

        // riskDistancePoints = 935; // TEST
        // riskAmount = 500; // TEST

        if (accountCurrency != assetCurrency)
        {
            double exchangeRate = Utils::GetAssetToAccountRate(_Symbol);
            // exchangeRate = 1.33497; //TEST
            double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
            double unitCost = _Point * contractSize * exchangeRate;
            tickValue = unitCost;
        }

        // TEST DEVE TORNARE 40.05 UK100 ompany: Five Percent Online Ltd

        if (riskAmount <= 0 || tickValue <= 0)
            return 0.0;

        double maxLots = riskAmount / (riskDistancePoints * tickValue + 2 * commission);

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
        string suffixes[5] = {"", ".m", ".i", ".c", ".raw"};

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