//+-----------------------------------------------------------------------------------------
//| 指标计算, 以及指标相关的其他计算, 比如均线速度,加速度,方向等等
//+-----------------------------------------------------------------------------------------
#include <Object.mqh>
#include <__A00/DWCache.mqh>
#include <__A00/SmoothAlgorithms.mqh> 
//+-----------------------------------------------------------------------------------------
//| 指标计算类
//+-----------------------------------------------------------------------------------------
class ObjectMARoundingStdev : public CObject{
public:
   //----输入变量
   ENUM_TIMEFRAMES   timeframe;
   Smooth_Method XMA_Method; //平滑方法 
   int XLength; // 平滑深度
   //int XPhase=15;  // 平滑参数
   //--- 对于JJMA，在-100 ... +100范围内变化会影响过渡过程的质量;
   //--- 对于VIDIA而言，这是CMO时期，对于AMA来说，这是一个缓慢的移动时期
   //Applied_price_ IPC=PRICE_CLOSE_; // 价格常量
   uint MaRound; // 舍入因子
   //double dK1=1.5;  // 平方律滤波系数 1
   //double dK2=2.5;  // 平方律滤波系数 2
   //uint std_period=9; // 二次滤波周期
   double   ReverseSpeed;  //转向速度
  // bool  Email_Alert = false;  //是否邮件提醒
  // bool  ShowComment = false;  //是否显示Comment
//int Shift=0; // 平移
   //----中间变量
   int               sec;  //周期对应的秒数
   datetime          dtLastCalcIndTime;              //记录上次获取指标的时间
   //----指标信息
   double            ma;
   double            deviatePoint;     //偏离点数
   
   int               direction;        //指标方向(由指标得出,速度>N 才有方向)
   int               direction2;       //实际方向(速度>0才是方向)
   double            speed;        //速度   
   double            speed2;
   
   //---指标句柄
   int               handle;
   //+-----------------------------------------------------------------------------------------
   //| 给参数赋值
   //+-----------------------------------------------------------------------------------------
   void InitParam(ENUM_TIMEFRAMES   timeframe_c,
                  Smooth_Method XMA_Method_c,
                  int XLength_c,
                  uint MaRound_c,
                  double ReverseSpeed_c){
      this.timeframe = timeframe_c;
      this.XMA_Method = XMA_Method_c;
      this.XLength = XLength_c;
      this.MaRound = MaRound_c;
      this.ReverseSpeed = ReverseSpeed_c;
      
      sec = PeriodSeconds(timeframe);
      dtLastCalcIndTime =  GetKnTime(timeframe, 3);
      //初始化指标句柄
      handle = iCustom(symbol_dw, timeframe, "__A00\\MA_RoundingStdev",
		                    XMA_Method,
		                    XLength, 
		                    MaRound,
		                    ReverseSpeed,
		                    false,
		                    false
                       );
      
      string msg = "MA_RoundingStdev-Init: handle=" + (string)handle + ", \n" +
                 "timeframe=" + TFToString(timeframe) +
                 ", XMA_Method="+EnumToString(XMA_Method) +
                 ", XLength="+(string)XLength +
                 ", MaRound="+(string)MaRound + 
                 ", ReverseSpeed="+(string)ReverseSpeed
                 ;
      MyPrint(msg);
   } 
   //+-----------------------------------------------------------------------------------------
   //| 打印指标值
   //+-----------------------------------------------------------------------------------------
   void PrintIndValue(){
      string msg="MA_RoundingStdev:\n handle=" + (string)handle +
                 ", timeframe=" + TFToString(timeframe) + "(" + (string)timeframe + ")" +
                 ", direction="+(string)direction +
                 ", direction2="+(string)direction2 +
                 ", speed="+(string)speed +
                 ", speed2="+(string)speed2 +
                 ", ma="+DoubleToString(ma, iDigits) + 
                 ", deviatePoint="+DoubleToString(deviatePoint, 0)
                 ;
      MyPrint(msg);
   }
   //+-----------------------------------------------------------------------------------------
   //| 读取指定时间的指标信息, 警告: 在调用该方法后,整个对象的属性都发生了变化,所以要重新调用ReadInfoPeriod()获取最新属性
   //+-----------------------------------------------------------------------------------------
   bool ReadInfoByTime(datetime mytime){
      bool res = readIndInfo(mytime);
      dtLastCalcIndTime = mytime; //非常重要
      return res;
   }
   //+-----------------------------------------------------------------------------------------
   //| 按K线读取指标信息,每根K线执行一次
   //+-----------------------------------------------------------------------------------------
   bool ReadInfoPeriod(){
      return readIndInfo(EMPTY_DATETIME_VALUE);
   }
   //+-----------------------------------------------------------------------------------------
   //| 读取指标信息, 以及其他计算信息
   //| 注意:报价一般都是用Bid计算的,所以图表计算以Bid为主
   //+-----------------------------------------------------------------------------------------
   bool readIndInfo(datetime mytime){
      //控制执行频率,根据周期，每根柱子执行一次即可(根据时间获取除外)
      datetime dTime_tmp = GetKnTime(timeframe, 0);
      
      //MyPrint((string)dTime_tmp+"xxxxxxxxxxxxxxxxx" + (string)dtLastCalcIndTime);
      //获取指定时间的指标信息后，需要重置上次读取时间，以便下次继续按指标读取
      if(mytime != EMPTY_DATETIME_VALUE){
         dtLastCalcIndTime =  GetKnTime(timeframe, 2);
      }
      //按周期（实时）读取时，避免重复读取
      if(dtLastCalcIndTime == dTime_tmp && mytime == EMPTY_DATETIME_VALUE){
         return true; 
      }
      //执行频率控制
      dtLastCalcIndTime=dTime_tmp;
      
      //读取指标信息
      double arr_ma_value[];
      double arr_ma_color[];  //0下跌, 1横盘, 2上涨
      //--- 把指标值复制到数组中
      if(mytime == EMPTY_DATETIME_VALUE){
         int count = CopyBuffer(handle, 0, 0, 10, arr_ma_value);
         if(count < 10){  //--- 如果数据少于所需
            MyPrint("指标MA_RoundingStdev读取错误!-1, handle=" + (string)handle + ", Error=" + (string)GetLastError());
            dtLastCalcIndTime = EMPTY_DATETIME_VALUE;
            return false; //--- 退出函数
         }
         CopyBuffer(handle, 1, 0, 10, arr_ma_color);
      }else{
         if(CopyBuffer(handle, 0, mytime, 10, arr_ma_value) < 10){  //--- 如果数据少于所需
            MyPrint("指标MA_RoundingStdev读取错误!-2");
            dtLastCalcIndTime = EMPTY_DATETIME_VALUE;
            return false; //--- 退出函数
         }
         CopyBuffer(handle, 1, mytime, 10, arr_ma_color);
      }
      //--- 设置数组索引类似于时间序列（倒序）                                   
      if(!ArraySetAsSeries(arr_ma_value, true)){
         MyPrint("指标MA_RoundingStdev读取错误!-3");
         dtLastCalcIndTime = EMPTY_DATETIME_VALUE;
         //--- 如果索引出错，退出函数
         return false;
      }
      ArraySetAsSeries(arr_ma_color, true);
         
      /*   
      for(int a=0; a<10; a++){
         Print("testaaa: " + (string)arr_ma_value[a] + ", " + (string)arr_ma_color[a]);
      }*/
      
      //复制K1指标信息给变量
      ma = arr_ma_value[1] < EMPTY_DOUBLE_VALUE? EMPTY_DOUBLE_VALUE : arr_ma_value[1];
      //计算方向和速度
      direction = 0;
      if(arr_ma_color[1] == 0){ direction = -1; }
      else if(arr_ma_color[1] == 1){ direction = 0; }
      else if(arr_ma_color[1] == 2){ direction = 1; }
      //Print("arr_ma_color[0]: " + arr_ma_color[0] + "arr_ma_color[1]: " + arr_ma_color[1] + "arr_ma_color[2]: " + arr_ma_color[2] + ", dir="+direction);
      //
      speed = 0; direction2 = 0;
      if(arr_ma_value[1] > 0.000000001 && arr_ma_value[2] > 0.00000001){
         if(arr_ma_value[1] > arr_ma_value[2]){
            direction2 = 1;
            speed = NormalizeDouble((MathAbs(arr_ma_value[1]-arr_ma_value[2])/arr_ma_value[2])*100000, 0);
            if(arr_ma_value[2] > 0.000000001 && arr_ma_value[3] > 0.00000001){
               speed2 = NormalizeDouble((MathAbs(arr_ma_value[2]-arr_ma_value[3])/arr_ma_value[3])*100000, 0);
            }
         }else if(arr_ma_value[1] < arr_ma_value[2]){
            direction2 = -1;
            speed = NormalizeDouble((MathAbs(arr_ma_value[1]-arr_ma_value[2])/arr_ma_value[1])*100000, 0);
            if(arr_ma_value[2] > 0.000000001 && arr_ma_value[3] > 0.00000001){
               speed2 = NormalizeDouble((MathAbs(arr_ma_value[2]-arr_ma_value[3])/arr_ma_value[2])*100000, 0);
            }
         }
      }
      
      //if(isPrintLog){
      //   PrintIndValue();
      //}      
            
      //释放内存
      ArrayFree(arr_ma_value);
      ArrayFree(arr_ma_color);
      
      return(true);
   }
   //+-----------------------------------------------------------------------------------------
   //| 偏离点数, 需要实时计算
   //+-----------------------------------------------------------------------------------------
   void RefreshActualTime(){
      deviatePoint = NormalizeDouble(MathAbs(bid - ma) / dPoint2, 1);
   }
};
//+------------------------------------------------------------------+
