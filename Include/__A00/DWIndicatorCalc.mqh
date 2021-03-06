//+------------------------------------------------------------------+
//|                                                         指标计算 |
//|                                  Copyright 2018, DWIndicatorCalc |
//|                                                 2018.06.02 07:31 |
//+------------------------------------------------------------------+
#include <MovingAverages.mqh>
//+-----------------------------------------------------------------------------------------
//| 均线SMA计算方法
//| 参数: 
//|   rates_total_c: 最近参与计算的K线数
//|   symbol_c: 货币对名称
//|   timeFrame: 时间框架
//|   period: 均线周期
//|   buffer: 返回计算后的均线数组
//| 返回:
//|   如果返回0,则表示数据不足,无法计算
//| Author:
//|   Copyright 2018, litao,  2018.06.02 06:42
//+-----------------------------------------------------------------------------------------
int DWI_SMA(const int rates_total_c,string symbol_c,ENUM_TIMEFRAMES timeFrame,
            int period,
            double &bufferR[])
  {
   double price[];
   int copyedCount=CopyClose(symbol_c,timeFrame,0,rates_total_c,price);
   if(copyedCount < rates_total_c-100) return 0;

   double buffer[];
   ArrayResize(buffer,rates_total_c);
   ArrayInitialize(buffer,0.0);

   int prev_calculated=0;
   int begin=0;
   int i,limit;
//--- check for data
   if(period<=1 || rates_total_c-begin<period) return(0);
//--- save as_series flags
   bool as_series_price=ArrayGetAsSeries(price);
   bool as_series_buffer=ArrayGetAsSeries(buffer);
   if(as_series_price) ArraySetAsSeries(price,false);
   if(as_series_buffer) ArraySetAsSeries(buffer,false);
//--- first calculation or number of bars was changed
   if(prev_calculated==0) // first calculation
     {
      limit=period+begin;
      //--- set empty value for first bars
      for(i=0;i<limit-1;i++) buffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
         firstValue+=price[i];
      firstValue/=period;
      buffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   for(i=limit;i<rates_total_c;i++)
      buffer[i]=buffer[i-1]+(price[i]-price[i-period])/period;
//--- restore as_series flags
   if(as_series_price) ArraySetAsSeries(price,true);
   if(as_series_buffer) ArraySetAsSeries(buffer,true);

   ArrayCopy(bufferR,buffer);
   ArrayFree(buffer);
   ArraySetAsSeries(bufferR,true);
//---
   return(rates_total_c);
  }
//+-----------------------------------------------------------------------------------------
//| 均线SMMA计算方法
//| 参数: 
//|   rates_total_c: 最近参与计算的K线数
//|   symbol_c: 货币对名称
//|   timeFrame: 时间框架
//|   period: 均线周期
//|   buffer: 返回计算后的均线数组
//| 返回:
//|   如果返回0,则表示数据不足,无法计算
//| Author:
//|   Copyright 2018, litao,  2018.06.02 06:42
//+-----------------------------------------------------------------------------------------
int DWI_SMMA(const int rates_total_c,string symbol_c,ENUM_TIMEFRAMES timeFrame,
             int period,
             double &bufferR[])
  {
   double price[];
   int copyedCount=CopyClose(symbol_c,timeFrame,0,rates_total_c,price);
   if(copyedCount < rates_total_c-100) return 0;

   double buffer[];
   ArrayResize(buffer,rates_total_c);
   ArrayInitialize(buffer,0.0);

   int prev_calculated=0;
   int begin=0;
   int i,limit;
//--- check for data
   if(period<=1 || rates_total_c-begin<period) return(0);
//--- save as_series flags
   bool as_series_price=ArrayGetAsSeries(price);
   bool as_series_buffer=ArrayGetAsSeries(buffer);
   if(as_series_price) ArraySetAsSeries(price,false);
   if(as_series_buffer) ArraySetAsSeries(buffer,false);
//--- first calculation or number of bars was changed
   if(prev_calculated==0) // first calculation
     {
      limit=period+begin;
      //--- set empty value for first bars
      for(i=0;i<limit-1;i++) buffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
         firstValue+=price[i];
      firstValue/=period;
      buffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   for(i=limit;i<rates_total_c;i++)
      buffer[i]=(buffer[i-1]*(period-1)+price[i])/period;
//--- restore as_series flags
   if(as_series_price) ArraySetAsSeries(price,true);
   if(as_series_buffer) ArraySetAsSeries(buffer,true);

   ArrayCopy(bufferR,buffer);
   ArrayFree(buffer);
   ArraySetAsSeries(bufferR,true);
//---
   return(rates_total_c);
  }
//+-----------------------------------------------------------------------------------------
//| 均线LWMA计算方法
//| 参数: 
//|   rates_total_c: 最近参与计算的K线数
//|   symbol_c: 货币对名称
//|   timeFrame: 时间框架
//|   period: 均线周期
//|   buffer: 返回计算后的均线数组
//| 返回:
//|   如果返回0,则表示数据不足,无法计算
//| Author:
//|   Copyright 2018, litao,  2018.06.02 06:42
//+-----------------------------------------------------------------------------------------
int DWI_LWMA(const int rates_total_c,string symbol_c,ENUM_TIMEFRAMES timeFrame,
             int period,
             double &bufferR[])
  {
   double price[];
   int copyedCount=CopyClose(symbol_c,timeFrame,0,rates_total_c,price);
   if(copyedCount < rates_total_c-100) return 0;

   double buffer[];
   ArrayResize(buffer,rates_total_c);
   ArrayInitialize(buffer,0.0);

   int prev_calculated=0;
   int begin=0;
   static int weightsum;
   double     sum;
   int i,limit;
//--- check for data
   if(period<=1 || rates_total_c-begin<period) return(0);
//--- save as_series flags
   bool as_series_price=ArrayGetAsSeries(price);
   bool as_series_buffer=ArrayGetAsSeries(buffer);
   if(as_series_price) ArraySetAsSeries(price,false);
   if(as_series_buffer) ArraySetAsSeries(buffer,false);
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
     {
      weightsum=0;
      limit=period+begin;
      //--- set empty value for first bars
      for(i=0;i<limit;i++) buffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
        {
         int k=i-begin+1;
         weightsum+=k;
         firstValue+=k*price[i];
        }
      firstValue/=(double)weightsum;
      buffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   for(i=limit;i<rates_total_c;i++)
     {
      sum=0;
      for(int j=0;j<period;j++) sum+=(period-j)*price[i-j];
      buffer[i]=sum/weightsum;
     }
//--- restore as_series flags
   if(as_series_price) ArraySetAsSeries(price,true);
   if(as_series_buffer) ArraySetAsSeries(buffer,true);

   ArrayCopy(bufferR,buffer);
   ArrayFree(buffer);
   ArraySetAsSeries(bufferR,true);
//---
   return(rates_total_c);
  }
//+-----------------------------------------------------------------------------------------
//| 均线SMA计算方法
//| 参数: 
//|   rates_total_c: 最近参与计算的K线数
//|   symbol_c: 货币对名称
//|   timeFrame: 时间框架
//|   InpBandsPeriod: Boll均线周期
//|   InpBandsDeviations: Boll偏差参数
//|   extMLBufferR: 返回计算后的均线数组,中线base
//|   extTLBufferR: 返回计算后的均线数组,上线upper
//|   extBLBufferR: 返回计算后的均线数组,下线lower
//| 返回:
//|   如果返回0,则表示数据不足,无法计算
//| Author:
//|   Copyright 2018, litao,  2018.06.02 06:42
//+-----------------------------------------------------------------------------------------
int DWI_BB(const int ma_type_c,const int rates_total_c,string symbol_c,ENUM_TIMEFRAMES timeFrame,
           int InpBandsPeriod,double InpBandsDeviations,
           double &extMLBufferR[],double &extTLBufferR[],double &extBLBufferR[])
  {
//--- check for input values
   if(InpBandsPeriod<2){ return 0; }
   if(InpBandsDeviations==0.0){ return 0; }

   double price[];
   int copyedCount=CopyClose(symbol_c,timeFrame,0,rates_total_c,price);
   if(copyedCount < rates_total_c-100) return 0;


   double        ExtMLBuffer[];
   double        ExtTLBuffer[];
   double        ExtBLBuffer[];
   double        ExtStdDevBuffer[];

   ArrayResize(ExtMLBuffer,rates_total_c);
   ArrayResize(ExtTLBuffer,rates_total_c);
   ArrayResize(ExtBLBuffer,rates_total_c);
   ArrayResize(ExtStdDevBuffer,rates_total_c);

   ArrayInitialize(ExtMLBuffer, 0.0);
   ArrayInitialize(ExtTLBuffer, 0.0);
   ArrayInitialize(ExtBLBuffer, 0.0);
   ArrayInitialize(ExtStdDevBuffer,0.0);

   int prev_calculated=0;
   int begin=0;
//--- variables
   int pos;
   int ExtPlotBegin=0;
//--- indexes draw begin settings, when we've recieved previous begin
   if(ExtPlotBegin!=InpBandsPeriod+begin)
     {
      ExtPlotBegin=InpBandsPeriod+begin;
     }
//--- check for bars count
   if(rates_total_c<ExtPlotBegin)
      return(0);
//--- starting calculation
   if(prev_calculated>1) pos=prev_calculated-1;
   else pos=1;
//--- main cycle
   for(int i=pos;i<rates_total_c;i++)
     {
      //--- middle line
      if(ma_type_c == 2) ExtMLBuffer[i]=LinearWeightedMA(i,InpBandsPeriod,price);
      if(ma_type_c == 3) ExtMLBuffer[i]=SimpleMA(i,InpBandsPeriod,price);      
      if(ma_type_c == 4) ExtMLBuffer[i]=SmoothedMA(i,InpBandsPeriod, ExtMLBuffer[i-1],price);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,price,ExtMLBuffer,InpBandsPeriod);
      //--- upper line
      ExtTLBuffer[i]=ExtMLBuffer[i]+InpBandsDeviations*ExtStdDevBuffer[i];
      //--- lower line
      ExtBLBuffer[i]=ExtMLBuffer[i]-InpBandsDeviations*ExtStdDevBuffer[i];
      //---
     }

   ArrayCopy(extMLBufferR,ExtMLBuffer);
   ArrayCopy(extTLBufferR,ExtTLBuffer);
   ArrayCopy(extBLBufferR,ExtBLBuffer);

   ArrayFree(ExtMLBuffer);
   ArrayFree(ExtTLBuffer);
   ArrayFree(ExtBLBuffer);
   ArrayFree(ExtStdDevBuffer);

   ArraySetAsSeries(extMLBufferR,true);
   ArraySetAsSeries(extTLBufferR,true);
   ArraySetAsSeries(extBLBufferR,true);
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total_c);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
  {
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position<period) return(StdDev_dTmp);
//--- calcualte StdDev
   for(int i=0;i<period;i++) StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2);
   StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
//--- return calculated value
   return(StdDev_dTmp);
  }
//+-----------------------------------------------------------------------------------------
//| ZigZag计算方法
//| 参数: 
//|   rates_total_c: 最近参与计算的K线数
//|   symbol_c: 货币对名称
//|   timeFrame: 时间框架
//|   dPoint_c: Point()的值
//|   extDepth_c: 步长,动态,主要参数
//|   buffer: 返回计算后的均线数组
//|   如果返回0,则表示数据不足,无法计算
//| Author:
//|   Copyright 2018, litao,  2018.05.31 22:32
//+-----------------------------------------------------------------------------------------
int DWI_ZigZag(const int rates_total_c,string symbol_c,ENUM_TIMEFRAMES timeFrame,
               double dPoint_c,
               int extDepth_c,
               double &bufferR[])
  {
   double high[];
   int copyedCount=CopyHigh(symbol_c,timeFrame,0,rates_total_c,high);
   if(copyedCount < 900) return 0;
   double low[];
   CopyLow(symbol_c,timeFrame,0,rates_total_c,low);
//Print("abc: " + high[998]);

//--- indicator buffers
   double         ZigzagBuffer[];      // main buffer
   double         HighMapBuffer[];     // highs
   double         LowMapBuffer[];      // lows

   ArrayResize(ZigzagBuffer,rates_total_c);
   ArrayResize(HighMapBuffer,rates_total_c);
   ArrayResize(LowMapBuffer,rates_total_c);

   ArrayInitialize(ZigzagBuffer,0.0);
   ArrayInitialize(HighMapBuffer,0.0);
   ArrayInitialize(LowMapBuffer,0.0);

   int      ExtDeviation=5;
   int      ExtBackstep=3;
   int      level=3;             // recounting depth
   double   deviation2=ExtDeviation*dPoint_c;

   int i=0;
   int limit=0,counterZ=0,whatlookfor=0;
   int shift=0,back=0,lasthighpos=0,lastlowpos=0;
   double val=0,res=0;
   double curlow=0,curhigh=0,lasthigh=0,lastlow=0;
   enum looling_for
     {
      Pike=1,  // searching for next high
      Sill=-1  // searching for next low
     };
   if(rates_total_c<100) return(0);
//--- set start position for calculations
   int prev_calculated=0;
   if(prev_calculated==0) limit=extDepth_c;

//--- ZigZag was already counted before
   if(prev_calculated>0)
     {
      i=rates_total_c-1;
      //--- searching third extremum from the last uncompleted bar
      while(counterZ<level && i>rates_total_c-100)
        {
         res=ZigzagBuffer[i];
         if(res!=0) counterZ++;
         i--;
        }
      i++;
      limit=i;

      //--- what type of exremum we are going to find
      if(LowMapBuffer[i]!=0)
        {
         curlow=LowMapBuffer[i];
         whatlookfor=Pike;
        }
      else
        {
         curhigh=HighMapBuffer[i];
         whatlookfor=Sill;
        }
      //--- chipping
      for(i=limit+1;i<rates_total_c && !IsStopped();i++)
        {
         ZigzagBuffer[i]=0.0;
         LowMapBuffer[i]=0.0;
         HighMapBuffer[i]=0.0;
        }
     }

//--- searching High and Low
   for(shift=limit;shift<rates_total_c && !IsStopped();shift++)
     {
      val=low[iLowest(low,extDepth_c,shift)];
      if(val==lastlow) val=0.0;
      else
        {
         lastlow=val;
         if((low[shift]-val)>deviation2) val=0.0;
         else
           {
            for(back=1;back<=ExtBackstep;back++)
              {
               res=LowMapBuffer[shift-back];
               if((res!=0) && (res>val)) LowMapBuffer[shift-back]=0.0;
              }
           }
        }
      if(low[shift]==val) LowMapBuffer[shift]=val; else LowMapBuffer[shift]=0.0;
      //--- high
      val=high[iHighest(high,extDepth_c,shift)];
      if(val==lasthigh) val=0.0;
      else
        {
         lasthigh=val;
         if((val-high[shift])>deviation2) val=0.0;
         else
           {
            for(back=1;back<=ExtBackstep;back++)
              {
               res=HighMapBuffer[shift-back];
               if((res!=0) && (res<val)) HighMapBuffer[shift-back]=0.0;
              }
           }
        }
      if(high[shift]==val) HighMapBuffer[shift]=val; else HighMapBuffer[shift]=0.0;
     }

//--- last preparation
   if(whatlookfor==0)// uncertain quantity
     {
      lastlow=0;
      lasthigh=0;
     }
   else
     {
      lastlow=curlow;
      lasthigh=curhigh;
     }

//--- final rejection
   for(shift=limit;shift<rates_total_c && !IsStopped();shift++)
     {
      res=0.0;
      switch(whatlookfor)
        {
         case 0: // search for peak or lawn
            if(lastlow==0 && lasthigh==0)
              {
               if(HighMapBuffer[shift]!=0)
                 {
                  lasthigh=high[shift];
                  lasthighpos=shift;
                  whatlookfor=Sill;
                  ZigzagBuffer[shift]=lasthigh;
                  res=1;
                 }
               if(LowMapBuffer[shift]!=0)
                 {
                  lastlow=low[shift];
                  lastlowpos=shift;
                  whatlookfor=Pike;
                  ZigzagBuffer[shift]=lastlow;
                  res=1;
                 }
              }
            break;
         case Pike: // search for peak
            if(LowMapBuffer[shift]!=0.0 && LowMapBuffer[shift]<lastlow && HighMapBuffer[shift]==0.0)
              {
               ZigzagBuffer[lastlowpos]=0.0;
               lastlowpos=shift;
               lastlow=LowMapBuffer[shift];
               ZigzagBuffer[shift]=lastlow;
               res=1;
              }
            if(HighMapBuffer[shift]!=0.0 && LowMapBuffer[shift]==0.0)
              {
               lasthigh=HighMapBuffer[shift];
               lasthighpos=shift;
               ZigzagBuffer[shift]=lasthigh;
               whatlookfor=Sill;
               res=1;
              }
            break;
         case Sill: // search for lawn
            if(HighMapBuffer[shift]!=0.0 && HighMapBuffer[shift]>lasthigh && LowMapBuffer[shift]==0.0)
              {
               ZigzagBuffer[lasthighpos]=0.0;
               lasthighpos=shift;
               lasthigh=HighMapBuffer[shift];
               ZigzagBuffer[shift]=lasthigh;
              }
            if(LowMapBuffer[shift]!=0.0 && HighMapBuffer[shift]==0.0)
              {
               lastlow=LowMapBuffer[shift];
               lastlowpos=shift;
               ZigzagBuffer[shift]=lastlow;
               whatlookfor=Pike;
              }
            break;
         default: return(rates_total_c);
        }
     }

   ArrayCopy(bufferR,ZigzagBuffer); //通过引用返回

   ArrayFree(ZigzagBuffer);
   ArrayFree(HighMapBuffer);
   ArrayFree(LowMapBuffer);

   ArraySetAsSeries(bufferR,true);
//--- return value of prev_calculated for next call
   return(rates_total_c);
  }
//+------------------------------------------------------------------+
//|  searching index of the highest bar                              |
//+------------------------------------------------------------------+
int iHighest(const double &array[],
             int depth,
             int startPos)
  {
   int index=startPos;
//--- start index validation
   if(startPos<0)
     {
      Print("Invalid parameter in the function iHighest, startPos =",startPos);
      return 0;
     }
   int size=ArraySize(array);
//--- depth correction if need
   if(startPos-depth<0) depth=startPos;
   double max=array[startPos];
//--- start searching
   for(int i=startPos;i>startPos-depth;i--)
     {
      if(array[i]>max)
        {
         index=i;
         max=array[i];
        }
     }
//--- return index of the highest bar
   return(index);
  }
//+------------------------------------------------------------------+
//|  searching index of the lowest bar                               |
//+------------------------------------------------------------------+
int iLowest(const double &array[],
            int depth,
            int startPos)
  {
   int index=startPos;
//--- start index validation
   if(startPos<0)
     {
      Print("Invalid parameter in the function iLowest, startPos =",startPos);
      return 0;
     }
   int size=ArraySize(array);
//--- depth correction if need
   if(startPos-depth<0) depth=startPos;
   double min=array[startPos];
//--- start searching
   for(int i=startPos;i>startPos-depth;i--)
     {
      if(array[i]<min)
        {
         index=i;
         min=array[i];
        }
     }
//--- return index of the lowest bar
   return(index);
  }
//+------------------------------------------------------------------+
