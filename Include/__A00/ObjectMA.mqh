//+-----------------------------------------------------------------------------------------
//| 指标计算, 以及指标相关的其他计算, 比如均线速度,加速度,方向等等
//+-----------------------------------------------------------------------------------------
#include <Object.mqh>
#include <__A00/DWCache.mqh>
//+-----------------------------------------------------------------------------------------
//| 指标计算类
//+-----------------------------------------------------------------------------------------
class ObjectMA : public CObject{
public:
   //----输入变量
   ENUM_TIMEFRAMES   timeframe;
   int               inpMAPeriod;
   ENUM_MA_METHOD    inpMAMethod;
   double            reverseSpeed;        //转向速度
   //----中间变量
   int               sec;  //周期对应的秒数
   datetime          dtLastCalcIndTime;              //记录上次获取指标的时间
   //----指标信息
   double            ma;               //ma线值
   double            deviatePoint;     //偏离点数,绝对值
   
   int               direction;        //方向
   int               direction_last;   //前K的ma方向
   double            speed;        //速度
   double            speed_last;
   //---指标句柄
   int               handle;
   //+-----------------------------------------------------------------------------------------
   //| 给参数赋值
   //+-----------------------------------------------------------------------------------------
   void InitParam(ENUM_TIMEFRAMES   timeframe_c,
                  int               inpMAPeriod_c,
                  ENUM_MA_METHOD    inpMAMethod_c,
                  double            reverseSpeed_c){
      this.timeframe = timeframe_c;
      this.inpMAPeriod = inpMAPeriod_c;
      this.inpMAMethod = inpMAMethod_c;
      this.reverseSpeed = reverseSpeed_c;
      dtLastCalcIndTime =  GetKnTime(timeframe, 2);
      
      sec = PeriodSeconds(timeframe);
      
      //初始化指标句柄
      handle = iCustom(symbol_dw, timeframe, "__A00\\EA_MovingAverage",
		                    inpMAPeriod,
		                    0,
		                    inpMAMethod,
		                    reverseSpeed
                       );
      
      string msg = "MA: handle=" + (string)handle + ", \n" +
                 "timeframe=" + TFToString(timeframe) +
                 ", inpMAPeriod="+(string)inpMAPeriod +
                 ", inpMAMethod="+(string)inpMAMethod +
                 ", ReverseSpeed="+(string)reverseSpeed
                 ;
      MyPrint(msg);
   } 
   //+-----------------------------------------------------------------------------------------
   //| 打印指标值
   //+-----------------------------------------------------------------------------------------
   void PrintIndValue(){
      string msg="MA:\n handle=" + (string)handle +
                 ", timeframe=" + TFToString(timeframe) + "(" + (string)timeframe + ")" +
                 ", direction="+(string)direction +
                 ", direction_last="+(string)direction_last +
                 ", ma="+DoubleToString(ma, iDigits) + 
                 ", speed="+(string)speed + 
                 ", deviatePoint="+(string)deviatePoint
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
      double ma_arr_t[];
      //--- 把指标值复制到数组中
      if(mytime == EMPTY_DATETIME_VALUE){
         int count = CopyBuffer(handle, 0, 0, 10, ma_arr_t);
         if(count < 10){  //--- 如果数据少于所需
            MyPrint("指标MA读取错误!-1, handle=" + (string)handle);
            return false; //--- 退出函数
         }
      }else{
         if(CopyBuffer(handle, 0, mytime, 10, ma_arr_t) < 10){  //--- 如果数据少于所需
            MyPrint("指标MA读取错误!-2");
            return false; //--- 退出函数
         }
      }
      //--- 设置数组索引类似于时间序列（倒序）                                   
      if(!ArraySetAsSeries(ma_arr_t, true)){
         MyPrint("指标MA读取错误!-3");
         //--- 如果索引出错，退出函数
         return false;
      }
      
      //复制K1指标信息给变量
      ma = ma_arr_t[1] < EMPTY_DOUBLE_VALUE? EMPTY_DOUBLE_VALUE : ma_arr_t[1];
      
      //计算方向和速度
      direction = 0;
      speed = 0;
      if(ma_arr_t[1] > ma_arr_t[2]){
         speed = (MathAbs(ma_arr_t[1]-ma_arr_t[2])/ma_arr_t[1])*200000000/sec;
         if(speed > reverseSpeed){
            direction = 1;
         }
      }else if(ma_arr_t[1] < ma_arr_t[2]){
         speed = (MathAbs(ma_arr_t[1]-ma_arr_t[2])/ma_arr_t[2])*200000000/sec;
         if(speed > reverseSpeed){
            direction = -1;
         }
      }
      
      //计算方向和速度-last
      direction_last = 0;
      speed_last = 0;
      if(ma_arr_t[2] > ma_arr_t[3]){
         speed_last = (MathAbs(ma_arr_t[2]-ma_arr_t[3])/ma_arr_t[2])*200000000/sec;
         if(speed_last > reverseSpeed){
            direction_last = 1;
         }
      }else if(ma_arr_t[2] < ma_arr_t[3]){
         speed = (MathAbs(ma_arr_t[2]-ma_arr_t[3])/ma_arr_t[3])*200000000/sec;
         if(speed_last > reverseSpeed){
            direction_last = -1;
         }
      }
      
      //释放内存
      ArrayFree(ma_arr_t);
      
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
