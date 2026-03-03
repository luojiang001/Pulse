import router from '@ohos.router';
import { IOrder, ICartItem, DEFAULT_ORDER } from '../../data/Data';

@Entry
@Component
struct MedicineOrderDetail {
  @State order: IOrder = DEFAULT_ORDER

  // 获取页面路由参数
  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    // 检查参数是否存在
    if (params && params['order']) {
      this.order = params['order'] as IOrder
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image("http://47.101.196.181:9000/department-grid/return.png")
          .width(24)
          .height(24)
          .onClick(() => {
            router.back() // 返回上一页
          })
        
        Text('订单详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ left: 15 })
      }
      .width('100%')
      .height(50)
      .padding({ left: 15, right: 15 })
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)

      // 只有当获取到订单数据时才渲染内容
      if (this.order.id) {
        Scroll() {
          Column() {
            // 订单状态卡片
            Column() {
              Text(this.order.status === 'completed' || this.order.status === 'paid' ? '已完成' : '处理中')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#007fff')
                .margin({ bottom: 5 })
              Text('感谢您的购买')
                .fontSize(14)
                .fontColor('#666')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .margin({ bottom: 10 })
            .alignItems(HorizontalAlign.Start)

            // 订单商品列表卡片
            Column() {
              Text('商品信息')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })
                .width('100%')

              ForEach(this.order.items, (item: ICartItem) => {
                Row() {
                  Image(item.image)
                    .width(60)
                    .height(60)
                    .objectFit(ImageFit.Contain)
                    .backgroundColor('#f9f9f9')
                    .borderRadius(8)
                  
                  Column() {
                    Text(item.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                    Text(item.manufacturer)
                      .fontSize(12)
                      .fontColor('#999')
                      .margin({ top: 4 })
                    Row() {
                      Text(`¥${item.price}`)
                        .fontColor('#FF0000')
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                      Text(`x${item.quantity}`)
                        .fontSize(14)
                        .fontColor('#666')
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .margin({ top: 8 })
                  }
                  .layoutWeight(1)
                  .padding({ left: 10 })
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .margin({ bottom: 15 })
              })
            }
            .width('100%')
            .padding(15)
            .backgroundColor(Color.White)
            .margin({ bottom: 10 })

            // 订单信息
            Column() {
              Row() {
                Text('订单编号')
                  .fontSize(14)
                  .fontColor('#666')
                Text(this.order.id)
                  .fontSize(14)
                  .fontColor('#333')
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 10 })

              Row() {
                Text('下单时间')
                  .fontSize(14)
                  .fontColor('#666')
                Text(new Date(this.order.createTime).toLocaleString())
                  .fontSize(14)
                  .fontColor('#333')
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 10 })

              Divider().color('#f0f0f0').margin({ bottom: 10 })

              Row() {
                Text('实付金额')
                  .fontSize(14)
                  .fontColor('#333')
                Text(`¥${this.order.totalAmount.toFixed(2)}`)
                  .fontSize(18)
                  .fontColor('#FF0000')
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .padding(15)
            .backgroundColor(Color.White)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
