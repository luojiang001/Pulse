import { IOrder, ICartItem, OrderResponse, OrderItemResponse, ApiResponse } from '../../data/Data'
import router from '@ohos.router';
import axios, { AxiosResponse } from '@ohos/axios';
import { PreferencesUtil } from '../../utils/fileUtils';
import promptAction from '@ohos.promptAction';
import { Constants } from '../../../common/Constants';

@Component
struct OrderCard {
  order: IOrder = {
    id: '',
    items: [],
    totalAmount: 0,
    createTime: 0,
    status: 'pending'
  }
  // 控制是否展开显示所有商品
  // 默认只显示前两个商品，点击"查看更多"展开
  @State isExpanded: boolean = false

  build() {
    Column() {
      // 头部区域：订单号和状态
      Row() {
        Text(`订单号: ${this.order.id}`)
          .fontSize(12)
          .fontColor('#999')
        Text(this.order.status === 'completed' || this.order.status === 'paid' ? '已完成' : '处理中')
          .fontSize(14)
          .fontColor('#007fff')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#f0f0f0' })
      .onClick(() => {
        // 点击头部跳转到详情页，传递订单对象作为参数
        router.pushUrl({
          url: 'pages/component/Medicine/MedicineOrderDetail',
          params: { order: this.order }
        })
      })

      // 订单商品列表区域
      Column() {
        // 根据 isExpanded 状态决定显示全部还是前两个
        ForEach(this.isExpanded ? this.order.items : this.order.items.slice(0, 2), (item: ICartItem) => {
          Row() {
            Text(item.name)
              .fontSize(14)
              .fontColor('#333')
              .layoutWeight(1)
            Text(`x${item.quantity}`)
              .fontSize(14)
              .fontColor('#999')
              .margin({ left: 10 })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 5 })
        })

        if (this.order.items.length > 2) {
          Row() {
            // 如果商品超过2件，显示展开/收起按钮
            Text(this.isExpanded ? '收起' : `还有 ${this.order.items.length - 2} 件商品`)
              .fontSize(12)
              .fontColor('#007fff')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 10 })
          .onClick(() => {
            this.isExpanded = !this.isExpanded // 切换展开状态
          })
        }
      }
      .padding({ top: 10, bottom: 10 })

      // 底部区域：时间和总价
      Row() {
        Text(new Date(this.order.createTime).toLocaleString())
          .fontSize(12)
          .fontColor('#999')

        Row() {
          Text(`实付: ¥${this.order.totalAmount.toFixed(2)}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
          
          if (this.order.status === 'pending') {
            Button('支付')
              .onClick(() => {
                const payUrl = `${Constants.BASE_URL}/alipay/pay?orderId=${this.order.id}`
                router.pushUrl({
                  url: 'pages/component/Medicine/PaymentPage',
                  params: { url: payUrl }
                })
              })
              .height(28)
              .fontSize(13)
              .backgroundColor('#007fff')
              .margin({ left: 10 })
          }
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 5 })
      .onClick(() => {
        // 点击底部同样跳转详情
        router.pushUrl({
          url: 'pages/component/Medicine/MedicineOrderDetail',
          params: { order: this.order }
        })
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .padding(15)
    .borderRadius(10)
    .margin({ bottom: 10 })
  }
}

@Component
export default struct MedicineOrder {
  @State orders: IOrder[] = []
  @Prop @Watch('onTabChange') currentTab: number // 监听 Tab 切换，实现每次进入刷新

  // 监听全局刷新请求（例如从支付页面返回时）
  @StorageLink('RefreshOrderList') @Watch('onRefreshChange') needRefresh: boolean = false

  @State isError: boolean = false
  @State errorMessage: string = ''

  onTabChange() {
    console.info(`MedicineOrder onTabChange: currentTab=${this.currentTab}`);
    if (this.currentTab === 2) {
      this.fetchOrders()
    }
  }

  onRefreshChange() {
    console.info(`MedicineOrder onRefreshChange triggered: ${this.needRefresh}`);
    if (this.needRefresh) {
      console.info('MedicineOrder: Refresh triggered by global event');
      this.fetchOrders();
      // 使用 setTimeout 延迟重置，确保 fetchOrders 已经开始执行
      setTimeout(() => {
          AppStorage.SetOrCreate('RefreshOrderList', false);
      }, 500)
    }
  }

  aboutToAppear() {
    console.info('MedicineOrder aboutToAppear');
    // 如果进入时已有刷新标记，也进行重置，避免逻辑混乱
    if (this.needRefresh) {
        AppStorage.SetOrCreate('RefreshOrderList', false);
    }
    this.fetchOrders()
  }

  async fetchOrders() {
    console.info('MedicineOrder fetchOrders start');
    this.isError = false;
    this.errorMessage = '';
    
    try {
      const user = await PreferencesUtil.getUserData();
      if (!user) {
        console.info('MedicineOrder fetchOrders: No user logged in');
        return;
      }
      
      console.info(`MedicineOrder fetching for user: ${user.id}`);
      // 使用联合类型以兼容后端可能返回 ApiResponse 结构或直接返回数组结构
      // 尝试将 userId 转为字符串，以防后端解析问题
      const response: AxiosResponse<ApiResponse<OrderResponse[]> | OrderResponse[]> = await axios.get<ApiResponse<OrderResponse[]> | OrderResponse[], AxiosResponse<ApiResponse<OrderResponse[]> | OrderResponse[]>, null>(
        `${Constants.BASE_URL}/order/list`, 
        { params: { userId: String(user.id), _t: new Date().getTime() } }
      )
      
      console.info('MedicineOrder fetch response:', JSON.stringify(response.data));

      if (response.status === 200) {
        let remoteOrders: OrderResponse[] | null = null;
        
        // 优先判断是否为数组（直接返回数据的情况）
        if (Array.isArray(response.data)) {
           remoteOrders = response.data;
        } else {
           // 否则尝试作为 ApiResponse 处理
           // 显式类型断言帮助编译器理解
           const apiRes = response.data as ApiResponse<OrderResponse[]>;
           if (apiRes && apiRes.code === 200) {
               remoteOrders = apiRes.data;
           }
        }

        if (remoteOrders && Array.isArray(remoteOrders)) {
             this.orders = remoteOrders.map((item: OrderResponse) => {
                let status: 'pending' | 'completed' | 'cancelled' | 'paid' = 'pending';
                // 兼容后端的 "paid" 状态，将其视为已完成
                if (item.status === 'completed') status = 'completed';
                else if (item.status === 'paid') status = 'paid';
                else if (item.status === 'cancelled') status = 'cancelled';

                return {
                  id: item.id,
                  totalAmount: item.totalAmount,
                  createTime: item.createTime,
                  status: status,
                  items: item.items ? item.items.map((sub: OrderItemResponse) => ({
                    id: sub.medicineId || sub.id,
                    name: sub.name,
                    price: sub.price,
                    quantity: sub.quantity,
                    image: sub.image,
                    manufacturer: '',
                    unit: '',
                    category: 0,
                    isPrescription: false
                  } as ICartItem)) : []
               } as IOrder
             })
             // 按时间倒序排列
             this.orders.sort((a, b) => b.createTime - a.createTime);
        } else {
             console.warn('MedicineOrder: Remote orders is not an array or empty');
        }
      }
    } catch (error) {
      console.error('Fetch orders error:', JSON.stringify(error));
      this.isError = true;
      this.errorMessage = '无法连接到服务器，请稍后重试';
    }
  }

  build() {
    Column() {
      if (this.isError) {
         Column() {
           Text(this.errorMessage)
             .fontSize(16)
             .fontColor('#999')
             .margin({ top: 20, bottom: 20 })
           
           Button('重新加载')
             .onClick(() => {
               this.fetchOrders()
             })
             .width(120)
             .height(40)
         }
         .width('100%')
         .height('100%')
         .justifyContent(FlexAlign.Center)
         .alignItems(HorizontalAlign.Center)
      } else if (this.orders.length === 0) {

        Column() {
          Text('暂无订单')
            .fontSize(16)
            .fontColor('#999')
            .margin({ top: 100 })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.orders, (order: IOrder) => {
            ListItem() {
              OrderCard({ order: order })
            }
          })
        }
        .width('100%')
        .height('100%')
        .padding(10)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
