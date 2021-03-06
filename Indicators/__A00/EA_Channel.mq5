//+------------------------------------------------------------------+
//|                                       channel_breakout_entry.mq5 | 
//|                                       Copyright ?2009, darmasdt | 
//|                                          http://indotraders.org/ | 
//+------------------------------------------------------------------+
#property copyright "Copyright ?2009, darmasdt"
#property link "http://indotraders.org/"
#property description ""
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers 8
#property indicator_buffers 2 
//---- only 8 graphical plots are used
#property indicator_plots   2

//+--------------------------------------------+
//|  BB levels indicator drawing parameters    |
//+--------------------------------------------+
//---- drawing the levels as lines
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
//---- selection of levels colors
#property indicator_color1 clrBlue
#property indicator_color2 clrBlue
//---- Bollinger Bands are continuous curves
#property indicator_style1 STYLE_DOT
#property indicator_style2 STYLE_DOT
//---- Bollinger Bands width is equal to 1
#property indicator_width1  1
#property indicator_width2  1
//---- display the labels of Bollinger Bands levels
#property indicator_label1  "trailing_Up"
#property indicator_label2  "trailing_Dn"

//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal

//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input uint Range1=20;
//没发现下面两个参数的作用, 暂时内置
 double atr_factor=2;
 int atr_range=14;
//+-----------------------------------+

//---- declaration of dynamic arrays that will further be 
//---- will be used as channel_breakout_entry indicator buffers
double ExtLineBuffer1[],ExtLineBuffer2[];

//---- Declaration of integer variables for the indicator handles
int ATR_Handle;
//---- Declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+   
//| channel_breakout_entry indicator initialization function         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=int(MathMax(Range1,atr_factor));

//---- getting the ATR indicator handle
   ATR_Handle=iATR(NULL,0,atr_range);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");

//---- setting dynamic arrays as indicator buffers
   SetIndexBuffer(0,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLineBuffer2,INDICATOR_DATA);
//---- set the position, from which the levels drawing starts
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(ExtLineBuffer1,true);
   ArraySetAsSeries(ExtLineBuffer2,true);

//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Channel(",Range1,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- end of initialization
  }
//+------------------------------------------------------------------+ 
//| channel_breakout_entry iteration function                        | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- checking the number of bars to be enough for calculation
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//---- declaration of variables with a floating point  
   double ATR[];
//---- declaration of local variables 
   int limit,to_copy,bar;

//---- calculations of the necessary amount of data to be copied and
//the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-2; // starting index for the calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars 
   to_copy=limit+2;

//---- copy newly appeared data in the SAR array
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- Main calculation loop of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtLineBuffer1[bar]=high[ArrayMaximum(high,bar,Range1)];
      ExtLineBuffer2[bar]=low[ArrayMinimum(low,bar,Range1)];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
