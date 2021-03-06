//+------------------------------------------------------------------+
//|                                             MA_RoundingStDev.mq5 | 
//|                                      Copyright © 2009, BACKSPACE | 
//|                                                                  | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, BACKSPACE"
#property link ""
//---- 指标版本号
#property version   "1.01"
//---- 在主窗口中绘制指标
#property indicator_chart_window 
//---- 六个缓冲区用于计算和绘制指标
#property indicator_buffers 2
//---- 仅使用五个图形构造。
#property indicator_plots   1
//+----------------------------------------------+
//| MA_Roundin指标渲染参数    |
//+----------------------------------------------+
//---- 将指标绘制成一条线
#property indicator_type1   DRAW_COLOR_LINE
//---- 作为使用的颜色线指示器
#property indicator_color1 clrCrimson,clrGray,clrBlue
//---- 指标线 - 连续曲线
#property indicator_style1  STYLE_SOLID
//---- 指示线的粗细为2
#property indicator_width1  2
//---- 指示标签显示
#property indicator_label1  "MA_Rounding"

//+-----------------------------------+
//| CXMA类描述              |
//+-----------------------------------+
#include <__A00/SmoothAlgorithms.mqh> 
#include <__A00/Func.mqh> 
//+-----------------------------------+
//---- 从SmoothAlgorithms.mqh文件声明CXMA类变量
CXMA XMA1;
//+-----------------------------------+
//| 上市公告           |
//+-----------------------------------+
/*
enum Applied_price_ //常数型
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price 
   PRICE_DEMARK_         //Demark Price
  };*/
//+-----------------------------------+
/*enum Smooth_Method - 枚举在SmoothAlgorithms.mqh文件中声明
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  }; */
//+-----------------------------------+
//| 指标输入参数      |
//+-----------------------------------+
input Smooth_Method XMA_Method=MODE_SMA_; //平滑方法 
input int XLength=12; // 平滑深度
int XPhase=15;  // 平滑参数
//--- 对于JJMA，在-100 ... +100范围内变化会影响过渡过程的质量;
//--- 对于VIDIA而言，这是CMO时期，对于AMA来说，这是一个缓慢的移动时期
Applied_price_ IPC=PRICE_CLOSE_; // 价格常量
input uint MaRound=50; // 舍入因子
double dK1=1.5;  // 平方律滤波系数 1
double dK2=2.5;  // 平方律滤波系数 2
uint std_period=9; // 二次滤波周期
input double   ReverseSpeed = 0;  //转向速度
input bool  Email_Alert = false;  //是否邮件提醒
input bool  ShowComment = false;  //是否显示Comment
 int Shift=0; // 平移
//+-----------------------------------+
//---- 声明动态数组 
//---- 用于将来的指标缓存区
double ExtLineBuffer[],ColorExtLineBuffer[];
//double BearsBuffer1[],BullsBuffer1[];
//double BearsBuffer2[],BullsBuffer2[];
double dMA_Roundin[];
//---- 垂直移位的变量声明
double MaRo;
//---- 整数基准变量的声明
int min_rates_total;
double speed;

datetime                last_time;
//+------------------------------------------------------------------+   
//| XMA indicator initialization function                            | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- 初始化基准变量
   min_rates_total=XMA1.GetStartBars(XMA_Method,XLength,XPhase)+2+int(std_period);
//---- 将警报设置为外部变量的无效值
   XMA1.XMALengthCheck("XLength", XLength);
   XMA1.XMAPhaseCheck("XPhase", XPhase, XMA_Method);
//---- 垂直移位初始化
   MaRo=_Point*MaRound;
//---- 变量数组的内存分配
   ArrayResize(dMA_Roundin,std_period);
//---- 将动态数组转换为指标缓冲区
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- 水平移动指示器
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- 移动指标渲染的起点
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- 设置图表上不可见的指标值
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- 将动态数组转换为颜色索引缓冲区
   SetIndexBuffer(1,ColorExtLineBuffer,INDICATOR_COLOR_INDEX);
//---- 将BearsBuffer的动态数组转换为指标缓冲区
   //SetIndexBuffer(2,BearsBuffer1,INDICATOR_DATA);
//---- 指标2的水平移动
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- 移动指标渲染的起点
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- 绘图的符号选择
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- 禁止绘图指标空值
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- 将一个动态的bullsbuffer数组转换为指标缓冲区
/*
   SetIndexBuffer(3,BullsBuffer1,INDICATOR_DATA);
//---- 指标3的水平移动
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- 移动指标渲染的起点
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- 绘图的符号选择
   PlotIndexSetInteger(2,PLOT_ARROW,159);
//---- 禁止绘图指标空值
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- 将BearsBuffer的动态数组转换为指标缓冲区
   SetIndexBuffer(4,BearsBuffer2,INDICATOR_DATA);
//---- 指标2的水平移动
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- 移动指标渲染的起点
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- 绘图的符号选择
   PlotIndexSetInteger(3,PLOT_ARROW,159);
//---- 禁止绘图指标空值
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- 将一个动态的bullsbuffer数组转换为指标缓冲区
   SetIndexBuffer(5,BullsBuffer2,INDICATOR_DATA);
//---- 指标3的水平移动
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);
//---- 移动指标渲染的起点
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- 绘图的符号选择
   PlotIndexSetInteger(4,PLOT_ARROW,159);
//---- 禁止绘图指标空值
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);*/
//----指标短名称的变量初始化
   string shortname;
   string Smooth1=XMA1.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"MA RoundingStDev(",Smooth1,", ",XLength,", ",MaRound,", ",ReverseSpeed,")");
//--- 创建一个名称，以便在单独的子窗口和工具提示中显示
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- 指标显示精度的确定
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- 完成初始化

   last_time = GetKnTime(_Symbol, PERIOD_CURRENT, 0);
   Comment("");
  }
//+------------------------------------------------------------------+ 
//| XMA iteration function                                           | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    //当前刻度线上的条形历史数量
                const int prev_calculated,// 上一个刻度线中的条形历史数量
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- 检查条数以保证计算的充分性
   if(rates_total<min_rates_total) return(0);
//---- 浮点变量声明
   double price,MovAve0,MovAle0,res0,res1;
   double MA_Roundin,SMAdif,Sum,StDev,dstd,BEARS1,BULLS1,BEARS2,BULLS2,Filter1,Filter2;
//---- 整数变量的声明
   int first,bar,clr;
//---- 静态变量声明
   static double MovAle1,MovAve1;
//---- 计算棒的重新计算周期的起始编号
   if(prev_calculated>rates_total || prev_calculated<=0) // 检查指标计算的第一次开始
     {
      first=1; // 用于计算所有条形的起始编号
      MovAve1=PriceSeries(IPC,first,open,low,high,close);
      MovAle1=0;
     }
   else first=prev_calculated-1; // 用于计算新柱的起始编号
//---- 主要指标计算周期
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
   {
      //---- 调用PriceSeries函数以获得price_ price输入
      price=PriceSeries(IPC,bar,open,low,high,close);
      //----
      MovAve0=XMA1.XMASeries(1,prev_calculated,rates_total,XMA_Method,XPhase,XLength,price,bar,false);
      //----
      res1=ExtLineBuffer[bar-1];
      //----
      if(MovAve0>MovAve1+MaRo
         || MovAve0<MovAve1-MaRo
         || MovAve0>res1+MaRo
         || MovAve0<res1-MaRo
         || (MovAve0>res1 && MovAle1==+1)
         || (MovAve0<res1 && MovAle1==-1))
         ExtLineBuffer[bar]=MovAve0;
      else ExtLineBuffer[bar]=res1;
      //----
      MovAle0=0;
      res0=ExtLineBuffer[bar];
      if(res0<res1) MovAle0 =-1;
      if(res0>res1) MovAle0 =+1;
      if(res0==res1) MovAle0=MovAle1;
      //--- 重新计算环形缓冲区中的位置
      if(bar<rates_total-1)
        {
         MovAle1=MovAle0;
         MovAve1=MovAve0;
        }
      //--- 指示线着色
      clr=1;
      if(ExtLineBuffer[bar-1]>ExtLineBuffer[bar]){
         clr=0;
         if(ExtLineBuffer[bar] != 0){
            speed = NormalizeDouble((MathAbs(ExtLineBuffer[bar-1]-ExtLineBuffer[bar])/ExtLineBuffer[bar])*100000, 0);
            if(speed < ReverseSpeed){
               clr = 1;
            }
         }
      }else if(ExtLineBuffer[bar-1]<ExtLineBuffer[bar]){
         clr=2;
         if(ExtLineBuffer[bar-1] != 0){
            speed = NormalizeDouble((MathAbs(ExtLineBuffer[bar-1]-ExtLineBuffer[bar])/ExtLineBuffer[bar-1])*100000, 0);
            if(speed < ReverseSpeed){
               clr = 1;
            }
         }
      }
      ColorExtLineBuffer[bar]=clr;
   }
     
//---- 重新计算棒的重新计算的起始编号
   if(prev_calculated>rates_total || prev_calculated<=0) // 检查指标计算的第一次开始
      first=min_rates_total;
//---- 计算标准偏差指标的主循环
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      //---- 负载指示器递增到数组中以进行中间计算
      for(int iii=0; iii<int(std_period); iii++) dMA_Roundin[iii]=ExtLineBuffer[bar-iii]-ExtLineBuffer[bar-iii-1];
      //---- 找到指标增量的简单平均值
      Sum=0.0;
      for(int iii=0; iii<int(std_period); iii++) Sum+=dMA_Roundin[iii];
      SMAdif=Sum/std_period;
      //---- 找到增量和均值差的平方和
      Sum=0.0;
      for(int iii=0; iii<int(std_period); iii++) Sum+=MathPow(dMA_Roundin[iii]-SMAdif,2);
      //---- 从指标增量确定StDev标准差的总值
      StDev=MathSqrt(Sum/std_period);
      //---- 变量初始化
      dstd=NormalizeDouble(dMA_Roundin[0],_Digits+2);
      Filter1=NormalizeDouble(dK1*StDev,_Digits+2);
      Filter2=NormalizeDouble(dK2*StDev,_Digits+2);
      BEARS1=EMPTY_VALUE;
      BULLS1=EMPTY_VALUE;
      BEARS2=EMPTY_VALUE;
      BULLS2=EMPTY_VALUE;
      MA_Roundin=ExtLineBuffer[bar];
      //---- 计算指标值
      if(dstd<-Filter1 && dstd>=-Filter2) BEARS1=MA_Roundin; //有一个下降趋势
      if(dstd<-Filter2) BEARS2=MA_Roundin; //有一个下降趋势
      if(dstd>+Filter1 && dstd<=+Filter2) BULLS1=MA_Roundin; //有一个上升趋势
      if(dstd>+Filter2) BULLS2=MA_Roundin; //有一个上升趋势
      //---- 初始化指示符的单元格缓冲获得的值
      //BullsBuffer1[bar]=BULLS1;
      //BearsBuffer1[bar]=BEARS1;
      //BullsBuffer2[bar]=BULLS2;
      //BearsBuffer2[bar]=BEARS2;
     }

   int my_index = ArraySize(ColorExtLineBuffer)-1;
   datetime now = GetKnTime(_Symbol, PERIOD_CURRENT, 0);
   if(last_time < now && ColorExtLineBuffer[my_index-1] != ColorExtLineBuffer[my_index-2]){
      last_time = now;
      string oldDir = getDirectionStr(ColorExtLineBuffer[my_index-2]);
      string newDir = getDirectionStr(ColorExtLineBuffer[my_index-1]);
      
      if(Email_Alert){
         string msg = "ma_roundingstdev: " + _Symbol + ", " + (string)TFToString(Period()) + ", " + oldDir + " -> " + (string)newDir + ", 舍入因子: " + (string)MaRound + ", 平滑深度: " + (string)XLength;
         Print(msg);
         //SendMail(msg, msg);
      }
   } 
   //
   double bears = 0.0; //熊
   double bulls = 0.0;//牛
  // if(BearsBuffer1[my_index-1] != EMPTY_VALUE){ bears = BearsBuffer1[my_index-1]; } else if(BearsBuffer2[my_index-1] != EMPTY_VALUE){ bears = BearsBuffer2[my_index-1]; }
  // if(BullsBuffer1[my_index-1] != EMPTY_VALUE){ bulls = BullsBuffer1[my_index-1]; } else if(BullsBuffer2[my_index-1] != EMPTY_VALUE){ bulls = BullsBuffer2[my_index-1]; }
   
   
   int size1 = ArraySize(ExtLineBuffer);
   int size2 = ArraySize(dMA_Roundin);
   string abc = "";
   if(size1 > 3 && ShowComment){
      double speed1 = NormalizeDouble((MathAbs(ExtLineBuffer[size1-2]-ExtLineBuffer[size1-3])/ExtLineBuffer[size1-2])*100000, 0);
      abc = "MA_Round ma2: "+DoubleToString(ExtLineBuffer[size1-3], _Digits)
            + ", ma1: "+DoubleToString(ExtLineBuffer[size1-2], _Digits)
            + ", speed1: "+DoubleToString(speed1,0)
            + ", speed: "+DoubleToString(speed,0)
            + ", color: " + (string)ColorExtLineBuffer[size1-1]
               ;
      Comment(abc);
   }
   
   
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------
string getDirectionStr(double tf){
   if(tf == 0.0) return "做空";
   if(tf == 1.0) return "横盘";
   if(tf == 2.0) return "做多";
   return "错误";
}