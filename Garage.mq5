// Preprocessor directives
#include <Trade\AccountInfo.mqh>
CAccountInfo account; // Perfetto qui!

int OnInit()
{
    double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    Print("Minimum Volume: " + minVolume);
    Print("Maximum Volume: " + maxVolume);
    Print("Volume Step: " + stepVolume);
    Print("ACCOUNT_BALANCE " + AccountInfoDouble(ACCOUNT_BALANCE));
    Print("TICK VALUE (come se fosse Dollari || Euro) " + SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE));
    Print("SYMBOL CURRENCY " + SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT));

    Print("LEVERAGE " + AccountInfoInteger(ACCOUNT_LEVERAGE));
    Print(" ACCOUNT_CURRENCY  " + AccountInfoString(ACCOUNT_CURRENCY));
    Print("FREE margin " + AccountInfoDouble(ACCOUNT_MARGIN_FREE));
    Print("MARGIN " + AccountInfoDouble(ACCOUNT_MARGIN));
    Print("LOGIN " + AccountInfoInteger(ACCOUNT_LOGIN));

    // Stampa info complete account
    Print("=== ACCOUNT INFO ===");
    Print("Balance: ", account.Balance());
    Print("Equity: ", account.Equity());
    Print("Margin Level: ", account.MarginLevel(), "%");
    Print("Company: ", account.Company());
    Print("Leverage: 1:", account.Leverage());
    Print("LEVERAGE " + AccountInfoInteger(ACCOUNT_LEVERAGE));

    // Controlli iniziali
    if (account.MarginLevel() < 100 && account.Margin() > 0)
    {
        Print("⚠️ WARNING: Starting with low margin level!");
    }

    // Validazioni pre-trading
    if (account.Leverage() < 50)
    {
        Print("⚠️ Low leverage detected: 1:", account.Leverage());
    }

    // Test costi lotti simboli principali
    Print("--- COSTI 1 LOTTO ---");
    string symbols[] = {"DAX40"};
    for (int i = 0; i < ArraySize(symbols); i++)
    {
        if (SymbolSelect(symbols[i], true))
        {
            double costLotto = GetLotCost(symbols[i]);
            // Print(symbols[i], " 1 lotto: ", costLotto, " ", AccountInfoString(ACCOUNT_CURRENCY));

            double costMicro = GetMinMax(symbols[i], 0.01);   // Micro lotto
            double costMini = GetMinMax(symbols[i], 0.1);     // Mini lotto
            double costStandard = GetMinMax(symbols[i], 1.0); // Lotto standard
            double costGrande = GetMinMax(symbols[i], 10.0);  // 10 lotti

            Print("Costo 0.01 lotti: $", costMicro);
            Print("Costo 0.1 lotti: $", costMini);
            Print("Costo 1.0 lotto: $", costStandard);
            Print("Costo 10 lotti: $", costGrande);

            double minVol = SymbolInfoDouble(symbols[i], SYMBOL_VOLUME_MIN);
            double costMinimo = GetMinMax(symbols[i], minVol);
            Print(symbols[i], " volume min (", minVol, "): ", costMinimo, " ", AccountInfoString(ACCOUNT_CURRENCY));
            CheckMarginExample(symbols[i], minVol);

            double maxVol = SymbolInfoDouble(symbols[i], SYMBOL_VOLUME_MAX);
            double costMassimo = GetMinMax(symbols[i], maxVol);
            // Print(symbols[i], " volume max (", maxVol, "): ", costMassimo, " ", AccountInfoString(ACCOUNT_CURRENCY));
            CheckMarginExample(symbols[i], maxVol);

            double stepVol = SymbolInfoDouble(symbols[i], SYMBOL_VOLUME_STEP);
            Print("MARGIN LEVEL " + account.MarginLevel());
            // Print(symbols[i], " step volume: ", stepVol);
        }
    }

    // CheckMarginExample();
    return INIT_SUCCEEDED;
}

double GetLotCost(string symbol)
{
    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    double price = SymbolInfoDouble(symbol, SYMBOL_ASK);

    return contractSize * price;
}

double GetMinMax(string symbol, double volume)
{
    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    // Calcola il costo in base al volume specificato
    double price = SymbolInfoDouble(symbol, SYMBOL_ASK);

    return contractSize * price * volume;
}

void CheckMarginExample(string symbol = "EURUSD", double lots = 1.0)
{
    double requiredMargin = 0.0; // Variabile per ricevere il risultato

    bool success = OrderCalcMargin(
        ORDER_TYPE_BUY,                       // Tipo ordine
        symbol,                               // Simbolo
        lots,                                 // 1 lotto
        SymbolInfoDouble(symbol, SYMBOL_ASK), // Prezzo corrente
        requiredMargin                        // [OUT] Risultato qui
    );

    if (success)
    {
        Print("✅ Margine richiesto: ", requiredMargin, " ", AccountInfoString(ACCOUNT_CURRENCY), " per ", lots, " lotti di ", symbol, " al prezzo di ", GetMinMax(symbol, lots));

        // Verifica se puoi permettertelo
        double freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
        if (requiredMargin <= freeMargin)
        {
            Print("✅ Trade possibile!");
        }
        else
        {
            Print("❌ Margine insufficiente. Ti servono: ", (requiredMargin - freeMargin));
        }
    }
    else
    {
        Print("❌ Errore nel calcolo margine");
    }
}