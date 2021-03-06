#include <Object.mqh>
#include <__A00\OrderList.mqh>
#include <__A00\IntegerList.mqh>
#include <__A00\DWCache.mqh>
#include <__A00\ObjectMARoundingStdev.mqh>
//+-----------------------------------------------------------------------------------------
//| 策略单元类
//+-----------------------------------------------------------------------------------------
class ObjectTactics : public CObject
  {
public:
   //----输入参数
   int               op_type;                        //1做多, -1做空
   string            op_type_name;                   //"B","S"
   OP_FirstPosition  firstPosition;                  //第一仓位置
   double            firstLots;                      //第一仓
   double            lotsAdd;                        //仓位递增
   int               lotsGrid;                       //仓位网格
   int               nextGrid;                      //补仓网格
   int               tPPoint;                        //止盈点数
   int               sLPoint;                        //止损点数
   double            sLProfit;                       //止损金额
   int               ctPoint;                        //续单点数
   int               ltpPoint;                       //小止盈点数
   double            riskLots;                       //风险仓位
   double            maxLots;                        //最大单仓限制
   int               slPointUseType;                 //点位止损(1第一仓，2最后一仓)
   int               point_start;                    //点数区间开始
   int               point_end;                      //点数区间结束
   int               tr_speed_start;                 //趋势速度范围开始
   int               tr_speed_end;                   //趋势速度范围结束

   //----中间变量
   bool              res_trade;
   bool              isSignalHasOpened;
   int               lastTrend;
   int               lastDirection;
   int               lastDirection1;
   int               lastDirection2;
   int               grid_point;
   double            grid_limit_price;                       //底价
   //---建仓锁
   int                     lock_openOrder;                     //开仓锁
   uint                    iOpenTick_last;                     //上次请求订单时间
   //---订单变量
   OrderList               orderList_tactics_now;              //本策略持仓-now,可能包括EA和人工
   OrderList               orderList_tactics_last;             //本策略持仓-last,可能包括EA和人工
   int                     firstOrderIndex;                //第一仓的索引
   int                     iVolumeCount;                   //持仓数量
   double                  dVolumeIn;                      //净持仓手数
   double                  dProfit;                        //浮动盈亏
   double                  dLowestOpPrice;                 //最低持仓价
   double                  dHighestOpPrice;                //最高持仓价
   double                  dAvgPrice;                      //持仓平均价位
   double                  sl_price;                        //策略预计止损价
   double                  tp_price;                        //策略预计止盈价
   bool                    isClosedB1S1;                   //是否已平仓B1,S1, 用于监控刚发生时
   double                  dHasClosedProfit;               //已平仓金额
   bool                    isLastTwoEqual;
   bool                    isRiskProfitEmail;
   //统计变量
   double                  dMaxProfit;                     //记录每批次的最大浮亏
   double                  dMaxVolumeIn;                   //记录每批次的最大持仓
   double                  dMaxVolumeInAll;                //历史最大持仓

   //+--------------------------------------------------------------------------------------
   //| 构造函数
   //+--------------------------------------------------------------------------------------
   void ObjectTactics(){
      res_trade = false;           dHasClosedProfit = 0.0;     grid_point = 0;
      iOpenTick_last = 0;          lock_openOrder = 0;         lastDirection = 99;
      dMaxProfit = 0.0;            dMaxVolumeIn = 0.0;         dMaxVolumeInAll = 0.0;
      grid_limit_price = 0.0;      lastDirection2 = 99;        lastDirection1 = 99;
      lastTrend = 99;              isRiskProfitEmail = false;
   }
   //+--------------------------------------------------------------------------------------
   //| 构造函数
   //+--------------------------------------------------------------------------------------
   void InitParam(
		   int               op_type_c,     
		   string            op_type_name_c, 
		   OP_FirstPosition  firstPosition_c,
		   double            firstLots_c,   
		   double            lotsAdd_c,  
		   int               lotsGrid_c,
		   int               nextGrid_c,
		   int               tPPoint_c,  
		   int               sLPoint_c,
		   double            sLProfit_c,
		   int               ctPoint_c,
		   int               ltpPoint_c,
		   double            riskLots_c,
		   double            maxLots_c,
		   int               slPointUseType_c,
		   int               point_start_c,                    //点数区间开始
         int               point_add_c,
         int               tr_speed_start_c,                 //趋势速度范围开始
         int               tr_speed_add_c
   ){
      this.op_type = op_type_c;
      this.op_type_name = op_type_name_c;
      this.firstPosition = firstPosition_c;
      this.firstLots = firstLots_c;
      this.lotsAdd = lotsAdd_c;
      this.lotsGrid = lotsGrid_c;
      this.nextGrid = nextGrid_c;
      this.tPPoint = tPPoint_c;
      this.sLPoint = sLPoint_c;
      this.sLProfit = sLProfit_c;
      this.ctPoint = ctPoint_c;
      this.ltpPoint = ltpPoint_c;
      this.riskLots = riskLots_c;
      this.maxLots = maxLots_c;
      this.slPointUseType = slPointUseType_c;
      this.point_start = point_start_c;
      this.point_end = point_start_c + point_add_c;
      this.tr_speed_start = tr_speed_start_c;
      if(tr_speed_add_c >= 0){
         this.tr_speed_end = tr_speed_start_c + tr_speed_add_c;
      }else{
         this.tr_speed_end = -1;
      }
      
      
      string msg = "ObjectTactics:\n " +
                 ", op_type="+(string)op_type +
                 ", op_type_name="+(string)op_type_name +
                 ", firstPosition="+(string)firstPosition +
                 ", firstLots="+DoubleToString(firstLots,2) +
                 ", lotsAdd="+DoubleToString(lotsAdd,2) +
                 ", lotsGrid="+(string)lotsGrid +
                 ", nextGrid="+(string)nextGrid +
                 ",\n tPPoint="+(string)tPPoint +
                 ", sLPoint="+(string)sLPoint +
                 ", sLProfit="+(string)sLProfit +
                 ", ctPoint="+(string)ctPoint +
                 ", ltpPoint="+(string)ltpPoint+
                 ", riskLots="+(string)riskLots+
                 ", maxLots="+(string)maxLots+
                 ", slPointUseType="+(string)slPointUseType+
                 ", point_start="+(string)point_start+
                 ", point_end="+(string)point_end
                 ;
      MyPrint(msg);
   }
   //+--------------------------------------------------------------------------------------
   //| 读取订单信息,初始化
   //| 仅用于读取订单,在订单变化时执行
   //+--------------------------------------------------------------------------------------
   void GetOrders_1(){      
      //--本策略订单
      //记录上次执行时的订单列表
      orderList_tactics_now.CopyTo(orderList_tactics_last);
      //清空当前订单列表
      orderList_tactics_now.Clear();
      
   }
   //+-----------------------------------------------------------------------------------------
   //| 读取订单信息, 单个订单处理
   //| 仅用于读取订单,在订单变化时执行
   //+-----------------------------------------------------------------------------------------
   void GetOrders_2(ulong magic_t, string strComment,double dLots,datetime dOpenTime,double dOpenPrice,ulong iOrderTicket,double dProfit_t,double sl, double tp, double swap){
      string tag = GetTag(strComment);   //如:B,S
      string tagFull = GetTagFull(strComment); //如B1,S1,B1_,S1_
      //
      if(tag != op_type_name){ return; }
      
      //实时记录持仓情况
      MyOrder objOrder;
      objOrder.magic = magic_t;
      objOrder.ticket = iOrderTicket;
      objOrder.volume = dLots;
      objOrder.comment = strComment;
      objOrder.profit = dProfit_t;
      objOrder.dOpTime = dOpenTime;
      objOrder.dOpPrice = dOpenPrice;
      objOrder.slPrice = sl;
      objOrder.tpPrice = tp;
      objOrder.swap = swap;
      
      //策略订单
      orderList_tactics_now.Add(objOrder);
   }
   //+-----------------------------------------------------------------------------------------
   //| 用于读取订单之后计算一些变量
   //| 仅用于读取订单,在订单变化时执行
   //+-----------------------------------------------------------------------------------------
   void GetOrders_3(ObjectMARoundingStdev &objMARound_c, ObjectMARoundingStdev &objSignal_c){
      //反转订单
      orderList_tactics_now.Reverse();
      //-- 监控策略订单变化
      int count_tactics_last = orderList_tactics_last.Count();
      int count_tactics_now = orderList_tactics_now.Count();
     
      //- 监控订单被平仓
      string tagFull;
      isClosedB1S1 = false;
      MyOrder last;
      MyOrder now;
      bool isClosed_t;
      for(int i=0; i<count_tactics_last; i++){
         isClosed_t = true; 
         last = orderList_tactics_last.TryGetValue(i);   
         for(int j=0; j<count_tactics_now; j++){
            now = orderList_tactics_now.TryGetValue(j);
            if(last.ticket == now.ticket){
               isClosed_t = false;
            }
         }
         //订单被平仓
         if(isClosed_t){
            isSignalHasOpened = false;   //重置 开仓标记
            if(op_type == 1){
               dHasClosedProfit += (bid-last.dOpPrice)/dPoint2;
            }else if(op_type == -1){
               dHasClosedProfit += (last.dOpPrice-ask)/dPoint2;
            }
            //记录B1S1被平仓时刻
            tagFull = GetTagFull(last.comment);
            if(tagFull == "B1" || tagFull == "S1"){
               isClosedB1S1 = true;
            }
            MyPrint("检测到有订单被平仓, #"+IntegerToString(last.ticket)+", dVolume:"+DoubleToString(last.volume,2)+", profit:"+DoubleToString(last.profit,2)+", dHasClosedProfit:"+DoubleToString(dHasClosedProfit,2));
         }
      }
      //- 监控新订单
      bool isOpenedNew_t;
      bool isReadInfoByTime_t = false; //是否执行了获取指定时间的指标信息
      //       持仓数量; 总持仓手数; 最高价; 最低价
      firstOrderIndex = -1;              //第一仓索引
      iVolumeCount = count_tactics_now;  //持仓数量
      dVolumeIn = 0.0;                   //总持仓手数
      dHighestOpPrice = 0.0;             //最高持仓价
      dLowestOpPrice = 0.0;              //最低持仓价      
      //       计算持仓均价: 持仓总市值/持仓总手数
      double dTotalMarketMoney = 0.0;   //持仓总市值
      dAvgPrice = 0.0;        //重置持仓均价
      for(int i=0; i<count_tactics_now; i++){
         isOpenedNew_t = true;
         now = orderList_tactics_now.TryGetValue(i);
         for(int j=0; j<count_tactics_last; j++){
            last = orderList_tactics_last.TryGetValue(j);
            if(now.ticket == last.ticket){
               isOpenedNew_t = false;
               //复制旧数据,避免重新计算
               now.ma = last.ma;
               now.round_ma = last.round_ma;
               //把修改后的订单对象存入列表
               orderList_tactics_now.TrySetValue(i, now);
            }
         }
         //有新订单
         if(isOpenedNew_t){
            //重置开仓锁
            lock_openOrder = 0;
            MyPrint("检测到新订单, #"+IntegerToString(now.ticket)+", dOpTime: " + (string)now.dOpTime + ", dOpPrice: " + (string)now.dOpPrice);
            //读取新订单相应的指标信息
            isReadInfoByTime_t = true;
            objSignal_c.ReadInfoByTime(now.dOpTime);
            now.ma = objSignal_c.ma;
            objMARound_c.ReadInfoByTime(now.dOpTime);
            now.round_ma = objMARound_c.ma;
            now.position = -1;
            //1.横向后方
            if(objMARound_c.direction == 0 && objMARound_c.direction2 == 0){
               if((op_type == 1 && now.dOpPrice < objMARound_c.ma) || (op_type == -1 && now.dOpPrice > objMARound_c.ma)){
                  now.position = 3;
               }
            }
            //2.弱单边顺势
            if(objMARound_c.direction == 0 && objMARound_c.direction2 == op_type){
               now.position = 2;
            }
            //3.强单边
            if(objMARound_c.direction == op_type){
               now.position = 1;
            }
            //把修改后的订单对象存入列表
            orderList_tactics_now.TrySetValue(i, now);
         }
         //计算总持仓
         dVolumeIn = dVolumeIn + now.volume;
         //计算最高价
         if(dHighestOpPrice == 0.0 || now.dOpPrice > dHighestOpPrice){ dHighestOpPrice = now.dOpPrice; }
         //计算最低价
         if(dLowestOpPrice == 0.0 || now.dOpPrice < dLowestOpPrice){ dLowestOpPrice = now.dOpPrice; }
         //计算持仓总市值
         dTotalMarketMoney = dTotalMarketMoney + now.dOpPrice * now.volume;
         //是否存在第一仓
         tagFull = GetTagFull(now.comment);
         if(tagFull == "B1" || tagFull == "S1"){
            firstOrderIndex = i;
         }
      }
      //最后两仓是否相等
      isLastTwoEqual = false;   
      if(count_tactics_now > 1){
         if(orderList_tactics_now.TryGetLast().volume == orderList_tactics_now.TryGetValue(count_tactics_now-2).volume){
            isLastTwoEqual = true;
         }
      }
      //- 重新载入指标当前信息
      if(isReadInfoByTime_t){
         objMARound_c.ReadInfoPeriod();
         objSignal_c.ReadInfoPeriod();
      }
      // 计算持仓均价
      if(dVolumeIn > 0.0){
         dAvgPrice = NormalizeDouble(dTotalMarketMoney/dVolumeIn, iDigits);
      }
      //-- 获取和修改订单的止损止盈
      GetSlTpOrderAndSetAllOrders();
      
      //-- 如果没有订单,重置已平仓记录(通过res_trade,保证每tick只操作一次订单)
      if(iVolumeCount==0 || dVolumeIn < 0.01){
         isRiskProfitEmail = false;
         dHasClosedProfit = 0.0;       //重置已平仓金额
         lock_openOrder = 0;           //重置开仓锁
         isSignalHasOpened = false;    //重置 开仓标记
         dMaxVolumeIn = 0.0;           //重置每批次的最大持仓
         dMaxProfit = 0.0;             //每批次最大浮亏
      }
      //-- 统计与记录
      if(dVolumeIn > dMaxVolumeIn){ 
         dMaxVolumeIn = dVolumeIn; 
         MyPrint("更新当前最大持仓: "+DoubleToString(dMaxVolumeIn,2)); 
      }
      if(dVolumeIn > dMaxVolumeInAll){
         dMaxVolumeInAll = dVolumeIn; 
         MyPrint("更新历史最大持仓: "+DoubleToString(dMaxVolumeInAll,2)); 
      }
   }
   //+--------------------------------------------------------------------------------------
   //| 获取止损止盈订单: 并设置策略内的所有订单的止损止盈 
   //|   人工订单优化(且按开仓先后依次查找),其次查找EA第一仓
   //+--------------------------------------------------------------------------------------
   void GetSlTpOrderAndSetAllOrders(){
      bool flag_geted = false; //是否获取到止损止盈订单
      MyOrder slTpOrder;
      
      //获取EA订单第一仓
      int count = orderList_tactics_now.Count();
      string tagFull;
      for(int i=0; i<count; i++){
         slTpOrder = orderList_tactics_now.TryGetValue(i);
         tagFull = GetTagFull(slTpOrder.comment);
         if(slTpOrder.slPrice > 0.0 || slTpOrder.tpPrice > 0.0){
            flag_geted = true;
            break;
         }
      }
      //
      sl_price = 0.0;  //必须有止损价
      tp_price = 0.0;
      //
      if(flag_geted){
         sl_price = slTpOrder.slPrice; //止损价
         tp_price = slTpOrder.tpPrice; //止盈价
      }            
      //修改策略内所有订单的止损止盈
      MyOrder orderTmp;
      if(sl_price > 0.000001 || tp_price > 0.000001){
         //
         for(int i=0; i<iVolumeCount; i++){
            orderTmp = orderList_tactics_now.TryGetValue(i);
            if(sl_price != orderTmp.slPrice || tp_price != orderTmp.tpPrice){
               //修改订单
               if(obj_trade.PositionModify(orderTmp.ticket, sl_price, tp_price)){
                  orderTmp.slPrice = sl_price;
                  orderTmp.tpPrice = tp_price;
                  orderList_tactics_now.TrySetValue(i, orderTmp);
               }else{
                  MyPrint("错误: 修改订单止损止盈时, 错误代码: " + (string)GetLastError());
               }
            }
         }
      }
   }
   //+-----------------------------------------------------------------------------------------
   //| 判断位置是否允许开仓(第一仓)
   //+-----------------------------------------------------------------------------------------
   bool MyOpen(ObjectMARoundingStdev &objMARound_c, ObjectMARoundingStdev &objSignal_c, bool isAllowOpenFirst){
      bool result = false;
      //-- 监控信号变化
      bool isSignalChange = false;
      if(lastDirection != objSignal_c.direction){
         lastDirection2 = lastDirection1; //记录前2信号
         lastDirection1 = lastDirection; //记录前1方向
         lastDirection = objSignal_c.direction;
         isSignalHasOpened = false; //重置为未开仓
         isSignalChange = true;  //信号正在变化
         if(isPrintLog){
            MyPrint("OpenFirst: 信号正在变化,SG_Direction=" + (string)objSignal_c.direction);
         }
      }
      //--监控趋势变化
      bool isTrendChange = false;
      if(lastTrend != objMARound_c.direction){
         lastTrend = objMARound_c.direction;
         isTrendChange = true;
         if(isPrintLog){
            MyPrint("OpenFirst: 趋势正在变化,TR_Direction=" + (string)objMARound_c.direction);
         }  
      }
      //--开仓条件判断
      // >1.只在信号变化时入场
      if(isSignalChange == false){ return false; }
      // >2.信号同向
      if(objSignal_c.direction != op_type){ return false; }
      // >3.保证信号有效
      if(op_type == 1 && ask < objSignal_c.ma) { return false; }
      else if(op_type == -1 && bid > objSignal_c.ma) { return false; }
      //
      string openMsg = "";
      //-- 第一仓和补仓
      bool isOpen = false;
      if(isAllowOpenFirst && firstOrderIndex < 0){
         //第一仓
         result = OpenFirst(objMARound_c, openMsg);
         if(result && isPrintLog){
            objMARound_c.PrintIndValue();
            objSignal_c.PrintIndValue();
         }
         return result;
      }else if(firstOrderIndex >= 0 && isSignalHasOpened == false){
         if(objMARound_c.direction2 != -op_type){
            isOpen = true;
         }
         if(isOpen == false){ return false; }
         //补仓: 每个信号只开一次
         result = OpenNext(objMARound_c, objSignal_c, openMsg);
         if(isPrintLog){
            objMARound_c.PrintIndValue();
            objSignal_c.PrintIndValue();
         }
         return result;
      }
      
      return false;
   }
   //+--------------------------------------------------------------------------------------
   //| 第一仓
   //+--------------------------------------------------------------------------------------
   bool OpenFirst(ObjectMARoundingStdev &objMARound_c, string openMsg_c){
      bool isOpen = false;
      //逆势不开
      if(objMARound_c.direction == -op_type){ return false; }
      //
      double start_price = op_type == 1? objMARound_c.ma+point_start*dPoint2 : objMARound_c.ma-point_start*dPoint2;
      double end_price =  op_type == 1? objMARound_c.ma+point_end*dPoint2 : objMARound_c.ma-point_end*dPoint2;
      //趋势速度范围
      if(objMARound_c.speed < tr_speed_start || (tr_speed_end >= 0 && objMARound_c.speed > tr_speed_end)){
         return false;
      }
      //和趋势线的距离点数范围
      if(op_type == 1 && bid > start_price && bid < end_price){
         isOpen = true;
      }else if(op_type == -1 && bid < start_price && bid > end_price){
         isOpen = true;
      }
      
      if(isOpen == false){ return false; }
      //计算止损价
      double sl = 0.0;
      /*
      if(op_type == 1){
         sl = bid - sLPoint*dPoint2;
      }else if(op_type == -1){
         sl = ask + sLPoint*dPoint2;
      }*/
      // 根据判断结果开建第一仓
      double dOpLots = GetNextLots();
      if(OpenOrder(op_type, dOpLots, sl)){
         isSignalHasOpened = true;   //标记已开仓
         MyPrint("FirstOpen: " + openMsg_c + ", 手数：" + DoubleToString(dOpLots, 2) + ", " + op_type_name+IntegerToString(iVolumeCount+1));
         return true;                  //建仓成功, 返回true
      }
      
      return  false;
   }
   
   //+-----------------------------------------------------------------------------------------
   //| 补仓
   //+-----------------------------------------------------------------------------------------
   bool OpenNext(ObjectMARoundingStdev &objMARound_c, ObjectMARoundingStdev &objSignal_c, string openMsg_c){
      if(objMARound_c.direction2 == -op_type){
         return false;
      }
      //最后一仓订单对象
      MyOrder objLastOrder_t = orderList_tactics_now.TryGetLast();
      // 正向选择法
      bool flag=false; 
      double nextGrid_t = nextGrid * dPoint2;     //用于补仓
      int grid_count_t = 0;   //网格数量
      //信号判断
      if(op_type==1 && bid < objLastOrder_t.dOpPrice){
         //当前信号线值必须小于最后一仓的线值
         if(objSignal_c.ma >= objLastOrder_t.ma){ return false; }
         if(objLastOrder_t.dOpPrice-ask < nextGrid_t){ return false; }
         //如果当前是横向，且前一仓在前方，则不允许在后方补仓
         //if(objMARound_c.direction==0 && ask<objMARound_c.ma && objMARound_c.direction==objMARound_c.direction2 && objLastOrder_t.dOpPrice>objMARound_c.ma)
         //{ return false; }
         //补仓实际距离换算成网格数量
         double lotsGrid_t = lotsGrid * dPoint2;
         grid_count_t = (int)MathFloor((objLastOrder_t.dOpPrice-ask)/lotsGrid_t);
         flag = true;
      }else if(op_type==-1 && bid < objSignal_c.ma && bid > objLastOrder_t.dOpPrice){
         //当前信号线值必须大于最后一仓的线值
         if(objSignal_c.ma <= objLastOrder_t.ma){ return false; }
         if(bid-objLastOrder_t.dOpPrice < nextGrid_t){ return false; }
         //如果当前是横向，且前一仓在前方，则不允许在后方补仓
         //if(objMARound_c.direction==0 && bid>objMARound_c.ma && objMARound_c.direction==objMARound_c.direction2 && objLastOrder_t.dOpPrice<objMARound_c.ma)
         //{ return false; }
         //补仓实际距离换算成网格数量
         double lotsGrid_t = lotsGrid * dPoint2;
         grid_count_t = (int)MathFloor((bid-objLastOrder_t.dOpPrice)/lotsGrid_t);
         flag = true;
      }
      if(flag==false) { return false; }
      if(grid_count_t < 1){ grid_count_t = 1; }
      //---标准网格
      double dOpLots=GetNextLots(grid_count_t, objLastOrder_t.volume);
      if(OpenOrder(op_type, dOpLots)){
         flag=true;
         isSignalHasOpened = true;   //标记已开仓
         if(dVolumeIn+dOpLots > riskLots){
            MySendEmail("NextOpen: " + openMsg_c + ", 手数：" + DoubleToString(dOpLots, 2) + ", " + op_type_name+IntegerToString(iVolumeCount+1));
         }else{
            MyPrint("NextOpen: " + openMsg_c + ", 手数：" + DoubleToString(dOpLots, 2) + ", " + op_type_name+IntegerToString(iVolumeCount+1));
         }
         
      }
      
      return flag;
   }
   //+-----------------------------------------------------------------------------------------
   //| 仓位策略:获取下一个仓位.
   //+-----------------------------------------------------------------------------------------
   double GetNextLots(const int grid_count_c=0, const double last_order_lots_c=0.0){
      //
      double dLots = 0.01;
      if(grid_count_c == 0 || iVolumeCount == 0){   
         //第一仓
         dLots = firstLots;
      }else if(grid_count_c > 0){
         //补仓
         dLots = last_order_lots_c;
         if(grid_count_c > 1){
            dLots = dLots + lotsAdd*grid_count_c;
         }
      }

      if(dLots < 0.01){
         dLots = 0.01;
      }else if(dLots > maxLots){
         dLots = maxLots;
      }

      return dLots;
   }
   //+-----------------------------------------------------------------------------------------
   //| 执行建仓(必须订单开仓成功并被读取后,才可以继续开仓下一单)
   //| 参数: 
   //|      iOpenType: -1表示建仓空单, 1表示建仓多单
   //|      dLots: 手数
   //|      strComment: 订单注释
   //+-----------------------------------------------------------------------------------------
   bool OpenOrder(const int iOpenType,const double dLots, const double sl=0.0, const double tp=0.0, string strComment=""){
      //comment默认处理
      if(strComment == "" || strComment == NULL){
         strComment=op_type_name+IntegerToString(iVolumeCount+1)+"_"+IntegerToString(magicNumber);
      }
      //判断是否允许交易, 仅仅是提示，以便手动开启和设置
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)==false){
         MyPrint("未开启和允许交易！不能建仓");
         return false;
      }
      //避免延迟导致重复开仓,使用订单锁,或120秒后自动打开
      uint now_tick=GetTickCount();
      if(now_tick-iOpenTick_last > 120000){ lock_openOrder = 0; }
      if(lock_openOrder == 1){ 
         MyPrint("订单锁定中,等待前面的订单处理, now_tick="+(string)now_tick+", iOpenTick_last="+(string)iOpenTick_last);
         return false; 
      }
      //
      iOpenTick_last=now_tick;
      MyPrint("start open tick: "+(string)now_tick);
      bool res=false;
      obj_trade.SetExpertMagicNumber(magicNumber); // magic
      if(iOpenType==1){
         //---op-buy,start
         double price=SymbolInfoDouble(symbol_dw,SYMBOL_ASK);
         if(obj_account.FreeMarginCheck(symbol_dw,ORDER_TYPE_BUY,dLots,price)<0.0){
            printf("保证金不足. Free Margin = %f. dLots = %G",obj_account.FreeMargin(),dLots);
         }else{
            if(obj_trade.PositionOpen(symbol_dw,ORDER_TYPE_BUY,dLots,price,sl,tp,strComment)){
               MyPrint("多单建仓成功！货币对: "+symbol_dw+",dLots:"+DoubleToString(dLots,2));
               res=true;
               lock_openOrder = 1; //开启订单锁
            }else{
               printf("错误: 多单建仓失败 by %s : '%s'",symbol_dw,obj_trade.ResultComment());
               printf("Open parameters : price=%f,TP=%f",price,0);
            }
         }
         //---op-buy,end
      }else if(iOpenType==-1){
         //---op-sell,start
         double price=SymbolInfoDouble(symbol_dw,SYMBOL_BID);
         if(obj_account.FreeMarginCheck(symbol_dw,ORDER_TYPE_SELL,dLots,price)<0.0){
            printf("保证金不足. Free Margin = %f. dLots = %G",obj_account.FreeMargin(),dLots);
         }else{
            if(obj_trade.PositionOpen(symbol_dw,ORDER_TYPE_SELL,dLots,price,sl,tp,strComment)){
               MyPrint("空单建仓成功！货币对: "+symbol_dw+", dLots:"+(string)DoubleToString(dLots,2));
               res=true;
               lock_openOrder = 1; //开启订单锁
            }else{
               printf("错误: 空单建仓失败 by %s : '%s'",symbol_dw,obj_trade.ResultComment());
               printf("Open parameters : price=%f,TP=%f",price,0);
            }
         }
         //---op-sell,end
      }
      if(res==true){
         //iVolumeCount++;   //记录开仓后的数量
         //dVolumeIn+=dLots;
         MyPrint(strComment+". dProfit="+DoubleToString(dProfit,2)+", dHasCloseProfit="+(string)dHasClosedProfit+",iVolumeCount:"+(string)iVolumeCount+", dVolumeIn:"+DoubleToString(dVolumeIn,2));
      }
      MyPrint("end open tick: "+(string)GetTickCount());
      return res;
   }
   //+-----------------------------------------------------------------------------------------
   //| 平仓
   //|   参数：
   //|      "B","S","BS"
   //|   返回：
   //|      成功平仓的订单数量
   //+-----------------------------------------------------------------------------------------
   int CloseOrder(string tags_name_c){
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)==false){
         MyPrint("未开启和允许交易！不能平仓");
         return false;
      }
      int iCloseCount=0;
      string tag="";     bool isOk=false; long pos_magic;
      double dOrderProfit;    ulong iOrderTicket;    double dOrderLots;   string strComment;
      
      for(int i=PositionsTotal()-1; i>=0; i--){
         if(obj_position.SelectByIndex(i)==false) continue;
         pos_magic = obj_position.Magic();
         if(obj_position.Symbol()!=symbol_dw || pos_magic!=magicNumber) continue;  //只接受本EA
         dOrderProfit=obj_position.Profit();    iOrderTicket=obj_position.Ticket();    dOrderLots=obj_position.Volume();
         
         strComment=obj_position.Comment();
         // 人工订单
         if(obj_position.Magic()==0){
            ENUM_POSITION_TYPE iOrderType=obj_position.PositionType();    // 持仓类型
            if(iOrderType==POSITION_TYPE_BUY){
               strComment="B0,0";
            }else if(iOrderType==POSITION_TYPE_SELL){
               strComment="S0,0";
            }
         }
         tag=GetTag(strComment);
         if(tag=="B" && tags_name_c=="B"){      //仅平多单
            if(obj_trade.PositionClose(obj_position.Ticket())){ iCloseCount++;  }
         }else if(tag=="S" && tags_name_c=="S"){ //仅平空单
            if(obj_trade.PositionClose(obj_position.Ticket())){ iCloseCount++; }
         }else if(tags_name_c=="BS"){  // 平仓多空
            if(obj_trade.PositionClose(obj_position.Ticket())){ iCloseCount++; }
         }

         MyPrint("CloseOrder: iOrderTicket="+IntegerToString(iOrderTicket)+", dOrderLots="+DoubleToString(dOrderLots,2)+", dOrderProfit="+DoubleToString(dOrderProfit,2));
      }
      return iCloseCount;
   }
   
   //+-----------------------------------------------------------------------------------------
   //| 刷新订单盈亏情况(计算)
   //+-----------------------------------------------------------------------------------------
   bool CalcOrderProfit(){
      dProfit = 0.0; //重置盈亏价
      if(dVolumeIn == 0.0 || iVolumeCount == 0){  return false;  }
      if(dAvgPrice == 0.0){
         MySendEmail("错误: 有持仓但未计算出均价.");
         return false;
      }
      
      int count = orderList_tactics_now.Count();
      double dProfit_t = 0.0;
      MyOrder orderTmp;
      //
      for(int j=0; j<count; j++){
         dProfit_t = 0.0;
         orderTmp = orderList_tactics_now.TryGetValue(j);
         if(op_type == 1){
            dProfit_t = (bid-orderTmp.dOpPrice)*orderTmp.volume/dPoint;
         }else if(op_type == -1){
            dProfit_t = (orderTmp.dOpPrice-ask)*orderTmp.volume/dPoint;
         }else{ continue; }
         //更新盈亏
         orderTmp.profit = dProfit_t;
         orderList_tactics_now.TrySetValue(j, orderTmp);
         dProfit += dProfit_t;
         
      }
      //校对总盈亏, 取较小值
      double dProfit_t2 = 0.0;
      if(op_type == 1){
         dProfit_t2 = (bid-dAvgPrice)*dVolumeIn/dPoint;
      }else if(op_type == -1){
         dProfit_t2 = (dAvgPrice-ask)*dVolumeIn/dPoint;
      }
      //取较小值
      if(dProfit > dProfit_t2){
         dProfit = dProfit_t2;
      }
      //记录最大浮亏
      if(dProfit < dMaxProfit){
         dMaxProfit = dProfit;
      }
      
      return true;
   }
   //+-----------------------------------------------------------------------------------------
   //| 止盈、止损、续单
   //+-----------------------------------------------------------------------------------------
   bool MyClose(ObjectMARoundingStdev &objMARound_c, ObjectMARoundingStdev &objSignal_c){
      //实时计算盈亏
      if(CalcOrderProfit() == false) { return false; }
   
      //-- 止损价止损(已经通过修改订单设置,这里不需要再写)
      //-- 止盈价止盈(已经通过修改订单设置,这里不需要再写)      
      bool isCloseAll = false;
      string strMsg = "";
      double p = op_type == 1? bid:ask;
      MyOrder firstOrder = orderList_tactics_now.TryGetFirst();
      MyOrder lastOrder = orderList_tactics_now.TryGetLast();
      double op_price = slPointUseType==1?firstOrder.dOpPrice:lastOrder.dOpPrice;
      
      //-- 金额止损(对所有情况适用)
      if(-sLProfit > dProfit){
         isCloseAll = true; 
         strMsg += "金额止损[sLProfit="+(string)sLProfit+"]; ";
      }
      //止损价止损
      if(objMARound_c.direction2 == -op_type && MathAbs(p-op_price) > sLPoint*dPoint2){
         isCloseAll = true; 
         strMsg += "点位止损[sLPoint="+(string)sLPoint+"]; ";
      }
      //有止盈价, 不使用其他止盈策略
      if(tp_price == 0.0){
         int tp_t = tPPoint;
         if(objMARound_c.direction2 == -op_type){
            tp_t = 5; 
            strMsg += "逆势[tp_t="+(string)tp_t+"]; ";
         }
         /*
         if(dVolumeIn >= riskLots && objMARound_c.direction2 == op_type && ((op_type == 1 && bid < objMARound_c.ma) || (op_type == -1 && bid > objMARound_c.ma))){
            tp_t = 5;
            strMsg += "逃离_顺势反侧[tp_t="+(string)tp_t+"]; ";
         }
         if(dVolumeIn >= riskLots && isLastTwoEqual){
            tp_t = 5; 
            strMsg += "逃离_横盘震荡[最后两仓位相等]; ";
         }*/
         if(dVolumeIn >= riskLots && dProfit > 3.0 && isRiskProfitEmail == false){
            isRiskProfitEmail = true;
            MySendEmail("触发持仓风险的盈利，建议平仓离场！");
         }
         //MyOrder lastOrder = orderList_tactics_now.TryGetLast();
         //if(dVolumeIn >= riskLots){
            //tp_t = 3;
            //strMsg += "风险仓位止盈[tp_t="+(string)tp_t+"]; ";
         //}
         double tp_money_t = tp_t*iDigitsNum*dVolumeIn;
         if(dProfit > tp_money_t){
            isCloseAll = true; 
            strMsg += "止盈; ";
         }
      }
      //如果没有B1,S1则清仓
      if(isClosedB1S1){
         isClosedB1S1 = false;
         strMsg += strMsg += "平仓所有["+op_type_name+"1不存在]; ";
         isCloseAll = true;
      }
      
      //平仓所有
      if(isCloseAll){
         strMsg += "盈亏="+(string)dProfit;
         if(CloseOrder(op_type_name) != 0){
            MySendEmail(strMsg);
            return true;
         }
      }
      /*
      bool res = false;
      //续单和减仓
      if(ctPoint > 1 && op_type == objSignal_c.direction){
         //信号同向方可续单
         res = CloseMyOrder_CT(ctPoint);
      }else if(ltpPoint > 1 && op_type == -objSignal_c.direction && isLastTwoEqual){
         //信号反向 小止盈
         res = CloseMyOrder_LTP(ltpPoint);
      }
      */
      return false;
   }
   //+-----------------------------------------------------------------------------------------
   //| 刷新盈亏情况
   //+-----------------------------------------------------------------------------------------
   /*
   void CalcOrderProfit(){
      string pos_symbol;
      double dLots,dOrderProfit;
      ulong pos_magic;  int iOpType=0;
      int orderTotal=PositionsTotal();
      int count = orderList_tactics_now.Count();
      MyOrder orderTmp;
      dProfit = 0.0;
      //
      int file_handle= FileOpen(file_out,FILE_WRITE|FILE_SHARE_WRITE|FILE_ANSI|FILE_CSV, ",");
      if(file_handle!=INVALID_HANDLE){
         FileWrite(file_handle, bid, ask, dProfit);
         //
         for(int i=orderTotal-1; i>=0; i--){
            ResetLastError();
            if(obj_position.SelectByIndex(i)==false) continue;
            pos_symbol=PositionGetSymbol(i);
            if(pos_symbol == ""){ PrintFormat("读取订单错误，错误代码：%d",GetLastError()); continue;}
            pos_magic=PositionGetInteger(POSITION_MAGIC);
            dLots=PositionGetDouble(POSITION_VOLUME);
            //if(dLots == 0.01 && pos_magic == 0) continue;   //排除人工0.01
            if(pos_symbol!=symbol_dw || pos_magic!=magicNumber) continue;   //只接受本EA
            //验证通过,正式处理
            dOrderProfit=PositionGetDouble(POSITION_PROFIT);
            for(int j=0; j<count; j++){
               orderTmp = orderList_tactics_now.TryGetValue(j);
               if(obj_position.Ticket() == orderTmp.ticket){
                  orderTmp.profit = dOrderProfit;
                  orderList_tactics_now.TrySetValue(j, orderTmp);
                  dProfit += dOrderProfit;
               }
            }
            //
            FileWrite(file_handle, obj_position.Symbol(), obj_position.Ticket(), obj_position.Time(), obj_position.PositionType(), obj_position.Volume(), obj_position.PriceOpen(), obj_position.StopLoss(), obj_position.TakeProfit(), obj_position.Swap(), obj_position.Profit(), obj_position.Comment());
         }
      }else{
         MyPrint("订单文件写入失败:"+IntegerToString(GetLastError()) + ", " + file_out);
      }
      FileClose(file_handle);
      //复制文件给Java
      if(FileIsExist(file_out_java) == false){
         FileCopy(file_out, 0, file_out_java, 0);
      }
   }*/
   //+-----------------------------------------------------------------------------------------
   //| 续单策略
   //|   参数：
   //|      ct_point_c: 续单点数
   //+-----------------------------------------------------------------------------------------
   bool CloseMyOrder_CT(int ct_point_c){
      bool isHasCT = false;
      int count = orderList_tactics_now.Count();
      MyOrder orderTmp;
      bool isContinue = true;
      //倒序
      for(int j=count-1; j>=0; j--){
         if(j != count-1){ break; }  //只判断最后一个订单
         if(isContinue == false) { break; }
         orderTmp = orderList_tactics_now.TryGetValue(j);
         
         if(orderTmp.profit<orderTmp.volume*ct_point_c*iDigitsNum) { isContinue=false; continue; }
         MyPrint("续单：Last -TP! "+orderTmp.comment+", dOrderProfit="+(string)orderTmp.profit);
         if(obj_trade.PositionClose(orderTmp.ticket)){
            if(OpenOrder(op_type,orderTmp.volume,0.0,0.0,orderTmp.comment)){
               isHasCT=true;
               isContinue = false;   //只有最后一仓允许续单
               MyPrint("续单：Last -Open! OK.");
            }
         }else{
            PrintFormat("读取订单错误，错误代码：%d",GetLastError());
         }
      }
      return isHasCT;
   }
   /*
   bool CloseMyOrder_CT2(double ct_point_c){
      bool isHasCT=false;
      double ct_point=ct_point_c;  //续单固定10个点
      string pos_symbol,strComment;
      double dLots,dOrderProfit;
      ulong pos_magic;  int iOpType=0;
      int orderTotal=PositionsTotal();
      string tagFull; string tag;
      bool isContinue=true;
      for(int i=orderTotal-1; i>=0 && isContinue; i--)
        {
         ResetLastError();
         if(obj_position.SelectByIndex(i)==false) continue;
         pos_symbol=PositionGetSymbol(i);
         if(pos_symbol!="")
           {
            pos_magic=PositionGetInteger(POSITION_MAGIC);
            dLots=PositionGetDouble(POSITION_VOLUME);
            dOrderProfit=PositionGetDouble(POSITION_PROFIT);
            //if(dLots == 0.01 && pos_magic == 0) continue;   //人工0.01不续单
            if(pos_symbol!=symbol_dw || pos_magic!=magicNumber) continue;   //只接受本EA
            if(dOrderProfit<dLots*ct_point*iDigitsNum) { isContinue=false; continue; }
            ENUM_POSITION_TYPE iOrderType=obj_position.PositionType();
            strComment=obj_position.Comment();
            if(pos_magic==0){
               //人工下单
               if(iOrderType==POSITION_TYPE_BUY){
                  strComment="B0,0";
               }else if(iOrderType==POSITION_TYPE_SELL){
                  strComment="S0,0";
               }
            }
            //保证策略的独立性
            tag = GetTag(strComment);
            if(tag != op_type_name){ continue; }
            
            tagFull= GetTagFull(strComment);

            if(iOrderType==POSITION_TYPE_BUY){ iOpType=1; }else if(iOrderType==POSITION_TYPE_SELL){ iOpType=-1; }
            MyPrint("续单：Last -TP! tagFull="+tagFull+", dOrderProfit="+(string)dOrderProfit);
            if(obj_trade.PositionClose(obj_position.Ticket()))
              {
               OpenOrder(iOpType,dLots,0.0,0.0,strComment);
               isHasCT=true;
               isContinue = false;   //只有最后一仓允许续单
               MyPrint("续单：Last -Open! OK.");
              }
              }else{
            PrintFormat("读取订单错误，错误代码：%d",GetLastError());
           }
        }
      return isHasCT;
   }*/
   //+-----------------------------------------------------------------------------------------
   //| 小止盈,部分平仓
   //|   参数：
   //|      tpPoint: 止盈点数
   //+-----------------------------------------------------------------------------------------
   bool CloseMyOrder_LTP(int ltp_point_c){
      if(iVolumeCount<2){ return false; }   //只有一个订单不能执行ltp
      bool res=false;
      
      int count = orderList_tactics_now.Count();
      MyOrder orderTmp;
      bool isContinue = true;
      string tagFull;
      IntegerList tickList;
      int iClosedCount = 0;
       //倒序, 计算得出待平仓的订单号
      for(int j=count-1; j>=0; j--){
         //用于退出循环
         if(isContinue == false) { break; }         
         orderTmp = orderList_tactics_now.TryGetValue(j);
         //第一仓不支持减仓
         tagFull=GetTagFull(orderTmp.comment);
         if(tagFull=="B1" || tagFull=="S1" || tagFull=="B0" || tagFull=="S0") continue;
         
         //记录满足条件的订单号
         if(orderTmp.profit>ltp_point_c*iDigitsNum*orderTmp.volume){
            tickList.Add(orderTmp.ticket);//记录需要平仓的订单号
         }else{
            isContinue = false; 
         }
      }
      //执行平仓
      int tickListCount = tickList.Count();
      if(tickListCount > 0){
         ulong ticket_t;
         for(int i=0; i<tickListCount; i++){
            ticket_t = tickList.TryGetValue(i);
            if(obj_trade.PositionClose(ticket_t)){
               res=true;
               iClosedCount++;
               MyPrint("LTP! iOrderTicket="+IntegerToString(ticket_t)+", dOrderProfit="+DoubleToString(orderTmp.profit,2));
            }               
         }
      }      
      return res;
   }
   /*
   bool CloseMyOrder_LTP2(int tpPoint){
      if(iVolumeCount<2){ return false; }   //只有一个订单不能执行ltp
      bool res=false;
      //获取所有达到盈利目标的订单，并计算总盈利金额
      ulong iOrderTicket;   double dOrderProfit;
      string strNeedCloseTickets="";  string tag;
      double dLots;    int orderTotal=PositionsTotal();
      string pos_symbol,tagFull;
      ulong pos_magic;  int index;
      for(int i=orderTotal-1; i>=0; i--)
        {
         ResetLastError();
         if(obj_position.SelectByIndex(i)==false) continue;
         pos_symbol=PositionGetSymbol(i);
         if(pos_symbol!="")
           {
            pos_magic=PositionGetInteger(POSITION_MAGIC);
            if(pos_symbol!=symbol_dw || pos_magic!=magicNumber) continue;
            string strComment = obj_position.Comment();
            ENUM_POSITION_TYPE iOrderType=obj_position.PositionType();
            if(pos_magic==0){
               //人工下单
               if(iOrderType==POSITION_TYPE_BUY){
                  strComment="B0,0";
               }else if(iOrderType==POSITION_TYPE_SELL){
                  strComment="S0,0";
               }
            }
            
            tagFull=GetTagFull(strComment);
            if(tagFull=="B1" || tagFull=="S1" || tagFull=="B0" || tagFull=="S0") continue;
            //保证策略的独立性
            tag = GetTag(strComment);
            if(tag != op_type_name){ continue; }

            iOrderTicket=  PositionGetTicket(i);
            dLots       =  PositionGetDouble(POSITION_VOLUME);
            dOrderProfit= PositionGetDouble(POSITION_PROFIT);
            if(dOrderProfit>tpPoint*iDigitsNum*dLots)
              {
               strNeedCloseTickets=strNeedCloseTickets+","+IntegerToString(iOrderTicket);   //记录需要平仓的订单号         
                 }else{
               break;
              }

              }else{
            PrintFormat("读取订单错误，错误代码：%d",GetLastError());
           }
        }

      //执行平仓
      if(StringLen(strNeedCloseTickets)>1) {
         double dProfit_t;
         int iClosedCount=0;
         for(int k=orderTotal-1; k>=0; k--)
           {
            ResetLastError();
            if(obj_position.SelectByIndex(k)==false) continue;
            if(obj_position.Symbol()!=symbol_dw || obj_position.Magic()!=magicNumber) continue;
            iOrderTicket=obj_position.Ticket();
            index=StringFind(strNeedCloseTickets,","+IntegerToString(iOrderTicket),0);
            if(index!=-1)
              {
               dProfit_t=obj_position.Profit();
               if(obj_trade.PositionClose(obj_position.Ticket()))
                 {
                  res=true;
                  iClosedCount++;
                 }
               MyPrint("Little-TP! iOrderTicket="+IntegerToString(iOrderTicket)+", dOrderProfit="+DoubleToString(dProfit_t,2)+
                       ",dHasClosedProfit："+DoubleToString(dHasClosedProfit,2));
              }
           }
        }
      return res;
   }*/
   
   //+-----------------------------------------------------------------------------------------
//| 打印日志
//+-----------------------------------------------------------------------------------------
void MyPrint(string strMsg){
   if(isOptimization==true){
      return;
   }
   strMsg = "["+symbol_dw+"_"+IntegerToString(magicNumber)+"_"+op_type_name+"]: " + strMsg;
   Print(strMsg);
}
void MySendEmail(string strMsg){
   if(isTester==true){
      return;
   }
   MyPrint(strMsg);
   if(isSendEmail){
      string str_title = "["+symbol_dw+"_"+IntegerToString(magicNumber)+"_"+op_type_name+"]";
      strMsg = str_title + ": \n" + strMsg + "\n\n账户["+login_number+"]";
      SendMail(str_title, strMsg);
   }
}
};
   //+------------------------------------------------------------------+
