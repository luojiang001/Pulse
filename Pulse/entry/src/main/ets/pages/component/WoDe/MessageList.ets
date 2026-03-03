import router from '@ohos.router';
import http from '@ohos.net.http';
import { INotification, User } from '../../data/Data';
import { Constants } from '../../../common/Constants';

@Entry
@Component
struct MessageList {
  @State messages: INotification[] = [];
  @State isLoading: boolean = true;
  @StorageLink('userData') currentUser: User | null = null;

  aboutToAppear() {
    this.fetchMessages();
  }

  async fetchMessages() {
    if (!this.currentUser) {
      this.isLoading = false;
      return;
    }
    
    let httpRequest = http.createHttp();
    try {
      // Using host IP for emulator access
      let result = await httpRequest.request(
        `${Constants.BASE_URL}/notification/list/${this.currentUser.id}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          },
          readTimeout: 60000,
          connectTimeout: 60000
        }
      );
      
      interface ResponseData {
        code: number;
        data: INotification[];
      }

      let res = JSON.parse(result.result.toString()) as ResponseData;
      if (res.code === 200) {
        this.messages = res.data;
      }
    } catch (err) {
      console.error('Fetch messages failed', JSON.stringify(err));
    } finally {
      this.isLoading = false;
      httpRequest.destroy();
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('<') 
          .fontSize(24)
          .padding(10)
          .onClick(() => {
            try {
              router.back();
            } catch (e) {
              console.error('router back error:', JSON.stringify(e));
            }
          })
        Text('消息通知')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 44 }) 
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .backgroundColor(Color.White)

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 50 })
      } else if (this.messages.length === 0) {
        Column() {
          Image($rawfile('Pulse/Common/foreground.png'))
            .width(100)
            .height(100)
            .fillColor('#E2E8F0')
            .margin({ bottom: 16 })
          Text('暂无消息')
            .fontSize(16)
            .fontColor('#999')
        }
        .width('100%')
        .margin({ top: 100 })
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.messages, (msg: INotification) => {
            ListItem() {
              Column() {
                Row() {
                  // 消息类型标签
                  Text(msg.type === 'ALL' ? '公告' : '通知')
                    .fontSize(10)
                    .fontColor(Color.White)
                    .backgroundColor(msg.type === 'ALL' ? '#FF9800' : '#4CD9C0')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .margin({ right: 8 })

                  Text(msg.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333')
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(msg.createTime ? new Date(msg.createTime).toLocaleDateString() : '')
                    .fontSize(12)
                    .fontColor('#999')
                    .margin({ left: 8 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .margin({ bottom: 8 })

                Text(msg.content)
                  .fontSize(14)
                  .fontColor('#666')
                  .width('100%')
                  .lineHeight(20)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
            }
            .padding({ left: 16, right: 16, bottom: 12 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 12 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}
