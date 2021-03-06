//+------------------------------------------------------------------+
//|                                                         SSL.mq5  |
//|                                       Copyright �2007, Kalenzo  |
//|                                     bartlomiej.gorski@gmail.com  |
//+------------------------------------------------------------------+
//---- 指标作者
#property copyright "Copyright �2007, Kalenzo"
//---- 指向作者网站的链接
#property link "bartlomiej.gorski@gmail.com"
//---- 指标版本号
#property version   "1.00"
//---- 在主窗口中绘图
#property indicator_chart_window
//---- 计算和绘制指标中使用4个缓冲区
#property indicator_buffers 4
//---- 使用4个绘图
#property indicator_plots   4
//+----------------------------------------------+
//|  绘制牛势指标的参数        |
//+----------------------------------------------+
//---- 指标绘为线
#property indicator_type1   DRAW_LINE
//---- Blue color is used for the indicator line
#property indicator_color1  clrBlue
//---- 指标1的线型为点横线
#property indicator_style1  STYLE_SOLID
//---- 指标1线宽为2
#property indicator_width1  1
//---- 显示指标线标签
#property indicator_label1  "Upper SSL"
//+----------------------------------------------+
//|  绘制熊势指标的参数 |
//+----------------------------------------------+
//---- 指标2画为线
#property indicator_type2   DRAW_LINE
//---- 指标线使用暗粉色
#property indicator_color2  clrDeepPink
//---- 指标2的线型为点横线
#property indicator_style2  STYLE_SOLID
//---- 指标2线宽为2
#property indicator_width2  1
//---- 显示指标线标签
#property indicator_label2  "Lower SSL"
//+----------------------------------------------+
//|  绘制牛势指标的参数        |
//+----------------------------------------------+
//---- 指标3绘制为标签
#property indicator_type3   DRAW_ARROW
//---- DeepSkyBlue color is used for the indicator
#property indicator_color3  clrDeepSkyBlue
//---- 指标3宽度等于4
#property indicator_width3  4
//---- 显示指标标签
#property indicator_label3  "Buy SSL"
//+----------------------------------------------+
//|  绘制熊势指标的参数 |
//+----------------------------------------------+
//---- 指标4绘制为标签
#property indicator_type4   DRAW_ARROW
//---- 指标使用红色
#property indicator_color4  clrRed
//---- 指标4宽度等于4
#property indicator_width4  4
//---- 显示指标标签
#property indicator_label4  "Sell SSL"
//+----------------------------------------------+
//|  声明常数                         |
//+----------------------------------------------+
#define RESET  0 // The constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| 指标输入参数                   |
//+----------------------------------------------+
input uint   period=13;           // Moving averages period;
//内置参数
 bool   NRTR=true;           // NRTR
 int    Shift=0;             // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//---- 声明动态数组
// 指标缓冲区的动态数组
double ExtMapBufferUp[];
double ExtMapBufferDown[];
double ExtMapBufferUp1[];
double ExtMapBufferDown1[];
//---- declaration of integer variables for indicators handles
int HMA_Handle,LMA_Handle;
//---- 声明整型变量用于数据计算的起始点
int min_rates_total;
//+------------------------------------------------------------------+
//| 自定义指标初始化函数                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- getting handle of the HMA indicator
   HMA_Handle=iMA(NULL,0,period,0,MODE_LWMA,PRICE_HIGH);
   if(HMA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the HMA indicator");
      return(1);
     }

//---- getting handle of the LMA indicator
   LMA_Handle=iMA(NULL,0,period,0,MODE_LWMA,PRICE_LOW);
   if(LMA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the LMA indicator");
      return(1);
     }

//---- 初始化数据计算起点的变量
   min_rates_total=int(period+1);

//---- 把 ExtMapBufferUp[] 动态数组设为指标缓冲区
   SetIndexBuffer(0,ExtMapBufferUp,INDICATOR_DATA);
//---- 把指标1水平转换设为Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- 转换指标1的绘制起点
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- 把缓冲区索引方向设为倒序   
   ArraySetAsSeries(ExtMapBufferUp,true);
//---- setting values of the indicator that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- 把 ExtMapBufferDown[] 动态数组设为缓冲区
   SetIndexBuffer(1,ExtMapBufferDown,INDICATOR_DATA);
//---- 水平转换指标2
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- shifting the starting point of calculation of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- 把缓冲区索引方向设为倒序   
   ArraySetAsSeries(ExtMapBufferDown,true);
//---- setting values of the indicator that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- 把 ExtMapBufferUp1[] 动态数组设为指标缓冲区
   SetIndexBuffer(2,ExtMapBufferUp1,INDICATOR_DATA);
//---- 把指标1水平转换设为Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- 转换指标 3 的绘制起点
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- 把缓冲区索引方向设为倒序   
   ArraySetAsSeries(ExtMapBufferUp1,true);
//---- setting values of the indicator that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- 指标符号
   PlotIndexSetInteger(2,PLOT_ARROW,159);

//---- 把 ExtMapBufferDown1[] 动态数组设为指标缓冲区
   SetIndexBuffer(3,ExtMapBufferDown1,INDICATOR_DATA);
//---- 水平转换指标2
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- 转换指标 4 的绘制起点
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- 把缓冲区索引方向设为倒序   
   ArraySetAsSeries(ExtMapBufferDown1,true);
//---- setting values of the indicator that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- 指标符号
   PlotIndexSetInteger(3,PLOT_ARROW,159);

//---- 初始化指标短名称的变量
   string shortname;
   StringConcatenate(shortname,"SSL(",period,", ",Shift,")");
//--- 创建用于显示于独立子窗口和弹出帮助中的名称
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| 自定义指标迭代函数                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // 当前订单时的历史柱数
                const int prev_calculated,// 前一订单时历史中的柱数
                const datetime &time[],
                const double &open[],
                const double& high[],     // 用于计算指标的最高价数组
                const double& low[],      // 用于计算指标的最低价数组
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- 检查柱是否足够用于计算
   if(BarsCalculated(HMA_Handle)<rates_total
      || BarsCalculated(LMA_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- 声明局部变量 
   double HMA[],LMA[];
   int limit,to_copy,bar,trend,Hld;
   static int trend_;

//---- indexing elements in arrays as in time series  
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(HMA,true);
   ArraySetAsSeries(LMA,true);

//---- calculation of the limit starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // 检查指标是否为第一次开始计算
     {
      limit=rates_total-min_rates_total-1;               // 计算所有柱的起始索引
      trend_=0;
     }
   else
     {
      limit=rates_total-prev_calculated;                 // 计算新柱的起点索引
     }

   to_copy=limit+2;
//---- 把新出现的数据复制到数组中
   if(CopyBuffer(HMA_Handle,0,0,to_copy,HMA)<=0) return(RESET);
   if(CopyBuffer(LMA_Handle,0,0,to_copy,LMA)<=0) return(RESET);

//---- 恢复变量值
   trend=trend_;

//---- 指标计算的主循环
   for(bar=limit; bar>=0; bar--)
     {
      ExtMapBufferUp[bar]=EMPTY_VALUE;
      ExtMapBufferDown[bar]=EMPTY_VALUE;
      ExtMapBufferUp1[bar]=EMPTY_VALUE;
      ExtMapBufferDown1[bar]=EMPTY_VALUE;

      if(close[bar]>HMA[bar+1]) Hld=+1;
      else
        {
         if(close[bar]<LMA[bar+1]) Hld=-1;
         else Hld=0;
        }
      if(Hld!=0) trend=Hld;
      if(trend==-1)
        {
         if(!NRTR || ExtMapBufferDown[bar+1]==EMPTY_VALUE) ExtMapBufferDown[bar]=HMA[bar+1];
         else if(ExtMapBufferDown[bar+1]!=EMPTY_VALUE) ExtMapBufferDown[bar]=MathMin(HMA[bar+1],ExtMapBufferDown[bar+1]);
        }
      else
        {

         if(!NRTR || ExtMapBufferUp[bar+1]==EMPTY_VALUE) ExtMapBufferUp[bar]=LMA[bar+1];
         else  if(ExtMapBufferUp[bar+1]!=EMPTY_VALUE) ExtMapBufferUp[bar]=MathMax(LMA[bar+1],ExtMapBufferUp[bar+1]);
        }

      if(ExtMapBufferUp[bar+1]==EMPTY_VALUE && ExtMapBufferUp[bar]!=EMPTY_VALUE) ExtMapBufferUp1[bar]=ExtMapBufferUp[bar];
      if(ExtMapBufferDown[bar+1]==EMPTY_VALUE && ExtMapBufferDown[bar]!=EMPTY_VALUE) ExtMapBufferDown1[bar]=ExtMapBufferDown[bar];
      /*
      if(ExtMapBufferDown[bar] > 10000000) ExtMapBufferDown[bar]=0.0;
      if(ExtMapBufferDown1[bar] > 10000000) ExtMapBufferDown1[bar]=0.0;
      if(ExtMapBufferUp[bar] > 10000000) ExtMapBufferUp[bar]=0.0;
      if(ExtMapBufferUp1[bar] > 10000000) ExtMapBufferUp1[bar]=0.0;
      */

      if(bar) trend_=trend;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
