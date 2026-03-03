import { ICartItem, IOrder, OrderResponse, OrderItemResponse, ApiResponse, User } from '../../data/Data';
import router from '@ohos.router';
import axios, { AxiosResponse } from '@ohos/axios';
import http from '@ohos.net.http';
import { PreferencesUtil } from '../../utils/fileUtils';
import { Constants } from '../../../common/Constants';

@Entry
@Component
struct OrderManager {
  @State ordersList: IOrder[] = [];
  @State ordersLoading: boolean = false;
  @State orderDetailVisible: boolean = false;
  @State orderDetail: OrderResponse = new OrderResponse();
  @State userName: string = '';
  @StorageLink('userData') currentUser: User | null = null;

  async aboutToAppear() {
    if (!this.currentUser) {
       const userData = await PreferencesUtil.getUserData();
       if (userData) {
         AppStorage.SetOrCreate('userData', userData);
         this.updateUserInfo();
       }
    } else {
      this.updateUserInfo();
    }
    this.fetchOrders();
  }

  updateUserInfo() {
    if (this.currentUser) {
      this.userName = this.currentUser.nickname || this.currentUser.username || '用户';
    }
  }

  getOrderStatusText(status: string): string {
    switch(status) {
      case 'pending': return '处理中';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return status;
    }
  }

  async fetchOrders() {
    if (!this.currentUser) return;
    this.ordersLoading = true;
    try {
      const response: AxiosResponse<ApiResponse<OrderResponse[]> | OrderResponse[]> = await axios.get(
        `${Constants.BASE_URL}/order/list`,
        { params: { userId: String(this.currentUser.id) } }
      );

      if (response.status === 200) {
        let remoteOrders: OrderResponse[] | null = null;
        if (Array.isArray(response.data)) {
          remoteOrders = response.data;
        } else {
          const apiRes = response.data as ApiResponse<OrderResponse[]>;
          if (apiRes && apiRes.code === 200) {
            remoteOrders = apiRes.data;
          }
        }

        if (remoteOrders && Array.isArray(remoteOrders)) {
          this.ordersList = remoteOrders.map((item: OrderResponse) => {
            let status: 'pending' | 'completed' | 'cancelled' = 'pending';
            if (item.status === 'completed') status = 'completed';
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
          });
          this.ordersList.sort((a, b) => b.createTime - a.createTime);
        } else {
          this.ordersList = [];
        }
      }
    } catch (e) {
      console.error('Fetch orders error', JSON.stringify(e));
    } finally {
      this.ordersLoading = false;
    }
  }

  async showOrderDetail(id: string) {
    if (!id) return;
    try {
      const response: AxiosResponse<ApiResponse<OrderResponse> | OrderResponse> = await axios.get(
        `${Constants.BASE_URL}/order/detail/${id}`
      );
      if (response.status === 200) {
        const data: ApiResponse<OrderResponse> | OrderResponse = response.data as ApiResponse<OrderResponse> | OrderResponse;
        let detail: OrderResponse | null = null;
        const apiRes = data as ApiResponse<OrderResponse>;
        if (typeof apiRes.code === 'number' && apiRes.code === 200 && apiRes.data) {
          detail = apiRes.data as OrderResponse;
        } else {
          const direct = data as OrderResponse;
          if (typeof direct.id === 'string') {
            detail = direct;
          }
        }
        if (detail) {
          this.orderDetail = detail;
          this.orderDetailVisible = true;
        }
      }
    } catch (e) {
      console.error('Order detail error', JSON.stringify(e));
    }
  }

  build() {
    Stack() {
      Column() {
        // Header
        Row() {
          Image("http://47.101.196.181:9000/department-grid/return.png")
            .width(24)
            .height(24)
            .onClick(() => {
              try {
                router.back();
              } catch (e) {
                console.error('router back error:', JSON.stringify(e));
              }
            })
            .margin({ right: 10 })

          Text('订单管理')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
        .zIndex(1)

        // Table Header
        Row() {
          Text('订单号').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333').layoutWeight(2)
          Text('用户').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333').layoutWeight(1.5)
          Text('金额').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333').layoutWeight(1)
          Text('时间').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333').layoutWeight(2)
          Text('状态').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333').layoutWeight(1)
          Text('操作').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333').layoutWeight(1.5).textAlign(TextAlign.End)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FAFAFA')
        .border({ width: { bottom: 1 }, color: '#eee' })

        if (this.ordersList.length === 0) {
           Column() {
             Text(this.ordersLoading ? '加载中...' : '暂无订单')
               .fontSize(14)
               .fontColor('#999')
               .margin({ top: 100 })
           }
           .width('100%')
           .layoutWeight(1)
           .alignItems(HorizontalAlign.Center)
        } else {
          // List
          List() {
            ForEach(this.ordersList, (order: IOrder) => {
              ListItem() {
                Row() {
                  Text(order.id).fontSize(12).fontColor('#666').layoutWeight(2).maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
                  Text(this.userName).fontSize(12).fontColor('#666').layoutWeight(1.5).maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
                  Text(`¥${order.totalAmount}`).fontSize(12).fontColor('#F56C6C').layoutWeight(1)
                  Text(new Date(order.createTime).toLocaleDateString()).fontSize(12).fontColor('#666').layoutWeight(2)
                  Text(this.getOrderStatusText(order.status)).fontSize(12).fontColor('#409EFF').layoutWeight(1)
                  Button('查看详情')
                    .type(ButtonType.Normal)
                    .borderRadius(4)
                    .backgroundColor('#4CD9C0')
                    .fontColor(Color.White)
                    .fontSize(10)
                    .height(24)
                    .onClick(() => this.showOrderDetail(order.id))
                    .layoutWeight(1.5)
                }
                .width('100%')
                .padding(12)
                .border({ width: { bottom: 1 }, color: '#f5f5f5' })
                .backgroundColor(Color.White)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')

      // Detail Dialog
      if (this.orderDetailVisible && this.orderDetail && this.orderDetail.id) {
        Column() {
          Row() {
            Text('订单详情').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333')
            Blank()
            Button('关闭').fontSize(12).backgroundColor('transparent').fontColor('#999').onClick(() => this.orderDetailVisible = false)
          }
          .width('100%')
          .padding(12)
          .border({ width: { bottom: 1 }, color: '#eee' })

          Column() {
            Row() {
              Text(`订单号：${this.orderDetail.id}`).fontSize(14).fontColor('#333')
            }.width('100%').margin({ bottom: 8 })
            Row() {
              Text('下单时间：').fontSize(14).fontColor('#64748B')
              Text(new Date(this.orderDetail.createTime).toLocaleString()).fontSize(14).fontColor('#333')
            }.width('100%').margin({ bottom: 8 })
            Row() {
              Text('状态：').fontSize(14).fontColor('#64748B')
              Text(this.getOrderStatusText(this.orderDetail.status)).fontSize(14).fontColor('#409EFF')
            }.width('100%').margin({ bottom: 8 })
            Row() {
              Text('总金额：').fontSize(14).fontColor('#64748B')
              Text(`¥${this.orderDetail.totalAmount}`).fontSize(14).fontColor('#F56C6C')
            }.width('100%').margin({ bottom: 12 })
            if (this.orderDetail.items && this.orderDetail.items.length > 0) {
              List() {
                ForEach(this.orderDetail.items, (it: ICartItem) => {
                  ListItem() {
                    Row() {
                      Text(it.name).fontSize(14).fontColor('#333').layoutWeight(1)
                      Text(`¥${it.price}`).fontSize(12).fontColor('#333').width(80)
                      Text(`x${it.quantity}`).fontSize(12).fontColor('#333').width(60)
                    }.width('100%').padding(8)
                  }
                })
              }.width('100%')
            }
          }
          .padding(16)
        }
        .width('90%')
        .height('60%')
        .backgroundColor('#fff')
        .borderRadius(12)
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 2 })
        .alignSelf(ItemAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
