//+------------------------------------------------------------------+
//|                                                         sper.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "NOT FOR DISTRIBUTION"
//#property link      "https://www.mql5.com"
#property version   "EVALUATION VERSION"
#property strict
#include <Func_error.mqh>

//------------------------------expert parameters
input double inpLot = 0.1;
//---- indicator parameters
input int InpDepth=12;     // Depth
input int InpDeviation=5;  // Deviation
input int InpBackstep=3;   // Backstep
//---- Trend parameters
input int InpDeep=300;
int Deep=InpDeep;

input int inpStoplossSell=100;
input int inpTakeProfitSell=100;
input int inpStoplossBuy=100;
input int inpTakeProfitBuy=100;
input int inpFifty=50;
input int inpPeriods=30;
input bool inpDblLot=false;

datetime Open_time=D'0000.00.00 00:00:00', Open_minutebar_time=D'0000.00.00 00:00:00';
string symbol = _Symbol;
double GDtrend[100], GUtrend[100], Dtrend[100], Utrend[100];
string Uname[100], Dname[100];
int u,t;


int Orders[50][4];
//double dblOrders[50];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if (InpDeep>1000 || InpDeep>Bars-1)
   {  
      Comment("ERROR: InpDeep>1000");
      return(INIT_FAILED);
   }
   
   ArrayInitialize(GDtrend,0.0);
   ArrayInitialize(GUtrend,0.0); 
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{   
   if (New_bar_detected())
   {     
      u=1; t=1;
      double max[1000], min[1000];
      datetime tmax[1000], tmin[1000];
      ArrayInitialize(max,0.0);
      ArrayInitialize(min, 0.0);
      ArrayInitialize(tmax,0);
      ArrayInitialize(tmin,0);     
      int m=0, n=0;
      bool k=false;
//----------------------------------------------collect dots of low and high--------------      
      for (int i=1; i<Deep; i++)
      {
         double buff0 = iCustom(NULL,0,"ZigZag",InpDepth,InpDeviation,InpBackstep,0,i);
         double buff1 = iCustom(NULL,0,"ZigZag",InpDepth,InpDeviation,InpBackstep,1,i);
         if (buff0!=0)
         {
            if (k==true)
            {
               if (buff1!=0)
               {
                  max[m]=buff1;
                  tmax[m]=Time[i];
                  m++;   
               }
               else
               {
                  min[n]=buff0;
                  tmin[n]=Time[i];
                  n++;
               }
            }
            else k=true;
         }         
      }
      
//-------------------------------------------------------deleting old objects-----------      
      for (int i=1; i<100; i++)
         ObjectDelete(Dname[i]); 
      for (int i=1; i<100; i++)
         ObjectDelete(Uname[i]);      
//-------------------------------------------------------------drawing downtrends---------------     
      
      //double Dtrend[100];
      datetime TDtrend[100];
      ArrayInitialize(Dtrend,0.0);
      ArrayInitialize(TDtrend,0);
      Dtrend[0]=max[0];
      TDtrend[0]=tmax[0];
      
      for (int i=1; i<m; i++)
      {
         bool flag=false; 
//--------------------------------------------
         for (int j=i; j>=0; j--)
            if (max[i]<max[j]) flag=true;
//----------------------------------------------------         
         if (flag==false)         
         {
            Dtrend[u]=max[i];
            TDtrend[u]=tmax[i];
            u++;
         }   
      }
      
     //while (ObjectsTotal())
       // ObjectDelete(ObjectName(ObjectsTotal()-1)); 
       
      
      for (int i=1; i<u; i++)
      {
         Dname[i] = string(Dtrend[i])+"  "+string(Dtrend[0]) + " i=" + string(i);
         ObjectCreate(Dname[i],OBJ_TREND,0,TDtrend[i],Dtrend[i],TDtrend[0],Dtrend[0]);
         ObjectSet(Dname[i],6,clrYellow);
         ObjectSet(Dname[i],OBJPROP_RAY_RIGHT,1);
         for (int j=1; TDtrend[i]!=tmax[j]; j++)
            if (max[j] > ObjectGetValueByTime(0,Dname[i],tmax[j]))
               ObjectDelete(Dname[i]);   
         
      } 
//--------------------------------------------drawing uptrends------------------------------      
      //double Utrend[100];
      datetime TUtrend[100];
      ArrayInitialize(Utrend,0.0);
      ArrayInitialize(TUtrend,0);      
      Utrend[0]=min[0];
      TUtrend[0]=tmin[0]; 

      for  (int i=1; i<n; i++)
      {  
         bool flag=false; 
//--------------------------------------------
         for (int j=i; j>=0; j--)
            if (min[i]>min[j]) flag=true;
//----------------------------------------------------         
         if (flag==false)
         {
            Utrend[t]=min[i];
            TUtrend[t]=tmin[i];
            t++;
         }
      } 
         
      for (int i=1; i<t; i++)
      {
         Uname[i] = string(Utrend[i])+"  "+string(Utrend[0]) + "i=" + string(i);
         ObjectCreate(Uname[i],OBJ_TREND,0,TUtrend[i],Utrend[i],TUtrend[0],Utrend[0]);
         ObjectSet(Uname[i],6,clrPaleTurquoise);
         ObjectSet(Uname[i],OBJPROP_RAY_RIGHT,1);
         for (int j=1; TUtrend[i]!=tmin[j]; j++)
            if (min[j] < ObjectGetValueByTime(0,Uname[i],tmin[j]))
               ObjectDelete(Uname[i]);  
      }         
   } //New bar
//------------------------------------------------
   if (New_minute_bar_detection())
   {
     // if (Orders[0,0]!=0)///////////////////////////////////////////////////////////////////////////!!!!!!!!!!!!!!!!!!!!!!!!!
     // {
         for (int i=0; i<Orders[0,0];i++)
            if (OrderSelect(Orders[i,1],SELECT_BY_TICKET))
            {
               switch(OrderType())
               {
                  case OP_BUY:
                  {
                     if (OrderCloseTime()>0)
                     {
                        if (Orders[i,2]==2 || OrderOpenPrice()<OrderClosePrice()) {}
                        //else Buy_stop(inpDblLot,iBarShift(NULL,PERIOD_CURRENT,OrderOpenTime()));
                        Orders[i,1]=0;
                     }
                     break;
                  }
                  case OP_SELL:
                  {
                     if (OrderCloseTime()>0)
                     {
                        if (Orders[i,2]==2 || OrderOpenPrice()>OrderClosePrice()) {}
                        //else Sell_stop(inpDblLot,iBarShift(NULL,PERIOD_CURRENT,OrderOpenTime()));
                        Orders[i,1]=0;
                     }
                     break;
                  }
                  case OP_SELLSTOP:
                  case OP_BUYSTOP:
                  {
                     if (OrderCloseTime()>0)
                     {
                        Orders[i,1]=0;
                        //Orders[i,2]=0;                       
                     }
                     else 
                     {
                        if (iBarShift(NULL,PERIOD_CURRENT,OrderOpenTime())>=inpPeriods && OrderDelete(Orders[i,1]))
                        {
                           Orders[i,1]=0;
                           //Orders[i,2]=0;
                        }  
                     }
                  }
               }
            }
      Sort();      
     //}      
   }
   
   double fifty = _Point*inpFifty;
   
 /*  for (int i=1; i<u; i++)
      if (GDtrend[i]!=Dtrend[0] && ObjectFind(Dname[i])!=-1)
         if (Bid - fifty > ObjectGetValueByTime(0, Dname[i], Time[0], 0)) 
            if (Buy()) 
               GDtrend[i]=Dtrend[0];
*/

         
   for (int i=1; i<t; i++)
      if (GUtrend[i]!=Utrend[0] && ObjectFind(Uname[i])!=-1)
         if (Bid + fifty < ObjectGetValueByTime(0, Uname[i], Time[0], 0)) 
            if (Sell()) 
            {
               GUtrend[i]=Utrend[0];
               //ObjectCreate(Uname[i]+" sell",OBJ_ARROW,0,Time[0],Ask);
               //ObjectSet(Uname[i]+" sell",OBJPROP_ARROWCODE,1);
            }   
} //OnTick

//+------------------------------------------------------------------+

bool New_bar_detected()
{
   if (Open_time != Time[0])
      { Open_time = Time[0]; return true; } 
   return false; 
}

bool New_minute_bar_detection()
{
   if (Open_minutebar_time != iTime(_Symbol,PERIOD_M1,0))
      { Open_minutebar_time = iTime(_Symbol,PERIOD_M1,0); return true; } 
   return false; 
} 

void Sort()
{
   int k=0;
   for (int i=0; i<Orders[0,0]; i++)
      if (Orders[i,1]!=0)
      {
         Orders[k,1]=Orders[i,1];
         Orders[k,2]=Orders[i,2];
         k++;
      }
   Orders[0,0]=k;   
}

int Sell()
{
   RefreshRates();
   double stoploss = Bid + inpStoplossSell*_Point;
   double takeprofit = Bid - inpTakeProfitSell*_Point;   
   double stoplevel = MarketInfo(symbol,MODE_STOPLEVEL)*_Point;
   if (Ask-takeprofit < stoplevel) takeprofit = Ask - stoplevel;
   if (stoploss - Ask < stoplevel) stoploss = Ask + stoplevel;      
   int ticket = OrderSend(symbol,OP_SELL,inpLot,Bid,20,stoploss,takeprofit,"SperandeoSell",0,0,clrRed);
   if (ticket!=-1)
   {
      Orders[Orders[0,0],1]=ticket;
      Orders[Orders[0,0],2]=1;
      Orders[0,0]++;
      return ticket;  
   }    
   Func_error("SperandeoSell");
   return (-1);   
}

int Buy() 
{
   RefreshRates();
   double stoploss = Ask - inpStoplossBuy*_Point;
   double takeprofit = Ask + inpTakeProfitBuy*_Point;   
   double stoplevel = MarketInfo(symbol,MODE_STOPLEVEL)*_Point;
   if (Bid-stoploss < stoplevel) stoploss = Bid - stoplevel;
   if (takeprofit-Bid < stoplevel) takeprofit = Bid + stoplevel;      
   int ticket = OrderSend(symbol,OP_BUY,inpLot,Ask,20,stoploss,takeprofit,"SperandeoBuy",0,0,clrBlue);
   if (ticket!=-1)
   {
      Orders[Orders[0,0],1]=ticket;
      Orders[Orders[0,0],2]=1;
      Orders[0,0]++;
      return ticket;  
   }    
   Func_error("SperandeoBuy"); 
   return (-1);
}

void Buy_stop(bool dblLot, int barNum) 
{
   double lot;
   if (dblLot) lot = inpLot*2;
   else lot = inpLot;
   double price = High[barNum]+20*_Point;
   double stoploss = Low[barNum];
   double takeprofit = (High[barNum]-Low[barNum]) + price - 20*_Point;
   int ticket=OrderSend(symbol,OP_BUYSTOP,lot,price,20,stoploss,takeprofit,"SperandeoBuyStop",0,0,clrBlue);
   if (ticket!=-1)
   {
      Orders[Orders[0,0],1]=ticket;
      Orders[Orders[0,0],2]=2;
      Orders[0,0]++;
      return;
   }   
   Func_error("SperandeoBuyStop");   
}

void Sell_stop(bool dblLot, int barNum) 
{
   double lot;
   if (dblLot) lot = inpLot*2;
   else lot = inpLot; 
   double price = Low[barNum]-10*_Point;
   double stoploss = High[barNum]+30*_Point;
   double takeprofit = price - (High[barNum]-Low[barNum]) - 40*_Point; 
   int ticket = OrderSend(symbol,OP_SELLSTOP,lot,price,20,stoploss,takeprofit,"SperandeoSellStop",0,0,clrRed);   
   if (ticket!=-1)
   {
      Orders[Orders[0,0],1]=ticket;
      Orders[Orders[0,0],2]=2;
      Orders[0,0]++;   
      return;
   }   
   Func_error("SperandeoSellStop");
}