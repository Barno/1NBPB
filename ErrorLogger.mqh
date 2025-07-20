// File: ErrorLogger.mqh
class ErrorLogger
{
public:    
    
    static void LogError(string message)
    {
        int error = GetLastError();
        Print("× ERR: ", message, " - Errore: ", error);
        ResetLastError();
    }

};