//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#include <WinUser32.mqh >
#import "winmm.dll"
int PlaySoundA(string, int, int);
int PlaySoundW(int, int, int);
#import

#include "ClassLabel.mqh"

extern double           InpDayRisk=2.0;
extern double           InpDayTarget=2.5;
input double            InpDiminishingCoeff=0.5;
input int               InpX=4;                // X-axis distance
input int               InpY=4;                // Y-axis distance
input string            InpFont="Arial";         // Font
input int               InpFontSize=15;          // Font size
input color             InpColor=clrBlack;         // Color
input ENUM_ANCHOR_POINT InpAnchor=ANCHOR_RIGHT_LOWER; // Anchor type
input ENUM_BASE_CORNER  InpCorner=CORNER_RIGHT_LOWER;
input bool              InpBack=false;           // Background object
input bool              InpSelection=false;       // Highlight to move
input bool              InpHidden=false;          // Hidden in the object list
input long              InpZOrder=0;             // Priority for mouse click

int clock = 0;
bool initialized, notificationSound;
int unprotectedTrades, noTPTrades;
double avgOpen, mouseoverPrice;
double totalCurrentRisk, symbolCurrentRisk;
double totalCurrentTP, symbolCurrentTP;

Button *btnNotification;
Label *lblDayEquity, *lblWeekEquity, *lblDayLimits, *lblRiskUsed, *lblRiskDisponible;
double dayEquity, dayChange, dayBestBalance, dayWorstBalance;
double weekEquity, weekChange, weekBestBalance, weekWorstBalance;
double oldBalance;
datetime dayEquityDate, weekEquityDate, candleCurrent;
MqlDateTime dayEquityStruc, weekEquityStruc;

double alarm1, alarm2;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- Initialize equity values only once
   if(initialized == 0)
     {
      //--- Open or create Equity history note file
      if(FileIsExist("Equities.csv"))
         OpenData();
      else
         CreateFile();

      //--- Update file if needed
      EquityCompare();
      //--- Upload or download day limits from global vars
      InitiateLimits();
      //--- var used for balance change comparison
      oldBalance = AccountBalance();

      //--- Construct the labels
      CreateGraphics();

      initialized = 1;
     }

//--- On Init after loading data adjust limits and
//    update label texts
   UpdateLabels();
   UpdateMarkline("Alarm 1", alarm1);
   UpdateMarkline("Alarm 2", alarm2);

//--- Set timer that runs updates
   EventSetMillisecondTimer(300);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Gets information on all open orders
   OrdersInfo();
//--- Updates best/worst balance for a day/week
   UpdateBalance();
//--- Write current equity change into label
   UpdateLabels();
//-- Check if alarms were crossed
   NotificationCheck();

//-- On any new candle
   if(candleCurrent!=iTime(Symbol(),Period(),0))
     {
      UpdateMarkline("Alarm 1", alarm1);
      UpdateMarkline("Alarm 2", alarm2);
      candleCurrent=iTime(Symbol(),Period(),0);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//--- Checks for new day/week
   if(initialized==1)
      EquityCompare();
//--- Gets information on all open orders
   OrdersInfo();
//--- Updates best/worst balance for a day/week
   UpdateBalance();
//--- Write current equity change into label
   UpdateLabels();

//--- Manage other conditional periodical calls
   clock = clock==20?0:(clock+1);
   if(notificationSound && clock==20)
      PlaySound("notification_sound");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
//--- Keeps track of mouse position
   if(id==CHARTEVENT_MOUSE_MOVE)
     {
      mouseoverPrice = MouseOverPrice(lparam, dparam);

     }
//--- Creates alarm at current mouseover price
   if(id==CHARTEVENT_KEYDOWN && lparam==65)
     {
      SetNotification(mouseoverPrice);
     }

   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam=="btnNotification")
        {
         StopNotification();
        }
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(reason != REASON_CHARTCHANGE)
     {
      delete lblDayEquity;
      delete lblDayLimits;
      delete lblWeekEquity;
      delete lblRiskUsed;
      delete lblRiskDisponible;
      delete btnNotification;

      GlobalVariableSet("DayRisk", InpDayRisk);
      GlobalVariableSet("DayTarget", InpDayTarget);
      EventKillTimer();
     }
   DelAvgOpen();
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
      price = NormalizeDouble(price, Digits());
     }
   return price;
  }

//+---------------------------------------------------------------------+
//| CreateFile creates equity history with current values               |
//+---------------------------------------------------------------------+
void CreateFile()
  {
//--- Wait in case no server update
   while(AccountEquity() <= DBL_EPSILON*2)
     {
      Print("0 equity!");
      Sleep(100);
     }
//--- Cache the current values
   dayEquity = AccountEquity();
   dayBestBalance = AccountBalance();
   dayWorstBalance = AccountBalance();
   dayEquityDate = TimeCurrent();

   weekEquity = AccountEquity();
   weekBestBalance = AccountBalance();
   weekWorstBalance = AccountBalance();
   weekEquityDate = TimeCurrent();

   SaveData();
   TimeToStruct(dayEquityDate, dayEquityStruc);
   TimeToStruct(weekEquityDate, weekEquityStruc);
  }

//+---------------------------------------------------------------------+
//| SavesData saves data of equity                                      |
//+---------------------------------------------------------------------+
void SaveData()
  {
   Print("Saving updated equity history -", Symbol(),"-");
   int handle = FileOpen("Equities.csv", FILE_WRITE|FILE_SHARE_WRITE|FILE_CSV);
   if(handle == INVALID_HANDLE)
     {
      Print("Invalid save file handle");
      return;
     }
   else
     {
      FileWrite(handle, dayEquity);
      FileWrite(handle, dayBestBalance);
      FileWrite(handle, dayWorstBalance);
      FileWrite(handle, dayEquityDate);

      FileWrite(handle, weekEquity);
      FileWrite(handle, weekBestBalance);
      FileWrite(handle, weekWorstBalance);
      FileWrite(handle, weekEquityDate);

      FileClose(handle);
      Print("Sucessfully saved equity history -", Symbol(),"-");
     }
  }

//+---------------------------------------------------------------------+
//| OpenData opens  data of equity                                      |
//+---------------------------------------------------------------------+
void OpenData()
  {
   Print("Opening current equity history -", Symbol(),"-");
   int handle = FileOpen("Equities.csv", FILE_READ|FILE_SHARE_READ|FILE_CSV);
   if(handle == INVALID_HANDLE)
     {
      Print("Operation OpenData failed, error ",GetLastError());
      return;
     }
   else
     {
      dayEquity = FileReadNumber(handle);
      dayBestBalance = FileReadNumber(handle);
      dayWorstBalance = FileReadNumber(handle);
      dayEquityDate = FileReadDatetime(handle);

      weekEquity = FileReadNumber(handle);
      weekBestBalance = FileReadNumber(handle);
      weekWorstBalance = FileReadNumber(handle);
      weekEquityDate = FileReadDatetime(handle);

      FileClose(handle);

      TimeToStruct(dayEquityDate, dayEquityStruc);
      TimeToStruct(weekEquityDate, weekEquityStruc);
      Print("Sucessfully loaded equity history -", Symbol(),"-");
     }
  }

//+---------------------------------------------------------------------+
//| TimeCompare determines whether to update equity history file        |
//+---------------------------------------------------------------------+
void EquityCompare()
  {
   MqlDateTime today;
   TimeToStruct(TimeCurrent(), today);

//--- Check whether day changed
   while(AccountEquity() <= DBL_EPSILON*2)
     {
      Print("Cannot compare - 0 equity!");
      Sleep(100);
     }

   if(today.day_of_year != dayEquityStruc.day_of_year)
     {
      Print("New day - updating equity history file");
      dayEquity = AccountEquity();
      dayBestBalance = AccountBalance();
      dayWorstBalance = AccountBalance();
      dayEquityDate = TimeCurrent();
      TimeToStruct(dayEquityDate, dayEquityStruc);

      int wDaysApart = today.day_of_week - weekEquityStruc.day_of_week;
      int daysApart = today.day_of_year - weekEquityStruc.day_of_year;
      daysApart += 365 * (today.year - weekEquityStruc.year);
      //--- Already exactly week or more passed
      if((wDaysApart >= 0) && (daysApart >= 7))
        {
         Print("New week (1)- updating equity history file");
         weekEquity = AccountEquity();
         weekEquityDate = TimeCurrent();
         TimeToStruct(weekEquityDate, weekEquityStruc);
        }
      //--- New week started
      else
         if(wDaysApart < 0)
           {
            Print("New week (2)- updating equity history file");
            weekEquity = AccountEquity();
            weekBestBalance = AccountBalance();
            weekWorstBalance = AccountBalance();
            weekEquityDate = TimeCurrent();
            TimeToStruct(weekEquityDate, weekEquityStruc);
           }

      SaveData();
     }
  }


//+---------------------------------------------------------------------+
//| UpdateBalance updates day/week best worst balance                   |
//+---------------------------------------------------------------------+
void UpdateBalance()
  {
   if(MathAbs(AccountBalance()-oldBalance) <= DBL_EPSILON)
      return;

   double change = AccountBalance()-oldBalance;
//--- On Loss
   if(change < 0)
     {
      UpdateTargetLim(change);
      //--- If worst daily balance, save
      if(AccountBalance() < dayWorstBalance)
        {
         dayWorstBalance = AccountBalance();
         if(dayWorstBalance < weekWorstBalance)
            weekWorstBalance = dayWorstBalance;
         SaveData();
        }
     }

//--- On Win
   else
     {
      UpdateRiskLim(change);
      //--- If best daily balance, save
      if(AccountBalance() > dayBestBalance)
        {
         dayBestBalance = AccountBalance();
         if(dayBestBalance > weekBestBalance)
            weekBestBalance = dayBestBalance;
         SaveData();
        }      
     }
  }

//+---------------------------------------------------------------------+
//| UpdateLimits updates daily loss/target by diminishing factor        |
//+---------------------------------------------------------------------+
void UpdateRiskLim(double change)
  {
   InpDayRisk -= change / dayEquity * InpDiminishingCoeff * 100;
   oldBalance = AccountBalance();
   Print("New daily loss limit is ", InpDayRisk,"%");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateTargetLim(double change)
  {
   InpDayTarget += change / dayEquity * InpDiminishingCoeff * 100;
   oldBalance = AccountBalance();
   Print("New daily target limit is ", InpDayTarget,"%");
  }

//--- Uploads limits as global variables for retrieval
void InitiateLimits()
  {
   MqlDateTime today;
   TimeToStruct(TimeCurrent(), today);
//--- If not in globals, or need reset, or test
   if(today.day_of_year != dayEquityStruc.day_of_year
      || !GlobalVariableCheck("DayRisk")
      || !GlobalVariableCheck("DayTarget")
      || AccountInfoInteger(ACCOUNT_LOGIN)==2100655614)
     {
      Print("Setting globals after reset to ", InpDayRisk," ", InpDayTarget);
      GlobalVariableSet("DayRisk", InpDayRisk);
      GlobalVariableSet("DayTarget", InpDayTarget);
     }
//--- If already uploaded today
   else
     {
      Print("Loading day limits from terminal");
      InpDayRisk = GlobalVariableGet("DayRisk");
      InpDayTarget = GlobalVariableGet("DayTarget");
     }
  }
//+---------------------------------------------------------------------+
//| CreateGraphics sets and draws all graphical elements                |
//+---------------------------------------------------------------------+
void CreateGraphics()
  {
//-- Labels
   lblWeekEquity = new Label("lblWeekEq", 0);
   lblWeekEquity.Draw();
   lblDayLimits = new Label("lblDayLim", 1);
   lblDayLimits.Size(10);
   lblDayLimits.Draw();
   lblDayEquity = new Label("lblDayEq", 2);
   lblDayEquity.Draw();
   lblRiskUsed = new Label("lblRiskUse", 3);
   lblRiskUsed.Size(10);
   lblRiskUsed.Draw();
   lblRiskDisponible = new Label("lblRiskDisponible", 0);
   lblRiskDisponible.Draw();
   lblRiskDisponible.SetPoint(ANCHOR_LEFT_UPPER, CORNER_LEFT_UPPER);
   lblRiskDisponible.SetXY(262, 66);

//--- Buttons
   btnNotification = new Button("btnNotification");

  }
//+---------------------------------------------------------------------+
//| WriteEquity updates label's showing the equity information          |
//+---------------------------------------------------------------------+
void UpdateLabels()
  {
      //--- Day's equity
      dayChange = (AccountEquity() - dayEquity) / dayEquity * 100;
      color dayProperColor = dayChange>0? clrGreen:clrRed;
      lblDayEquity.Update(DoubleToStr(dayChange, 2)+"%",
                           dayProperColor);
      
      //--- Week's equity
      weekChange = (AccountEquity() - weekEquity) / weekEquity * 100;
      color weekProperColor = weekChange>0? clrGreen:clrRed;
      lblWeekEquity.Update(DoubleToStr(weekChange, 2)+"%", weekProperColor);
      
      //--- Current Day limits
      double dayLimLow = (dayBestBalance - dayEquity)
                         / dayEquity * 100 - InpDayRisk;
      double dayLimHigh = (dayWorstBalance - dayEquity)
                          / dayEquity * 100 + InpDayTarget;
      lblDayLimits.Update(DoubleToStr(dayLimLow, 2)+"% "+
                          DoubleToStr(dayLimHigh, 2)+"%", clrBeige);
      
      //--- Current used risk
      double riskLeft = (AccountBalance() - dayEquity)
                        / dayEquity * 100 - dayLimLow;
      riskLeft = riskLeft<0?0:riskLeft;
      lblRiskUsed.Update(DoubleToStr(symbolCurrentRisk, 2)+"/"+
                         DoubleToStr(riskLeft, 2)+"%", clrBeige);
      
      //--- Global disponible risk
      double riskDisponible = riskLeft - totalCurrentRisk;
      string mainText = DoubleToStr(riskDisponible, 2)+"% ";
      if(riskDisponible<-0.1)
         RiskWarning();
      else
      {
         riskDisponible = riskDisponible<0? 0 : riskDisponible;     
         string noSL = "";
         if(unprotectedTrades!=0)
         {
            noSL = "*! "+ IntegerToString(unprotectedTrades)+" SL missing !*";
         }     
         lblRiskDisponible.Update(DoubleToStr(riskDisponible, 2)+"% "+noSL, clrRed);                   
      }
   }

void RiskWarning()   
   {
   ObjectSetText("lblRiskDisponible", CharToStr(78), 10, "Wingdings", clrRed); 
   ObjectSetInteger(NULL, "lblRiskDisponible", OBJPROP_FONTSIZE, 100);
   }
   

//+---------------------------------------------------------------------+
//| OrdersInfo Collect all order information for given symbol           |
//+---------------------------------------------------------------------+
void OrdersInfo()
  {
   unprotectedTrades = 0;
   noTPTrades = 0;
   totalCurrentRisk = 0;
   symbolCurrentRisk = 0;
   totalCurrentTP = 0;
   symbolCurrentTP = 0;
   avgOpen = 0;

   double symbolLots = 0;
   int symbolOrders = 0;

   if(OrdersTotal() > 0)
     {
      //--- Cycle all orders
      for(int i=0; i<OrdersTotal(); i++)
        {
         //--- Select each order and errorcheck
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) != true)
            Print("Error in OrderSelect: ", GetLastError());
         else
           {
            //--- Only work with executed orders
            if(OrderType() == OP_BUY || OrderType() == OP_SELL)
              {
               //--- Cache order vars for calculation
               double sl = OrderStopLoss();
               double tp = OrderTakeProfit();
               double open = OrderOpenPrice();
               double lots = OrderLots();
               double fee = OrderCommission();
               double contract = SymbolInfoDouble(OrderSymbol(),
                                                  SYMBOL_TRADE_CONTRACT_SIZE);
               //--- add up a open prices and lots to calculate avg open
               if(Symbol()==OrderSymbol())
                  avgOpen += lots*open;
               symbolLots += lots;
               symbolOrders++;

               //--- Check SL, sum them up or add to counter
               if(sl > DBL_EPSILON*2)
                 {
                  double risk;
                  //--- Risk defined as positive, negative is profit
                  if(OrderType() == OP_BUY)
                     risk = (open-sl)*lots*contract;
                  else
                     risk = (sl-open)*lots*contract;
                  risk /= ToDepositCurrency(OrderSymbol());
                  risk += fee;
                  totalCurrentRisk += risk;
                  if(Symbol()==OrderSymbol())
                     symbolCurrentRisk += risk;

                 }
               else
                  unprotectedTrades++;

               //--- Check TP, sum them up or add to counter
               if(tp > DBL_EPSILON*2)
                 {
                  double tprofit = MathAbs(open-tp)*lots*contract;
                  tprofit /= ToDepositCurrency(OrderSymbol());
                  tprofit -= fee;

                  totalCurrentTP += tprofit;
                  if(Symbol()==OrderSymbol())
                     symbolCurrentTP += tprofit;
                 }
               else
                  noTPTrades++;
              }
           }
        }
      //--- Normalize all variables to daily percentage
      totalCurrentRisk = totalCurrentRisk / dayEquity * 100;
      symbolCurrentRisk = symbolCurrentRisk / dayEquity * 100;
      totalCurrentTP = totalCurrentTP / dayEquity * 100;
      symbolCurrentTP = symbolCurrentTP / dayEquity * 100;
      if(symbolOrders != 0)
         avgOpen = avgOpen / symbolLots;

      //--- Draw avg open price if more than one order
      if(symbolOrders>1)
         DrawAvgOpen();
      else
         DelAvgOpen();
      return;
     }
   DelAvgOpen();
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ToDepositCurrency(string symbol)
  {
   string profitCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   string profitToDeposit = "EUR" + profitCurrency;
   double profitToDeposit_ratio = SymbolInfoDouble(profitToDeposit, SYMBOL_ASK);
   return profitToDeposit_ratio;
  }

//+---------------------------------------------------------------------+
//| DrawAvgOpen draws and updates the average open price line           |
//+---------------------------------------------------------------------+
void DrawAvgOpen()
  {
   DrawMarkline("Avg Open", avgOpen, clrOrangeRed);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DelAvgOpen()
  {
   if(ObjectFind("Avg Open")>=0)
      ObjectDelete(NULL, "Avg Open");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawMarkline(string name, double price, color clr)
  {
   datetime time1 = TimeCurrent()-PeriodSeconds();
   datetime time2 = TimeCurrent()+PeriodSeconds();
//--- Create if does not exist
   if(ObjectFind(name)<0)
     {
      if(!ObjectCreate(NULL, name,
                       OBJ_TREND,0,
                       time1,price,
                       time2,price))
         Print(__FUNCTION__,": failed to create a trend line!",
               "Error code = ", GetLastError());

      ObjectSetInteger(NULL,name,OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(NULL,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(NULL,name,OBJPROP_BACK, false);
      ObjectSetInteger(NULL,name,OBJPROP_RAY, false);
     }

//--- Update price and times
   UpdateMarkline(name, price);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateMarkline(string name, double price)
  {
   if(ObjectFind(name)>=0)
     {
      datetime time1 = TimeCurrent()-PeriodSeconds();
      datetime time2 = TimeCurrent()+PeriodSeconds();
      ObjectSetInteger(NULL,name,OBJPROP_TIME1, time1);
      ObjectSetInteger(NULL,name,OBJPROP_TIME2, time2);
      ObjectSetDouble(NULL,name,OBJPROP_PRICE1, price);
      ObjectSetDouble(NULL,name,OBJPROP_PRICE2, price);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteMarkline(string name)
  {
   ObjectDelete(name);
  }


//+---------------------------------------------------------------------+
//| Notification           |
//+---------------------------------------------------------------------+
void SetNotification(double price)
  {
//-- Delete both alarms if there are two already
   if(ObjectFind("Alarm 2")>=0)
     {
      ObjectDelete("Alarm 1");
      alarm1 = -1;
      ObjectDelete("Alarm 2");
      alarm2 = -1;
      NotificationCheck(true);//reset
      StopNotification();
      return;
     }

//-- Draw the currently needed alarm
   string name = ObjectFind("Alarm 1")>=0?"Alarm 2":"Alarm 1";
   DrawMarkline(name, price, clrBeige);

//-- create variable holding the price
   if(name == "Alarm 1")
      alarm1 = price;
   else
      alarm2 = price;

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void NotificationCheck(bool reset=false)
  {
//-- Static vars hold previous relative position
//   0 - null, -1 below limit, 1 above limit
   static int previousPos1, previousPos2;
   if(reset)
     {
      previousPos1 = 0;
      previousPos2 = 0;
     }

   if(alarm1>0)
      CheckCrossing(alarm1, previousPos1);
   if(alarm2>0)
      CheckCrossing(alarm2, previousPos2);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckCrossing(double level, int &previous)
  {
   int relativePos = level>Bid? 1 : -1;
//-- If first time position is checked, cache it
   if(previous==0)
     {
      previous = relativePos;
      return;
     }
//-- Ceck if crossed in last tick, if so Notify
   bool crossed = previous!=relativePos;
   if(!crossed)
      return;
   Notify();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Notify()
  {
//-- TODO: draw chart to the front

//-- Draw button, already created as object
   if(ObjectFind("btnNotification")<0)
     {
      PlaySound("notification_sound");
      btnNotification.Draw();
      btnNotification.SetSize(95, 18);
      btnNotification.SetXY(101, 76);
      btnNotification.SetText("Alarm!");
      notificationSound = 1;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StopNotification()
  {
   notificationSound = 0;
   btnNotification.Hide();
   DeleteMarkline("Alarm 1");
   alarm1 = -1;
   DeleteMarkline("Alarm 2");
   alarm2 = -1;
   NotificationCheck(true); //reset=true;
  }   
