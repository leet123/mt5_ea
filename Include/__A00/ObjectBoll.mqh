//+-----------------------------------------------------------------------------------------
//| 指标计算, 以及指标相关的其他计算, 比如均线速度,加速度,方向等等
//+-----------------------------------------------------------------------------------------
#include <Object.mqh>
#include <__A00\DWCache.mqh>
//+-----------------------------------------------------------------------------------------
//| 指标计算类
//+-----------------------------------------------------------------------------------------
class ObjectBoll : public CObject{
public:
   //----输入变量
   ENUM_TIMEFRAMES   timeframe;
   SM_Method         method;
   int               bollMA;                   
   //----中间变量
   datetime          dtLastCalcIndTime;              //记录上次获取指标的时间
   //----Boll信息
   double            base_price;                        //中线价格,K1
   double            upper_price;                       //上线价格,K1
   double            lower_price;                       //下线价格,K1
   int               base_direction;                    //中线方向,向上为1,向下为-1,横向为0
   int               upper_direction;                   //上线方向,向上为1,向下为-1,横向为0
   int               lower_direction;                   //下线方向,向上为1,向下为-1,横向为0
   int               base_speed;                        //中线速度
   int               upper_speed;                       //上线速度
   int               lower_speed;                       //下线速度
   int               base_speed_r;                      //中线加速度,加速为1, 减速为-1, 匀速为0(可能性较小)
   int               upper_speed_r;                     //中线加速度,加速为1, 减速为-1, 匀速为0(可能性较小)
   int               lower_speed_r;                     //中线加速度,加速为1, 减速为-1, 匀速为0(可能性较小)

   //---指标句柄
   int               handle;
   //+-----------------------------------------------------------------------------------------
   //| 给参数赋值
   //+-----------------------------------------------------------------------------------------
   void InitParam(ENUM_TIMEFRAMES timeframe_c, SM_Method method_c, int bollMA_c){
      this.timeframe = timeframe_c;
      this.method = method_c;
      this.bollMA = bollMA_c;
      dtLastCalcIndTime =  GetKnTime(timeframe, 2);
      //初始化指标句柄
      if(method == SM_SMMA){
         handle = iCustom(symbol_dw, timeframe, "__A00\\BB_SMMA", bollMA);
      }else if(method == SM_SMA){
         handle = iCustom(symbol_dw, timeframe, "__A00\\BB_SMA", bollMA);
      }else if(method == SM_LWMA){
         handle = iCustom(symbol_dw, timeframe, "__A00\\BB_LWMA", bollMA);
      }
      
      string msg = "BB-Init: handle=" + (string)handle + ", \n" +
                 "timeframe=" + TFToString(timeframe) +
                 ", method="+(string)method + 
                 ", bollMA="+(string)bollMA
                 ;
      MyPrint(msg);
      
   }
   
   //+-----------------------------------------------------------------------------------------
   //| 打印指标值
   //+-----------------------------------------------------------------------------------------
   void PrintIndValue(){
      string msg="指标值:\n (boll)base_direction="+(string)base_direction+
                 ", upper_direction="+(string)upper_direction+
                 ", lower_direction="+(string)lower_direction+
                 ",\n base_speed="+(string)base_speed+
                 ", upper_speed="+(string)upper_speed+
                 ", lower_speed="+(string)lower_speed+
                 ",\n base_speed_r="+(string)base_speed_r+
                 ", upper_speed_r="+(string)upper_speed_r+
                 ", lower_speed_r="+(string)lower_speed_r+
                 ",\n base_price="+(string)base_price+
                 ", upper_price="+(string)upper_price+
                 ", lower_price="+(string)lower_price;
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
      double base_price_arr[];
      //--- 把指标值复制到数组中
      if(mytime == EMPTY_DATETIME_VALUE){
         if(CopyBuffer(handle, 0, 0, 10, base_price_arr) < 10){  //--- 如果数据少于所需
            MyPrint("指标EA_BB读取错误!-1");
            return false; //--- 退出函数
         }
      }else{
         if(CopyBuffer(handle, 0, mytime, 10, base_price_arr) < 10){  //--- 如果数据少于所需
            MyPrint("指标EA_BB读取错误!-2");
            return false; //--- 退出函数
         }
      }
      //--- 设置数组索引类似于时间序列（倒序）                                   
      if(!ArraySetAsSeries(base_price_arr, true)){
         MyPrint("指标EA_BB读取错误!-3");
         //--- 如果索引出错，退出函数
         return false;
      }
      //前面已经做了验证, 后面直接获取
      double upper_price_arr[];
      if(mytime == EMPTY_DATETIME_VALUE){
         CopyBuffer(handle, 1, 0, 10, upper_price_arr);
      }else{
         CopyBuffer(handle, 1, mytime, 10, upper_price_arr);
      }
      ArraySetAsSeries(upper_price_arr, true);
      
      double lower_price_arr[];
      if(mytime == EMPTY_DATETIME_VALUE){
         CopyBuffer(handle, 2, 0, 10, lower_price_arr);
      }else{
         CopyBuffer(handle, 2, mytime, 10, lower_price_arr);
      }
      ArraySetAsSeries(lower_price_arr, true);
            
      //价格,方向,速度
      base_price=base_price_arr[1];
      upper_price = upper_price_arr[1];
      lower_price = lower_price_arr[1];
      base_direction=0;
      if(base_price_arr[1]>base_price_arr[2]){ base_direction=1; } else if(base_price_arr[1]<base_price_arr[2]){ base_direction=-1; }
      upper_direction=0;
      if(upper_price_arr[1]>upper_price_arr[2]){ upper_direction=1; } else if(upper_price_arr[1]<upper_price_arr[2]){ upper_direction=-1; }
      lower_direction=0;
      if(lower_price_arr[1]>lower_price_arr[2]){ lower_direction=1; } else if(lower_price_arr[1]<lower_price_arr[2]){ lower_direction=-1; }
      base_speed=(int)((MathAbs(base_price_arr[1]-base_price_arr[2])/base_price_arr[2])*100000);
      upper_speed = (int)((MathAbs(upper_price_arr[1]-upper_price_arr[2])/upper_price_arr[2]) * 100000);
      lower_speed = (int)((MathAbs(lower_price_arr[1]-lower_price_arr[2])/lower_price_arr[2]) * 100000);
      //加速度计算
      int base_speed2=(int)((MathAbs(base_price_arr[2]-base_price_arr[3])/base_price_arr[3])*100000);
      int upper_speed2 = (int)((MathAbs(upper_price_arr[2]-upper_price_arr[3])/upper_price_arr[3]) * 100000);
      int lower_speed2 = (int)((MathAbs(lower_price_arr[2]-lower_price_arr[3])/lower_price_arr[3]) * 100000);
      base_speed_r=base_speed-base_speed2;
      upper_speed_r=upper_speed-upper_speed2;
      lower_speed_r=lower_speed-lower_speed2;
      //释放内存
      ArrayFree(base_price_arr);
      ArrayFree(upper_price_arr);
      ArrayFree(lower_price_arr);
     
      return(true);
   }
   
};
//+------------------------------------------------------------------+
