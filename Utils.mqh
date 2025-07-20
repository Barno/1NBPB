
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
        // TRUCCO MATEMATICO per ottenere solo la data (senza orario)
        //
        // Esempio: 20 Luglio 2025, 14:30:45 → 20 Luglio 2025, 00:00:00
        //
        // Step 1: Divisione intera elimina i secondi del giorno corrente
        // fullDateTime (es. 1753200645) / 86400 = 20291 giorni dall'1 Jan 1970
        // La divisione intera taglia automaticamente la parte frazionaria (le ore)
        long days = fullDateTime / SECONDS_PER_DAY;

        // Step 2: Moltiplicazione ricostruisce il datetime solo con giorni completi
        // 20291 * 86400 = 1753113600 secondi = 20 Luglio 2025, 00:00:00
        // Risultato: stessa data ma con orario azzerato a mezzanotte
        return (datetime)(days * SECONDS_PER_DAY);

        // Alternativa tradizionale (più lenta):
        // MqlDateTime dt;
        // TimeToStruct(fullDateTime, dt);
        // dt.hour = 0; dt.min = 0; dt.sec = 0;
        // return StructToTime(dt);
    }
};