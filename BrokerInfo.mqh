// BrokerInfo.mqh
#ifndef BROKER_INFO_MQH
#define BROKER_INFO_MQH

#define CLASS_NAME "BROKER INFO"

class BrokerInfo
{
public:
    // === METODI PRINCIPALI ===
    static void LogTradingInfo();
    static string GetBrokerSummary();
    static bool Initialize();
    static void PrintFillingModes();

    // === INFO ESSENZIALI ===
    static string GetCompanyName();
    static string GetServerName();
    static string GetAccountType();
    static int GetLeverage();
    static double GetMarginCall();
    static double GetMarginStopOut();
    static string GetExecutionMode();
    static int GetPing();
    static string GetConnectionStatus();
    static datetime GetServerTime();
    static int GetGmtOffset();
    static string GetServerTimezone();
    static bool IsDaylightSaving();
    static bool IsTradeAllowed();
    static bool IsExpertAllowed();
    static int GetMaxOrders();
    static string GetPlatformInfo();

    // === TIMEZONE METHODS ===
    static void LogTimezoneInfo();
};

// === IMPLEMENTAZIONI ===

static bool BrokerInfo::Initialize()
{
    LOG_INFO("BrokerInfo: Collecting essential trading information...");
    return true;
}

static void BrokerInfo::LogTradingInfo()
{
    LOG_INFO("=== ESSENTIAL BROKER INFO ===");
    LOG_INFO("Company: " + GetCompanyName());
    LOG_INFO("Server: " + GetServerName());
    LOG_INFO("Account Type: " + GetAccountType());
    LOG_INFO("Leverage: 1:" + IntegerToString(GetLeverage()));
    LOG_INFO("Margin Call: " + DoubleToString(GetMarginCall(), 2) + "%");
    LOG_INFO("Margin Stop Out: " + DoubleToString(GetMarginStopOut(), 2) + "%");
    LOG_INFO("Execution Mode: " + GetExecutionMode());
    LOG_INFO("Connection: " + GetConnectionStatus());
    LOG_INFO("Ping: " + IntegerToString(GetPing()) + "ms");
    LOG_INFO("Server Time: " + TimeToString(GetServerTime(), TIME_DATE | TIME_SECONDS));
    LOG_INFO("GMT Offset: " + IntegerToString(GetGmtOffset()) + " hours");
    LOG_INFO("Server Timezone: " + GetServerTimezone());
    LOG_INFO("Platform: " + GetPlatformInfo());
    LOG_INFO("Max Orders: " + IntegerToString(GetMaxOrders()));
    LOG_INFO("Expert Allowed: " + (IsExpertAllowed() ? "YES" : "NO"));
    LOG_INFO("Trade Allowed: " + (IsTradeAllowed() ? "YES" : "NO"));
    PrintFillingModes();
    LOG_INFO("=== END BROKER INFO ===");

    // Log timezone dettagliato separato
    LogTimezoneInfo();
}

static string BrokerInfo::GetBrokerSummary()
{
    return StringFormat("%s | %s | %s | 1:%d | %s | Ping:%dms",
                        GetCompanyName(),
                        GetServerName(),
                        GetAccountType(),
                        GetLeverage(),
                        GetExecutionMode(),
                        GetPing());
}

static string BrokerInfo::GetCompanyName()
{
    string company = AccountInfoString(ACCOUNT_COMPANY);
    return (company != "") ? company : "Unknown";
}

static string BrokerInfo::GetServerName()
{
    string server = AccountInfoString(ACCOUNT_SERVER);
    return (server != "") ? server : "Unknown";
}

static string BrokerInfo::GetAccountType()
{
    ENUM_ACCOUNT_TRADE_MODE tradeMode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
    switch (tradeMode)
    {
    case ACCOUNT_TRADE_MODE_DEMO:
        return "DEMO";
    case ACCOUNT_TRADE_MODE_CONTEST:
        return "CONTEST";
    case ACCOUNT_TRADE_MODE_REAL:
        return "REAL";
    default:
        return "UNKNOWN";
    }
}

static int BrokerInfo::GetLeverage()
{
    int leverage = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
    return (leverage > 0) ? leverage : 1;
}

static double BrokerInfo::GetMarginCall()
{
    double marginCall = AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
    return (marginCall > 0) ? marginCall : 100.0; // Default 100% se non disponibile
}

static double BrokerInfo::GetMarginStopOut()
{
    double marginStopOut = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
    return (marginStopOut > 0) ? marginStopOut : 50.0; // Default 50% se non disponibile
}

static string BrokerInfo::GetExecutionMode()
{
    ENUM_SYMBOL_TRADE_EXECUTION execution = (ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_EXEMODE);
    switch (execution)
    {
    case SYMBOL_TRADE_EXECUTION_REQUEST:
        return "REQUEST";
    case SYMBOL_TRADE_EXECUTION_INSTANT:
        return "INSTANT";
    case SYMBOL_TRADE_EXECUTION_MARKET:
        return "MARKET";
    case SYMBOL_TRADE_EXECUTION_EXCHANGE:
        return "EXCHANGE";
    default:
        return "UNKNOWN";
    }
}

static int BrokerInfo::GetPing()
{
    int ping = (int)TerminalInfoInteger(TERMINAL_PING_LAST);
    return (ping >= 0) ? ping : 0;
}

static string BrokerInfo::GetConnectionStatus()
{
    bool connected = (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
    return connected ? "CONNECTED" : "DISCONNECTED";
}

static datetime BrokerInfo::GetServerTime()
{
    return TimeCurrent();
}

static int BrokerInfo::GetGmtOffset()
{
    datetime serverTime = TimeCurrent();
    datetime gmtTime = TimeGMT();

    // Calcola la differenza in ore
    int offsetSeconds = (int)(serverTime - gmtTime);
    return offsetSeconds / 3600; // Converti in ore
}

static string BrokerInfo::GetServerTimezone()
{
    int offset = GetGmtOffset();

    // Mapping comuni delle timezone broker
    switch (offset)
    {
    case 0:
        return "GMT/UTC (London Winter)";
    case 1:
        return "CET (London Summer / Frankfurt Winter)";
    case 2:
        return "EET (Frankfurt Summer / Cyprus)";
    case 3:
        return "MSK (Moscow / Turkey)";
    case -5:
        return "EST (New York Winter)";
    case -4:
        return "EDT (New York Summer)";
    case -8:
        return "PST (Los Angeles Winter)";
    case -7:
        return "PDT (Los Angeles Summer)";
    case 9:
        return "JST (Tokyo)";
    case 10:
        return "AEST (Sydney Winter)";
    case 11:
        return "AEDT (Sydney Summer)";
    default:
        return "GMT" + (offset >= 0 ? "+" : "") + IntegerToString(offset);
    }
}

static void BrokerInfo::PrintFillingModes()
{
    int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    if (filling & SYMBOL_FILLING_IOC)
        LOG_INFO("IOC permesso");
    if (filling & SYMBOL_FILLING_FOK)
        LOG_INFO("FOK permesso");
}

static bool BrokerInfo::IsDaylightSaving()
{
    // Metodo approssimativo per rilevare DST
    datetime now = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(now, dt);

    // Controlla se siamo nel periodo DST (marzo-ottobre nell'emisfero nord)
    // Questa è una stima approssimativa
    if (dt.mon >= 3 && dt.mon <= 10)
    {
        int offset = GetGmtOffset();
        // Se offset è maggiore del normale, probabilmente è DST
        return (offset > 0 && (offset == 1 || offset == 2 || offset == -4 || offset == -7));
    }

    return false;
}

static void BrokerInfo::LogTimezoneInfo()
{
    datetime serverTime = TimeCurrent();
    datetime gmtTime = TimeGMT();
    datetime localTime = TimeLocal();

    LOG_INFO("=== TIMEZONE INFORMATION ===");
    LOG_INFO("Server Time: " + TimeToString(serverTime, TIME_DATE | TIME_SECONDS));
    LOG_INFO("GMT Time: " + TimeToString(gmtTime, TIME_DATE | TIME_SECONDS));
    LOG_INFO("Local Time: " + TimeToString(localTime, TIME_DATE | TIME_SECONDS));
    LOG_INFO("GMT Offset: " + IntegerToString(GetGmtOffset()) + " hours");
    LOG_INFO("Server Timezone: " + GetServerTimezone());
    LOG_INFO("Daylight Saving: " + (IsDaylightSaving() ? "Probably YES" : "Probably NO"));
    LOG_INFO("=== END TIMEZONE INFO ===");
}

static bool BrokerInfo::IsTradeAllowed()
{
    return (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
}

static bool BrokerInfo::IsExpertAllowed()
{
    return (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
}

static int BrokerInfo::GetMaxOrders()
{
    int maxOrders = (int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
    return (maxOrders > 0) ? maxOrders : 999999; // Illimitato se 0
}

static string BrokerInfo::GetPlatformInfo()
{
    string name = TerminalInfoString(TERMINAL_NAME);
    int build = (int)TerminalInfoInteger(TERMINAL_BUILD);

    if (name == "")
        name = "MetaTrader 5";

    return name + " Build " + IntegerToString(build);
}

#endif // BROKER_INFO_MQH