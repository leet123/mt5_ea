//+---------------------------------------------------------------------+
//|                                             ColorX2MA-Parabolic.mq5 | 
//|                         Copyright �2010, Nikolay Kositsin + lukas1 | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+
//| 编译指标，请放置 SmoothAlgorithms.mqh 文件     |
//| 于目录: 客户端数据文件夹\MQL5\Include                 |
//+---------------------------------------------------------------------+
#property copyright "Copyright �2011, Nikolay Kositsin + lukas1"
#property link "farria@mail.redcom.ru"
//---- 指标版本号
#property version   "1.00"
//---- 绘制指标于主窗口
#property indicator_chart_window 
//---- 指标使用 6 个缓存区用于计算和绘图
#property indicator_buffers 2
//---- 仅使用 5 个绘图通道
#property indicator_plots   1
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- 绘制指标作为多色线
#property indicator_type1   DRAW_COLOR_LINE
//---- 使用以下颜色于 3 色线中
#property indicator_color1  Gray,Blue,Red
//---- 线型为实线
#property indicator_style1  STYLE_SOLID
//---- 指标线宽度 2
#property indicator_width1  2
//---- 显示指标标签
#property indicator_label1  "X2MA"

//+-----------------------------------+
//|  CXMA class description           |
//+-----------------------------------+
#include <__A00/SmoothAlgorithms.mqh> 
#include <__A00/Func.mqh> 
//+-----------------------------------+

//---- 声明 CXMA 类变量，定义在 SmoothAlgorithms.mqh 文件
CXMA XMA1,XMA2;
//+----------------------------------------------+
//| X2MA indicator input parameters              |
//+----------------------------------------------+
input Smooth_Method MA_Method1=MODE_SMA_; //第一个平滑方法 
input uint Length1=12; //第一个平滑深度                    
input int Phase1=15; //第一个平滑参数,
                     // 对于 JJMA 范围 -100 ... +100. 它影响平滑中间处理的品质;
// 对于 VIDIA 它是 CMO 周期, 对于 AMA 它是慢速平均周期
input Smooth_Method MA_Method2=MODE_JJMA; //第二个平滑方法 
input uint Length2=5; //第二个平滑深度 
input int Phase2=15;  //第二个平滑参数,
                      // 对于 JJMA 范围 -100 ... +100. 它影响平滑中间处理的品质;
// 对于 VIDIA 它是 CMO 周期, 对于 AMA 它是慢速平均周期
input Applied_price_ IPC=PRICE_CLOSE_;//价格常量
input int   ReverseSpeed = 5;    //转向速度
input bool  Email_Alert = false;  //是否邮件提醒
/* , 用于指标计算 ( 1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPL, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */

//+----------------------------------------------+

//---- 声明动态数组 
//---- 用于将来的指标缓存区
double X2MA[];
double ColorX2MA[];
//---- 
bool dirlong_,first_;
double ep_,start_,last_high_,last_low_;
//----声明数据计算开始的整数变量
int min_rates_total,min_rates_1,min_rates_2;
double                  dPoint2;
datetime                last_time;
double                  minutes ;
//+------------------------------------------------------------------   
//| X2MA indicator initialization function                           | 
//+------------------------------------------------------------------ 
void OnInit()
  {
//---- 初始化数据起始计算的变量
   min_rates_1=XMA1.GetStartBars(MA_Method1, Length1, Phase1);
   min_rates_2=XMA2.GetStartBars(MA_Method2, Length2, Phase2);
   min_rates_total=min_rates_1+min_rates_2+2;
//---- 设置外部参数无效数值报警
   XMA1.XMALengthCheck("Length1", Length1);
   XMA2.XMALengthCheck("Length2", Length2);
//---- 设置外部参数无效数值报警
   XMA1.XMAPhaseCheck("Phase1", Phase1, MA_Method1);
   XMA2.XMAPhaseCheck("Phase2", Phase2, MA_Method2);

//---- 设置动态数组作为指标缓存区
   SetIndexBuffer(0,X2MA,INDICATOR_DATA);
//---- 指标开始绘制的平移
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- 设置指标在图表中的不可见值
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- 设置动态数组作为颜色索引缓存区   
   SetIndexBuffer(1,ColorX2MA,INDICATOR_COLOR_INDEX);

//---- 创建显示在分离子窗口与悬浮提示的名字
   IndicatorSetString(INDICATOR_SHORTNAME,"X2MA");

//--- 设置指标的显示精度
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- 结束初始化

   last_time = GetKnTime(_Symbol, PERIOD_CURRENT, 0);
   minutes = PeriodSeconds();
  }
//+------------------------------------------------------------------ 
//| X2MA iteration function                                          | 
//+------------------------------------------------------------------ 
int OnCalculate(
                const int rates_total,    // 当前所有历史柱线数量
                const int prev_calculated,// 前一次计算的历史柱线数量
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
//---- 检查柱线数量是否足够计算
   if(rates_total<min_rates_total) return(0);

//double start,last_high,last_low;
//double ep,StepH,StepL;

//---- 声明浮点变量  
   double price_,x1xma,x2xma;
   double price_low,price_high;
   double ep,start,last_high,last_low;
//---- 声明证书变量并取得已计算的柱线数
   int gfirst,bar;
   bool dirlong,first;

//---- 计算循环重计算的第一个起始柱线号
   if(prev_calculated>rates_total || prev_calculated<=0) // 检查指标的第一个起始柱线号
     {
      gfirst=0; // 所有柱线的起始计算索引
      first_=false;
      dirlong_=false;
      last_high_=0.0;
      last_low_=999999999.0;
      ep_=close[min_rates_total-1];
      start_=0.0;
     }
   else gfirst=prev_calculated-1; // 计算新柱线起始索引

//---- 恢复变量值
   ep=ep_;
   start=start_;
   last_high=last_high_;
   last_low=last_low_;
   dirlong=dirlong_;
   first=first_;

//---- X2MA 指标的主计算循环
   for(bar=gfirst; bar<rates_total && !IsStopped(); bar++)
     {
      //---- 调用 PriceSeries 函数获得价格 price_
      price_=PriceSeries(IPC,bar,open,low,high,close);

      //---- 两次调用 XMASeries 函数。 
      //该 'begin' 参数在第二次调用时增加 min_rates_ 作为这是其它的 XMA 平滑  
      x1xma = XMA1.XMASeries( 0, prev_calculated, rates_total, MA_Method1, Phase1, Length1, price_, bar, false);
      x2xma = XMA2.XMASeries(min_rates_1, prev_calculated, rates_total, MA_Method2, Phase2, Length2,  x1xma, bar, false);
      //----       
      X2MA[bar]=x2xma;
     }

//---- correction of the first variable value
   if(prev_calculated>rates_total || prev_calculated<=0) // 检查指标的第一个起始柱线号
      gfirst=min_rates_total; //  所有柱线的起始计算索引

//---- X2MA 指标着色主循环
   double speed;
   for(bar=gfirst; bar<rates_total; bar++)
   {
      ColorX2MA[bar]=0; 
      if(X2MA[bar] > X2MA[bar-1]){
         speed = (MathAbs(X2MA[bar]-X2MA[bar-1])/X2MA[bar])*200000000/minutes;
         if(speed > ReverseSpeed){
            ColorX2MA[bar]=1;
         }
      }else if(X2MA[bar] < X2MA[bar-1]){
         speed = (MathAbs(X2MA[bar]-X2MA[bar-1])/X2MA[bar-1])*200000000/minutes;
         if(speed > ReverseSpeed){
            ColorX2MA[bar]=2;
         }
      }else{
         speed = 0;
      }
      if(bar == rates_total-1){
         Comment("speed=" + DoubleToString(speed, 2));
      }
   }
   //
  // Print(",,,,,,,,,,,,,,,,," + gfirst);
   int my_index = ArraySize(ColorX2MA)-1;
   datetime now = GetKnTime(_Symbol, PERIOD_CURRENT, 0);
   if(last_time < now && ColorX2MA[my_index-1] != ColorX2MA[my_index-2]){
      last_time = now;
      string oldDir = getDirectionStr(ColorX2MA[my_index-2]);
      string newDir = getDirectionStr(ColorX2MA[my_index-1]);
      string msg = "X2ma: " + _Symbol + ", " + (string)TFToString(Period()) + ", " + oldDir + " -> " + newDir + ", 转向速度: " + (string)ReverseSpeed  + ", 第一个平滑深度: " + (string)Length1 ;
      
      if(Email_Alert){
         Print(msg);
         SendMail(msg, msg);
      }
   } 

//---- 抛物线指标的主计算循环
   for(bar=gfirst; bar<rates_total; bar++)
     {
      price_low=X2MA[bar]-_Point;
      price_high=X2MA[bar]+_Point;
     
      //---- 保存变量值
      if(bar==rates_total-2)
        {
         ep_=ep;
         start_=start;
         last_high_=last_high;
         last_low_=last_low;
         dirlong_=dirlong;
         first_=first;
        }
     }

//---- 重新计算所有柱线的起始计算索引
   if(prev_calculated>rates_total || prev_calculated<=0)// 检查指标的第一个起始柱线号     
      gfirst++;

//----      
   return(rates_total);
  }
//+------------------------------------------------------------------
string getDirectionStr(double tf){
   if(tf == 0.0) return "横盘";
   if(tf == 1.0) return "做多";
   if(tf == 2.0) return "做空";
   return "错误";
}