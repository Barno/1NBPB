
#include "Enums.mqh"

class Utils
{
public:
    // Crea un datetime a partire da ora e minuti
    // Se pHour e pMinute sono 0, usa l'ora corrente
    static datetime CreateDateTime(int pHour = 0, int pMinute = 0)
    {
        MqlDateTime timeStruct;
        TimeToStruct(TimeCurrent(), timeStruct);
        timeStruct.hour = pHour;
        timeStruct.min = pMinute;
        datetime useTime = StructToTime(timeStruct);
        return (useTime);
    }

    static datetime Utils::GetDateOnly(datetime fullDateTime)
    {
        // UNIX TIMESTAMP RESET
        // MQL5 datetime = Unix timestamp (secondi dal 1 Jan 1970 UTC)
        // Trucco: dividere per secondi/giorno elimina ore/minuti/secondi

        long days = fullDateTime / SECONDS_PER_DAY; // Giorni completi dall'Unix Epoch
        return (datetime)(days * SECONDS_PER_DAY);  // Mezzanotte dello stesso giorno
    }

    static datetime Utils::GetTime(datetime fullDateTime)
    {
        // UNIX TIMESTAMP RESET
        // MQL5 datetime = Unix timestamp (secondi dal 1 Jan 1970 UTC)
        // Trucco: dividere per secondi/giorno elimina ore/minuti/secondi

        long days = fullDateTime / SECONDS_PER_DAY; // Giorni completi dall'Unix Epoch
        return (datetime)(days * SECONDS_PER_DAY);  // Mezzanotte dello stesso giorno
    }

    static bool checkTime(datetime checkTime, int startHour, int startMin, int endHour, int endMin)
    {
        MqlDateTime dt;
        TimeToStruct(checkTime, dt);

        int currentMinutes = dt.hour * 60 + dt.min;
        int startMinutes = startHour * 60 + startMin;
        int endMinutes = endHour * 60 + endMin;

        return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
    }

    static bool IsExactTime(int targetHour, int targetMinute)
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return (dt.hour == targetHour && dt.min == targetMinute);
    }

    static bool IsExactTimeOnce(int targetHour, int targetMinute)
    {
        static int lastExecutedHour = -1;
        static int lastExecutedMinute = -1;

        if (IsExactTime(targetHour, targetMinute))
        {
            if (lastExecutedHour != targetHour || lastExecutedMinute != targetMinute)
            {
                lastExecutedHour = targetHour;
                lastExecutedMinute = targetMinute;
                return true;
            }
        }
        else
        {
            // Reset quando cambia l'orario
            if (lastExecutedHour == targetHour && lastExecutedMinute == targetMinute)
            {
                lastExecutedHour = -1;
                lastExecutedMinute = -1;
            }
        }
        return false;
    }

    static int GetCurrentHour()
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return dt.hour;
    }

    static int GetCurrentMinute()
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return dt.min;
    }
};