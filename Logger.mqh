// Logger.mqh
#ifndef LOGGER_MQH
#define LOGGER_MQH

class Logger
{
private:
    static int s_logLevel;
    static bool s_silentMode;

public:
    enum LOG_LEVEL 
    {
        LOG_DEBUG = 0,
        LOG_INFO = 1, 
        LOG_WARN = 2,
        LOG_ERROR = 3
    };
    
    static void Debug(const string message);
    static void Info(const string message);
    static void Warn(const string message);
    static void Error(const string message);
    static void Success(const string message);
    
    static void SetLogLevel(int level);
    static void SetSilentMode(bool silent);
    static bool IsSilent();
    static void LogError(string message);
};

// ✅ DEFINIZIONI STATICHE (fuori dalla classe)
static int Logger::s_logLevel = 0;
static bool Logger::s_silentMode = false;

// ✅ IMPLEMENTAZIONI
static void Logger::Debug(const string message) 
{ 
    if (!s_silentMode && s_logLevel <= LOG_DEBUG) Print("[DEBUG] ", message); 
}

static void Logger::Info(const string message) 
{ 
    if (!s_silentMode && s_logLevel <= LOG_INFO) Print("[INFO] ", message); 
}

static void Logger::Warn(const string message) 
{ 
    if (!s_silentMode && s_logLevel <= LOG_WARN) Print("[WARN] ", message); 
}

static void Logger::Error(const string message) 
{ 
    if (!s_silentMode && s_logLevel <= LOG_ERROR) Print("[ERROR] ", message); 
}

static void Logger::Success(const string message) 
{ 
    if (!s_silentMode && s_logLevel <= LOG_INFO) Print("[OK] ", message); 
}

static void Logger::SetLogLevel(int level) 
{ 
    s_logLevel = level; 
}

static void Logger::SetSilentMode(bool silent) 
{ 
    s_silentMode = silent; 
}

static bool Logger::IsSilent() 
{ 
    return s_silentMode; 
}

static void Logger::LogError(string message)
{
    int error = GetLastError();
    Error(message + " - Errore: " + IntegerToString(error));
    ResetLastError();
}

#endif // LOGGER_MQH