#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

//--- Arrays holding Symbols based on their category
string forex [28] = {"USDCHF", "GBPUSD", "EURUSD", "USDJPY", "USDCAD",
                     "AUDUSD", "EURGBP", "EURAUD", "EURCHF", "EURJPY",
                     "GBPCHF", "CADJPY", "GBPJPY", "AUDNZD", "AUDCAD",
                     "AUDCHF", "AUDJPY", "CHFJPY", "EURNZD", "EURCAD",
                     "CADCHF", "NZDJPY", "NZDUSD", "NZDCHF", "NZDCAD",
                     "GBPNZD", "GBPCAD", "GBPAUD"};
string exotics [18] = {"USDHKD", "USDZAR", "EURRUB", "USDNOK", "USDTRY",
                     "EURTRY", "USDSEK", "EURSEK", "USDPLN", "EURPLN",
                     "EURNOK", "USDMXN", "USDHUF", "EURHUF", "EURCZK",
                     "USDCZK", "USDILS", "USDRUB"};   
string indices [14] = {"GER30.cash", "US500.cash", "AUS200.cash", "CH.cash",
                     "US30.cash", "SPN35.cash", "EU50.cash", "FRA40.cash",
                     "HK50.cash", "JP225.cash", "US100.cash", "UKOIL.cash",
                     "UK100.cash", "USOIL.cash"};
string metals [8] = {"XAGEUR", "XPTUSD", "XAGAUD", "XAGUSD", "XAUAUD",
                    "XAUEUR", "XAUUSD", "XPDUSD"};   
string futures [4] = {"DX.f", "USTN10.f", "ERBN.f", "NATGAS.f"}; 
string crypto [4] = {"DASHUSD", "ETHUSD", "LTCUSD", "BTCUSD",
                     "XRPUSD", "XMRUSD", "NEOUSD"}; 
string equities [23] = {"ALVG", "IBE", "VOWG_p", "AAPL", "AMZN",
                      "FB", "GOOG", "NFLX", "NVDA", "PFE",
                      "TSLA", "WMT", "ZM", "DBKGn", "LVMH",
                      "AIRF", "BAYGn", "MSFT", "V", "RACE",
                      "T", "BABA", "BAC"};                                    

int measuring = -1; 
int initialized = 0;

double sprd;
double startEquity = 10000;
double fee = 0;
double mouseOverPrice;
double price1 = -1;
double price2 = -1;
double tickValue = 0;
double tickSize = 0;
double rangeValue = 0;
double tradeSize, tradeSize05, tradeSize025;
double idealTradeSize = 0;

void OnInit() 
  {    
      //--- enable CHART_EVENT_MOUSE_MOVE messages 
      ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1);
      tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
  } 

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
   {
   sprd = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   sprd = sprd * MathPow(10, -_Digits);
   
   return(rates_total);
   }
   
   
//+------------------------------------------------------------------+ 
//| ChartEvent function                                              | 
//+------------------------------------------------------------------+ 
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam) 
  { 
   if(id==CHARTEVENT_MOUSE_MOVE) 
   {
      mouseOverPrice = MouseOverPrice(lparam, dparam);
      tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
      
      //--- If mouse button was clicked, update measured range
      if (sparam == 1 && measuring == 1)
      {  
         if (price1 != -1 && price2 != -1)
            {
               price1 = -1;
               price2 = -1;
            }
         else if(price1 != -1)
            {
               price2 = mouseOverPrice;
               rangeValue = RangeValue(price1, price2); 
               if (rangeValue > 0) 
               { 
                  TradeSize(rangeValue, tradeSize, idealTradeSize);
                  tradeSize05 = ArbitraryTradeSize(rangeValue, 0.005);
                  tradeSize025 = ArbitraryTradeSize(rangeValue, 0.0025);        
               }
            }
         else
            price1 = mouseOverPrice;       
      }
      
      //----"POINT: ",(int)lparam,",",(int)dparam,"\n",MouseState((uint)sparam),
      Comment("\nMeasuring: ", measuring,
              "\nCurrent: ", DoubleToStr(mouseOverPrice, Digits()),
              "\nPrice1: ", DoubleToStr(price1, Digits()),
              "\nPrice2: ", DoubleToStr(price2, Digits()),
              "\nRangeValue: ", rangeValue, " Eur",
              "\n1.0%  Risk   ", DoubleToStr(tradeSize, Digits()), " Lot",
              "\n0.5%  Risk   ", DoubleToStr(tradeSize05, Digits()), " Lot",
              "\n.25%  Risk   ", DoubleToStr(tradeSize025, Digits()), " Lot");
//            "\n",DoubleToStr(RecommendedRisk(),2),"% ", idealTradeSize, " Lot");   
   }
   
   if(id==CHARTEVENT_KEYDOWN && lparam==77)
      {
         measuring = -measuring;
      }
  }

  
//+------------------------------------------------------------------+ 
//| MouseState function, returns string of pressed keys              | 
//+------------------------------------------------------------------+ 
string MouseState(uint state) 
  { 
   string res; 
   res+="\nML: "   +(((state& 1)== 1)?"DN":"UP");   // mouse left 
   res+="\nMR: "   +(((state& 2)== 2)?"DN":"UP");   // mouse right  
   res+="\nMM: "   +(((state&16)==16)?"DN":"UP");   // mouse middle 
   res+="\nMX: "   +(((state&32)==32)?"DN":"UP");   // mouse first X key 
   res+="\nMY: "   +(((state&64)==64)?"DN":"UP");   // mouse second X key 
   res+="\nSHIFT: "+(((state& 4)== 4)?"DN":"UP");   // shift key 
   res+="\nCTRL: " +(((state& 8)== 8)?"DN":"UP");   // control key 
   return(res); 
  } 

//+------------------------------------------------------------------+ 
//| ClickedPrice function, returns double of price at click position | 
//+------------------------------------------------------------------+ 
double MouseOverPrice(double lparam, double dparam)
   {
   //--- Prepare variables 
   int      x     =(int)lparam; 
   int      y     =(int)dparam; 
   datetime dt    =0; 
   double   price =-1; 
   int      window=0; 
   int      digits=Digits();
   //--- Convert the X and Y coordinates in terms of date/time 
   if(ChartXYToTimePrice(0,x,y,window,dt,price)) 
     { 
      price = NormalizeDouble(price, digits);
     } 
   return price;   
   }

//+---------------------------------------------------------------------+ 
//| RangeValue return double EUR value per lot per given range          | 
//+---------------------------------------------------------------------+ 
double RangeValue(double price1, double price2)
   {
      double priceDiff = MathAbs(price1 - price2);   
      priceDiff = NormalizeDouble(priceDiff, _Digits);
                    
      double rangeValue = priceDiff / tickSize * tickValue;
      rangeValue = NormalizeDouble(rangeValue, 2); 
      
      return rangeValue;      
   }

//+---------------------------------------------------------------------+ 
//| RecommendedRisk func return % of recommended risk for current state | 
//+---------------------------------------------------------------------+ 
double RecommendedRisk()
   {
      double percentLeft = 100 * (AccountEquity() / startEquity - 0.9); 
      int tradesLeft = 3.85102571 + (log(percentLeft) / log(1.45421543));
      double risk = percentLeft / tradesLeft;
      risk = NormalizeDouble(risk, 2);
      
      return risk;
   }


//+---------------------------------------------------------------------+ 
//| TradeSizeFromRV func return 1% and Ideal risk trade Size            | 
//+---------------------------------------------------------------------+    
void TradeSize(double rngValue, double &tradeSize, double &idealTradeSize)
   {
      if (rngValue > 0)
      {  
         // Cost = 1% of equity
         double cost = NormalizeDouble(AccountEquity() * 0.01, 2);        
         tradeSize = FeeAdjustedVolume(cost, rngValue);
         
         // cost adjuste by recommended risk
         cost = cost * RecommendedRisk();
         cost = NormalizeDouble(cost, 2); 
         idealTradeSize = FeeAdjustedVolume(cost, rngValue);               
      }
      else
      {
         tradeSize = -1;
         idealTradeSize = -1;
      }
   }
   
double ArbitraryTradeSize(double rngValue, double percentage)
   {
      if (rngValue > 0)
      {  
         double cost = NormalizeDouble(AccountEquity() * percentage, 2);        
         double tSize = FeeAdjustedVolume(cost, rngValue);  
         return tSize;       
      }
      else
      {
         double tSize = -1;
         return tSize;
      }
   }

//+---------------------------------------------------------------------+ 
//| FeeAdjustedVolume returns volume that will cost exactly the cost    | 
//+---------------------------------------------------------------------+   
double FeeAdjustedVolume(double cost, double rangeValue)
   {
      double fee = GetFee();
      double volume = cost / (fee + rangeValue);
      volume = NormalizeDouble(volume, 2);
      return volume;
   }

//+---------------------------------------------------------------------+ 
//| GetFee return EUR fee price per lot                                 | 
//+---------------------------------------------------------------------+  
double GetFee()
   {
      string symbol = SymbolCategory(Symbol());
      int contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      string profitCurrency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
      string profitToDeposit = "EUR" + profitCurrency;
      double profitToDeposit_ratio = SymbolInfoDouble(profitToDeposit, SYMBOL_ASK);
      double contractPrice = contractSize * price1;
      double contractPriceDeposit = contractPrice / profitToDeposit_ratio;     
      
      if (symbol == "forex" || symbol == "exotics")
         return 2.5;
      if (symbol == "metals")
         return NormalizeDouble((0.00001 * contractPriceDeposit), 2);    
      if (symbol != "none")
         return NormalizeDouble((0.00004 * contractPriceDeposit), 2);
         
      return -1;                    
   }

//+---------------------------------------------------------------------+ 
//| SymbolCategory return string name of market category of given symbol| 
//+---------------------------------------------------------------------+   
string SymbolCategory(string symbol)
   {
      int n_symbols = ArraySize(forex);
      for (int j=0; j < n_symbols; j++)
      {
         if (symbol != forex[j])
            continue;
         return "forex";
      }
      n_symbols = ArraySize(exotics);
      for (int j=0; j < n_symbols; j++)
      {
         if (symbol != exotics[j])
            continue;
         return "exotics";
      }         
      n_symbols = ArraySize(indices);
      for (int j=0; j < n_symbols; j++)
      {
         if (symbol != indices[j])
            continue;
         return "indices";
      }       
      n_symbols = ArraySize(futures);
      for (int j=0; j < n_symbols; j++)
      {
         if (symbol != futures[j])
            continue;
         return "futures";
      }   
      n_symbols = ArraySize(metals);
      for (int j=0; j < n_symbols; j++)
      {
         if (symbol != metals[j])
            continue;
         return "metals";
      }   
      n_symbols = ArraySize(crypto);
      for (int j=0; j < n_symbols; j++)
      {
         if (symbol != crypto[j])
            continue;
         return "crypto";
      }     
      n_symbols = ArraySize(equities);
      for (int j=0; j < n_symbols; j++)
      {
         if (symbol != equities[j])
            continue;
         return "equities";
      }                           
      return "none";   
   }
  
//+---------------------------------------------------------------------+ 
//| PipeteRounder rorunds price to half pip                             | 
//+---------------------------------------------------------------------+    
double PipetteRounder(double price)
   {
      int price_int = (price * MathPow(10, _Digits));
      int reminder = price_int % 5;
      if (reminder <= 2)
         return (price_int - reminder);
      else
         return (price_int + (5-reminder));
   }
