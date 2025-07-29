class TimeUtils
{
private:
    static datetime lastExecutedTarget;
    static bool executedInCurrentWindow;

public:
    static datetime CreateDateTime(int hour, int minute, int second)
    {
        MqlDateTime timeStruct;
        TimeToStruct(TimeCurrent(), timeStruct);
        timeStruct.hour = hour;
        timeStruct.min = minute;
        timeStruct.sec = second;
        return StructToTime(timeStruct);
    }

    static bool IsInTimeWindow(int targetHour, int targetMinute, int secondsBefore = 10, int secondsAfter = 20)
    {
        datetime targetTime = CreateDateTime(targetHour, targetMinute, 0);
        datetime currentTime = TimeCurrent();

        datetime windowStart = targetTime - secondsBefore;
        datetime windowEnd = targetTime + secondsAfter;

        bool inWindow = (currentTime >= windowStart && currentTime <= windowEnd);
        return inWindow;
    }

    static datetime CalculateTargetTime(int baseHour, int baseMinute, int additionalMinutes)
    {
        // Converti tutto in timestamp Unix per calcoli più precisi
        datetime baseTime = CreateDateTime(baseHour, baseMinute, 0);
        datetime targetTime = baseTime + (additionalMinutes * 60); // Aggiungi i minuti in secondi

        return targetTime;
    }

    static bool IsInTargetWindow(int baseHour, int baseMinute, int additionalMinutes, int secondsBefore = 10, int secondsAfter = 20)
    {
        datetime targetTime = CalculateTargetTime(baseHour, baseMinute, additionalMinutes);
        datetime currentTime = TimeCurrent();

        // Calcola finestra con timestamp Unix
        datetime windowStart = targetTime - secondsBefore;
        datetime windowEnd = targetTime + secondsAfter;

        return (currentTime >= windowStart && currentTime <= windowEnd);
    }

    // da un TIMEFRAME restituisce i minuti
    static int getMinutesFromPeriod(ENUM_TIMEFRAMES timeframe)
    {
        int seconds = PeriodSeconds(timeframe);
        return (seconds > 0) ? seconds / 60 : -1;
    }
};