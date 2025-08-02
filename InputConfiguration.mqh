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

input group "===  TARGET 1 ===";
input double g_TP1_RiskReward = 1.8;
input double g_TP1_VolumePercent = 50.0;

input group "===  TARGET 2 ===";
input double g_TP2_RiskReward = 3.0;
input double g_TP2_VolumePercent = 50.0;

input group "===  TARGET 3 ===";
input double g_TP3_RiskReward = 4.5;
input double g_TP3_VolumePercent = 0.0; // 0 = non usato

input group "===  TARGET 4 ===";
input double g_TP4_RiskReward = 6.0;
input double g_TP4_VolumePercent = 0.0; // 0 = non usato

input group "===  TARGET 5 ===";
input double g_TP5_RiskReward = 8.0;
input double g_TP5_VolumePercent = 0.0; // 0 = non usato

// ARRAY GLOBALI - popolati dinamicamente
double g_TargetRR[];
double g_TargetVolumePercent[];

input bool g_AttivareBreakevenDopoTP = true; // Attiva breakeven automatico dopo TP
input int g_BreakevenAfterTPNumber = 1;      // Dopo quale TP attivare breakeven (1,2,

input group "===  GESTIONE RISCHIO ===";
input double g_RischioPercentuale = 0.5; // Percentuale rischio per trade (% del capitale) ()
input bool g_UsaEquityPerRischio = true;

// Funzione di inizializzazione array (chiamata in OnInit)
#define CLASS_NAME "INPUT CONFIGURATION"
void InitializeTargetArrays()
{
    ArrayResize(g_TargetRR, 5);
    ArrayResize(g_TargetVolumePercent, 5);

    g_TargetRR[0] = g_TP1_RiskReward;
    g_TargetRR[1] = g_TP2_RiskReward;
    g_TargetRR[2] = g_TP3_RiskReward;
    g_TargetRR[3] = g_TP4_RiskReward;
    g_TargetRR[4] = g_TP5_RiskReward;

    g_TargetVolumePercent[0] = g_TP1_VolumePercent;
    g_TargetVolumePercent[1] = g_TP2_VolumePercent;
    g_TargetVolumePercent[2] = g_TP3_VolumePercent;
    g_TargetVolumePercent[3] = g_TP4_VolumePercent;
    g_TargetVolumePercent[4] = g_TP5_VolumePercent;

    LOG_DEBUG("Target arrays initialized:", "TEST");
    for (int i = 0; i < ArraySize(g_TargetRR); i++)
    {
        LOG_DEBUG(StringFormat("Target %d: RR=%.1f, Volume=%.1f%%", i + 1, g_TargetRR[i], g_TargetVolumePercent[i], "TEST"));
    }
}