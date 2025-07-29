class TradingExecutor
{
private:
    static datetime executedDate;
    static datetime lastAttemptTime;

public:
    static bool ShouldExecuteTrade(int baseHour, int baseMinute, int additionalMinutes, int secondsBefore = 0, int secondsAfter = 20)
    {
        // Controlla se siamo nella finestra temporale
        if (!TimeUtils::IsInTargetWindow(baseHour, baseMinute, additionalMinutes, secondsBefore, secondsAfter))
        {
            // Reset attempt time quando usciamo dalla finestra
            lastAttemptTime = 0;
            return false;
        }

        // Ottieni la data di oggi (senza ora)
        datetime today = GetTodayDate();

        // Se abbiamo già eseguito oggi, non fare nulla
        if (executedDate == today)
            return false;

        datetime currentTime = TimeCurrent();
        datetime targetTime = TimeUtils::CalculateTargetTime(baseHour, baseMinute, additionalMinutes);

        // Esegui alle :00 in punto (primi 1 secondo)
        if (currentTime >= targetTime && currentTime <= targetTime + 1)
        {
            executedDate = today;
            lastAttemptTime = currentTime;
            Logger::Debug("Eseguito in punto! Tempo: " + TimeToString(currentTime, TIME_SECONDS));
            return true;
        }

        // Se non siamo riusciti nel primo secondo, riprova dopo 1 secondo
        // massimo riprova due volte per evitare loop infiniti
        if (currentTime > targetTime + 1 && (lastAttemptTime == 0 || currentTime >= lastAttemptTime + 1))
        {
            executedDate = today;
            lastAttemptTime = currentTime;
            Logger::Warn("Eseguito in retry! Tempo: " + TimeToString(currentTime, TIME_SECONDS));
            return true;
        }

        return false;
    }

    static datetime GetTodayDate()
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        dt.hour = 0;
        dt.min = 0;
        dt.sec = 0;
        return StructToTime(dt);
    }

    static datetime GetExecutedDate()
    {
        return executedDate;
    }

    static datetime GetLastAttemptTime()
    {
        return lastAttemptTime;
    }

    static bool HasExecutedToday()
    {
        return (executedDate == GetTodayDate());
    }

    static void ResetExecution()
    {
        executedDate = 0;
        lastAttemptTime = 0;
        Print("TradingExecutor: Reset manuale eseguito");
    }

    static string GetStatusInfo()
    {
        datetime today = GetTodayDate();
        string status = "TradingExecutor Status:\n";
        status = status + "- Today: " + TimeToString(today, TIME_DATE) + "\n";
        status = status + "- Executed Date: " + (executedDate > 0 ? TimeToString(executedDate, TIME_DATE) : "Never") + "\n";
        status = status + "- Has Executed Today: " + (HasExecutedToday() ? "YES" : "NO") + "\n";
        status = status + "- Last Attempt: " + (lastAttemptTime > 0 ? TimeToString(lastAttemptTime, TIME_SECONDS) : "Never");
        return status;
    }
};

// Definizioni statiche
datetime TradingExecutor::executedDate = 0;
datetime TradingExecutor::lastAttemptTime = 0;