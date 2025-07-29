//+------------------------------------------------------------------+
//|                                           CurrencyConversionTest.mq5 |
//|                            Test per verificare conversione automatica |
//|                                    VERSIONE EA per test continuo     |
//+------------------------------------------------------------------+

// Parametri input
input bool TestOnInit = true;          // Esegui test all'avvio
input bool TestOnTick = false;         // Esegui test ad ogni tick
input string TestSymbol = "DAX40";     // Simbolo da testare

bool testExecuted = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if(TestOnInit)
    {
        Print("=== CURRENCY TEST EA STARTED ===");
        RunCurrencyTest();
        testExecuted = true;
    }
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(TestOnTick || !testExecuted)
    {
        RunCurrencyTest();
        testExecuted = true;
    }
}

//+------------------------------------------------------------------+
//| Funzione principale di test                                      |
//+------------------------------------------------------------------+
void RunCurrencyTest()
{
    string symbol = TestSymbol; // Usa il simbolo impostato nei parametri
    
    Print("=== CURRENCY CONVERSION TEST ===");
    
    // 1. INFORMAZIONI BASE
    string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
    string profitCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
    string baseCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
    
    Print("Account Currency: ", accountCurrency);
    Print("Symbol: ", symbol);
    Print("Profit Currency: ", profitCurrency);
    Print("Base Currency: ", baseCurrency);
    
    // 2. VALORI TICK
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    
    Print("Tick Value: ", DoubleToString(tickValue, 6));
    Print("Tick Size: ", DoubleToString(tickSize, 6));
    
    // 3. TEST CONVERSIONE
    if(profitCurrency == accountCurrency)
    {
        Print("✅ NO CONVERSION NEEDED - Same currency!");
        Print("Il tick value è già nella tua valuta account");
    }
    else
    {
        Print("⚠️ CONVERSION NEEDED!");
        Print("Tick Value è in ", profitCurrency, ", ma account è in ", accountCurrency);
        
        // Verifica se tick value sembra già convertito
        if(accountCurrency == "USD" && profitCurrency == "EUR")
        {
            // Per DAX (EUR) su account USD, un tick value "normale" sarebbe ~1.05-1.10
            if(tickValue > 1.0 && tickValue < 2.0)
            {
                Print("✅ SEMBRA GIÀ CONVERTITO (valore ragionevole per EUR->USD)");
            }
            else if(tickValue < 1.0)
            {
                Print("❌ SEMBRA NON CONVERTITO (troppo basso per USD)");
            }
        }
    }
    
    // 4. CALCOLO MODE
    int calcMode = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE);
    Print("Trade Calc Mode: ", calcMode);
    
    switch(calcMode)
    {
        case 0: Print("Mode 0: Forex"); break;
        case 1: Print("Mode 1: CFD"); break;
        case 2: Print("Mode 2: Futures (tick value in base currency!)"); break;
        case 3: Print("Mode 3: CFD Index"); break;
        case 4: Print("Mode 4: CFD Leverage"); break;
        default: Print("Mode ", calcMode, ": Other"); break;
    }
    
    // 5. TEST PRATICO
    Print("\n=== TEST PRATICO ===");
    double testLots = 1.0;
    double testPoints = 100.0;
    double calculatedRisk = testLots * testPoints * tickValue;
    
    Print("Test: 1 lotto, 100 punti di movimento");
    Print("Rischio calcolato: ", DoubleToString(calculatedRisk, 2), " ", 
          (profitCurrency == accountCurrency ? accountCurrency : profitCurrency));
    
    // 6. RACCOMANDAZIONI
    Print("\n=== RACCOMANDAZIONI ===");
    
    if(profitCurrency != accountCurrency && calcMode == 2)
    {
        Print("❌ ATTENZIONE: Futures mode + diverse valute = tick value NON convertito!");
        Print("Devi fare conversione manuale!");
    }
    else if(profitCurrency != accountCurrency)
    {
        Print("⚠️ VERIFICA NECESSARIA: Testa con trade reale piccolo");
        Print("Confronta rischio calcolato vs. rischio effettivo in MT5");
    }
    else
    {
        Print("✅ OK: Stessa valuta, nessun problema");
    }
}

//+------------------------------------------------------------------+
//| Funzione di test avanzata per il tuo caso specifico           |
//+------------------------------------------------------------------+
void TestYourSpecificCase()
{
    Print("\n=== IL TUO CASO SPECIFICO ===");
    
    double riskUSD = 500.0;
    double stopLossPoints = 2715.0;
    double yourTickValue = 0.0138; // Il valore che hai
    
    double calculatedLots = riskUSD / (stopLossPoints * yourTickValue);
    
    Print("I tuoi parametri:");
    Print("Risk: $", DoubleToString(riskUSD, 2));
    Print("SL Points: ", DoubleToString(stopLossPoints, 0));
    Print("Tick Value: ", DoubleToString(yourTickValue, 6));
    Print("Lotti calcolati: ", DoubleToString(calculatedLots, 4));
    
    // Test di verifica
    double backCalculatedRisk = calculatedLots * stopLossPoints * yourTickValue;
    Print("Back-test rischio: $", DoubleToString(backCalculatedRisk, 2));
    Print("Accuracy: ", DoubleToString((backCalculatedRisk/riskUSD)*100, 2), "%");
}