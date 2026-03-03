import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct OrderConfirm {
  @State doctorId: number = 0;
  @State date: string = '';
  @State time: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.doctorId = params['doctorId'] as number;
      this.date = params['date'] as string;
      this.time = params['time'] as string;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('<')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onClick(() => router.back())
          .margin({ right: 10 });
        Text('预约确认')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
        Text('') // 占位
      }
      .width('100%')
      .padding(10)
      .backgroundColor(Color.White)

      Column({ space: 20 }) {
        Text('预约信息确认')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })

        Row() {
          Text('医生ID:').width(80).fontColor('#666')
          Text(this.doctorId.toString())
        }
        
        Row() {
          Text('日期:').width(80).fontColor('#666')
          Text(this.date)
        }

        Row() {
          Text('时间:').width(80).fontColor('#666')
          Text(this.time)
        }

        Button('确认预约')
          .width('80%')
          .margin({ top: 40 })
          .onClick(() => {
            promptAction.showToast({ message: '预约成功！' });
            router.back();
          })
      }
      .padding(20)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}