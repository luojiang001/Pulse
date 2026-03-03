import router from '@ohos.router';
import web_webview from '@ohos.web.webview';

@Entry
@Component
struct PaymentPage {
  @State url: string = ''
  controller: web_webview.WebviewController = new web_webview.WebviewController()

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params && params['url']) {
      this.url = params['url'] as string
    }
  }

  aboutToDisappear() {
    // 离开支付页面时（通常是返回），设置全局标志通知订单列表刷新
    AppStorage.SetOrCreate('RefreshOrderList', true);
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image("http://47.101.196.181:9000/department-grid/return.png")
          .width(24)
          .height(24)
          .onClick(() => {
            // 手动点击返回时，也触发刷新，确保万无一失
            AppStorage.SetOrCreate('RefreshOrderList', true);
            // 延迟一点点返回，确保 AppStorage 设置生效
            setTimeout(() => {
                router.back() 
            }, 50)
          })
        
        Text('支付')
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

      // Web组件加载支付页面
      if (this.url) {
        Web({ src: this.url, controller: this.controller })
          .width('100%')
          .layoutWeight(1)
          .domStorageAccess(true)
          .javaScriptAccess(true)
      } else {
        Column() {
          Text('无效的支付链接')
            .fontSize(16)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
