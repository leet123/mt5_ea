//+-----------------------------------------------------------------------------------------
//| 指标计算, 以及指标相关的其他计算, 比如均线速度,加速度,方向等等
//+-----------------------------------------------------------------------------------------
#include <Object.mqh>
#include <__A00/DWCache.mqh>
#include <__A00/SmoothAlgorithms.mqh> 
//+-----------------------------------------------------------------------------------------
//| 指标计算类
//+-----------------------------------------------------------------------------------------
class ObjectX2ma : public CObject{
public:
   //----输入变量
   ENUM_TIMEFRAMES   timeframe;
   Smooth_Method     MA_Method1;
   uint              Length1;          
   int               Phase1;
   Smooth_Method     MA_Method2;
   uint              Length2;
   int               Phase2;
   Applied_price_    IPC;
   double            ReverseSpeed;        //转向速度
   //----中间变量
   int               sec;  //周期对应的秒数
   datetime          dtLastCalcIndTime;              //记录上次获取指标的时间
   //----指标信息
   double            x2ma;
   double            deviatePoint;     //偏离点数
   
   int               direction;
   int               direction_last;
   double            speed;        //速度
   double            speed_last;
   
   //---指标句柄
   int               handle;
   //+-----------------------------------------------------------------------------------------
   //| 给参数赋值
   //+-----------------------------------------------------------------------------------------
   void InitParam(ENUM_TIMEFRAMES   timeframe_c,
                  Smooth_Method MA_Method1_c,
                  uint Length1_c,
                  int Phase1_c,
                  Smooth_Method MA_Method2_c,
                  uint Length2_c,
                  int Phase2_c,
                  Applied_price_ IPC_c,
                  int ReverseSpeed_c){
      this.timeframe = timeframe_c;
      this.MA_Method1 = MA_Method1_c;
      this.Length1 = Length1_c;
      this.Phase1 = Phase1_c;
      this.MA_Method2 = MA_Method2_c;
      this.Length2 = Length2_c;
      this.Phase2 = Phase2_c;
      this.IPC = IPC_c;
      this.ReverseSpeed = ReverseSpeed_c;
      
      sec = PeriodSeconds(timeframe);
      dtLastCalcIndTime =  GetKnTime(timeframe, 2);
      
      //初始化指标句柄
      handle = iCustom(symbol_dw, timeframe, "__A00\\EA_x2ma",
		                    MA_Method1,
		                    Length1, 
		                    Phase1,
		                    MA_Method2,
		                    Length2,
		                    Phase2,
		                    IPC,
		                    ReverseSpeed,
		                    false
                       );
      
      string msg = "x2ma-Init: handle=" + (string)handle + ", \n" +
                 "timeframe=" + TFToString(timeframe) +
                 ", MA_Method1="+(string)MA_Method1 +
                 ", Length1="+(string)Length1 +
                 ", Phase1="+(string)Phase1 +
                 ", MA_Method2="+(string)MA_Method2 +
                 ", Length2="+(string)Length2 +
                 ", Phase2="+(string)Phase2 +
                 ", IPC="+(string)IPC+
                 ", ReverseSpeed="+(string)ReverseSpeed
                 ;
      MyPrint(msg);
   } 
   //+-----------------------------------------------------------------------------------------
   //| 打印指标值
   //+-----------------------------------------------------------------------------------------
   void PrintIndValue(){
      string msg="x2ma:\n handle=" + (string)handle +
                 ", timeframe=" + TFToString(timeframe) + "(" + (string)timeframe + ")" +
                 ", direction="+(string)direction +
                 ", direction_last="+(string)direction_last +
                 ", speed="+(string)speed +
                 ", speed_last="+(string)speed_last +
                 ", x2ma="+DoubleToString(x2ma, iDigits) + 
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
      if(dtLastCalcIndTime == dTime_tmp && mytime == EMPTY_DATETIME_VALUE){ 
         dtLastCalcIndTime =  GetKnTime(timeframe, 2);
         return true; 
      }
      //执行频率控制
      dtLastCalcIndTime=dTime_tmp;
      
      //读取指标信息
      double arr_ma_value[];
      //--- 把指标值复制到数组中
      if(mytime == EMPTY_DATETIME_VALUE){
         int count = CopyBuffer(handle, 0, 0, 10, arr_ma_value);
         if(count < 10){  //--- 如果数据少于所需
            MyPrint("指标x2ma读取错误!-1, handle=" + (string)handle);
            return false; //--- 退出函数
         }
      }else{
         if(CopyBuffer(handle, 0, mytime, 10, arr_ma_value) < 10){  //--- 如果数据少于所需
            MyPrint("指标x2ma读取错误!-2");
            return false; //--- 退出函数
         }
      }
      //--- 设置数组索引类似于时间序列（倒序）                                   
      if(!ArraySetAsSeries(arr_ma_value, true)){
         MyPrint("指标x2ma读取错误!-3");
         //--- 如果索引出错，退出函数
         return false;
      }
      //复制K1指标信息给变量
      x2ma = arr_ma_value[1] < EMPTY_DOUBLE_VALUE? EMPTY_DOUBLE_VALUE : arr_ma_value[1];
      //计算方向和速度
      direction = 0;
      speed = 0;
      if(arr_ma_value[1] > arr_ma_value[2]){
         speed = (MathAbs(arr_ma_value[1]-arr_ma_value[2])/arr_ma_value[1])*200000000/sec;
         if(speed > ReverseSpeed){
            direction = 1;
         }
      }else if(arr_ma_value[1] < arr_ma_value[2]){
         speed = (MathAbs(arr_ma_value[1]-arr_ma_value[2])/arr_ma_value[2])*200000000/sec;
         if(speed > ReverseSpeed){
            direction = -1;
         }
      }
      
      //计算方向和速度-last
      direction_last = 0;
      speed_last = 0;
      if(arr_ma_value[2] > arr_ma_value[3]){
         speed_last = (MathAbs(arr_ma_value[2]-arr_ma_value[3])/arr_ma_value[2])*200000000/sec;
         if(speed_last > ReverseSpeed){
            direction_last = 1;
         }
      }else if(arr_ma_value[2] < arr_ma_value[3]){
         speed_last = (MathAbs(arr_ma_value[2]-arr_ma_value[3])/arr_ma_value[3])*200000000/sec;
         if(speed_last > ReverseSpeed){
            direction_last = -1;
         }
      }
      
      //释放内存
      ArrayFree(arr_ma_value);
      
      return(true);
   }
   //+-----------------------------------------------------------------------------------------
   //| 偏离点数, 需要实时计算
   //+-----------------------------------------------------------------------------------------
   void RefreshActualTime(){
      deviatePoint = NormalizeDouble(MathAbs(bid - x2ma) / dPoint2, 1);
   }
};
//+------------------------------------------------------------------+
