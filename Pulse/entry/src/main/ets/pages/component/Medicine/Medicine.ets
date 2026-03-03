import { ICartItem, IOrder } from '../../data/Data';
import MedicineList from './MedicineList'
import MedicineCart from './MedicineCart'
import MedicineOrder from './MedicineOrder'
import { StorageUtil, STORAGE_KEYS } from '../../utils/StorageUtil';

@Component
export default struct MaiYao {
  @State currentMainTab: number = 0
  @State searchKeyword: string = ''
  @State searchHistory: string[] = []
  @State isSearchFocused: boolean = false

  @State mainTabs: string[] = ['药品浏览', '购物车', '我的订单']

  // 购物车数据（用于角标）
  @StorageLink('cart') @Watch('onCartChange') cart: ICartItem[] = []
  
  async aboutToAppear() {
    // 如果购物车不存在则初始化
    if (!AppStorage.Has('cart')) {
      const savedCart = await StorageUtil.getData<ICartItem[]>(STORAGE_KEYS.CART, []);
      AppStorage.SetOrCreate('cart', savedCart)
    }
  }

  async onCartChange() {
    await StorageUtil.saveData(STORAGE_KEYS.CART, this.cart);
  }


  performSearch(value: string) {
    this.searchKeyword = value
    if (value && !this.searchHistory.includes(value)) {
      this.searchHistory.unshift(value)
      if (this.searchHistory.length > 5) {
        this.searchHistory.pop()
      }
    }
    this.isSearchFocused = false
  }

  @Builder builderMainTab(item: string, index: number) {
    Column() {
      // 购物车角标
      Stack({ alignContent: Alignment.TopEnd }) {
        Text(item)
          .fontSize(16)
          .fontWeight(index == this.currentMainTab ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(index == this.currentMainTab ? '#4CD9C0' : '#64748B')
        
        if (item === '购物车' && this.cart.length > 0) {
          Circle({ width: 8, height: 8 })
            .fill('#EF4444')
            .margin({ top: -2, right: -8 })
        }
      }

      // 指示线
      if (index == this.currentMainTab) {
        Divider()
          .width(24)
          .strokeWidth(3)
          .color('#4CD9C0')
          .margin({ top: 4 })
          .lineCap(LineCapStyle.Round)
      }
    }
    .width('100%')
    .height(44)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(255,255,255,0.8)') // 半透明背景
  }

  build() {
    Column({ space: 0 }) {
      // 顶部区域：包含标题栏和搜索框
      Column() {
        // 标题栏：显示应用名称和通知图标
        Row() {
          Text('在线买药')
            .fontSize(24)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
          
          // 通知图标及红点
          Stack() {
            Text()
              .width(24)
              .height(24)

          }
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 12, bottom: 12 })

        // 搜索栏区域
      Column() {
        Row() {
          Image($rawfile('Pulse/Common/foreground.png'))
            .width(18)
            .height(18)
            .fillColor('#94A3B8')
            .margin({ left: 12 })
          
          // 搜索输入框
          TextInput({ placeholder: '搜索药品名称', text: this.searchKeyword })
            .placeholderColor('#94A3B8')
            .backgroundColor(Color.Transparent)
            .height(36)
            .fontSize(14)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.searchKeyword = value 
            })
            .onFocus(() => {
              this.isSearchFocused = true 
            })
            .onSubmit(() => {
              this.performSearch(this.searchKeyword) 
            })
        }
        .width('92%')
        .height(36)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .alignItems(VerticalAlign.Center)
        // 动态调整下边距：当显示搜索历史时，移除下边距以连接历史记录列表
        .margin({ bottom: this.isSearchFocused && this.searchHistory.length > 0 ? 0 : 16 })

        // 搜索历史下拉列表
        if (this.isSearchFocused && this.searchHistory.length > 0) {
          Column() {
            List() {
              ForEach(this.searchHistory, (item: string) => {
                ListItem() {
                  Row() {
                    Image($rawfile('Pulse/Common/foreground.png'))
                      .width(16)
                      .height(16)
                      .fillColor('#94A3B8')
                      .margin({ right: 10 })
                    
                    Text(item)
                      .fontSize(14)
                      .fontColor('#1E293B')
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                  .onClick(() => {
                    this.searchKeyword = item
                    this.isSearchFocused = false 
                  })
                }
              })
              
              // 底部清除历史按钮
              ListItem() {
                Text('清除历史记录')
                  .fontSize(12)
                  .fontColor('#94A3B8')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding(12)
                  .onClick(() => {
                    this.searchHistory = [] 
                  })
              }
            }
            .divider({ strokeWidth: 1, color: '#F1F5F9', startMargin: 16, endMargin: 16 })
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius({ bottomLeft: 12, bottomRight: 12 })
          .margin({ bottom: 16 })
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
        }
      }
      }
      .width('100%')
      .linearGradient({
        angle: 180,
        colors: [['#4CD9C0', 0.0], ['#80CBC4', 1.0]] // 薄荷绿渐变
      })
      .padding({ top: 8, bottom: 8 })
      .borderRadius({ bottomLeft: 24, bottomRight: 24 })

      // 主要内容区域：使用 Tabs 组件管理三个主页面
      Column() {
        Tabs({ barPosition: BarPosition.Start, index: this.currentMainTab }) {
          ForEach(this.mainTabs, (item: string, index: number) => {
            TabContent() {
              if (index === 0) {
                // --- 药品浏览 Tab ---
                // 传入 searchKeyword 实现跨组件搜索联动
                MedicineList({ searchKeyword: $searchKeyword, currentTab: this.currentMainTab })
              } else if (index === 1) {
                // --- 购物车 Tab ---
                // 传入 orders 用于生成新订单，currentMainTab 用于跳转
                MedicineCart({ currentMainTab: $currentMainTab })
              } else if (index === 2) {
                // --- 我的订单 Tab ---
                MedicineOrder({ currentTab: this.currentMainTab })
              }
            }
            .tabBar(this.builderMainTab(item, index)) // 使用自定义 TabBar
          })
        }
        .width('100%')
        .height('100%')
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.currentMainTab = index // 保持 Tab 索引同步
        })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff')
  }
}