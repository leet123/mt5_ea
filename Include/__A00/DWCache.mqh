//+-----------------------------------------------------------------------------------------
//| 缓存和全局变量,用于实时刷新数据,避免多次读取, 比如当前价格等
//+-----------------------------------------------------------------------------------------
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <__A00\Func.mqh>

//---固定值
const static int        Rates_total_max=1000;            //指标计算,最近需要参与计算的K线数
const static double     stop_open=0.8;                   //浮亏大于70%,禁止新开仓
const static int        Max_orderCount=30;               //同一品种同一macgic的最多持仓数量,一般不超过30个
const static int        boll_ma_type = 3;                //布林中线参数: 2.LinearWeightedMA, 3.SimpleMA, 4.SmoothedMA
const static int        EMPTY_INT_VALUE = 111111;
const static double     EMPTY_DOUBLE_VALUE = 0.000001;
const static datetime   EMPTY_DATETIME_VALUE = StringToTime("2000.01.01 01:00");
const static double     LOTS_001 = 0.01;
// 非固定值
static   long           magicNumber = 1;                 //魔法数,以小版本号作为, 默认1
static   bool           isCanRun = true;                             //如果不满足运行的条件，则为false
//---刷新订单锁: 0允许刷新订单,1不允许刷新订单
static   int            lock_readOrder = 0;
static   uint           orders_check_lastTicket = 0;        //订单上次检查时间
static   uint           orders_check_per = 2400000;         //固定周期检查订单,24分钟检查一次

string                  file_out;                  //文件,实时写入持仓列表
string                  file_out_java; 
bool                    isPrintLog = false;        //默认不打印日志
bool                    isSendEmail = false;       //默认不发生邮件
//---全局变量   
CAccountInfo            obj_account;               //账户对象
CSymbolInfo             obj_symbol;                //品种对象
CTrade                  obj_trade;                 //交易对象
CPositionInfo           obj_position;              //订单对象

string                  symbol_dw;
string                  arr_symbol[];              //已开仓的品种

string                  login_number;              //交易账户
string                  login_name;                //交易账户的姓名
string                  login_type;                //账户类型, 真实/模拟
string                  leverage;                  //杠杆

bool                    isOptimization;            //是否是优化模式
bool                    isTester;                  //是否是测试模式
bool                    isVisualMode;              //可视化测试模式

double                  dPoint;                    //比如报价为5位小数, 那么该值为0.00001
double                  dPoint2;                   //dPoint2=dPoint*iDigitsNum,用于计算
int                     iDigits;                   //报价小数位数, 比如5位
int                     iDigitsNum;                //用于价格(或价差)计算的中间变量, 如果小数位数是2或4,则该值为1, 否则为10
double                  dVolumeMin;                //允许交易的最小手数
int                     iVolumeMinDigits;          //允许交易的最小手数-小数位数

//---tick刷新
double                  ask;
double                  bid;

//---用于统计
double      cnt_max_accountBalance = 0.0;        //最大余额
double      cnt_min_accountEquity = 0.0;         //最小净值
double      cnt_min_accountBalance = 0.0;        //最小余额
double      cnt_max_backProfit = 0.0;            //最大回撤-净值
double      cnt_max_backBalance = 0.0;           //最大回测-余额
double      cnt_max_margin = 0.0;                //最大占用保证金
//+-----------------------------------------------------------------------------------------
//| 刷新数据,用于单个tick使用的数据
//+-----------------------------------------------------------------------------------------
void RefreshCache(){
   //
   if(!obj_symbol.RefreshRates()){
      MyPrint("RefreshRates 错误");
   }
   dPoint=_Point;
   ask = SymbolInfoDouble(symbol_dw,SYMBOL_ASK);
   bid = SymbolInfoDouble(symbol_dw,SYMBOL_BID);
}
//+-----------------------------------------------------------------------------------------
//| 初始化, 入口
//+-----------------------------------------------------------------------------------------
void InitGlobalInfo(string symbol_c, long magicNumber_c, bool isPrintLog_c, bool isSendEmail_c){
   //入参
   magicNumber = magicNumber_c;
   isPrintLog = isPrintLog_c;
   isSendEmail = isSendEmail_c;
   //
   symbol_dw = symbol_c;
   RefreshCache();
   //account
   login_number=(string)obj_account.Login();
   login_name=obj_account.Name();
   ENUM_ACCOUNT_TRADE_MODE account_type=obj_account.TradeMode();
   switch(account_type){
      case  ACCOUNT_TRADE_MODE_DEMO:
         login_type="live";
         break;
      case  ACCOUNT_TRADE_MODE_CONTEST:
         login_type="contest";
         break;
      case ACCOUNT_TRADE_MODE_REAL:
         login_type="LIVE";
         break; 
   }
   leverage=(string)obj_account.Leverage();

   //--- 如果是测试模式
   if(MQLInfoInteger(MQL_TESTER))
      isTester=true;
   else
      isTester=false;
   //--- 如果是优化模式
   if(MQLInfoInteger(MQL_OPTIMIZATION))
      isOptimization=true;
   else
      isOptimization=false;
   //--- 如果是可视化测试模式
   if(MQLInfoInteger(MQL_VISUAL_MODE))
      isVisualMode=true;
   else
      isVisualMode=false;

   //---symbol
   symbol_dw = _Symbol;
   obj_symbol.Name(symbol_dw);

   iDigits=obj_symbol.Digits();
   //这里默认所有品种都乘以10
   if(iDigits == 4){
      iDigitsNum=1;
   }else{
      iDigitsNum=10;
   }
   dPoint=_Point;
   dPoint2=dPoint*iDigitsNum;
   dVolumeMin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(dVolumeMin==0.001){
      iVolumeMinDigits=3;
   }else if(dVolumeMin==0.01){
      iVolumeMinDigits=2;
   }else if(dVolumeMin==0.1){
      iVolumeMinDigits=1;
   }else{
      iVolumeMinDigits=0;
   }

   //obj_trade_c, 注:magicNumber在下单时实时设置
   obj_trade.SetMarginMode();                          //保证金模式
   obj_trade.SetTypeFillingBySymbol(symbol_dw);        //品种
   obj_trade.SetDeviationInPoints(3*iDigitsNum);       //可接受的滑点

                                                       //非优化模式,打印初始化信息
   if(isOptimization==false){
      string strMsg="初始化数据: \n";
      strMsg+="login_number="+login_number;
      strMsg+=", login_name="+login_name;
      strMsg+=", login_type="+login_type;
      strMsg+=", leverage="+leverage;
      strMsg+=", isOptimization="+IntegerToString(isOptimization);
      strMsg+=", isTester="+IntegerToString(isTester);
      strMsg+=", isVisualMode="+IntegerToString(isVisualMode);
      strMsg+=", \nsymbol="+symbol_dw;
      strMsg+=", dPoint="+DoubleToString(dPoint, iDigits);
      strMsg+=", iDigits="+IntegerToString(iDigits);
      strMsg+=", iDigitsNum="+IntegerToString(iDigitsNum);
      strMsg+=", dVolumeMin="+DoubleToString(dVolumeMin, iVolumeMinDigits);
      strMsg+=", iVolumeMinDigits="+IntegerToString(iVolumeMinDigits);

      MyPrint(strMsg);
   }
}
//+-----------------------------------------------------------------------------------------
//| Method
//+-----------------------------------------------------------------------------------------
enum SM_Method{
   SM_SMMA, //SMMA
   SM_SMA,  //SMA
   SM_LWMA //LWMA
};
//+-----------------------------------------------------------------------------------------
//| 第一仓入场方式
//+-----------------------------------------------------------------------------------------
enum OP_FirstPosition{
   StrongTrend, //强单边
   LightTrend,  //弱单边
   ShockBack //横向后方   
};
//+-----------------------------------------------------------------------------------------
//| Channel指标的选择
//+-----------------------------------------------------------------------------------------
enum Channel_Type{
   Channel,
   Channel2
};
enum ENUM_TIMEFRAMES2{
   PERIOD_M1_,  //PERIOD_M1
   PERIOD_M5_, //PERIOD_M5
   PERIOD_M15_,   //PERIOD_M15
   PERIOD_M30_,   //PERIOD_M30
   PERIOD_H1_, //PERIOD_H1
   PERIOD_H4_  //PERIOD_H4
};
ENUM_TIMEFRAMES GetFrom2_Timeframe(ENUM_TIMEFRAMES2 tf){
   switch(tf){
      case PERIOD_M1_: return(PERIOD_M1);
      case PERIOD_M5_: return(PERIOD_M5);
      case PERIOD_M15_: return(PERIOD_M15);
      case PERIOD_M30_: return(PERIOD_M30);
      case PERIOD_H1_: return(PERIOD_H1);
      case PERIOD_H4_: return(PERIOD_H4);
      default: return(PERIOD_CURRENT);
   }
}
enum Smooth_Method2{
   MODE_SMA2,  //SMA
   MODE_EMA2,  //EMA
   MODE_SMMA2, //SMMA
   MODE_AMA2     //AMA
};
Smooth_Method GetFrom2_Method(Smooth_Method2 tf){
   switch(tf){
      case MODE_SMA2: return(MODE_SMA_);
      case MODE_EMA2: return(MODE_EMA_);
      case MODE_SMMA2: return(MODE_SMMA_);
      case MODE_AMA2: return(MODE_AMA);
      default: return(MODE_AMA);
   }
}
//+-----------------------------------------------------------------------------------------
//| 持仓对象: 主要用于实时平仓,记录订单
//+-----------------------------------------------------------------------------------------
struct MyOrder{
   ulong             magic;               //魔法数
   ulong             ticket;              //订单号
   double            volume;              //手数
   string            comment;             //订单备注
   double            profit;              //盈亏金额
   datetime          dOpTime;             //建仓时间
   double            dOpPrice;            //建仓价格
   double            slPrice;             //止损价
   double            tpPrice;             //止盈价
   double            swap;
   double            ma;
   double            round_ma;
   int               position;
};


//+-----------------------------------------------------------------------------------------
//| 是否等于0, 0.0, -0.0
//+-----------------------------------------------------------------------------------------
bool Is00(double num){
   if(num > -0.0000001 && num < 0.0000001) return true;
   return false;
}
//+-----------------------------------------------------------------------------------------
//| 打印日志
//+-----------------------------------------------------------------------------------------
void MyPrint(string strMsg){
   if(isOptimization==true){
      return;
   }
   Print("【"+symbol_dw+"-"+IntegerToString(magicNumber)+"】账户["+login_number+"]: "+strMsg);
}
void MySendEmail(string strMsg){
   if(isTester==true){
      return;
   }
   Print("【"+symbol_dw+"-"+IntegerToString(magicNumber)+"】账户["+login_number+"]: "+strMsg);
   if(isSendEmail){
      SendMail(strMsg, "【"+symbol_dw+"-"+IntegerToString(magicNumber)+"】账户["+login_number+"]: "+strMsg);
   }
}
//+--------------------------------------------------------------------------------------
//| 根据KN的时间: 柱线的开始时间
//+--------------------------------------------------------------------------------------
datetime GetKnTime(ENUM_TIMEFRAMES timeframe_c, int n){
   return GetKnTime(symbol_dw, timeframe_c, n);
}
//+------------------------------------------------------------------+ 
//| 创建文本标签                                                       | 
//+------------------------------------------------------------------+ 
bool LabelCreate(const long              chart_ID=0,               // 图表 ID 
                 const string            name="Label",             // 标签名称 
                 const int               sub_window=0,             // 子窗口指数 
                 const int               x=0,                      // X 坐标 
                 const int               y=0,                      // Y 坐标 
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // 图表定位角 
                 const string            text="Label",             // 文本 
                 const string            font="Arial",             // 字体 
                 const int               font_size=10,             // 字体大小 
                 const color             clr=clrRed,               // 颜色 
                 const double            angle=0.0,                // 文本倾斜 
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // 定位类型 
                 const bool              back=false,               // 在背景中 
                 const bool              selection=false,          // 突出移动 
                 const bool              hidden=true,              // 隐藏在对象列表 
                 const long              z_order=0)                // 鼠标单击优先 
  {
//--- 重置错误的值 
   ResetLastError();
//--- 创建文本标签 
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
     }
//--- 设置标签坐标 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- 设置相对于定义点坐标的图表的角 
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- 设置文本 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- 设置文本字体 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- 设置字体大小 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- 设置文本的倾斜角 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- 设置定位类型 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- 设置颜色 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- 显示前景 (false) 或背景 (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- 启用 (true) 或禁用 (false) 通过鼠标移动标签的模式 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- 在对象列表隐藏(true) 或显示 (false) 图形对象名称 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- 设置在图表中优先接收鼠标点击事件 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- 成功执行 
   return(true);
  }
  
//+-----------------------------------------------------------------------------------------
//| 从开始时间到目前的最高价/最低价,默认用5分钟计算(计算不包括头和尾,即不包括第一根和最后一根)
//| time_t:开始时间; type_t: 1表示获取最高价,-1表示获取最低价
//| 返回: 正常情况返回价格, 否则返回-1
//| eg: datetime dd = D'2018.07.02 10:46';
//|   double h1 = GetHLestPrice(Symbol(), dd, 1);
//|   double l1 = GetHLestPrice(Symbol(), dd, -1);
//| 由于iBarShift不支持优化和回撤,所以弃用该方法,改为续单方式
//+-----------------------------------------------------------------------------------------
double GetHLestPrice(string symbol_t,datetime time_t,int type_t)
  {
   ENUM_TIMEFRAMES tf=PERIOD_M5;
   //Print("h - index: "+TimeToString(time_t,TIME_DATE|TIME_MINUTES));
   int bar_index=iBarShift(symbol_t,tf,time_t,true);
   //Print("test----22:333:"+(string)type_t+ ", bar_index="+(string)bar_index);
   if(bar_index==-1){ return -1; }

//datetime bar_time=iTime(symbol,tf,bar_index);
//Print("bar_time="+TimeToString(bar_time,TIME_DATE|TIME_MINUTES));
//计算不包括开始时间所在柱子

   if(type_t==1)
     {
      double High[];
      ArraySetAsSeries(High,true);
      CopyHigh(symbol_t,tf,0,bar_index,High);
      int index=ArrayMaximum(High,0,bar_index);
      //Print("h - index: "+index);
      if(index < 0) return(-1);
      double Arr[];
      if(CopyHigh(symbol_t,tf,index,1,Arr)>0)
         return(Arr[0]);
      else return(-1);
        }else{
        //Print("test----22:333:");
      double Low[];
      ArraySetAsSeries(Low,true);
      CopyLow(symbol_t,tf,0,bar_index,Low);
      int index=ArrayMinimum(Low,0,bar_index);
      //Print("test----22:index:" + (string)index);
      if(index < 0) return(-1);
      double Arr[];
      if(CopyLow(symbol_t,tf,index,1,Arr)>0)
         return(Arr[0]);
      else return(-1);
     }
   return -1;
  }
/**
 * 授权验证
 */
bool myCheck(string key){
   long account_t = obj_account.Login();
   // || login_type == "live"
   if(isOptimization || isTester || account_t == 4290246 || account_t == 25289087){ return true; }
   //string account = "130289";
   string gened_key = "";          //解析后的账号
   string d_date = "";             //解析后的截止日期
   //string key = "ABAYHRWRARA_ADAHHNHHAN";   
   int index=StringFind(key,"_",0);
   //Print("test----------"+(string)index+", "+(string)isTester);
   if(index < 3){ return false; }
    //Print("test----------"+(string)index);
   string t = "";
   //解析账号
   string key_account = StringSubstr(key, 2, index-2);
   char key_arr[];
   int key_length = StringToCharArray(key_account, key_arr);
   
   for(int i=0; i<key_length; i++){
      t = CharToString(key_arr[i]);
      if(t == "") continue;
      gened_key = gened_key + getkey(t);
      Print("t="+t);
   }
   //Print("gened_key="+gened_key);
   //解析截止日期
   string my_date=StringSubstr(key,index+3);
   char d_arr[];
   int d_length = StringToCharArray(my_date, d_arr);
   
   for(int i=0; i<d_length; i++){
      t = CharToString(d_arr[i]);
      if(t == "") continue;
      d_date = d_date + getkey(t);
   }   
   Print("d_date = " + d_date);
   //获取当前日期字符串
   MqlDateTime current;
   TimeToStruct(TimeCurrent(),current);
   int year = current.year;
   int mon = current.mon;
   int day = current.day;
   string now = IntegerToString(year) + IntegerToString(mon) + IntegerToString(day);
   Print(now);
   //账号和日期, 前两位随意
   
   if(gened_key == IntegerToString((account_t + 8) * 68) && StringToInteger(d_date) > StringToInteger(now)){
      return true;
   }else{
      return false;
   }
}
string getkey(string k){
   if(k == "F") return "0";
   else if(k == "H") return "1";
   else if(k == "A") return "2";
   else if(k == "W") return "3";
   else if(k == "X") return "4";
   else if(k == "J") return "5";
   else if(k == "P") return "6";
   else if(k == "R") return "7";
   else if(k == "N") return "8";
   else if(k == "Y") return "9";
   else return "";
}
//+------------------------------------------------------------------+
