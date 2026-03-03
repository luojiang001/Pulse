import { ITab_main, ICartItem, IOrder, IRegistrationRecord, Patient } from './data/Data'
import { HomeTab } from './component/ShouYe/HomeTab'
import Medicine from "./component/Medicine/Medicine"
import { WoDe } from './component/WoDe/WoDe'
import { StorageUtil, STORAGE_KEYS } from './utils/StorageUtil'
import { PreferencesUtil } from './utils/fileUtils'

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import { FloatingBallMap } from './component/Map/FloatingBallMap'
import { AI } from './Ai/AI'

@Entry
@Component
struct Main {
  @State curIndex:number=0
  @State curColor:ResourceColor='#4CD9C0' // 清新薄荷绿
  @State contentOpacity:number=1
  @State tabArr:ITab_main[]=[
    {id:1,name:'首页',photo:$r('app.media.Component1')},
    {id:2,name:'医药',photo:$r('app.media.Component2')},
    {id:3,name:'AI',photo:$r('app.media.Component3')},
    // {id:4,name:'导航',photo:$rawfile('Pulse/Common/navigation.png')},
    {id:5,name:'我的',photo:$r('app.media.Component4')}
  ]

  // 全局拦截器：检查登录状态
  aboutToAppear() {
    console.info('Main Page aboutToAppear');
    this.initApp();
  }

  async initApp() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await StorageUtil.init(context);
      PreferencesUtil.init(context);

      // 全局数据预加载
      if (!AppStorage.Has('cart')) {
        const savedCart = await StorageUtil.getData<ICartItem[]>(STORAGE_KEYS.CART, []);
        AppStorage.SetOrCreate('cart', savedCart);
      }
      if (!AppStorage.Has('orders')) {
        const savedOrders = await StorageUtil.getData<IOrder[]>(STORAGE_KEYS.ORDERS, []);
        AppStorage.SetOrCreate('orders', savedOrders);
      }
      if (!AppStorage.Has('registrationRecords')) {
        let savedRecords = await StorageUtil.getData<IRegistrationRecord[]>(STORAGE_KEYS.REGISTRATIONS, []);
        // 初始化模拟数据
        if (savedRecords.length === 0) {
          savedRecords = [
            { id: '1', doctorName: '张医生', department: '心内科', time: '明天 09:00', status: 'upcoming', createTime: Date.now() },
            { id: '2', doctorName: '李医生', department: '呼吸科', time: '2023-10-20 14:30', status: 'completed', createTime: Date.now() - 86400000 },
            { id: '3', doctorName: '王医生', department: '皮肤科', time: '2023-10-15 10:00', status: 'completed', createTime: Date.now() - 172800000 }
          ];
          await StorageUtil.saveData(STORAGE_KEYS.REGISTRATIONS, savedRecords);
        }
        AppStorage.SetOrCreate('registrationRecords', savedRecords);
      }

      // 初始化就诊人数据 (USER_INFO)
      let savedPatients = await StorageUtil.getData<Patient[]>(STORAGE_KEYS.USER_INFO, []);
      if (savedPatients.length === 0) {
        savedPatients = [
          { id: 1, name: '张三', age: 30, gender: '男', phone: '138****5678', idCard: '110101199001011234', isDefault: true },
          { id: 2, name: '李四', age: 28, gender: '女', phone: '139****1234', idCard: '110101199202025678', isDefault: false }
        ];
        await StorageUtil.saveData(STORAGE_KEYS.USER_INFO, savedPatients);
      }
      
      const persistedUser = await PreferencesUtil.getUserData();
      if (persistedUser) {
        AppStorage.SetOrCreate('userData', persistedUser);
        AppStorage.SetOrCreate('isLoggedIn', true);
      } else {
        AppStorage.SetOrCreate('isLoggedIn', false);
        router.replaceUrl({ url: 'pages/LoginView' });
      }

      console.info('StorageUtil initialized successfully');
    } catch (err) {
      console.error('Main Page initApp error:', JSON.stringify(err));
    }
  }

  onPageShow() {
    
    if (AppStorage.Has('isLoggedIn')) {
       const isLoggedIn = AppStorage.Get<boolean>('isLoggedIn');
       console.info(`Main Page onPageShow: isLoggedIn = ${isLoggedIn}`);
       if (!isLoggedIn) {
         console.info('未登录，跳转至登录页');
         promptAction.showToast({ message: '请先登录' });
         router.replaceUrl({ url: 'pages/LoginView' });
       }
    }
  }

  onTabClicked(index: number) {
    this.contentOpacity = 0
    this.curIndex = index
    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
      this.contentOpacity = 1
    })
  }

  @Builder ContentArea() {
    Column() {
      if (this.curIndex === 0) {
        HomeTab()
      } else if (this.curIndex === 1) {
        Medicine()
      } else if (this.curIndex === 2) {
        AI()
      } else if (this.curIndex === 3) {
        WoDe()
      }
    }
    .opacity(this.contentOpacity)
    .width('100%')
    .height('100%')
  }

  @Builder BottomNav() {
    Stack() {
      if (this.tabArr[this.curIndex]) {
        Image(this.tabArr[this.curIndex].photo)
          .width('100%')
          .height(80)
      }
      Row() {
        ForEach(this.tabArr, (item: ITab_main, index: number) => {
          Column() {
            // 点击区域，保持透明不渲染内容
          }
          .layoutWeight(1)
          .height('100%')
          .onClick(() => this.onTabClicked(index))
        })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height(72)
    .backgroundColor(Color.White)
  }

  build() {
    Stack() {
      Column() {
        Column() {
          this.ContentArea()
        }
        .layoutWeight(1)
        .width('100%')

        this.BottomNav()
      }
      .height('100%')
      .width('100%')

      // 悬浮球组件
      FloatingBallMap()
    }
    .height('100%')
    .width('100%')
  }
}
//医生你好
