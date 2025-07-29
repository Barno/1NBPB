class CandleAnalyzer
{
public:
    // Enum per i tipi di candela
    enum CANDLE_TYPE
    {
        CANDLE_BEAR,
        CANDLE_BULL,
        CANDLE_DOJI,
        CANDLE_ERROR
    };

    // Metodo generico che restituisce il tipo
    static CANDLE_TYPE GetCandleType(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        datetime targetTime = TimeUtils::CreateDateTime(targetHour, targetMinute, 0);
        int barIndex = iBarShift(Symbol(), timeframe, targetTime, true);

        if (barIndex == -1)
        {
            Logger::Error("Cannot find exact bar for " + IntegerToString(targetHour) + ":" + IntegerToString(targetMinute));
            return CANDLE_ERROR;
        }

        double open = iOpen(Symbol(), timeframe, barIndex);
        double close = iClose(Symbol(), timeframe, barIndex);

        if (close < open)
            return CANDLE_BEAR;
        if (close > open)
            return CANDLE_BULL;
        return CANDLE_DOJI;
    }

    // Metodi di convenienza
    static bool IsBearCandle(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        return GetCandleType(targetHour, targetMinute, timeframe) == CANDLE_BEAR;
    }

    static bool IsBullCandle(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        return GetCandleType(targetHour, targetMinute, timeframe) == CANDLE_BULL;
    }

    static bool IsDoji(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        return GetCandleType(targetHour, targetMinute, timeframe) == CANDLE_DOJI;
    }

    // Ottiene il massimo della candela
    static double GetCandleHigh(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        datetime targetTime = TimeUtils::CreateDateTime(targetHour, targetMinute, 0);
        int barIndex = iBarShift(Symbol(), timeframe, targetTime, true);

        if (barIndex == -1)
        {
            Logger::Error("Cannot find bar for high price");
            return 0.0;
        }

        return iHigh(Symbol(), timeframe, barIndex);
    }

    // Ottiene il minimo della candela
    static double GetCandleLow(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        datetime targetTime = TimeUtils::CreateDateTime(targetHour, targetMinute, 0);
        int barIndex = iBarShift(Symbol(), timeframe, targetTime, true);

        if (barIndex == -1)
        {
            Logger::Error("Cannot find bar for low price");
            return 0.0;
        }

        return iLow(Symbol(), timeframe, barIndex);
    }

    // Ottiene l'apertura della candela
    static double GetCandleOpen(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        datetime targetTime = TimeUtils::CreateDateTime(targetHour, targetMinute, 0);
        int barIndex = iBarShift(Symbol(), timeframe, targetTime, true);

        if (barIndex == -1)
        {
            Logger::Error("Cannot find bar for open price");
            return 0.0;
        }

        return iOpen(Symbol(), timeframe, barIndex);
    }

    // Ottiene la chiusura della candela
    static double GetCandleClose(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        datetime targetTime = TimeUtils::CreateDateTime(targetHour, targetMinute, 0);
        int barIndex = iBarShift(Symbol(), timeframe, targetTime, true);

        if (barIndex == -1)
        {
            Logger::Error("Cannot find bar for close price");
            return 0.0;
        }

        return iClose(Symbol(), timeframe, barIndex);
    }

    // Debug: stampa info della candela
    static void PrintCandleInfo(int targetHour, int targetMinute, ENUM_TIMEFRAMES timeframe)
    {
        datetime targetTime = TimeUtils::CreateDateTime(targetHour, targetMinute, 0);
        // Cerca la barra per orario. La funzione restituisce l'indice della barra corrispondente al tempo/orario specificato.
        int barIndex = iBarShift(Symbol(), timeframe, targetTime, true);

        if (barIndex == -1)
        {
            Logger::Error("Cannot find bar for debug info");
            return;
        }
        // indice 1 perchè questo metodo viene chiamato alla chiusura della candela di riferimento
        // 1 significa quella precedente, 0 quella corrente
        Logger::Info("Candle index " + barIndex);

        double open = iOpen(Symbol(), timeframe, barIndex);
        double high = iHigh(Symbol(), timeframe, barIndex);
        double low = iLow(Symbol(), timeframe, barIndex);
        double close = iClose(Symbol(), timeframe, barIndex);

        string candleType = (close < open) ? "BEAR" : "BULL";

        Logger::Info(StringFormat("Candle %d:%02d [%s] - %s | O:%.5f H:%.5f L:%.5f C:%.5f",
                                  targetHour, targetMinute,
                                  EnumToString(timeframe), candleType,
                                  open, high, low, close));
    }
};