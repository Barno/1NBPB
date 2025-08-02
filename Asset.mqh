// Asset.mqh
#ifndef ASSET_MQH
#define ASSET_MQH

#define ASSET_CACHE_TIMEOUT 30
#define CLASS_NAME "ASSET"

class Asset
{
private:
    static string cachedSymbol;
    static int cachedAssetType;
    static datetime lastCacheUpdate;

public:
    enum ASSET_TYPE
    {
        FOREX = 0,
        INDICES = 1,
        CRYPTO = 2,
        COMMODITY = 3,
        UNKNOWN = 4
    };
    enum TRADE
    {
        BUY = 0,
        SELL = 1
    };

    // Detection Methods
    static ASSET_TYPE GetAssetType(const string symbol);
    static bool IsForex(const string symbol);
    static bool IsIndex(const string symbol);
    static bool IsCrypto(const string symbol);
    static bool IsCommodity(const string symbol);

    // Symbol Info Methods
    static double GetSpread(const string symbol);
    static long GetPointSpread(const string symbol);
    static double GetPoint(const string symbol);
    static double GetTickSize(const string symbol);
    static double GetTickValue(const string symbol);
    static int GetDigits(const string symbol);
    static string GetCurrency(const string symbol);
    static double GetContractSize(const string symbol);

    // Trading Info Methods
    static double GetMinLot(const string symbol);
    static double GetMaxLot(const string symbol);
    static double GetLotStep(const string symbol);
    static bool IsTradeAllowed(const string symbol);
    static double GetMarginRequired(const string symbol, double lots, TRADE tradeType = BUY);
    static double FreeMarginAvailable();

    // Price Methods
    static double GetBid(const string symbol);
    static double GetAsk(const string symbol);
    static double GetLastPrice(const string symbol);
    static double NormalizePrice(const string symbol, double price);
    static double GetLotCost(const string symbol, const double contract = 1.0, TRADE tradeType = BUY);

    // Utility Methods
    static bool Initialize();
    static void LogAssetInfo(const string symbol);
    static bool ValidateSymbol(const string symbol);
    static int GetMinStopTrade(const string symbol);

private:
    static bool IsCacheValid(const string symbol);
    static void UpdateCache(const string symbol, ASSET_TYPE assetType);
    static void ClearCache();
};

static double Asset::GetMinLot(string symbol)
{
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    if (minLot <= 0)
    {
        Logger::LogError("GetMinLot: Invalid minimum lot size for symbol " + symbol);
        return 0.0;
    }
    return minLot;
}

/**
 * BID: Il mercato ti fa un'offerta ("bid") per comprare da te → Tu VENDI al Bid
   ASK: Il mercato ti chiede ("ask") un prezzo per venderti → Tu COMPRI all'Ask
**/

static double Asset::GetBid(const string symbol)
{
    return SymbolInfoDouble(symbol, SYMBOL_BID);
}

static double Asset::GetAsk(const string symbol)
{
    return SymbolInfoDouble(symbol, SYMBOL_ASK);
}

static double Asset::GetLotStep(const string symbol)
{
    return SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
}

static double Asset::GetLastPrice(const string symbol)
{
    return SymbolInfoDouble(symbol, SYMBOL_LAST);
}

static double Asset::GetContractSize(const string symbol)
{
    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    if (contractSize <= 0)
    {
        LOG_ERROR("Invalid contract size for symbol: " + symbol);
        return 0.0;
    }

    return contractSize;
}

static double Asset::GetLotCost(const string symbol, const double contract, TRADE tradeType)
{
    // Ottieni prezzo in base al tipo di trade
    double price = (tradeType == BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);

    // Ottieni dimensione contratto
    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    if (price <= 0 || contractSize <= 0)
    {
        LOG_ERROR("Invalid price or contract size for symbol: " + symbol);
        return 0.0;
    }

    // Calcola costo totale
    return contract * contractSize * price;
}

static double Asset::FreeMarginAvailable()
{
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    if (freeMargin < 0)
    {
        LOG_ERROR("Free margin is negative: " + DoubleToString(freeMargin, 2));
        return 0.0;
    }
    return freeMargin;
}
static double Asset::GetMarginRequired(const string symbol, double lots, TRADE tradeType = BUY)
{
    // Validazione input
    if (lots <= 0)
    {
        LOG_ERROR("Invalid lot size: " + DoubleToString(lots, 3));
        return 0.0;
    }

    // Ottieni prezzo in base al tipo di trade
    double price = (tradeType == BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);

    double requiredMargin = 0.0; // Variabile per ricevere il risultato
    // Converti TRADE enum a ENUM_ORDER_TYPE per MT5
    ENUM_ORDER_TYPE orderType = (tradeType == BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

    // Metodo 1: Usa funzione MT5 per calcolo margine preciso
    double success = OrderCalcMargin(orderType, symbol, lots, price, requiredMargin);

    if (success)
    {
        return requiredMargin;
    }

    // Metodo 2: Fallback - calcolo manuale
    LOG_WARN("OrderCalcMargin failed, using manual calculation for: " + symbol);

    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double leverage = (double)AccountInfoInteger(ACCOUNT_LEVERAGE);

    if (contractSize <= 0 || leverage <= 0)
    {
        LOG_ERROR("Invalid contract size or leverage for: " + symbol);
        return 0.0;
    }

    // Calcolo manuale: (Lotti × ContractSize × Prezzo) / Leva
    double manualMargin = (lots * contractSize * price) / leverage;

    return manualMargin;
}

static double Asset::GetSpread(const string symbol)
{

    long spreadPoints = SymbolInfoInteger(symbol, SYMBOL_SPREAD);

    if (spreadPoints <= 0)
    {
        LOG_WARN("Invalid spread for symbol: " + symbol);
        return 0.0;
    }

    // Converti punti in valore decimale
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    return spreadPoints * point;
}

static long Asset::GetPointSpread(const string symbol)
{
    long spreadPoints = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    return spreadPoints;
}

// === IMPLEMENTAZIONI MANCANTI ===

// Definizioni variabili statiche
string Asset::cachedSymbol = "";
int Asset::cachedAssetType = UNKNOWN;
datetime Asset::lastCacheUpdate = 0;

// === DETECTION METHODS ===

static Asset::ASSET_TYPE Asset::GetAssetType(const string symbol)
{
    // Controlla cache prima
    if (IsCacheValid(symbol))
    {
        return (ASSET_TYPE)cachedAssetType;
    }

    ASSET_TYPE type = UNKNOWN;

    if (IsForex(symbol))
        type = FOREX;
    else if (IsIndex(symbol))
        type = INDICES;
    else if (IsCrypto(symbol))
        type = CRYPTO;
    else if (IsCommodity(symbol))
        type = COMMODITY;

    // Aggiorna cache
    UpdateCache(symbol, type);

    LOG_INFO("Asset type detected: " + symbol + " = " + EnumToString(type));
    return type;
}

static bool Asset::IsForex(const string symbol)
{
    // Lista major pairs
    string forexPairs[] = {
        "EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD", "NZDUSD",
        "EURJPY", "GBPJPY", "EURGBP", "AUDJPY", "EURAUD", "EURCHF", "AUDCAD",
        "GBPCHF", "EURCA"};

    for (int i = 0; i < ArraySize(forexPairs); i++)
    {
        if (StringFind(symbol, forexPairs[i]) >= 0)
            return true;
    }

    // Pattern check: 6 caratteri, formato XXXYYY
    if (StringLen(symbol) >= 6)
    {
        // Controlla se contiene valute comuni
        if (StringFind(symbol, "USD") >= 0 || StringFind(symbol, "EUR") >= 0 ||
            StringFind(symbol, "GBP") >= 0 || StringFind(symbol, "JPY") >= 0)
            return true;
    }

    return false;
}

static bool Asset::IsIndex(const string symbol)
{
    string indices[] = {
        "SPX", "SP500", "US500", "SPY",
        "DAX", "GER", "DE30", "GER40",
        "FTSE", "UK100", "UKX",
        "NIKKEI", "JP225", "JPN225",
        "NASDAQ", "US100", "NAS100",
        "CAC", "FR40", "FRA40",
        "ASX", "AUS200",
        "HANG", "HK50"};

    string upperSymbol = symbol;
    StringToUpper(upperSymbol);

    for (int i = 0; i < ArraySize(indices); i++)
    {
        if (StringFind(upperSymbol, indices[i]) >= 0)
            return true;
    }

    return false;
}

static bool Asset::IsCrypto(const string symbol)
{
    string cryptos[] = {
        "BTC", "ETH", "LTC", "XRP", "ADA", "DOT", "LINK", "BCH",
        "XLM", "DOGE", "MATIC", "SOL", "AVAX", "ATOM", "ALGO"};

    string upperSymbol = symbol;
    StringToUpper(upperSymbol);

    for (int i = 0; i < ArraySize(cryptos); i++)
    {
        if (StringFind(upperSymbol, cryptos[i]) >= 0)
            return true;
    }

    return false;
}

static bool Asset::IsCommodity(const string symbol)
{
    string commodities[] = {
        "GOLD", "SILVER", "OIL", "BRENT", "WTI", "COPPER", "PLATINUM",
        "XAUUSD", "XAGUSD", "XPTUSD", "XPDUSD",
        "WHEAT", "CORN", "SUGAR", "COFFEE", "COCOA",
        "NATGAS", "GASOLINE"};

    string upperSymbol = symbol;
    StringToUpper(upperSymbol);

    for (int i = 0; i < ArraySize(commodities); i++)
    {
        if (StringFind(upperSymbol, commodities[i]) >= 0)
            return true;
    }

    return false;
}

// === SYMBOL INFO METHODS ===

static double Asset::GetPoint(const string symbol)
{
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if (point <= 0)
    {
        LOG_ERROR("Invalid point value for symbol: " + symbol);
        return 0.0;
    }
    return point;
}

static double Asset::GetTickSize(const string symbol)
{
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    if (tickSize <= 0)
    {
        LOG_ERROR("Invalid tick size for symbol: " + symbol);
        return 0.0;
    }
    return tickSize;
}

static double Asset::GetTickValue(const string symbol)
{
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    if (tickValue <= 0)
    {
        LOG_ERROR("Invalid tick value for symbol: " + symbol);
        return 0.0;
    }
    return tickValue;
}

static int Asset::GetDigits(const string symbol)
{
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    if (digits < 0)
    {
        LOG_ERROR("Invalid digits for symbol: " + symbol);
        return 0;
    }
    return digits;
}

static string Asset::GetCurrency(const string symbol)
{
    string currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
    if (currency == "")
    {
        LOG_WARN("Could not get base currency for symbol: " + symbol);
        return "UNKNOWN";
    }
    return currency;
}

// === TRADING INFO METHODS ===

static double Asset::GetMaxLot(const string symbol)
{
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    if (maxLot <= 0)
    {
        LOG_ERROR("Invalid maximum lot size for symbol: " + symbol);
        return 0.0;
    }
    return maxLot;
}

static bool Asset::IsTradeAllowed(const string symbol)
{
    // Controlla se il trading è abilitato
    long tradeMode = SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
    bool tradeEnabled = (tradeMode == SYMBOL_TRADE_MODE_FULL || tradeMode == SYMBOL_TRADE_MODE_LONGONLY || tradeMode == SYMBOL_TRADE_MODE_SHORTONLY);

    // Ottieni il giorno corrente della settimana
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    ENUM_DAY_OF_WEEK dayOfWeek = (ENUM_DAY_OF_WEEK)dt.day_of_week;

    datetime from, to;
    bool sessionActive = SymbolInfoSessionTrade(symbol, dayOfWeek, 0, from, to);

    if (!tradeEnabled)
    {
        LOG_WARN("Trading not allowed for symbol: " + symbol);
        return false;
    }

    if (!sessionActive)
    {
        LOG_INFO("Market closed for symbol: " + symbol);
        return false;
    }

    return true;
}

// === PRICE METHODS ===

static double Asset::NormalizePrice(const string symbol, double price)
{
    int digits = GetDigits(symbol);
    return NormalizeDouble(price, digits);
}

// === UTILITY METHODS ===

static bool Asset::Initialize()
{
    LOG_INFO("Asset class initializing...");

    // Pulisci cache
    ClearCache();

    // Valida simbolo corrente
    string currentSymbol = _Symbol;

    if (!ValidateSymbol(currentSymbol))
    {
        LOG_ERROR("Current symbol validation failed: " + currentSymbol);
        return false;
    }

    // Log info del simbolo corrente
    LogAssetInfo(currentSymbol);

    LOG_INFO("Asset class initialized successfully");
    return true;
}

static void Asset::LogAssetInfo(const string symbol)
{

    LOG_INFO("==== Asset Info for " + symbol + " ===");
    LOG_INFO("Type: " + EnumToString(GetAssetType(symbol)));
    LOG_INFO("Digits: " + IntegerToString(GetDigits(symbol)));
    LOG_INFO("Point: " + DoubleToString(GetPoint(symbol), 8));
    LOG_INFO("Spread: " + DoubleToString(GetSpread(symbol), GetDigits(symbol)));
    LOG_INFO("Min Lot: " + DoubleToString(GetMinLot(symbol), 3));
    LOG_INFO("Max Lot: " + DoubleToString(GetMaxLot(symbol), 3));
    LOG_INFO("Lot Step: " + DoubleToString(GetLotStep(symbol), 3));
    LOG_INFO("Contract Size: " + DoubleToString(GetContractSize(symbol), 2));
    LOG_INFO("Currency: " + GetCurrency(symbol));
    LOG_INFO("Trade Allowed: " + (IsTradeAllowed(symbol) ? "YES" : "NO"));
    LOG_INFO("Current Bid: " + DoubleToString(GetBid(symbol), GetDigits(symbol)));
    LOG_INFO("Current Ask: " + DoubleToString(GetAsk(symbol), GetDigits(symbol)));
    LOG_INFO("Get MinStop: " + IntegerToString(GetMinStopTrade(symbol)) + " points");
    LOG_INFO("=== End Asset Info ===");
}

static bool Asset::ValidateSymbol(const string symbol)
{
    if (symbol == "")
    {
        LOG_ERROR("Empty symbol provided");
        return false;
    }

    // Controlla se il simbolo esiste
    bool exists = SymbolInfoInteger(symbol, SYMBOL_SELECT);
    if (!exists)
    {
        // Prova ad aggiungerlo al Market Watch
        if (!SymbolSelect(symbol, true))
        {
            LOG_ERROR("Symbol not found and cannot be added: " + symbol);
            return false;
        }
    }

    // Controlla che abbia dati validi
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);

    if (bid <= 0 || ask <= 0)
    {
        LOG_WARN("Invalid price data for symbol: " + symbol);
        return false;
    }

    return true;
}

/**
 * Ottiene il minimo stop trade in punti per il simbolo corrente.SYMBOL_TRADE_STOPS_LEVEL indica la distanza minima (in punti) dal prezzo corrente a cui puoi piazzare un ordine pending (come buy limit, sell limit, buy stop, sell stop) o impostare uno stop loss/take profit.
 • Se provi a piazzare un ordine troppo vicino al prezzo attuale, il broker lo rifiuta.
 */
static int Asset::GetMinStopTrade(const string symbol)
{
    // Ottieni il minimo stop trade in punti
    int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (stopsLevel < 0)
    {
        LOG_ERROR("Invalid minimum stop trade for symbol: " + symbol);
        return 0;
    }
    return stopsLevel;
}

// === PRIVATE CACHE METHODS ===

static bool Asset::IsCacheValid(const string symbol)
{
    if (cachedSymbol != symbol)
        return false;

    datetime currentTime = TimeCurrent();
    return (currentTime - lastCacheUpdate) < ASSET_CACHE_TIMEOUT;
}

static void Asset::UpdateCache(const string symbol, ASSET_TYPE assetType)
{
    cachedSymbol = symbol;
    cachedAssetType = assetType;
    lastCacheUpdate = TimeCurrent();
}

static void Asset::ClearCache()
{
    cachedSymbol = "";
    cachedAssetType = UNKNOWN;
    lastCacheUpdate = 0;
}

#endif // ASSET_MQH