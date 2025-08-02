#ifndef LOGGER_MQH
#define LOGGER_MQH

#define LOG_INFO(msg) Logger::Info(msg, CLASS_NAME)
#define LOG_DEBUG(msg) Logger::Debug(msg, CLASS_NAME)
#define LOG_WARN(msg) Logger::Warn(msg, CLASS_NAME)
#define LOG_ERROR(msg) Logger::Error(msg, CLASS_NAME)
#define LOG_SUCCESS(msg) Logger::Success(msg, CLASS_NAME)

class Logger
{
private:
    static int s_logLevel;

    // Metodo privato centralizzato
    static void PrintLog(const string label, int level, const string message, const string className = "")
    {
        if (s_logLevel <= level)
            Print(label, (className != "" ? " [" + className + "] " : " "), message);
    }

public:
    enum LOG_LEVEL
    {
        LEVEL_DEBUG = 0,
        LEVEL_INFO = 1,
        LEVEL_WARN = 2,
        LEVEL_ERROR = 3
    };

    static void Debug(const string message, const string className = "") { PrintLog("[DEBUG]", LEVEL_DEBUG, message, className); }
    static void Info(const string message, const string className = "") { PrintLog("[INFO]", LEVEL_INFO, message, className); }
    static void Warn(const string message, const string className = "") { PrintLog("[WARN]", LEVEL_WARN, message, className); }
    static void Error(const string message, const string className = "") { PrintLog("[!!! ERROR !!!]", LEVEL_ERROR, message, className); }
    static void Success(const string message, const string className = "") { PrintLog("[OK]", LEVEL_INFO, message, className); }

    static void SetLogLevel(int level) { s_logLevel = level; }

    static void LogError(string message, const string className = "")
    {
        int error = GetLastError();
        Error(message + " - Errore: " + IntegerToString(error), className);
        ResetLastError();
    }
};

int Logger::s_logLevel = Logger::LEVEL_DEBUG;

#endif // LOGGER_MQH
