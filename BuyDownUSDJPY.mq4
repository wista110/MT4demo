//+------------------------------------------------------------------+
//| USDJPY Buy-Down EA with Swap Breakeven Exit                     |
//+------------------------------------------------------------------+
#property strict

extern double Lots = 0.01;
extern int MaxPositions = 10;
extern double BasePrice = 157.00;
extern int PipInterval = 30;   
// 10pips（0.1円）	狭い。頻繁にエントリー	0.9円（90pips）	リスク高い 🔺
//30pips（0.3円）	標準～やや慎重	2.7円	良好 👍 （AI推奨）
//50pips（0.5円）	慎重。試験運用に最適	4.5円	高安全性 ✅

double GetTotalNetProfitWithSwap()
{
    double totalProfit = 0;

    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderSymbol() == Symbol() && OrderType() == OP_BUY)
            {
                totalProfit += OrderProfit() + OrderSwap();  // 含み損益＋スワップ
            }
        }
    }

    return totalProfit;
}

void CloseAllBuyOrders()
{
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderSymbol() == Symbol() && OrderType() == OP_BUY)
            {
                OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrRed);
            }
        }
    }
}

int OnInit()
{
    return (INIT_SUCCEEDED);
}

void OnTick()
{
    double ask = NormalizeDouble(Ask, Digits);
    double pointValue = Point * PipInterval;

    int currentOrders = 0;
    double existingPrices[MaxPositions];
    ArrayInitialize(existingPrices, -1);

    // ポジション数とエントリー価格の把握
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderSymbol() == Symbol() && OrderType() == OP_BUY)
            {
                existingPrices[currentOrders] = NormalizeDouble(OrderOpenPrice(), Digits);
                currentOrders++;
            }
        }
    }

    // 利益＋スワップがプラスになったら決済
    double netTotal = GetTotalNetProfitWithSwap();
    if (netTotal >= 0.0 && currentOrders > 0)
    {
        Print("スワップ込みで損益がプラスに到達。全決済します。");
        CloseAllBuyOrders();
        return;
    }

    if (currentOrders >= MaxPositions)
        return;

    // ナンピンエントリー判定
    for (int i = 0; i < MaxPositions; i++)
    {
        double targetPrice = NormalizeDouble(BasePrice - i * pointValue, Digits);
        bool alreadyExists = false;

        for (int j = 0; j < currentOrders; j++)
        {
            if (MathAbs(existingPrices[j] - targetPrice) < Point * 5)
            {
                alreadyExists = true;
                break;
            }
        }

        if (ask <= targetPrice && !alreadyExists)
        {
            OrderSend(Symbol(), OP_BUY, Lots, ask, 3, 0, 0, "BuyDownSwapEA", 123456, 0, clrBlue);
            break;
        }
    }
}
