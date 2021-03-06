//+------------------------------------------------------------------+
//|                                                DWaterEA_V2019.mq4|
//|                                2015-2019, litao Source Code Inc. |
//|                                                946115322@qq.comm |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2015-2019, litao Source Code Inc."
#property description "DWaterEA！"
#property description "-"
#property description "▲▲▲ 策略概要 ▲▲▲"
#property description "1.不提供强单边入场机会: "
#property description "1-1.强单边是危险的,因为目标和止损都不是明确的;"
#property description "1-2.强单边波动太快,仓位不易累积,利润低;"
#property description "1-3.强单边的行情是有限的,且强度各异,不易把握;"
#property description "1-3.天发板和地板基本都在强单边,在此入场容易被套劳;"

#property description "2.主要在横盘和弱单边行情入场"
#property description "QQ和微信：171137734(验证：EA)"

#include <__DWaterEA_V21\ObjectTactics.mqh>

//---------------------------------------------------------------------------

       string            KEY;

input       double            op_FirstLots = 0.01;                           //第一仓手数
input       double            op_LotsAdd = 0.01;                             //仓位递增
input       int               op_lotsGrid = 5;                       //仓位网格
input       int               op_NextGrid = 10;                           //补仓网格
input       int               op_TPPoint = 20;                             //止盈点数 
input       int               sLPoint = 100;                        //止损点数
input       double            op_SLProfit = 60;                            //止损金额
input       int               op_ctPoint;                             //续单点数
input       int               op_ltpPoint;                            //小止盈点数

input       ENUM_TIMEFRAMES2   tr_Timeframe;                //趋势时间框架 ------趋势分割线------
input       Smooth_Method2     tr_XMA_Method;                  //趋势 平滑方法 
input       int               tr_XLength;                     //趋势 平滑深度
input       uint              tr_MaRound;                     //趋势 舍入因子
input       double            tr_ReverseSpeed;                //趋势 转向速度

input       ENUM_TIMEFRAMES2   sg_Timeframe;                //交易时间框架 ------信号分割线------
input       Smooth_Method2     sg_XMA_Method;               //信号 平滑方法 
input       int               sg_XLength;                  //信号 平滑深度
input       uint              sg_MaRound;                  //信号 舍入因子
input       double            sg_ReverseSpeed;             //信号 转向速度


input       int              Paramseconds = 300;            //参数刷新频率(秒)----分割线----
input       long             MagicNumber = 861;                     //唯一魔法数
input       bool             IsPrintLog = false;                    //是否打印日志
input       bool             IsSendEmail = false;                   //是否发送邮件
input       bool             b_IsOpen = false;                       //是否开仓-多
input       bool             s_IsOpen = false;                       //是否开仓-空
input       OP_FirstPosition  FirstPosition = StrongTrend;                  //第一仓位置
input       bool             isSignalOpenOnlyOne = true;             //是否每个信号只开一次
input       double           MaxLots = 0.3;                          //最大手数限制
input       double           Max_back = 0.0;                  //优化接受的最大回撤（余额）
//---EA版本
string      EA_name="Dwater";    //EA名称版本
string      EA_version="V20";
//---掉线检测,允许控制,执行时间控制
bool        IsHasSendEmailOfDisconnect = false;          //记录掉线后是否已发邮件
datetime    lastDisconnectTime;                          //记录最近掉线时间,超过10分钟邮件提醒
bool        isThisConnect = true;                        //网络是否连接正常
bool        isHourHasLocked = false;                     //根据时间设置，不执行
bool        isHourNotRunHasPrint = false;                //根据时间设置，不执行
bool        optFail = false;
//---指标对象,策略对象
bool                             isOpenTimer = false;           //只有在tick执行一次,才开启timer
ObjectMARoundingStdev            objSignal;              //信号,用于入场判断
ObjectMARoundingStdev            objMARound;
ObjectTactics                    objTacticsBuy;
ObjectTactics                    objTacticsSell;
//---其他变量
bool              isTickEnd=true;         //保证Tick按次序执行
int               lastOrdersTotal;        //上次的订单总数
ulong             lastOrderTicket;        //上次订单列表中最新一仓订单号
//+-----------------------------------------------------------------------------------------
//| 初始化
//+-----------------------------------------------------------------------------------------
int OnInit(void){
   /*
   if(myCheck(KEY) == false){ 
      isCanRun=false; 
      Alert("请联系管理员授权(微信QQ:171137734),或查看文档说明.");
      MyPrint("授权失败");
      return(INIT_SUCCEEDED);
   }*/
   Print("授权成功");
   uint tiks=GetTickCount();
   isCanRun=false; //在初始化完成之前不允许EA运行
   // 运行环境检查
   if(false==CheckRunEnvironmentOnInt()){
      isCanRun=false;
      return INIT_SUCCEEDED;
   }
   // 初始化全局数据,入参(避免修改参数或调整时间框架时重复加载参数)
   InitGlobalInfo(_Symbol, MagicNumber, IsPrintLog, IsSendEmail);  //初始化全局
   InitObjectParams(); //加载交易对象和指标对象
   
   // 只在 非优化模式 显示
   if(isOptimization==false){
      //开启定时器,10分钟执行一次
      EventSetTimer(Paramseconds);
      //EventSetMillisecondTimer(ParamMilliseconds); //毫秒
      if(isTester == false){ 
         LabelCreate(0,"bg0001",0,2,25,CORNER_LEFT_UPPER,"g","Webdings",250,
                  clrBlack,0.0,ANCHOR_LEFT_UPPER,false,false,false,0);
      }      
   }
   // 初始化成功,可以运行
   isCanRun=true;
   uint tiks2=GetTickCount();
   MyPrint("OnInit执行用时: "+(string)(tiks2-tiks));
   //立刻执行获取信息
   OnTick();
   //MyPrint("OnInit执行完成, 并执行Tick一次!");
   //重绘图表,为了初始化加载文字对象
   ChartRedraw();
   
   return(INIT_SUCCEEDED);
}
//+-----------------------------------------------------------------------------------------
//| 检查允许环境,初始化时
//+-----------------------------------------------------------------------------------------
bool CheckRunEnvironmentOnInt(){
   if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)==false){
      Alert("未开启和允许交易！");
      return false;
   }
   double dMinLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);           //允许交易的最小手数。
   if(dMinLot!=0.01){
      Alert("该平台最小不支持0.01手交易！");
      return false;
   }

   return true;
  }
//+-----------------------------------------------------------------------------------------
//| 初始化或重新加载交易对象,以及指标
//+-----------------------------------------------------------------------------------------
void InitObjectParams(){
   // 交易对象赋值
   objTacticsBuy.InitParam(1, "B", FirstPosition, op_FirstLots, op_LotsAdd, op_lotsGrid, op_NextGrid, op_TPPoint, sLPoint, op_SLProfit, op_ctPoint, op_ltpPoint, MaxLots);
   objTacticsSell.InitParam(-1, "S", FirstPosition, op_FirstLots, op_LotsAdd, op_lotsGrid, op_NextGrid, op_TPPoint, sLPoint, op_SLProfit, op_ctPoint, op_ltpPoint, MaxLots);   
   objSignal.InitParam(GetFrom2_Timeframe(sg_Timeframe), GetFrom2_Method(sg_XMA_Method), sg_XLength, sg_MaRound, sg_ReverseSpeed);
   objMARound.InitParam(GetFrom2_Timeframe(tr_Timeframe), GetFrom2_Method(tr_XMA_Method), tr_XLength, tr_MaRound, tr_ReverseSpeed);
}

//+-----------------------------------------------------------------------------------------
//| 定时器执行
//+-----------------------------------------------------------------------------------------
void OnTimer(){
   //tick不执行,则timer不开启
   if(isOpenTimer == false && isTester){ return; }
   
   //根据频率设置检查订单
   uint orders_check_ticket = GetTickCount();
   if(orders_check_ticket-orders_check_lastTicket>orders_check_per){
      if(IsOrderChange()){
         lock_readOrder = 0;    //每隔段时间开启一次订单刷新,避免死锁(尤其是周末)
      }
   }
   if(!isTester){
      //监控是否掉线，如果掉线超过10分钟，发邮件提醒
      bool isConnected=TerminalInfoInteger(TERMINAL_CONNECTED);
      if(isConnected==0){
         if(IsHasSendEmailOfDisconnect==false && TimeCurrent()-lastDisconnectTime>600){
            MySendEmail("账户已经有一段时间没有连接到服务器!");
            IsHasSendEmailOfDisconnect=true;
         }
      }
      if(isConnected==0 && isThisConnect==true){
         lastDisconnectTime=TimeCurrent();
         IsHasSendEmailOfDisconnect=false;
         isThisConnect=false;
         return;
      }else if(isConnected==0 && isThisConnect==false){
         return;
      }else{
         lastDisconnectTime=TimeCurrent();
         IsHasSendEmailOfDisconnect=false;
         isThisConnect=true;
      }
   }   
    
}
//+------------------------------------------------------------------+ 
//| 当Trade事件到达时被调用                                             | 
//+------------------------------------------------------------------+ 
void OnTrade(){
   //只要有订单变化，就可以重新读取订单
   lock_readOrder = 0; 
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   //当tick开始时,才允许timer执行
   if(isOpenTimer == false){
      isOpenTimer = true;
   }
   // 保证tick执行一轮,避免重复下单,或订单刷新不及时(提醒: onTick()中的返回时,必须重置该标记)
   if(isTickEnd==false){ return; }   
   isTickEnd=false;
   // 运行环境如果不满足，则禁止运行下面的代码
   if(isCanRun==false){ isTickEnd=true; return; }
   
   if((isTester || isOptimization) && optFail){
      double ask_ = SymbolInfoDouble(symbol_dw,SYMBOL_ASK);
      double bid_ = SymbolInfoDouble(symbol_dw,SYMBOL_BID);
      //强制亏损,逆势开仓,为的是不让优化程序统计出结果
      if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) > 5.0){
         double a;
         MqlTradeCheckResult check;
         double sl = 0.0;
         int total = PositionsTotal();
         if(total == 0){
            if(objMARound.direction2 == -1){
               double price=ask_;
               sl = bid_ - 10*dPoint2;
               for(a = 1; a > 0.0; a=a-0.01){
                  //---- 检查的交易请求正确性
                  if(obj_account.FreeMarginCheck(symbol_dw, ORDER_TYPE_BUY, a, price) > 0.0){
                     obj_trade.PositionOpen(symbol_dw,ORDER_TYPE_BUY,a,price, 0.0, 0.0, "");
                     //break;
                  }
               }
            }else{
               double price=bid_;
               sl = ask_ + 10*dPoint2;
               for(a = 1; a > 0.0; a=a-0.01){
                  if(obj_account.FreeMarginCheck(symbol_dw, ORDER_TYPE_SELL, a, price) > 0.0){
                     obj_trade.PositionOpen(symbol_dw,ORDER_TYPE_SELL,a,price, 0.0, 0.0, "");
                     //break;
                  }
               }
            }
         }
      }
      //如果可用保证金小于0,平仓全部,用于优化过滤利润
      /*
      if(AccountInfoDouble() < 5.0){
         objTacticsBuy.CloseOrder("B");
         objTacticsSell.CloseOrder("S");
      }*/
      double dProfit_t = 0.0;
      for(int i=PositionsTotal()-1; i>=0; i--){
         if(obj_position.SelectByIndex(i)==false) continue;
         ENUM_POSITION_TYPE iOrderType=obj_position.PositionType();    // 持仓类型
         bool is_sl = false;
         if(iOrderType==POSITION_TYPE_BUY){
         //Print(obj_position.Ticket() + ",a, "+ is_sl + ", " + obj_position.PriceOpen() +", " + ask_ + ", " + DoubleToString(dPoint2,5) + ", " );
            if(obj_position.PriceOpen()-bid_ > 10*dPoint2 || bid_-obj_position.PriceOpen() > 30*dPoint2){
               is_sl = true;
            }
         }else if(iOrderType==POSITION_TYPE_SELL){
         //Print(obj_position.Ticket() + ",b, "+ is_sl + ", " + obj_position.PriceOpen() +", " + ask_ + ", " + DoubleToString(dPoint2,5) + ", " );
            if(ask_-obj_position.PriceOpen() > 10*dPoint2 || obj_position.PriceOpen()-ask_ > 30*dPoint2){
               is_sl = true;
            }
         }
       
         if(is_sl){
            obj_trade.PositionClose(obj_position.Ticket());
         }
      }
      isTickEnd=true;
      return; 
   }
   
   // 刷新缓存
   RefreshCache();
   
   // 刷新指标信息
   objMARound.ReadInfoPeriod();
   objSignal.ReadInfoPeriod();
   
   objMARound.RefreshActualTime();
   objSignal.RefreshActualTime();
   
   // 读取订单 
   if(lock_readOrder == 0){
      ReadOrders();
      lock_readOrder = 1; //标记为已读取订单
   }
   // 读取之后处理: 平仓计算
   if(objTacticsBuy.res_trade==false) { objTacticsBuy.res_trade=objTacticsBuy.MyClose(objMARound, objSignal); }
   if(objTacticsSell.res_trade==false) { objTacticsSell.res_trade=objTacticsSell.MyClose(objMARound, objSignal); }
   //Print("abc");
   // 图表打印信息
   PrintInfoToChart();
   
   // 记录账户情况, 优化管理
   if(CountInfo() == false){
      isTickEnd=true;
      return;
   }
   
   // 开仓
   if(objTacticsBuy.res_trade==false){
      objTacticsBuy.res_trade = objTacticsBuy.MyOpen(objMARound, objSignal, b_IsOpen, isSignalOpenOnlyOne); 
   }
   if(objTacticsSell.res_trade==false){
      objTacticsSell.res_trade = objTacticsSell.MyOpen(objMARound, objSignal, s_IsOpen, isSignalOpenOnlyOne); 
   }
   
   isTickEnd=true;
}
//+-----------------------------------------------------------------------------------------
//| 记录账户情况, 以及优化回撤情况
//+-----------------------------------------------------------------------------------------
bool CountInfo(){
   // 记录最大占用保证金
   double margin=AccountInfoDouble(ACCOUNT_MARGIN);
   if(margin > cnt_max_margin){
      if(isOptimization==false && isTester){
         MyPrint("M保证金-更新, cnt_max_margin: "+DoubleToString(margin,2)+", 时间："+TimeToString(TimeCurrent(),TIME_DATE)+" "+TimeToString(TimeCurrent(),TIME_MINUTES));
      }
      cnt_max_margin=margin;
   }
   // 账号情况记录
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   // 记录最大余额, 在最大余额刷新时, 重置最小净值和最小余额
   if(balance > cnt_max_accountBalance){
      cnt_max_accountBalance = balance;
      cnt_min_accountEquity = 0.0;
      cnt_min_accountBalance = 0.0;
   }
   // 实时记录最小净值
   if(cnt_min_accountEquity == 0.0 || cnt_min_accountEquity > equity){
      cnt_min_accountEquity = equity;
   }
   // 实时计算最大净值回撤
   double backProfit = cnt_max_accountBalance - cnt_min_accountEquity;
   if(backProfit > cnt_max_backProfit){
      if(isOptimization == false && isTester && backProfit - cnt_max_backProfit > 10.0){
         MyPrint("最大回测-净值-更新, cnt_max_backProfit: "+DoubleToString(backProfit,2)+", 时间："+TimeToString(TimeCurrent(),TIME_DATE)+" "+TimeToString(TimeCurrent(),TIME_MINUTES));
      }
      cnt_max_backProfit = backProfit;
   }
   // 实时记录最小余额
   if(cnt_min_accountBalance == 0.0 || cnt_min_accountBalance > balance){
      cnt_min_accountBalance=balance;
   }
   // 实时计算最大余额回撤
   double backBalance = cnt_max_accountBalance - cnt_min_accountBalance;
   if(backBalance > cnt_max_backBalance){
      if(isOptimization == false && isTester && backBalance-cnt_max_backBalance > 10.0){
         MyPrint("最大回测-余额-更新, cnt_max_backBalance: "+DoubleToString(backBalance,2)+", 时间："+TimeToString(TimeCurrent(),TIME_DATE)+" "+TimeToString(TimeCurrent(),TIME_MINUTES));
      }
      cnt_max_backBalance = backBalance;
   }
   //优化过滤
   if((isOptimization) && Max_back > 0.00000000001){
      if(cnt_max_backProfit > Max_back){
         optFail = true;
         Print("回撤过大!");
      }
   }   
   //
   if(equity < 5.0 && isOptimization == false){
      MyPrint("账户净值小于5美金，禁止开仓！");
      if(balance < 5.0){
         MyPrint("账户余额小于5美金，EA停止执行！");
         isCanRun=false;    //不再执行
      }
      return false;
   }else if(equity < 5.0 && isOptimization){
      objTacticsBuy.CloseOrder("B");
      objTacticsSell.CloseOrder("S");
      isCanRun = false;
      return false;
   }else if(obj_account.FreeMargin() < 5.0 && isOptimization){
      objTacticsBuy.CloseOrder("B");
      objTacticsSell.CloseOrder("S");
      isCanRun = false;
      return false;
   }
   
   return true;
}
//+-----------------------------------------------------------------------------------------
//| 读取订单和指标，止盈止损，实时监控
//+-----------------------------------------------------------------------------------------
void ReadOrders(){
   string strComment;      double dOpenPrice;
   double dOrderProfit;    string strOrderSymbol;
   long iOrderMagicNumber;
   // 1.读取订单前先重置变量
   objTacticsBuy.GetOrders_1();
   objTacticsSell.GetOrders_1();

   // 2.开始读取订单   
   string tag;
   for(int cnt=PositionsTotal()-1; cnt>=0; cnt--){
      if(obj_position.SelectByIndex(cnt)==false) continue;
      strOrderSymbol=obj_position.Symbol();
      iOrderMagicNumber=obj_position.Magic();
      //只接口EA订单
      if(strOrderSymbol != symbol_dw || iOrderMagicNumber != magicNumber) continue;
      //
      ENUM_POSITION_TYPE iOrderType=obj_position.PositionType();
      strComment=obj_position.Comment();   dOpenPrice=obj_position.PriceOpen();   dOrderProfit=obj_position.Profit();
      //人工下单处理
      if(iOrderMagicNumber == 0){
         if(iOrderType == POSITION_TYPE_BUY){
            strComment = "B0,0";
         }else if(iOrderType == POSITION_TYPE_SELL){
            strComment = "S0,0";
         }
      }
      //2.按策略分别读取订单
      tag = GetTag(strComment);
      if(tag == "B"){
         objTacticsBuy.GetOrders_2(iOrderMagicNumber, strComment,obj_position.Volume(),obj_position.Time(),dOpenPrice,obj_position.Ticket(),dOrderProfit, obj_position.StopLoss(), obj_position.TakeProfit(), obj_position.Swap());
      }else if(tag == "S"){
         objTacticsSell.GetOrders_2(iOrderMagicNumber, strComment,obj_position.Volume(),obj_position.Time(),dOpenPrice,obj_position.Ticket(),dOrderProfit, obj_position.StopLoss(), obj_position.TakeProfit(), obj_position.Swap());
      } 
   }
   objTacticsBuy.res_trade = false;
   objTacticsBuy.GetOrders_3(objMARound, objSignal);
   objTacticsSell.res_trade = false;
   objTacticsSell.GetOrders_3(objMARound, objSignal);
}
  //+-----------------------------------------------------------------------------------------
  //| 打印信息到窗口
  //+-----------------------------------------------------------------------------------------
  void ShowMsg(int index, string msg, color clr){
   string name = "Label000" + (string)index;
   int y = 40 + index * 18;
  // LabelCreate(0,name,0,10,y,CORNER_LEFT_UPPER,msg,"宋体",9,
  //             clr,0.0,ANCHOR_LEFT_LOWER,false,false,true,0);
   
   LabelCreate(0,name,0,10,y,CORNER_LEFT_UPPER,msg,"宋体",9,
               clr,0.0,ANCHOR_LEFT_LOWER,false,false,false,0);
               
               
  }
  //+-----------------------------------------------------------------------------------------
  //| 判读订单是否发生变化
  //+-----------------------------------------------------------------------------------------
   bool IsOrderChange(){
      bool flag = false;
      int ordersTotal_t = PositionsTotal();
      ulong lastTicket_t = 0;
      for(int cnt=ordersTotal_t-1; cnt>=0; cnt--){
         if(obj_position.SelectByIndex(cnt)==false) continue;
         lastTicket_t = obj_position.Ticket();
         break;
      }
      //
      if(ordersTotal_t != lastOrdersTotal || lastTicket_t != lastOrderTicket){
         flag = true;
      }
      lastOrdersTotal = ordersTotal_t;
      lastOrderTicket = lastTicket_t;
      
      return flag;
   }
//+-----------------------------------------------------------------------------------------
//| 打印信息到窗口
//+-----------------------------------------------------------------------------------------
void PrintInfoToChart(){
//---优化模式，以下不执行
   if(isOptimization==true){ return; }
   if(isTester){ return; }
   //LabelCreate(0,"bg0001",0,2,25,CORNER_LEFT_UPPER,"g","Webdings",250,
   //            clrBlack,0.0,ANCHOR_LEFT_UPPER,false,false,false,0);
   string tmp = "";
   
   ShowMsg(1, "杠杆: " + leverage + ",  点差: " + (string)((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)/10) + ", dPont2: " + DoubleToString(dPoint2,iDigits), clrWhite);
  
   ShowMsg(2, "--------------------------------------------------", clrWhite);
   ShowMsg(3, "【指标】: ", clrWhite);
   ShowMsg(4, "TR: 指标方向:" + (string)objMARound.direction + ", 实际方向："+ (string)objMARound.direction2 + ", 速度:" + (string)objMARound.speed + ", 偏离:" + DoubleToString(objMARound.deviatePoint,1), clrWhite);
   ShowMsg(5, "SG: 指标方向:" + (string)objSignal.direction + ", 实际方向："+ (string)objSignal.direction2 + ", 速度:" + (string)objSignal.speed + ", 偏离:" + DoubleToString(objSignal.deviatePoint,1), clrWhite);
         
   ShowMsg(6, "  ", clrWhite);
   ShowMsg(7, "【多单】: - ", clrWhite);
   ShowMsg(8, "实时: 浮盈：" + DoubleToString(objTacticsBuy.dProfit,2) + ", 数量: " + IntegerToString(objTacticsBuy.iVolumeCount) + ", 持仓:" + DoubleToString(objTacticsBuy.dVolumeIn,2) + ", 已平仓：" + DoubleToString(objTacticsBuy.dHasClosedProfit,2), clrWhite);
   ShowMsg(9, "批次: 最大浮盈：" + DoubleToString(objTacticsBuy.dMaxProfit,2) + ", 最大持仓：" + DoubleToString(objTacticsBuy.dMaxVolumeIn,2)+", 均价: " + DoubleToString(objTacticsBuy.dAvgPrice, iDigits), clrWhite);
   ShowMsg(10, "历史: 最大持仓: "+DoubleToString(objTacticsBuy.dMaxVolumeInAll, 2), clrWhite);
   
   ShowMsg(11, "  ", clrWhite);
   ShowMsg(12, "【空单】: - ", clrWhite);
   ShowMsg(13, "实时: 浮盈：" + DoubleToString(objTacticsSell.dProfit,2) + ", 数量: " + IntegerToString(objTacticsSell.iVolumeCount) + ", 持仓:" + DoubleToString(objTacticsSell.dVolumeIn,2) + ", 已平仓：" + DoubleToString(objTacticsSell.dHasClosedProfit,2), clrWhite);
   ShowMsg(14, "批次: 最大浮盈：" + DoubleToString(objTacticsSell.dMaxProfit,2) + ", 最大持仓：" + DoubleToString(objTacticsSell.dMaxVolumeIn,2), clrWhite);
   ShowMsg(15, "历史: 最大持仓: "+DoubleToString(objTacticsSell.dMaxVolumeInAll, 2), clrWhite);
   
   ShowMsg(16, "--------------------------------------------------", clrWhite);
   
}

//+-----------------------------------------------------------------------------------------
//| 销毁结束
//+-----------------------------------------------------------------------------------------
void OnDeinit(const int reason){
   string str_text = "OnDeinit - EA停止";
   MyPrint(str_text);
   
   if(isOptimization==true){ return; }
      
   EventKillTimer();
   
   if(isTester == false){ 
      ObjectDelete(0, "bg0001");
      for(int i=21; i>=0; i--){
         ObjectDelete(0, "Label000"+(string)i);
      }
   }
   //
   str_text = "";
   str_text += "杠杆: " + leverage + ",  点差: " + (string)((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)/10) + ", dPont2: " + DoubleToString(dPoint2,iDigits);
   str_text += "\n账户: " + login_name + " / " + login_number + ",  类型:  " + login_type;
   str_text += "\n最大余额:" + DoubleToString(cnt_max_accountBalance, 2) + ", 最大回撤(实时/余额): "+DoubleToString(cnt_max_backProfit, 2)+"/"+DoubleToString(cnt_max_backBalance, 2);
   str_text += "\n最大占用保证金: " + DoubleToString(cnt_max_margin, 2) + ", 余额: " + DoubleToString(obj_account.Balance(),2) + ", 净值: " + DoubleToString(obj_account.Equity(), 2);
   str_text += "\n可用保证金: " + DoubleToString(obj_account.FreeMargin(),2) + ", 已用保证金: " + DoubleToString(obj_account.Margin(), 2) + ", 浮盈: " + DoubleToString(obj_account.Profit(), 2);
   str_text += "\n----------------------------------------------------------";
   str_text += "\n【指标】: ";
   str_text += "\nTR: 方向:" + (string)objMARound.direction + ", 速度:" + (string)objMARound.speed + ", 偏离:" + (string)objMARound.deviatePoint;
   str_text += "\nSG: 方向:" + (string)objSignal.direction + ", 速度:" + (string)objSignal.speed + ", 偏离:" + (string)objSignal.deviatePoint;
   
   MyPrint(str_text);
   str_text = "";
   str_text += "\n  ";
   str_text += "\n【多单】: - ";
   str_text += "\n实时: 浮盈：" + DoubleToString(objTacticsBuy.dProfit,2) + ", 数量: " + IntegerToString(objTacticsBuy.iVolumeCount) + ", 持仓:" + DoubleToString(objTacticsBuy.dVolumeIn,2) + ", 已平仓：" + DoubleToString(objTacticsBuy.dHasClosedProfit,2);
   str_text += "\n批次: 最大浮盈：" + DoubleToString(objTacticsBuy.dMaxProfit,2) + ", 最大持仓：" + DoubleToString(objTacticsBuy.dMaxVolumeIn,2)+", 均价: " + DoubleToString(objTacticsBuy.dAvgPrice, iDigits);
   str_text += "\n历史: 最大持仓: "+DoubleToString(objTacticsBuy.dMaxVolumeInAll, 2);
   
   str_text += "\n  ";
   str_text += "\n【空单】: - ";
   str_text += "\n实时: 浮盈：" + DoubleToString(objTacticsSell.dProfit,2) + ", 数量: " + IntegerToString(objTacticsSell.iVolumeCount) + ", 持仓:" + DoubleToString(objTacticsSell.dVolumeIn,2) + ", 已平仓：" + DoubleToString(objTacticsSell.dHasClosedProfit,2);
   str_text += "\n批次: 最大浮盈：" + DoubleToString(objTacticsSell.dMaxProfit,2) + ", 最大持仓：" + DoubleToString(objTacticsSell.dMaxVolumeIn,2);
   str_text += "\n历史: 最大持仓: "+DoubleToString(objTacticsSell.dMaxVolumeInAll, 2);
   MyPrint(str_text);
//   
}
//+------------------------------------------------------------------+
//| 用于优化显示自定义列                                                  
//+------------------------------------------------------------------+
double OnTester(){
//返回净值最大回撤
   string a = DoubleToString(cnt_max_backProfit,0);
   string b = DoubleToString(cnt_max_backBalance,0);
   if(b != "0"){
      string b2 = StringSubstr(b, StringLen(b)-1);
      if(b2 == "0"){
         b = StringSubstr(b, 0, StringLen(b)-1) + "1";
      }
   }
   string c = a + "." + b;
   return StringToDouble(c);
}
//+------------------------------------------------------------------+
//| OnChartEvent                                                     |
//+------------------------------------------------------------------+
 //  void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
 //     PrintInfoToChart();
 //  }