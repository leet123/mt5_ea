//+-----------------------------------------------------------------------------------------
//| 指标计算, 以及指标相关的其他计算, 比如均线速度,加速度,方向等等
//+-----------------------------------------------------------------------------------------
#include <Object.mqh>
#include <__A00\DWCache.mqh>
//+-----------------------------------------------------------------------------------------
//| 指标计算类
//+-----------------------------------------------------------------------------------------
class ObjectSSL : public CObject{
public:
   //----输入变量
   ENUM_TIMEFRAMES   timeframe;
   int               period;                         
   //----中间变量
   datetime          dtLastCalcIndTime;              //记录上次获取指标的时间
   //----指标信息
   int               direction;
   double            upperSSL;                        
   double            lowerSSL;                       
   double            buySSL;                      
   double            sellSSL;
   int               upperSslSpeed;
   int               lowerSslSpeed;
   int               upperSslSpeedR;
   int               lowerSslSpeedR;

   //---指标句柄
   int               handle;
   //+-----------------------------------------------------------------------------------------
   //| 给参数赋值
   //+-----------------------------------------------------------------------------------------
   void InitParam(ENUM_TIMEFRAMES timeframe_c, int period_c){
      this.timeframe = timeframe_c;
      this.period = period_c;
      dtLastCalcIndTime =  GetKnTime(timeframe, 2);
      //初始化指标句柄
      handle = iCustom(symbol_dw, timeframe, "__A00\\EA_SSL", period);
   }
   
   //+-----------------------------------------------------------------------------------------
   //| 打印指标值
   //+-----------------------------------------------------------------------------------------
   void PrintIndValue(){
      string msg="SSL:\n handle=" + (string)handle +
                 ", timeframe=" + TFToString(timeframe) + "(" + (string)timeframe + ")" +
                 ", period="+(string)period +
                 ", direction="+(string)direction +
                 ",\n upperSSL="+DoubleToString(upperSSL, iDigits) +
                 ", buySSL="+DoubleToString(buySSL, iDigits) +
                 ", upperSslSpeed="+IntegerToString(upperSslSpeed) +
                 ", upperSslSpeedR="+IntegerToString(upperSslSpeedR) +
                 ",\n lowerSSL="+DoubleToString(lowerSSL, iDigits) +
                 ", sellSSL="+DoubleToString(sellSSL, iDigits) +
                 ", lowerSslSpeed="+IntegerToString(lowerSslSpeed) +
                 ", lowerSslSpeedR="+IntegerToString(lowerSslSpeedR)
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
      double upper_ssl_price[];
      //--- 把指标值复制到数组中
      if(mytime == EMPTY_DATETIME_VALUE){
         int count = CopyBuffer(handle, 0, 1, 3, upper_ssl_price);
         if(count < 3){  //--- 如果数据少于所需
            MyPrint("指标SSL读取错误!-1-" + (string)count + ", handle=" + (string)handle + ", size: " + (string)ArraySize(upper_ssl_price));
            return false; //--- 退出函数
         }
      }else{
         if(CopyBuffer(handle, 0, mytime, 3, upper_ssl_price) < 3){  //--- 如果数据少于所需
            MyPrint("指标SSL读取错误!-2");
            return false; //--- 退出函数
         }
      }
      //--- 设置数组索引类似于时间序列（倒序）                                   
      if(!ArraySetAsSeries(upper_ssl_price, true)){
         MyPrint("指标SSL读取错误!-3");
         //--- 如果索引出错，退出函数
         return false;
      }
      //前面已经做了验证, 后面直接获取
      double lower_ssl_price[];
      if(mytime == EMPTY_DATETIME_VALUE){
         CopyBuffer(handle, 1, 1, 3, lower_ssl_price);
      }else{
         CopyBuffer(handle, 1, mytime, 3, lower_ssl_price);
      }
      ArraySetAsSeries(lower_ssl_price, true);
      
      double buy_ssl_price[];
      if(mytime == EMPTY_DATETIME_VALUE){
         CopyBuffer(handle, 2, 1, 3, buy_ssl_price);
      }else{
         CopyBuffer(handle, 2, mytime, 3, buy_ssl_price);
      }
      ArraySetAsSeries(buy_ssl_price, true);
      
      double sell_ssl_price[];
      if(mytime == EMPTY_DATETIME_VALUE){
         CopyBuffer(handle, 3, 1, 3, sell_ssl_price);
      }else{
         CopyBuffer(handle, 3, mytime, 3, sell_ssl_price);
      }
      ArraySetAsSeries(sell_ssl_price, true);
      
      //复制K1指标信息给变量
      upperSSL = upper_ssl_price[0] == EMPTY_VALUE? EMPTY_DOUBLE_VALUE : upper_ssl_price[0];
      lowerSSL = lower_ssl_price[0] == EMPTY_VALUE? EMPTY_DOUBLE_VALUE : lower_ssl_price[0];
      buySSL = buy_ssl_price[0] == EMPTY_VALUE? EMPTY_DOUBLE_VALUE : buy_ssl_price[0];
      sellSSL = sell_ssl_price[0] == EMPTY_VALUE? EMPTY_DOUBLE_VALUE : sell_ssl_price[0];
      //direction
      if(upperSSL != EMPTY_DOUBLE_VALUE) direction = 1;
      else if(lowerSSL != EMPTY_DOUBLE_VALUE) direction = -1;
      //计算速度
      if(upper_ssl_price[0] != EMPTY_VALUE && upper_ssl_price[1] != EMPTY_VALUE){
         upperSslSpeed = (int)((MathAbs(upper_ssl_price[0]-upper_ssl_price[1])/upper_ssl_price[1])*100000);
      }else{
         upperSslSpeed = EMPTY_INT_VALUE;
      }
      if(lower_ssl_price[0] != EMPTY_VALUE && lower_ssl_price[1] != EMPTY_VALUE){
         lowerSslSpeed = (int)((MathAbs(lower_ssl_price[1]-lower_ssl_price[0])/lower_ssl_price[1])*100000);
      }else{
         lowerSslSpeed = EMPTY_INT_VALUE;
      }
      //计算加速度
      int upperSslSpeed2;
      if(upper_ssl_price[0] != EMPTY_VALUE && upper_ssl_price[1] != EMPTY_VALUE && upper_ssl_price[2] != EMPTY_VALUE){
         upperSslSpeed2 = (int)((MathAbs(upper_ssl_price[1]-upper_ssl_price[2])/upper_ssl_price[2])*100000);
         upperSslSpeedR = upperSslSpeed - upperSslSpeed2;
      }else{
         upperSslSpeedR = EMPTY_INT_VALUE;
      }
      int lowerSslSpeed2;
      if(lower_ssl_price[0] != EMPTY_VALUE && lower_ssl_price[1] != EMPTY_VALUE && lower_ssl_price[2] != EMPTY_VALUE){
         lowerSslSpeed2 = (int)((MathAbs(lower_ssl_price[2]-lower_ssl_price[1])/lower_ssl_price[2])*100000);
         lowerSslSpeedR = lowerSslSpeed - lowerSslSpeed2;
      }else{
         lowerSslSpeedR = EMPTY_INT_VALUE;
      }
      //释放内存
      ArrayFree(upper_ssl_price);
      ArrayFree(lower_ssl_price);
      ArrayFree(buy_ssl_price);
      ArrayFree(sell_ssl_price);
      
      return(true);
   }
   
};
//+------------------------------------------------------------------+
