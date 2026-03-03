import { IRegistrationRecord, User } from '../../data/Data'
import { Constants } from '../../../common/Constants'
import axios, { AxiosResponse } from '@ohos/axios';
import promptAction from '@ohos.promptAction';
import { PreferencesUtil } from '../../utils/fileUtils';
import router from '@ohos.router';

@CustomDialog
struct RecordsDialog {
  controller?: CustomDialogController
  @StorageLink('registrationRecords') records: IRegistrationRecord[] = []
  @State isLoading: boolean = false
  private readonly BASE_URL: string = Constants.BASE_URL;

  aboutToAppear() {
    this.fetchRecords()
  }

  async fetchRecords() {
    this.isLoading = true
    try {
      // 获取当前登录用户
      const user = await PreferencesUtil.getUserData();
      if (!user) {
        promptAction.showToast({ message: '请先登录查看挂号记录' });
        this.isLoading = false;
        return;
      }

      // 使用当前用户ID发起请求
      // 注意：后端 Controller 的 @RequestMapping 是 "registrationRecord"，方法是 "/record/list"
      // 所以完整路径应该是 /registrationRecord/record/list
      const response: AxiosResponse = await axios.get(`${this.BASE_URL}/registrationRecord/record/list`, {
        params: { userId: user.id }, 
        timeout: 10000
      })

      if (response.status === 200 && response.data.code === 200) {
        this.records = response.data.data as IRegistrationRecord[];
      }
    } catch (error) {
      console.error('Fetch records error:', JSON.stringify(error));
      let msg = '获取失败';
      if (error.message) {
        msg += `: ${error.message}`;
      } else if (error.response) {
        msg += `: HTTP ${error.response.status}`;
      } else {
        msg += `: ${JSON.stringify(error)}`;
      }
      promptAction.showToast({ message: msg });
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      Text('挂号记录查询')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15, top: 10 })
      
      Divider().color('#eee')

      if (this.records.length === 0) {
        Column() {
          Image($rawfile('Pulse/Common/foreground.png')) // Placeholder
            .width(50).height(50).fillColor('#ccc').margin({ bottom: 10 })
          Text('暂无挂号记录')
            .fontSize(16)
            .fontColor('#999')
        }
        .height(150)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.records, (item: IRegistrationRecord) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.doctorName)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333')
                  Text(`${item.department} | ${item.time}`)
                    .fontSize(14)
                    .fontColor('#666')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(item.status === 'upcoming' ? '待就诊' : (item.status === 'completed' ? '已完成' : '已取消'))
                  .fontSize(14)
                  .fontColor(item.status === 'upcoming' ? '#007fff' : (item.status === 'completed' ? '#4CAF50' : '#999'))
                  .backgroundColor(item.status === 'upcoming' ? '#E3F2FD' : (item.status === 'completed' ? '#E8F5E9' : '#F5F5F5'))
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(4)
              }
              .width('100%')
              .onClick(() => {
                this.controller?.close()
                if (item.doctorId) {
                  // Construct a User object for Chat
                  const targetUser: User = {
                    id: item.doctorId,
                    username: item.doctorName,
                    nickname: item.doctorName,
                    avatar: item.doctorAvatar || '',
                    password: '',
                    phone: '',
                    cratedAt: new Date()
                  };
                  router.pushUrl({
                    url: 'pages/component/ShouYe/Chat',
                    params: { user: targetUser }
                  })
                }
              })
              .padding({ top: 12, bottom: 12 })
              .border({ width: { bottom: 1 }, color: '#f5f5f5' })
            }
          })
        }
        .width('100%')
        .height(250)
      }

      Button('关闭')
        .onClick(() => this.controller?.close())
        .width('80%')
        .height(40)
        .margin({ top: 15, bottom: 10 })
        .backgroundColor('#007fff')
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }
}

@Component
export struct HomeHeaderComponent {
  @State unreadCount: number = 0;
  private readonly BASE_URL = Constants.BASE_URL;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: RecordsDialog(),
    autoCancel: true,
    customStyle: true 
  })

  // 接收父组件传入的搜索回调
  onSearch: (keyword: string) => void = () => {}

  aboutToAppear() {
    this.fetchUnreadCount();
  }

  async fetchUnreadCount() {
    try {
      const user = await PreferencesUtil.getUserData();
      if (user) {
        const response: AxiosResponse = await axios.get(`${this.BASE_URL}/chat/unread`, {
          params: { userId: user.id }
        });
        if (response.status === 200 && response.data.code === 200) {
          this.unreadCount = response.data.data;
        }
      }
    } catch (error) {
      console.error('Fetch unread count failed:', JSON.stringify(error));
    }
  }

  build() {
    Column() {
      Row(){
        Text('在线挂号')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        
        Stack({ alignContent: Alignment.TopEnd }) {
           Image($r('app.media.kefu'))
             .width(24)
             .height(24)
             .fillColor(Color.White)
           
           if (this.unreadCount > 0) {
             Circle({ width: 8, height: 8 })
               .fill('#EF4444')
               .margin({ top: 0, right: 0 }) 
           }
        }
        .width(30)
        .height(30)
        .onClick(() => {
           router.pushUrl({ url: 'pages/component/ShouYe/MessageList' })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
      


      Row() {
        Image($r('app.media.search'))
          .width(18) // 标准图标大小
          .height(18)
          .margin({ left: 12, right: 8 })
        
        TextInput({ placeholder: '搜索医生' })
          .placeholderColor('#94A3B8') 
          .fontSize(14) // 标准正文大小
          .backgroundColor(Color.Transparent)
          .height('100%')
          .layoutWeight(1)
          .onChange((value: string) => {
            if (this.onSearch) {
              this.onSearch(value)
            }
          })
      }
      .width('90%')
      .height(36) // 搜索栏标准高度
      .backgroundColor('#FFFFFF')
      .borderRadius(18) // 全圆角
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 16 }) 

      Button('挂号记录')
        .width('90%')
        .height(44) // 按钮标准高度
        .backgroundColor('rgba(255,255,255,0.3)') // 增加透明度
        .fontColor('#FFFFFF') 
        .fontSize(16) // 按钮文字大小
        .fontWeight(FontWeight.Medium) 
        .borderRadius(8) // 圆角
        .margin({ bottom: 16 }) 
        .onClick(() => {
          this.dialogController.open()
        })
    }
    .width('100%')
    .linearGradient({
        angle: 180,
        colors: [['#4CD9C0', 0.0], ['#80CBC4', 1.0]] // 薄荷绿渐变
    })
    .borderRadius({ bottomLeft: 16, bottomRight: 16 }) // 底部圆角
  }
}
