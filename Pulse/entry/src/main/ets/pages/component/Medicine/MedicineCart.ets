import { ICartItem, IOrder, OrderRequest, OrderItemRequest, ApiResponse } from '../../data/Data'
import axios, { AxiosResponse } from '@ohos/axios'
import promptAction from '@ohos.promptAction'
import { PreferencesUtil } from '../../utils/fileUtils'
import { StorageUtil, STORAGE_KEYS } from '../../utils/StorageUtil'
import { Constants } from '../../../common/Constants';

@Component
export default struct MedicineCart {
  @StorageLink('cart') cart: ICartItem[] = []
  @Link currentMainTab: number
  @State isSubmitting: boolean = false

  // 计算购物车总金额
  getCartTotal(): number {
    return this.cart.reduce((total, item) => total + (item.price * item.quantity), 0)
  }

  // 提交订单逻辑
  async submitOrder() {
    // 防御性编程：如果购物车为空，直接返回
    if (this.cart.length === 0) {
      promptAction.showToast({ message: '请选择需要购买的药品' })
      return
    }

    if (this.isSubmitting) return
    this.isSubmitting = true

    try {
      const user = await PreferencesUtil.getUserData()
      if (!user) {
        promptAction.showToast({ message: '请先登录' })
        this.isSubmitting = false
        return
      }

      // 使用类实例替代对象字面量，解决 ArkTS 报错
      // 后端接受的结构为 Orders 对象
      const orderData = new OrderRequest()
      orderData.userId = user.id
      orderData.totalAmount = this.getCartTotal()
      // 后端现在使用 items 字段接收商品列表
      orderData.items = this.cart.map((item: ICartItem) => {
        const orderItem = new OrderItemRequest()
        orderItem.medicineId = item.id
        orderItem.name = item.name
        orderItem.price = item.price
        orderItem.quantity = item.quantity
        orderItem.image = typeof item.image === 'string' ? item.image : ''
        if (item.prescriptionId) {
          orderItem.prescriptionId = parseInt(item.prescriptionId)
        }
        return orderItem
      })

      // 显式指定泛型参数，避免 inferred any 报错
      // ApiResponse 需要泛型参数，这里创建订单可能只返回 null 或简单对象
      const response: AxiosResponse<ApiResponse<null>> = await axios.post<ApiResponse<null>, AxiosResponse<ApiResponse<null>>, OrderRequest>(
        `${Constants.BASE_URL}/order/create`, 
        orderData
      )
      
      console.info('Order Submit Response:', JSON.stringify(response.data));

      if (response.status === 200) {
        // 兼容处理：如果后端返回标准 ApiResponse 结构且 code=200，或者直接返回 200 状态码
        const isSuccess = (response.data && response.data.code === 200) || 
                          (response.data && typeof response.data.code === 'undefined');
        
        if (isSuccess) {
              // 1. 优先清空购物车数据 (逻辑优先于 UI 反馈)
              const emptyCart: ICartItem[] = [];
              
              try {
                // 显式更新全局状态
                AppStorage.setOrCreate('cart', emptyCart);
                // 更新本地 Link (确保当前组件感知)
                this.cart = emptyCart;
                console.info('Cart state cleared in memory');
              } catch (e) {
                console.error('State update error:', JSON.stringify(e));
              }

              // 2. 持久化存储 (即使 Watcher 会触发，这里显式保存更安全)
              // StorageUtil.saveData 内部已捕获异常，不会抛出
              await StorageUtil.saveData(STORAGE_KEYS.CART, emptyCart);

              // 3. UI 反馈 (放在最后，避免 toast 失败阻断逻辑)
              try {
                promptAction.showToast({ message: '订单提交成功' })
              } catch (err) {
                console.error('Toast error:', JSON.stringify(err))
              }
                
              console.info('Cart cleared successfully');
              
              // 延时跳转
              setTimeout(() => {
                this.currentMainTab = 2 
              }, 500)
        } else {
             promptAction.showToast({ message: '订单提交失败: ' + (response.data.msg || '未知错误') })
        }
      } else {
        promptAction.showToast({ message: '订单提交失败，状态码: ' + response.status })
      }
    } catch (error) {
      console.error('Submit order error:', JSON.stringify(error))
      promptAction.showToast({ message: '网络请求失败，请稍后重试' })
    } finally {
      this.isSubmitting = false
    }
  }

  build() {
    Column() {
      // 购物车列表为空时的缺省页
      if (this.cart.length === 0) {
        Column() {
          Image($rawfile('Pulse/Common/foreground.png'))
            .width(80)
            .height(80)
            .fillColor('#94A3B8')
          Text('购物车空空如也')
            .fontSize(14)
            .fontColor('#94A3B8')
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.cart, (item: ICartItem) => {
            ListItem() {
              Row() {
                Image(item.image)
                  .width(72)
                  .height(72)
                  .objectFit(ImageFit.Contain)
                  .backgroundColor('#F8FAFC')
                  .borderRadius(8)
                  .margin({ right: 16 })
                
                Column() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1E293B')
                    .margin({ bottom: 4 })
                  
                  Text(item.manufacturer)
                    .fontSize(12)
                    .fontColor('#94A3B8')
                    .margin({ bottom: 8 })
                  
                  Row() {
                    Text() {
                      Span('¥').fontSize(12)
                      Span(item.price.toString()).fontSize(18)
                    }
                    .fontColor('#FF6D00') // 价格橙色
                    .fontWeight(FontWeight.Bold)

                    Text(`x${item.quantity}`)
                      .fontSize(14)
                      .fontColor('#64748B')
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
            }
            .margin({ bottom: 12, left: 16, right: 16 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 12, bottom: 12 })

        // 底部结算栏：显示总价和提交按钮
        Row() {
          Row() {
            Text('总计: ')
              .fontSize(14)
              .fontColor('#64748B')
            Text(`¥${this.getCartTotal().toFixed(2)}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6D00') // 价格橙色
          }
          
          Button('提交订单')
            .backgroundColor('#4CD9C0') // 薄荷绿
            .fontColor(Color.White)
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width(120)
            .borderRadius(16)
            .onClick(() => {
              this.submitOrder()
            })
        }
        .width('100%')
        .height(80)
        .backgroundColor(Color.White)
        .padding({ left: 24, right: 24 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.05)', offsetY: -4 })
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180, 
      colors: [['#D1F2EB', 0.0], ['#E0F7FA', 0.3], ['#FFFFFF', 1.0]] 
    })
  }
}
