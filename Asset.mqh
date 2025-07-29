// Asset.mqh
#ifndef ASSET_MQH
#define ASSET_MQH

#include "Logger.mqh"
#define ASSET_CACHE_TIMEOUT 30 // ✅ Usa define

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
        Logger::Error("Invalid contract size for symbol: " + symbol);
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
        Logger::Error("Invalid price or contract size for symbol: " + symbol);
        return 0.0;
    }

    // Calcola costo totale
    return contract * contractSize * price;
}

static double Asset::FreeMarginAvailable() {
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    if (freeMargin < 0)
    {
        Logger::Error("Free margin is negative: " + DoubleToString(freeMargin, 2));
        return 0.0;
    }
    return freeMargin;
}
static double Asset::GetMarginRequired(const string symbol, double lots, TRADE tradeType = BUY)
{
    // Validazione input
    if (lots <= 0)
    {
        Logger::Error("Invalid lot size: " + DoubleToString(lots, 3));
        return 0.0;
    }

    // Ottieni prezzo in base al tipo di trade
    double price = (tradeType == BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);

    double requiredMargin = 0.0; // Variabile per ricevere il risultato
    // Converti TRADE enum a ENUM_ORDER_TYPE per MT5
    ENUM_ORDER_TYPE orderType = (tradeType == BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

    // Metodo 1: Usa funzione MT5 per calcolo margine preciso
    double success = OrderCalcMargin(orderType, symbol, lots, price,requiredMargin);

    if (success)
    {
        return requiredMargin;
    }

    // Metodo 2: Fallback - calcolo manuale
    Logger::Warn("OrderCalcMargin failed, using manual calculation for: " + symbol);

    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);

    if (contractSize <= 0 || leverage <= 0)
    {
        Logger::Error("Invalid contract size or leverage for: " + symbol);
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
        Logger::Warn("Invalid spread for symbol: " + symbol);
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

#endif // ASSET_MQH