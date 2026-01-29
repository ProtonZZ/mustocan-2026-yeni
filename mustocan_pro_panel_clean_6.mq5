#property strict

input double InpLotSize      = 0.01;      
input int    InpMAPeriod     = 200;       
input int    InpRSIPeriod    = 14;        
input int    InpStepPoints   = 80;        
input int    InpTPPoints     = 100;       
input int    InpMaxOrders    = 3;         
input int    InpMagic        = 999111;

int handleMA, handleRSI;

int OnInit() {
   handleMA = iMA(_Symbol, PERIOD_M15, InpMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   handleRSI = iRSI(_Symbol, PERIOD_M15, InpRSIPeriod, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   double ma[], rsi[];
   if(CopyBuffer(handleMA,0,0,1,ma)<0 || CopyBuffer(handleRSI,0,0,1,rsi)<0) return;
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double bakiye = AccountInfoDouble(ACCOUNT_BALANCE);
   double karZarar = AccountInfoDouble(ACCOUNT_PROFIT);
   double ozSermaye = AccountInfoDouble(ACCOUNT_EQUITY);
   int aktifIslem = CountPositions();
   int bekleyenEmir = CountOrders();

   bool trendUp = (ask > ma[0]);
   bool trendDown = (bid < ma[0]);
   Cleanup(trendUp, trendDown);

   if((aktifIslem + bekleyenEmir) < InpMaxOrders) {
      if(trendUp && rsi[0] < 45) {
         double p = NormalizeDouble(ask + InpStepPoints*_Point, _Digits);
         if(!IsExist(p)) Place(ORDER_TYPE_BUY_STOP, p, p + InpTPPoints*_Point);
      }
      if(trendDown && rsi[0] > 55) {
         double p = NormalizeDouble(bid - InpStepPoints*_Point, _Digits);
         if(!IsExist(p)) Place(ORDER_TYPE_SELL_STOP, p, p - InpTPPoints*_Point);
      }
   }

   string panel = "======= MUSTOCAN KOMUTA MERKEZİ =======\n";
   panel += "💰 BAKİYE       : " + DoubleToString(bakiye, 2) + " $\n";
   panel += "📊 ÖZSERMAYE  : " + DoubleToString(ozSermaye, 2) + " $\n";
   panel += "📈 ANLIK K/Z   : " + DoubleToString(karZarar, 2) + " $\n";
   panel += "---------------------------------------\n";
   panel += "🏃 AKTİF İŞLEM : " + (string)aktifIslem + "\n";
   panel += "⏳ BEKLEYEN    : " + (string)bekleyenEmir + "\n";
   panel += "🎯 TREND       : " + (trendUp ? "YUKARI" : "AŞAĞI") + "\n";
   panel += "🚀 RSI GÜCÜ    : " + DoubleToString(rsi[0], 2) + "\n";
   panel += "=======================================";
   
   Comment(panel);
}

int CountPositions() {
   int c=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(PositionGetSymbol(i)==_Symbol && PositionGetInteger(POSITION_MAGIC)==InpMagic) c++;
   return c;
}

int CountOrders() {
   int c=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
      if(OrderGetInteger(ORDER_MAGIC)==InpMagic) c++;
   return c;
}

void Cleanup(bool up, bool down) {
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) && OrderGetInteger(ORDER_MAGIC)==InpMagic) {
         long type = OrderGetInteger(ORDER_TYPE);
         if(up && type == ORDER_TYPE_SELL_STOP) OrderDelete(ticket);
         if(down && type == ORDER_TYPE_BUY_STOP) OrderDelete(ticket);
      }
   }
}

bool IsExist(double p) {
   for(int i=OrdersTotal()-1; i>=0; i--)
      if(OrderGetInteger(ORDER_MAGIC)==InpMagic && MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-p)<15*_Point) return true;
   return false;
}

void Place(ENUM_ORDER_TYPE t, double p, double tp) {
   MqlTradeRequest req={}; MqlTradeResult res={};
   req.action=TRADE_ACTION_PENDING; req.symbol=_Symbol; req.volume=InpLotSize;
   req.price=p; req.tp=tp; req.type=t; req.magic=InpMagic; req.type_filling=ORDER_FILLING_IOC;
   OrderSend(req,res);
}
