//+------------------------------------------------------------------+
//|                                        Custom Moving Average.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1

//#property indicator_type1   DRAW_LINE
//#property indicator_color1  Red

//---- 绘制指标作为多色线
#property indicator_type1   DRAW_COLOR_LINE
//---- 使用以下颜色于 3 色线中
#property indicator_color1  Gray,Blue,Red
//---- 线型为实线
#property indicator_style1  STYLE_SOLID
//---- 指标线宽度 2
#property indicator_width1  1
//---- 显示指标标签
#property indicator_label1  "ma"

//--- input parameters
input int            InpMAPeriod=13;         // 均线周期
input int            InpMAShift=0;           // 平移
input ENUM_MA_METHOD InpMAMethod=MODE_SMMA;  // 方法
input int   ReverseSpeed = 1;    //转向速度
//--- indicator buffers
double               ExtLineBuffer[];
double               ExtLineBufferColor[];
double               minutes ;
//+------------------------------------------------------------------+
//|   simple moving average                                          |
//+------------------------------------------------------------------+
void CalculateSimpleMA(int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int i,limit;
//--- first calculation or number of bars was changed
   if(prev_calculated==0)// first calculation
     {
      limit=InpMAPeriod+begin;
      //--- set empty value for first limit bars
      for(i=0;i<limit-1;i++) ExtLineBuffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
         firstValue+=price[i];
      firstValue/=InpMAPeriod;
      ExtLineBuffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   double speed;
   for(i=limit;i<rates_total && !IsStopped();i++){
      ExtLineBuffer[i]=ExtLineBuffer[i-1]+(price[i]-price[i-InpMAPeriod])/InpMAPeriod;
      ExtLineBufferColor[i]=0; 
      if(ExtLineBuffer[i] > ExtLineBuffer[i-1]){
         speed = (MathAbs(ExtLineBuffer[i]-ExtLineBuffer[i-1])/ExtLineBuffer[i])*200000000/minutes;
         if(speed > ReverseSpeed){
            ExtLineBufferColor[i]=1;
         }
      }else if(ExtLineBuffer[i] < ExtLineBuffer[i-1]){
         speed = (MathAbs(ExtLineBuffer[i]-ExtLineBuffer[i-1])/ExtLineBuffer[i-1])*200000000/minutes;
         if(speed > ReverseSpeed){
            ExtLineBufferColor[i]=2;
         }
      }  
   }
//---
  }
//+------------------------------------------------------------------+
//|  exponential moving average                                      |
//+------------------------------------------------------------------+
void CalculateEMA(int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int    i,limit;
   double SmoothFactor=2.0/(1.0+InpMAPeriod);
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
     {
      limit=InpMAPeriod+begin;
      ExtLineBuffer[begin]=price[begin];
      for(i=begin+1;i<limit;i++)
         ExtLineBuffer[i]=price[i]*SmoothFactor+ExtLineBuffer[i-1]*(1.0-SmoothFactor);
     }
   else limit=prev_calculated-1;
//--- main loop
   double speed;
   for(i=limit;i<rates_total && !IsStopped();i++){
      ExtLineBuffer[i]=price[i]*SmoothFactor+ExtLineBuffer[i-1]*(1.0-SmoothFactor);
      ExtLineBufferColor[i]=0; 
      if(ExtLineBuffer[i] > ExtLineBuffer[i-1]){
         speed = (MathAbs(ExtLineBuffer[i]-ExtLineBuffer[i-1])/ExtLineBuffer[i])*200000000/minutes;
         if(speed > ReverseSpeed){
            ExtLineBufferColor[i]=1;
         }
      }else if(ExtLineBuffer[i] < ExtLineBuffer[i-1]){
         speed = (MathAbs(ExtLineBuffer[i]-ExtLineBuffer[i-1])/ExtLineBuffer[i-1])*200000000/minutes;
         if(speed > ReverseSpeed){
            ExtLineBufferColor[i]=2;
         }
      }  
   }
//---
  }
//+------------------------------------------------------------------+
//|  linear weighted moving average                                  |
//+------------------------------------------------------------------+
void CalculateLWMA(int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int        i,limit;
   static int weightsum;
   double     sum;
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
     {
      weightsum=0;
      limit=InpMAPeriod+begin;
      //--- set empty value for first limit bars
      for(i=0;i<limit;i++) ExtLineBuffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
        {
         int k=i-begin+1;
         weightsum+=k;
         firstValue+=k*price[i];
        }
      firstValue/=(double)weightsum;
      ExtLineBuffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   double speed;
   for(i=limit;i<rates_total && !IsStopped();i++)
   {
      sum=0;
      for(int j=0;j<InpMAPeriod;j++) sum+=(InpMAPeriod-j)*price[i-j];
      ExtLineBuffer[i]=sum/weightsum;
      ExtLineBufferColor[i]=0; 
      if(ExtLineBuffer[i] > ExtLineBuffer[i-1]){
         speed = (MathAbs(ExtLineBuffer[i]-ExtLineBuffer[i-1])/ExtLineBuffer[i])*200000000/minutes;
         if(speed > ReverseSpeed){
            ExtLineBufferColor[i]=1;
         }
      }else if(ExtLineBuffer[i] < ExtLineBuffer[i-1]){
         speed = (MathAbs(ExtLineBuffer[i]-ExtLineBuffer[i-1])/ExtLineBuffer[i-1])*200000000/minutes;
         if(speed > ReverseSpeed){
            ExtLineBufferColor[i]=2;
         }
      }
   }
//---
  }
//+------------------------------------------------------------------+
//|  smoothed moving average                                         |
//+------------------------------------------------------------------+
void CalculateSmoothedMA(int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int i,limit;
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
     {
      limit=InpMAPeriod+begin;
      //--- set empty value for first limit bars
      for(i=0;i<limit-1;i++) ExtLineBuffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
         firstValue+=price[i];
      firstValue/=InpMAPeriod;
      ExtLineBuffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   double speed;
   for(i=limit;i<rates_total && !IsStopped();i++){
      ExtLineBuffer[i]=(ExtLineBuffer[i-1]*(InpMAPeriod-1)+price[i])/InpMAPeriod;
      ExtLineBufferColor[i]=0; 
      if(ExtLineBuffer[i] > ExtLineBuffer[i-1]){
         speed = (MathAbs(ExtLineBuffer[i]-ExtLineBuffer[i-1])/ExtLineBuffer[i])*200000000/minutes;
         if(speed > ReverseSpeed){
            ExtLineBufferColor[i]=1;
         }
      }else if(ExtLineBuffer[i] < ExtLineBuffer[i-1]){
         speed = (MathAbs(ExtLineBuffer[i]-ExtLineBuffer[i-1])/ExtLineBuffer[i-1])*200000000/minutes;
         if(speed > ReverseSpeed){
            ExtLineBufferColor[i]=2;
         }
      }
   }
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod);
//---- line shifts when drawing
   PlotIndexSetInteger(0,PLOT_SHIFT,InpMAShift);
   
   //---- 设置动态数组作为颜色索引缓存区   
   SetIndexBuffer(1,ExtLineBufferColor,INDICATOR_COLOR_INDEX);

//--- name for DataWindow
   string short_name="unknown ma";
   switch(InpMAMethod)
     {
      case MODE_EMA :  short_name="EMA";  break;
      case MODE_LWMA : short_name="LWMA"; break;
      case MODE_SMA :  short_name="SMA";  break;
      case MODE_SMMA : short_name="SMMA"; break;
     }
   IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+string(InpMAPeriod)+")");
//---- sets drawing line empty value--
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   
   minutes = PeriodSeconds();
//---- initialization done
  }
//+------------------------------------------------------------------+
//|  Moving Average                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//--- check for bars count
   if(rates_total<InpMAPeriod-1+begin)
      return(0);// not enough bars for calculation
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
      ArrayInitialize(ExtLineBuffer,0);
//--- sets first bar from what index will be draw
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod-1+begin);

//--- calculation
   switch(InpMAMethod)
     {
      case MODE_EMA:  CalculateEMA(rates_total,prev_calculated,begin,price);        break;
      case MODE_LWMA: CalculateLWMA(rates_total,prev_calculated,begin,price);       break;
      case MODE_SMMA: CalculateSmoothedMA(rates_total,prev_calculated,begin,price); break;
      case MODE_SMA:  CalculateSimpleMA(rates_total,prev_calculated,begin,price);   break;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
