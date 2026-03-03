import { IRegistrationRecord, IPrescriptionRecord, User, INotification } from '../../data/Data';
import { StorageUtil, STORAGE_KEYS } from '../../utils/StorageUtil';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { PreferencesUtil } from '../../utils/fileUtils';
import { Constants } from '../../../common/Constants';
import { common } from '@kit.AbilityKit';
import http from '@ohos.net.http';

@Component
export struct WoDe {
  // 挂号记录
  @StorageLink('registrationRecords') registrationRecords: IRegistrationRecord[] = []
  
  // 处方记录
  @StorageLink('prescriptions') prescriptions: IPrescriptionRecord[] = []

  // 用户信息
  @StorageLink('userData') @Watch('updateUserInfo') currentUser: User | null = null;
  
  // 用于 UI 显示的计算属性或状态
  @State userName: string = '请登录';
  @State userPhone: string = '';
  @State userIntro: string = '暂无简介';
  @State photo: string='';
  @State messages: INotification[] = [];

  async aboutToAppear() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      PreferencesUtil.init(context);
    } catch (e) {
      console.error('WoDe context init error:', e);
    }

    // 尝试从 AppStorage 获取用户信息
    if (AppStorage.Has('userData')) {
      this.updateUserInfo();
    } else {
      const userData = await PreferencesUtil.getUserData();
      if (userData) {
        AppStorage.SetOrCreate('userData', userData);
        this.updateUserInfo();
      }
    }

    // Load other data...
    if (!AppStorage.Has('registrationRecords')) {
      let savedRecords = await StorageUtil.getData<IRegistrationRecord[]>(STORAGE_KEYS.REGISTRATIONS, []);
      AppStorage.SetOrCreate('registrationRecords', savedRecords);
    }

    if (!AppStorage.Has('prescriptions')) {
      let savedPrescriptions = await StorageUtil.getData<IPrescriptionRecord[]>(STORAGE_KEYS.PRESCRIPTIONS, []);
      AppStorage.SetOrCreate('prescriptions', savedPrescriptions);
    }
    

    this.fetchMessages();
  }

  async fetchMessages() {
    if (!this.currentUser) return;
    let httpRequest = http.createHttp();
    try {
      let result = await httpRequest.request(
        `${Constants.BASE_URL}/notification/list/${this.currentUser.id}`,
        { method: http.RequestMethod.GET }
      );
      
      // Define a simple interface for the response structure
      interface ResponseData {
        code: number;
        data: INotification[];
      }
      
      let res = JSON.parse(result.result.toString()) as ResponseData;
      if (res.code === 200) {
        this.messages = res.data.slice(0, 2); 
      }
    } catch (e) {
      console.error('Fetch messages error', JSON.stringify(e));
    }
  }

  updateUserInfo() {
    if (this.currentUser) {
      // 根据 Data.ets 中的 User 接口，字段是 username 和 phone
      this.userName = this.currentUser.nickname || this.currentUser.username || '用户';
      this.userPhone = this.currentUser.phone || '';
      this.userIntro = this.currentUser.intro || '暂无简介';
      this.photo=this.currentUser.avatar;
    }
  }

  async handleLogout() {
    try {
      AppStorage.SetOrCreate('isLoggedIn', false);
      AppStorage.SetOrCreate('userData', null);
      await PreferencesUtil.clearUserData();
      promptAction.showToast({ message: '已退出登录' });
      router.replaceUrl({ url: 'pages/LoginView' });
    } catch (e) {
      console.error('Logout failed:', JSON.stringify(e));
      promptAction.showToast({ message: '退出失败，请重试' });
    }
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          // 1. 顶部用户信息区域
          Stack({ alignContent: Alignment.Bottom }) {
            // 渐变背景
            Column()
              .width('100%')
              .height(200) 
              .linearGradient({
                angle: 180,
                colors: [['#4CD9C0', 0.0], ['#80CBC4', 1.0]] // 薄荷绿渐变
              })
              .borderRadius({ bottomLeft: 24, bottomRight: 24 })
            
            // 用户资料
            Row() {
              // 头像
              Image(this.photo)
                .width(72) 
                .height(72)
                .borderRadius(36)
                .backgroundColor('#FFFFFF')
                .padding(2) 
                .margin({ right: 16 })

              Column() {
                Text(this.userName)
                  .fontSize(24) 
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .margin({ bottom: 4 })
                
                Text(this.userIntro)
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.8)')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 24, bottom: 80 }) 
          }
          .height(200)
          .width('100%')
          .margin({ bottom: -50 }) 

          // 2. 我的功能入口 (水平排列)
          Row() {
            this.FunctionItem('就诊人管理', 'pages/component/WoDe/PatientManager')
          }
          .width('92%')
          .height(88)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({ bottom: 24})
          .shadow({ radius: 16, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          // 3. 菜单列表
          Column({ space: 1 }) {
            this.MenuItem('个人信息设置', '编辑头像、昵称、手机号', () => {
              try {
                router.push({ url: 'pages/component/WoDe/Formartion' })
              } catch (err) {
                promptAction.showToast({ message: '页面跳转失败' })
              }
            })
            Divider().color('#F1F5F9').padding({ left: 56 })
            this.MenuItem('处方管理', '查看电子处方', () => {
               router.push({ url: 'pages/component/WoDe/PrescriptionManager' })
            })
            Divider().color('#F1F5F9').padding({ left: 56 })
            this.MenuItem('订单管理', '查看所有订单', () => {
               router.pushUrl({ url: 'pages/component/WoDe/OrderManager' })
            })
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(16)
          .padding({ top: 8, bottom: 8 })
          .shadow({ radius: 16, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
          .margin({ bottom: 24 })

          // 4. 消息通知
          Column() {
            Row() {
              // 铃铛图标
              Stack() {
                 Circle({ width: 8, height: 8 }).fill('#EF4444').margin({ top: 0, right: 0 }).zIndex(1)
                 Image($rawfile('Pulse/Common/foreground.png')).width(24).height(24).fillColor('#FF5252') 
              }.width(30).height(30).alignContent(Alignment.TopEnd).margin({ right: 12 })

              Text('消息通知')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1E293B')
              
              Blank()

              Text('查看全部')
                .fontSize(14)
                .fontColor('#4CD9C0') // 薄荷绿
                .onClick(() => {
                  router.pushUrl({ url: 'pages/component/WoDe/MessageList' });
                })
            }
            .width('100%')
            .padding(16)
            .border({ width: { bottom: 1 }, color: '#F1F5F9' })

            // 消息列表
            if (this.messages.length > 0) {
               ForEach(this.messages, (msg: INotification) => {
                 this.NotificationItem(msg.title, msg.content, msg.createTime ? new Date(msg.createTime).toLocaleDateString() : '')
               })
            } else {
               Text('暂无新消息')
                 .fontSize(14)
                 .fontColor('#94A3B8')
                 .margin({ top: 16, bottom: 16 })
                 .alignSelf(ItemAlign.Center)
            }
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(16)
          .shadow({ radius: 16, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
          .margin({ bottom: 24 })

          // 5. 设置
          Column() {
             this.MenuItem('退出登录', '', () => {
               this.handleLogout()
             })
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(16)
          .shadow({ radius: 16, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
          .margin({ bottom: 40 })

        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 180, 
        colors: [['#D1F2EB', 0.0], ['#E0F7FA', 0.3], ['#FFFFFF', 1.0]] 
      })
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder FunctionItem(title: string, url: string) {
      Image($r('app.media.patient')).width(32).height(32).margin({bottom: 8})
      Text(title)
        .fontSize(20)
        .fontColor('#1E293B')
        .fontWeight(FontWeight.Medium)
        .margin({left:20})
    .onClick(() => {
       if (url.includes('PatientManager') && !this.currentUser) {
          promptAction.showToast({ message: '请先登录' });
          return;
       }
       router.pushUrl({ url: url }).catch((err: Error) => {
         promptAction.showToast({ message: '功能开发中...' });
       });
    })
  }

  @Builder MenuItem(title: string, subtitle: string, onClick?: () => void) {
    Row() {
      // 图标 placeholder
      Image($rawfile('Pulse/Common/foreground.png'))
        .width(24)
        .height(24)
        .margin({ right: 16 })
        .fillColor(this.getIconColor(title))
        .backgroundColor(this.getIconBgColor(title))
        .padding(4)
        .borderRadius(8)

      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#1E293B')
          .fontWeight(FontWeight.Medium)
        if (subtitle) {
          Text(subtitle)
            .fontSize(12)
            .fontColor('#94A3B8')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($rawfile('Pulse/Common/foreground.png')) // Arrow icon
        .width(16)
        .height(16)
        .fillColor('#CBD5E1')
    }
    .width('100%')
    .padding(16)
    .onClick(() => {
      if (onClick) onClick()
    })
  }

  @Builder NotificationItem(title: string, content: string, time: string) {
    Column() {
      Row() {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1E293B')
          .margin({ bottom: 4 })
        
        Blank()
        
        Text(time)
          .fontSize(12)
          .fontColor('#94A3B8')
      }
      .width('100%')
      
      Text(content)
        .fontSize(13)
        .fontColor('#64748B')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  getIconColor(title: string): string {
    if (title.includes('就诊人')) return '#448AFF'
    if (title.includes('处方')) return '#00C853'
    if (title.includes('订单')) return '#FF6D00'
    if (title.includes('设置')) return '#607D8B'
    return '#333'
  }

  getIconBgColor(title: string): string {
    if (title.includes('就诊人')) return '#E3F2FD'
    if (title.includes('处方')) return '#E8F5E9'
    if (title.includes('订单')) return '#FFF3E0'
    if (title.includes('设置')) return '#ECEFF1'
    return '#f5f5f5'
  }
}
