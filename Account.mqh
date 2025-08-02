// Account.mqh
#ifndef ACCOUNT_MQH
#define ACCOUNT_MQH

#include <Trade\AccountInfo.mqh>
#define CLASS_NAME "ACCOUNT"
//+------------------------------------------------------------------+
//| Account Static Facade Class                                    |
//+------------------------------------------------------------------+
class Account
{
private:
    static CAccountInfo s_accountInfo;

public:
    static bool Initialize();
    static double GetBalance();
    static double GetEquity();
    static string GetCurrency();
};

//+------------------------------------------------------------------+
//| Static member definition - DOPO la classe                      |
//+------------------------------------------------------------------+
static CAccountInfo Account::s_accountInfo;

//+------------------------------------------------------------------+
//| Initialize account (senza Refresh che non esiste)             |
//+------------------------------------------------------------------+
static bool Account::Initialize()
{
    double balance = s_accountInfo.Balance();
    if (balance < 0)
    {
        Logger::LogError("Account::Initialize(). Account initialized with balance: " + DoubleToString(balance, 2) + " Invalid balance");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Get account balance                                            |
//+------------------------------------------------------------------+
static double Account::GetBalance()
{
    return s_accountInfo.Balance();
}

//+------------------------------------------------------------------+
//| Get account equity                                             |
//+------------------------------------------------------------------+
static double Account::GetEquity()
{
    return s_accountInfo.Equity();
}

//+------------------------------------------------------------------+
//| Get account currency                                           |
//+------------------------------------------------------------------+
static string Account::GetCurrency()
{
    return s_accountInfo.Currency();
}

#endif // ACCOUNT_MQH