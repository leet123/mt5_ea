#include <__A00/SmoothAlgorithms.mqh> 
//+--------------------------------------------------------------------------------------
//| 根据KN的时间: 柱线的开始时间
//+--------------------------------------------------------------------------------------
datetime GetKnTime(string symbol_c, ENUM_TIMEFRAMES timeframe_c, int n){
   datetime dtK0Arr[]; //
   CopyTime(symbol_c, timeframe_c, 0, n+1, dtK0Arr);
   ArraySetAsSeries(dtK0Arr, true);
   if(ArraySize(dtK0Arr) < 1){
      return TimeCurrent();
   }
   datetime dTime_tmp=dtK0Arr[n];
   return dTime_tmp;
}
//+-----------------------------------------------------------------------------------------
//| 获取当前K线的开盘价, K0
//|   
//+-----------------------------------------------------------------------------------------
double GetOpenPrice_K0(string symbol_c, ENUM_TIMEFRAMES timeframe_c){
   double Open[];
   ArraySetAsSeries(Open,true);
   CopyOpen(symbol_c,timeframe_c,0,2,Open);
   return Open[0];
}
//+-----------------------------------------------------------------------------------------
//| 截取订单标签, 将得到B(多), S(空)
//|   参数：
//|      comment: 订单注释OrderComment().
//+-----------------------------------------------------------------------------------------
string GetTag(string strComment){
   string tag=StringSubstr(strComment,0,1);//方向B或S
   return tag;
}
//+-----------------------------------------------------------------------------------------
//| 截取订单标签, 将得到B(多), B_(锁多), S(空), S(锁空)_
//|   参数：
//|      comment: 订单注释OrderComment().
//+-----------------------------------------------------------------------------------------
/*
string GetTag2(string strComment){
   int index=StringFind(strComment,"_",0);
   string tag=StringSubstr(strComment,0,index);
   string tag2=StringSubstr(strComment,0,1);//方向B或S
   if(StringSubstr(tag,StringLen(tag)-1,1)=="_")
     {
      return tag2 + "_";
     }
   return tag2;
}*/
//+-----------------------------------------------------------------------------------------
//| 截取订单标签, B1,B2,S1,S2,B1_
//|   参数：
//|      comment: 订单注释OrderComment().
//+-----------------------------------------------------------------------------------------
string GetTagFull(string strComment){
   int index=StringFind(strComment,"_",0);
   string tag=StringSubstr(strComment,0,index);
   return tag;
}
//+-----------------------------------------------------------------------------------------
//| 根据秒获取周期字符串
//|   仅供参考: PeriodSeconds(), Period()
//+-----------------------------------------------------------------------------------------
string GetPeriodString(){
   return TFToString(TFMigrate((PeriodSeconds()/60)));
}
//+-----------------------------------------------------------------------------------------
//| 时间框架转换，方便优化
//+-----------------------------------------------------------------------------------------
int GetFrameTime(int timeframe_c)
  {
   switch(timeframe_c)
     {
      case 21:
         return 1;
      case 22:
         return 5;
      case 23:
         return 15;
      case 24:
         return 30;
      case 25:
         return 60;
      case 26:
         return 240;
      default:
         return timeframe_c;
     }
  }
//+-----------------------------------------------------------------------------------------
//| 时间框架的类型转换
//+-----------------------------------------------------------------------------------------
ENUM_TIMEFRAMES TFMigrate(int tf){
   switch(tf){
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);

      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);
      default: return(PERIOD_CURRENT);
   }
}
//+-----------------------------------------------------------------------------------------
//| 时间框架转字符串
//+-----------------------------------------------------------------------------------------
string TFToString(ENUM_TIMEFRAMES tf){
   switch(tf){
      case PERIOD_M1: return "PERIOD_M1";
      case PERIOD_M5: return "PERIOD_M5";
      case PERIOD_M15: return "PERIOD_M15";
      case PERIOD_M30: return "PERIOD_M30";
      case PERIOD_H1: return "PERIOD_H1";
      case PERIOD_H4: return "PERIOD_H4";
      case PERIOD_D1: return "PERIOD_D1";
      case PERIOD_W1: return "PERIOD_W1";
      case PERIOD_MN1: return "PERIOD_MN1";

      case PERIOD_M2: return "PERIOD_M2";
      case PERIOD_M3: return "PERIOD_M3";
      case PERIOD_M4: return "PERIOD_M4";
      case PERIOD_M6: return "PERIOD_M6";
      case PERIOD_M10: return "PERIOD_M10";
      case PERIOD_M12: return "PERIOD_M12";
      case PERIOD_H2: return "PERIOD_H2";
      case PERIOD_H3: return "PERIOD_H3";
      case PERIOD_H6: return "PERIOD_H6";
      case PERIOD_H8: return "PERIOD_H8";
      case PERIOD_H12: return "PERIOD_H12";
   }
   return "PERIOD_CURRENT";
}
//+-----------------------------------------------------------------------------------------
//| 字符串 -> 时间框架
//+-----------------------------------------------------------------------------------------
ENUM_TIMEFRAMES StringToTF(string tf){

   if(tf == "PERIOD_M1"){ return PERIOD_M1; }
   if(tf == "PERIOD_M5"){ return PERIOD_M5; }
   if(tf == "PERIOD_M15"){ return PERIOD_M15; }
   if(tf == "PERIOD_M30"){ return PERIOD_M30; }
   if(tf == "PERIOD_H1"){ return PERIOD_H1; }
   if(tf == "PERIOD_H4"){ return PERIOD_H4; }
   if(tf == "PERIOD_D1"){ return PERIOD_D1; }
   if(tf == "PERIOD_W1"){ return PERIOD_W1; }
   if(tf == "PERIOD_MN1"){ return PERIOD_MN1; }
   
   if(tf == "PERIOD_M2"){ return PERIOD_M2; }
   if(tf == "PERIOD_M3"){ return PERIOD_M3; }
   if(tf == "PERIOD_M4"){ return PERIOD_M4; }
   if(tf == "PERIOD_M6"){ return PERIOD_M6; }
   if(tf == "PERIOD_M10"){ return PERIOD_M10; }
   if(tf == "PERIOD_M12"){ return PERIOD_M12; }
   if(tf == "PERIOD_H2"){ return PERIOD_H2; }
   if(tf == "PERIOD_H3"){ return PERIOD_H3; }
   if(tf == "PERIOD_H6"){ return PERIOD_H6; }
   if(tf == "PERIOD_H8"){ return PERIOD_H8; }
   if(tf == "PERIOD_H12"){ return PERIOD_H12; }
  
   return PERIOD_CURRENT;
};

//+-----------------------------------+
//| string -> Smooth_Method
//+-----------------------------------+
Smooth_Method stringToSmooth_Method(string str){
   if(str == "MODE_SMA_"){ return MODE_SMA_; }
   if(str == "MODE_EMA_"){ return MODE_EMA_; }
   if(str == "MODE_SMMA_"){ return MODE_SMMA_; }
   if(str == "MODE_LWMA_"){ return MODE_LWMA_; }
   if(str == "MODE_JJMA"){ return MODE_JJMA; }
   if(str == "MODE_JurX"){ return MODE_JurX; }
   if(str == "MODE_ParMA"){ return MODE_ParMA; }
   if(str == "MODE_T3"){ return MODE_T3; }
   if(str == "MODE_VIDYA"){ return MODE_VIDYA; }
   if(str == "MODE_AMA"){ return MODE_AMA; }
  
   return MODE_SMA_;
}
//+-----------------------------------+
//| 价格
//+-----------------------------------+
/*
enum Applied_price_ {//常数型
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