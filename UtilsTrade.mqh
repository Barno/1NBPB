//+------------------------------------------------------------------+
//| UtilsTrade.mqh - Trading Utilities                              |
//+------------------------------------------------------------------+

#define CLASS_NAME "UTILS TRADE"

class UtilsTrade
{
public:
    /**
     * @brief Calcola il prezzo di entry reale per ordini pending
     *
     * @details Il metodo gestisce la logica complessa di posizionamento degli ordini considerando:
     * 1. Prezzo desiderato dall'utente (desired_price)
     * 2. Offset dal prezzo desiderato (offset_points)
     * 3. Vincoli del broker (TRADE_STOPS_LEVEL)
     * 4. Limiti di deviazione massima accettabile (maxPointsDistanceAccepted)
     *
     * Sequenza di calcolo:
     * - Calcola prezzo base: desired_price ± offset_points
     * - Verifica rispetto dei vincoli TRADE_STOPS_LEVEL
     * - Corregge automaticamente se forceTrade=true
     * - Scarta se deviazione > maxPointsDistanceAccepted
     *
     * @param ENUM_ORDER_TYPE order_type Tipo di ordine (BUY_LIMIT, SELL_STOP, etc.)
     * @param double desired_price Prezzo dove si vuole entrare
     * @param double offset_points Punti di offset dal desired_price
     * @param bool forceTrade Se true, corregge automaticamente per TRADE_STOPS_LEVEL
     * @param double maxPointsDistanceAccepted Massima deviazione accettabile (default: 50.0)
     * @param string symbol Simbolo di trading (default: _Symbol)
     *
     * @return double Prezzo di entry normalizzato, 0.0 se non fattibile
     *
     * @note Gli ordini market (BUY/SELL) ignorano tutti i parametri e restituiscono direttamente tick.ask/tick.bid
     *
     * @warning Se forceTrade=false e il prezzo viola TRADE_STOPS_LEVEL il metodo restituisce 0.0 e logga un errore
     */
    static double GetRealEntryPrice(ENUM_ORDER_TYPE order_type,              // Tipo di ordine
                                    double desired_price,                    // Prezzo dove si vuole entrare
                                    double offset_points,                    // Punti di offset dal desired_price
                                    bool forceTrade,                         // Corregge automaticamente per TRADE_STOPS_LEVEL
                                    double maxPointsDistanceAccepted = 50.0, // Massima deviazione accettabile
                                    string symbol = "");                     // Simbolo (default = corrente)
};

//+------------------------------------------------------------------+
//| IMPLEMENTAZIONE                                                  |
//+------------------------------------------------------------------+

static double UtilsTrade::GetRealEntryPrice(ENUM_ORDER_TYPE order_type,
                                            double desired_price,
                                            double offset_points,
                                            bool forceTrade,
                                            double maxPointsDistanceAccepted,
                                            string symbol)
{

    if (symbol == "")
    {
        symbol = _Symbol; // Usa il simbolo corrente se non specificato
    }

    // Ottieni tick corrente del mercato
    MqlTick tick;
    if (!SymbolInfoTick(symbol, tick))
    {
        LOG_ERROR(StringFormat("[UtilsTrade] Impossibile ottenere tick per %s", symbol));
        return 0.0;
    }

    // Gli ordini market ignorano tutti i calcoli e usano il prezzo corrente
    if (order_type == ORDER_TYPE_BUY)
        return tick.ask;
    if (order_type == ORDER_TYPE_SELL)
        return tick.bid;

    // Ottieni vincoli del broker
    long trade_stops_level_points = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL); // In punti
    double trade_stops_level_price = trade_stops_level_points * _Point;                  // Convertito in prezzo

    // Variabili per il calcolo
    double ideal_price = 0.0;     // Prezzo calcolato ideale
    double reference_price = 0.0; // Prezzo di riferimento per TRADE_STOPS_LEVEL
    bool need_above = false;      // true se deve essere sopra reference_price

    // Calcola prezzo ideale in base al tipo di ordine
    switch (order_type)
    {
    case ORDER_TYPE_BUY_LIMIT:
        // LONG: Entra sotto il desired_price
        // Step 1: Applica offset (sotto il prezzo desiderato)
        ideal_price = Utils::GetPriceWithOffset(desired_price, offset_points, false);
        // Step 3: Configura controlli TRADE_STOPS_LEVEL
        reference_price = tick.ask;
        need_above = false; // Deve essere sotto Ask
        break;

    case ORDER_TYPE_SELL_LIMIT:
        // SHORT: Entra sopra il desired_price
        // Step 1: Applica offset (sopra il prezzo desiderato)
        ideal_price = Utils::GetPriceWithOffset(desired_price, offset_points, true);
        // Step 3: Configura controlli TRADE_STOPS_LEVEL
        reference_price = tick.bid;
        need_above = true; // Deve essere sopra Bid
        break;

    case ORDER_TYPE_BUY_STOP:
        // LONG: Entra sopra il desired_price (breakout)
        // Step 1: Applica offset (sopra il prezzo desiderato)
        ideal_price = Utils::GetPriceWithOffset(desired_price, offset_points, true);
        // Step 3: Configura controlli TRADE_STOPS_LEVEL
        reference_price = tick.ask;
        need_above = true; // Deve essere sopra Ask
        break;

    case ORDER_TYPE_SELL_STOP:
        // SHORT: Entra sotto il desired_price (breakdown)
        // Step 1: Applica offset (sotto il prezzo desiderato)
        ideal_price = Utils::GetPriceWithOffset(desired_price, offset_points, false);
        // Step 3: Configura controlli TRADE_STOPS_LEVEL
        reference_price = tick.bid;
        need_above = false; // Deve essere sotto Bid
        break;

    case ORDER_TYPE_BUY_STOP_LIMIT:
        // LONG: Trigger sopra desired_price, limit può essere diverso
        ideal_price = Utils::GetPriceWithOffset(desired_price, offset_points, true);
        reference_price = tick.ask;
        need_above = true;
        break;

    case ORDER_TYPE_SELL_STOP_LIMIT:
        // SHORT: Trigger sotto desired_price, limit può essere diverso
        ideal_price = Utils::GetPriceWithOffset(desired_price, offset_points, false);
        reference_price = tick.bid;
        need_above = false;
        break;

    default:
        LOG_ERROR(StringFormat("[UtilsTrade] Tipo di ordine non supportato: %s", EnumToString(order_type)));
        return 0.0;
    }

    // Verifica vincoli TRADE_STOPS_LEVEL del broker
    double final_price = ideal_price;
    bool violated_stops_level = false;

    // verifico se il prezzo deve essere sopra o sotto il reference_price (SYMBOL_TRADE_STOPS_LEVEL), ovvero il livello minimo che impone il broker
    // sostanzialmente se voglio andare Long, verifico se devo Togliere il trade_stops_level dal prezzo desiderato per rendere l'ordine valido
    if (need_above)
    {
        // Il prezzo deve essere sopra reference_price + TRADE_STOPS_LEVEL
        double min_allowed_price = reference_price + trade_stops_level_price;
        if (ideal_price <= min_allowed_price)
        {
            violated_stops_level = true;
            if (forceTrade)
            {
                final_price = min_allowed_price;
                LOG_WARN(StringFormat("[UtilsTrade] Prezzo corretto da %.5f a %.5f per TRADE_STOPS_LEVEL (%d punti)",
                                      ideal_price, final_price, trade_stops_level_points));
            }
        }
    }
    else
    {
        // Esempio: Voglio comprare a ideal_price = 9062.78
        //  il prezzo di riferimento per l'acquisto è reference_price = 9063.81 ovvero il prezzo Ask corrente (tick.ask)
        //  max_allowed_price è il prezzo massimo che posso usare per l'ordine 9063.71
        //  Il prezzo deve essere sotto reference_price - TRADE_STOPS_LEVEL
        double max_allowed_price = reference_price - trade_stops_level_price;
        if (ideal_price >= max_allowed_price)
        {
            violated_stops_level = true;
            if (forceTrade)
            {
                final_price = max_allowed_price;
                LOG_WARN(StringFormat("[UtilsTrade] Prezzo corretto da %.5f a %.5f per TRADE_STOPS_LEVEL (%d punti)",
                                      ideal_price, final_price, trade_stops_level_points));
            }
        }
    }

    if (violated_stops_level)
    {
        LOG_DEBUG(StringFormat("[UtilsTrade] Prezzo %.5f non viola TRADE_STOPS_LEVEL (%d punti)", ideal_price, trade_stops_level_points));
    }

    // Se viola TRADE_STOPS_LEVEL e non è permesso forzare, restituisci errore
    if (violated_stops_level && !forceTrade)
    {
        LOG_ERROR(StringFormat("[UtilsTrade] Prezzo %.5f viola TRADE_STOPS_LEVEL (%d punti). Usa forceTrade=true",
                               ideal_price, trade_stops_level_points));
        return 0.0;
    }

    // Verifica che la deviazione finale non superi il limite accettabile
    // questo mi serve per evitare ordini troppo lontani dal prezzo desiderato
    double actual_distance_points = MathAbs(final_price - desired_price) / _Point;
    if (actual_distance_points > maxPointsDistanceAccepted)
    {
        LOG_ERROR(StringFormat("[UtilsTrade] Distanza finale %.1f > limite %.1f punti. Ordine scartato",
                               actual_distance_points, maxPointsDistanceAccepted));
        return 0.0;
    }

    // Log informativo per debug quando c'è stata una correzione
    if (violated_stops_level && forceTrade)
    {
        LOG_INFO(StringFormat("[UtilsTrade] Prezzo finale: %.5f (distanza da desired: %.1f punti)",
                              final_price, actual_distance_points));
    }

    double normalized_price = NormalizeDouble(final_price, _Digits);
    LOG_INFO(StringFormat("[UtilsTrade] Prezzo finale: a cui cerchiamo di entrare sarà: %.5f", normalized_price));
    return normalized_price;
}
