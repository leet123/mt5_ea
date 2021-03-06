//+-----------------------------------------------------------------------------------------
//| 指标计算, 以及指标相关的其他计算, 比如均线速度,加速度,方向等等
//+-----------------------------------------------------------------------------------------
#include <Object.mqh>
#include <__A00\DWCache.mqh>
//+-----------------------------------------------------------------------------------------
//| 指标计算类
//+-----------------------------------------------------------------------------------------
class ObjectChannel : public CObject{
public:
   //----输入变量
   ENUM_TIMEFRAMES   timeframe;
   int               range1;
   Channel_Type      channelType;               //channel, channel2
   //----中间变量
   datetime          dtLastCalcIndTime;              //记录上次获取指标的时间
   //----指标信息
   double            trailingUp;                        
   double            trailingDn; 
   double            trailingUp2;                        
   double            trailingDn2; 

   //---指标句柄
   int               handle;
   //+-----------------------------------------------------------------------------------------
   //| 给参数赋值
   //+-----------------------------------------------------------------------------------------
   void InitParam(ENUM_TIMEFRAMES timeframe_c, int range1_c, Channel_Type channelType_c){
      this.timeframe = timeframe_c;
      this.range1 = range1_c;
      this.channelType = channelType_c;
      dtLastCalcIndTime =  GetKnTime(timeframe, 2);
      
      //初始化指标句柄
      if(channelType == 0){
         handle = iCustom(symbol_dw, timeframe, "__A00\\EA_Channel", range1);
      }else{
         handle = iCustom(symbol_dw, timeframe, "__A00\\EA_Channel2", range1);
      }
      
      string msg = "Channel-Init: handle=" + (string)handle + ", \n" +
                 "timeframe=" + TFToString(timeframe) +
                 ", range1="+(string)range1 + 
                 ", channelType="+(string)channelType
                 ;
      MyPrint(msg);
      
   }
   
   //+-----------------------------------------------------------------------------------------
   //| 打印指标值
   //+-----------------------------------------------------------------------------------------
   void PrintIndValue(){
      string msg="Channel:\n handle=" + (string)handle +
                 ", timeframe=" + TFToString(timeframe) + "(" + (string)timeframe + ")" +
                 ", range1="+(string)range1 +
                 ",\n trailingUp="+DoubleToString(trailingUp, iDigits) +
                 ", trailingUp2="+DoubleToString(trailingUp2, iDigits) +
                 ", trailingDn="+DoubleToString(trailingDn, iDigits) +
                 ", trailingDn2="+DoubleToString(trailingDn2, iDigits)
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
      double trailing_up_price[];
      //--- 把指标值复制到数组中
      if(mytime == EMPTY_DATETIME_VALUE){
         if(CopyBuffer(handle, 0, 0, 10, trailing_up_price) < 10){  //--- 如果数据少于所需
            MyPrint("指标EA_Channel读取错误!-1");
            return false; //--- 退出函数
         }
      }else{
         if(CopyBuffer(handle, 0, mytime, 10, trailing_up_price) < 10){  //--- 如果数据少于所需
            MyPrint("指标EA_Channel读取错误!-2");
            return false; //--- 退出函数
         }
      }
      //--- 设置数组索引类似于时间序列（倒序）                                   
      if(!ArraySetAsSeries(trailing_up_price, true)){
         MyPrint("指标EA_Channel读取错误!-3");
         //--- 如果索引出错，退出函数
         return false;
      }
      //前面已经做了验证, 后面直接获取
      double trailing_dn_price[];
      if(mytime == EMPTY_DATETIME_VALUE){
         CopyBuffer(handle, 1, 0, 10, trailing_dn_price);
      }else{
         CopyBuffer(handle, 1, mytime, 10, trailing_dn_price);
      }
      ArraySetAsSeries(trailing_dn_price, true);
            
      //复制K1指标信息给变量
      trailingUp = trailing_up_price[1] == EMPTY_VALUE? EMPTY_DOUBLE_VALUE : trailing_up_price[1];
      trailingUp2 = trailing_up_price[2] == EMPTY_VALUE? EMPTY_DOUBLE_VALUE : trailing_up_price[2];
      trailingDn = trailing_dn_price[1] == EMPTY_VALUE? EMPTY_DOUBLE_VALUE : trailing_dn_price[1];
      trailingDn2 = trailing_dn_price[2] == EMPTY_VALUE? EMPTY_DOUBLE_VALUE : trailing_dn_price[2];
      
      //释放内存
      ArrayFree(trailing_up_price);
      ArrayFree(trailing_dn_price);
     
      return(true);
   }
   
};
//+------------------------------------------------------------------+
