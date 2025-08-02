input group "===  ORA CANDELA DI RIFERIMENTO ===";
input ENUM_TIMEFRAMES g_referenceCandleTimeframe = PERIOD_M5; // Timeframe per candela di riferimento
input int g_HourInput = 10;                                   // Ora Candela di riferimento
input int g_MinuteInput = 0;                                  // Minuti di riferimento per l'operazione

input group "===  LIVELLO DI LOG ===";
input Logger::LOG_LEVEL logLevel = Logger::LEVEL_DEBUG; // Livello di log

input group "=== OPZIONI DI ENTRATA ===";
input int g_OffsetPointsEntry = 5; // Punti di offset di entrata sotto il minimo della candela. mettendo 5, si entra 5 punti distante dal prezzo che vogliamo
input int g_OffsetPointsRisk = 0;  // Punti di offset di rischio (SL) da aggiungere allo stop loss.
input int g_Deviation = 5;         // Quantità di punti di deviazione che si accettano per l'ordine (slippage). se il mio prezzo è 100, 5 deviation accetto 95 o 105

input group "===  TAKE PROFIT PRINCIPALI ===";
input int g_NumeroTarget = 2;
input double g_TP1_RiskReward = 1.8;         // TP1: Rapporto Rischio/Rendimento (1:0.5)
input double g_TP1_PercentualeVolume = 50.0; // TP1: Percentuale volume posizione (%)
input double g_TP2_RiskReward = 3.0;         // TP2: Rapporto Rischio/Rendimento (1:3.0)
input double g_TP2_PercentualeVolume = 50.0; // TP2: Percentuale volume posizione (%)
input bool g_AttivareBreakevenDopoTP = true; // Attiva breakeven automatico dopo TP
input int g_BreakevenAfterTPNumber = 1;      // Dopo quale TP attivare breakeven (1,2,

input group "===  GESTIONE RISCHIO ===";
input double g_RischioPercentuale = 0.5; // Percentuale rischio per trade (% del capitale) ()
input bool g_UsaEquityPerRischio = true;