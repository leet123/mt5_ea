#include <Object.mqh>
#include <__A00\DWCache.mqh>
//+-----------------------------------------------------------------------------------------
//| 集合类
//+-----------------------------------------------------------------------------------------
class OrderList : public CObject{
private:
   int            flag_index;       //记录数组的当前顺序,0原始顺序,1倒序
public:
   MyOrder        order_arr[];
public:
   //+--------------------------------------------------------------------------------------
   //| 构造函数
   //+--------------------------------------------------------------------------------------
   void ObjectTactics(){ flag_index = 0; }
   //+--------------------------------------------------------------------------------------
   //| 清空列表
   //+--------------------------------------------------------------------------------------
   bool Clear(){
      ArrayFree(order_arr);
      return true;
   }
   //+--------------------------------------------------------------------------------------
   //| 添加
   //+--------------------------------------------------------------------------------------
   int Add(MyOrder &myOrder_c){
      int size = ArraySize(order_arr);
      int new_size = size + 1;
      ArrayResize(order_arr, new_size);
      order_arr[size] = myOrder_c;
      
      return new_size;
   }
   //+--------------------------------------------------------------------------------------
   //| 获取元素数量
   //+--------------------------------------------------------------------------------------
   int Count(){
      return ArraySize(order_arr);
   }
   //+--------------------------------------------------------------------------------------
   //| 获取指定位置的元素: 如果获取失败,则ticket=0;
   //+--------------------------------------------------------------------------------------
   MyOrder TryGetValue(const int index){
      MyOrder myOrder_t;
      myOrder_t.ticket = 0; //默认订单号为0
      int size = ArraySize(order_arr);
      if(index < 0 || index >= size){ return myOrder_t; }
      myOrder_t = order_arr[index];
      return myOrder_t;
   }
   //+--------------------------------------------------------------------------------------
   //| 获取第一个元素
   //+--------------------------------------------------------------------------------------
   MyOrder TryGetFirst(){
      return order_arr[0];
   }
   //+--------------------------------------------------------------------------------------
   //| 获取最后一个元素
   //+--------------------------------------------------------------------------------------
   MyOrder TryGetLast(){
      int size = ArraySize(order_arr);
      return order_arr[size-1];
   }
   //+--------------------------------------------------------------------------------------
   //| 根据开仓价查找订单: 如果查询失败,则ticket是0
   //+--------------------------------------------------------------------------------------
   MyOrder FindByOpPrice(double op_price_c){
      MyOrder orderTmp;
      bool flag = true;
      int size = ArraySize(order_arr);
       for(int i=0; i<size; i++){
         if(order_arr[i].dOpPrice == op_price_c){
            orderTmp = order_arr[i];
            flag = false;
         }
      }
      if(flag){
         orderTmp.ticket = 0;
      }
      return orderTmp;
   }
   //+--------------------------------------------------------------------------------------
   //| 获取指定位置的元素: 如果获取失败,则ticket=0;
   //+--------------------------------------------------------------------------------------
   bool TrySetValue(const int index, MyOrder &myOrder_c){
      int size = ArraySize(order_arr);
      if(index < 0 || index >= size){ return false; }
      order_arr[index] = myOrder_c;
      return true;
   }
   //+--------------------------------------------------------------------------------------
   //| 复制列表
   //+--------------------------------------------------------------------------------------
   bool CopyTo(OrderList &orderList_c){
      int size = ArraySize(order_arr);
      ArrayFree(orderList_c.order_arr);
      ArrayResize(orderList_c.order_arr, size);
      for(int i=0; i<size; i++){
         orderList_c.order_arr[i] = order_arr[i];
      }
      return true;
   }
   //+--------------------------------------------------------------------------------------
   //| 反转数据列表
   //+--------------------------------------------------------------------------------------
   bool Reverse(){
      if(flag_index == 0){
         ArraySetAsSeries(order_arr, 1);
         flag_index = 1;
      }else{
         ArraySetAsSeries(order_arr, 0);
         flag_index = 0;
      }
      return true;
   }
};
//+------------------------------------------------------------------+
