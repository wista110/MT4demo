#include <Trade\Trade.mqh>
CTrade trade;

input double Lots = 0.01;
input int MaxPositions = 10;
input double BasePrice = 144.31;
input int PipInterval = 30;

double GetTotalNetProfitWithSwap()
{
    double totalProfit = 0.0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == _Symbol)
        {
            totalProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
    }
    return totalProfit;
}

void CloseAllBuyOrders()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            trade.PositionClose(_Symbol);
        }
    }
}

void OnTick()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double pointValue = _Point * PipInterval;

    int currentOrders = 0;
    double existingPrices[];
    ArrayResize(existingPrices, MaxPositions);
    ArrayInitialize(existingPrices, -1);

    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            existingPrices[currentOrders] = PositionGetDouble(POSITION_PRICE_OPEN);
            currentOrders++;
        }
    }

    double netTotal = GetTotalNetProfitWithSwap();
    if (netTotal >= 0.0 && currentOrders > 0)
    {
        Print("スワップ込みで損益がプラスに到達。全決済します。");
        CloseAllBuyOrders();
        return;
    }

    if (currentOrders >= MaxPositions)
        return;

    for (int i = 0; i < MaxPositions; i++)
    {
        double targetPrice = BasePrice - i * pointValue;
        bool alreadyExists = false;

        for (int j = 0; j < currentOrders; j++)
        {
            if (MathAbs(existingPrices[j] - targetPrice) < _Point * 5)
            {
                alreadyExists = true;
                break;
            }
        }

        if (ask <= targetPrice && !alreadyExists)
        {
            trade.Buy(Lots, _Symbol, ask, 0, 0, "BuyDownSwapEA");
            break;
        }
    }
}
