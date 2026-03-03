import { IMedicine, ICartItem,ICategory, IPrescriptionRecord, PrescriptionCheckResult } from '../../data/Data';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import axios, { AxiosResponse } from '@ohos/axios';
import { Constants } from '../../../common/Constants';

interface HighlightPart {
  id: number
  content: string
  isHighlight: boolean
}

interface PageInfo<T> {
  list: T[]
  total: number
  pageNum: number
  pageSize: number
  pages: number
  size: number
  startRow: number
  endRow: number
  prePage: number
  nextPage: number
  isFirstPage: boolean
  isLastPage: boolean
  hasPreviousPage: boolean
  hasNextPage: boolean
  navigatePages: number
  navigatepageNums: number[]
}

@Component
export default struct MedicineList {
  @Link @Watch('onFilterChange') searchKeyword: string
  @Prop currentTab: number // 接收当前 Tab 索引
  @StorageLink('cart') @Watch('onCartChange') cart: ICartItem[] = []
  @StorageLink('prescriptions') prescriptions: IPrescriptionRecord[] = []

  @State curCategoryIndex: number = 0

  // 监听 Tab 切换，当切换回本页面(index=0)时，强制刷新状态
  @Watch('onTabChange')
  @State watchTab: number = 0
  
  aboutToAppear() {
    this.watchTab = this.currentTab
    this.watchKeyword = this.searchKeyword // 初始化
    this.initData();
    
    // 开发阶段：自动触发一次 ES 数据同步，防止没有数据导致搜索为空
    axios.get(`${Constants.BASE_URL}/medicine/syncEs`).then(() => {
      console.info('Auto ES Sync triggered successfully');
    }).catch((e: Error) => {
      console.warn('Auto ES Sync failed (ignore if production):', e);
    });
  }

  onTabChange() {
    if (this.currentTab === 0) {
      console.info('MedicineList become active, refreshing list')
      this.onFilterChange()
    }
  }
  
  // 分类筛选（子标签页）
  @State categories:ICategory[]=[{ id: 0, name: '全部' }]


  private categoryScroller: Scroller = new Scroller()

  @State medicineList: IMedicine[] = []
  
  // 用于 UI 显示的过滤后列表
  @State filteredList: IMedicine[] = []

  // 监听数据变化，更新 filteredList
  async onFilterChange() {
    if (this.searchKeyword && this.searchKeyword.trim().length > 0) {
      // Server-side search with ES
      await this.searchMedicine(this.searchKeyword);
    } else {
      // Local filtering (Category only)
      this.filteredList = this.getFilteredMedicineList()
    }
  }

  async searchMedicine(keyword: string) {
    try {
      const res: AxiosResponse<PageInfo<IMedicine>> = await axios.get(`${Constants.BASE_URL}/medicine/list`, {
        params: { name: keyword, pageNum: 1, pageSize: 100 }
      });
      if (res.data && res.data.list && Array.isArray(res.data.list)) {
        this.filteredList = res.data.list.map((item: IMedicine) => {
          return {
            id: item.id,
            name: item.name,
            manufacturer: item.manufacturer,
            price: item.price,
            unit: item.unit,
            image: item.image,
            description: item.description,
            efficacy: item.efficacy,
            isPrescription: item.prescription === 1,
            category: item.categoryId ? item.categoryId : 0,
            prescription: item.prescription,
            categoryId: item.categoryId
          } as IMedicine;
        });
      }
    } catch (e) {
      console.error('Search failed', e);
    }
  }
  
  // 监听购物车变化，强制刷新列表以更新购买数量显示
  // 当购物车变化时，重新赋值 filteredList 触发 UI 更新
  onCartChange() {
    // If not searching, refresh local list. If searching, we might want to keep search results?
    // For simplicity, just re-trigger filter logic
    this.onFilterChange()
  }

  // 监听 searchKeyword 和 curCategoryIndex 的变化
  @Watch('onFilterChange') 
  @State watchKeyword: string = ''
  updateCategory(index: number) {
    this.curCategoryIndex = index
    this.onFilterChange()
  }

  // 代理 searchKeyword 的变化 (通过 build 中的逻辑或 @Watch)
  // 更好的方式是在 medicineList 变化或筛选条件变化时更新 DataSource
  
  // ---------------------------------------------------------
  
  getFilteredMedicineList(): IMedicine[] {
    let list = this.medicineList;
    // Only filter by category locally
    if (this.curCategoryIndex !== 0) {
      const selectedId = this.categories[this.curCategoryIndex]?.id;
      if (selectedId !== undefined) {
        list = list.filter(med => med.category === selectedId);
      }
    }
    return list;
  }

  splitHighlight(text: string): HighlightPart[] {
    let parts: HighlightPart[] = [];
    let temp = text;
    let index = 0;
    while(temp.indexOf('<highlight>') !== -1) {
      let start = temp.indexOf('<highlight>');
      let end = temp.indexOf('</highlight>');
      if (start > 0) {
        parts.push({id: index++, content: temp.substring(0, start), isHighlight: false});
      }
      if (end > start) {
        parts.push({id: index++, content: temp.substring(start + 11, end), isHighlight: true});
        temp = temp.substring(end + 12);
      } else {
        break;
      }
    }
    if (temp.length > 0) {
      parts.push({id: index++, content: temp, isHighlight: false});
    }
    return parts;
  }

  @Builder HighlightText(text: string) {
    Text() {
      if (text && text.includes('<highlight>')) {
        ForEach(this.splitHighlight(text), (part: HighlightPart) => {
          Span(part.content)
            .fontColor(part.isHighlight ? Color.Red : '#1E293B')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
        }, (item: HighlightPart) => item.id.toString())
      } else {
        Span(text)
          .fontColor('#1E293B')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }
    }
    .maxLines(1)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
    .width('100%')
  }

  getCartQuantity(medicineId: number | string): number {
    const item = this.cart.find(item => item.id === medicineId)
    return item ? item.quantity : 0
  }

  checkPrescription(medicineName: string): PrescriptionCheckResult {
    // 1. 检查本地 AppStorage 中的处方数据
    if (this.prescriptions && this.prescriptions.length > 0) {
      for (const record of this.prescriptions) {
        // 只检查有效处方
        if (record.status === 'valid' && record.medicines) {
          const match = record.medicines.find(m => m.medicineName === medicineName);
          if (match) {
            return { hasPrescription: true, maxCount: match.count };
          }
        }
      }
    }
    return { hasPrescription: false, maxCount: 0 };
  }

  addToCart(medicine: IMedicine) {
    // 处方药验证：跳转到详情页进行处方选择
    if (medicine.isPrescription) {
      promptAction.showToast({ message: '处方药需在详情页选择处方购买' });
      router.pushUrl({
        url: 'pages/component/Medicine/MedicineDetail',
        params: { medicine: medicine }
      });
      return;
    }
    
    // 非处方药，直接执行添加
    this.processAddToCart(medicine)
  }

  processAddToCart(medicine: IMedicine) {
    const existingItem = this.cart.find(item => item.id === medicine.id)
    if (existingItem) {
      existingItem.quantity += 1
      // 触发 UI 更新
      const index = this.cart.indexOf(existingItem)
      this.cart[index] = {
        id: existingItem.id,
        name: existingItem.name,
        manufacturer: existingItem.manufacturer,
        price: existingItem.price,
        unit: existingItem.unit,
        image: existingItem.image,
        quantity: existingItem.quantity,
        category: existingItem.category,
        description: existingItem.description,
        efficacy: existingItem.efficacy,
        isPrescription: existingItem.isPrescription
      }
    } else {
      this.cart.push({
        id: medicine.id,
        name: medicine.name,
        manufacturer: medicine.manufacturer,
        price: medicine.price,
        unit: medicine.unit,
        image: medicine.image,
        quantity: 1,
        category: medicine.category,
        description: medicine.description,
        efficacy: medicine.efficacy,
        isPrescription: medicine.isPrescription
      })
    }
  }

  removeFromCart(medicine: IMedicine) {
    const existingItem = this.cart.find(item => item.id === medicine.id)
    if (existingItem) {
      if (existingItem.quantity > 1) {
        existingItem.quantity -= 1
        const index = this.cart.indexOf(existingItem)
        this.cart[index] = {
          id: existingItem.id,
          name: existingItem.name,
          manufacturer: existingItem.manufacturer,
          price: existingItem.price,
          unit: existingItem.unit,
          image: existingItem.image,
          quantity: existingItem.quantity,
          category: existingItem.category,
          description: existingItem.description,
          efficacy: existingItem.efficacy,
          isPrescription: existingItem.isPrescription
        }
      } else {
        const index = this.cart.indexOf(existingItem)
        this.cart.splice(index, 1)
      }
    }
  }

  async initData() {
    // 1. 尝试从缓存获取分类数据
    const cachedCategories = AppStorage.Get<ICategory[]>('cachedCategories');
    if (cachedCategories && cachedCategories.length > 1) {
      console.log('使用缓存的分类数据');
      this.categories = cachedCategories;
    } else {
      try {
        console.log('开始请求分类数据');
        await axios.get(`${Constants.BASE_URL}/medicine/categoryList`)
          .then((res: AxiosResponse<ICategory[]>) => {
            if (Array.isArray(res.data)) {
              this.categories = [{ id: 0, name: '全部' }, ...res.data];
              // 存入缓存
              AppStorage.SetOrCreate('cachedCategories', this.categories);
            }
          })
        if (this.categories.length > 1) {
          console.log('分类数据加载成功：', JSON.stringify(this.categories));
        } else {
          console.warn('后端返回数据异常，使用默认分类');
        }

      } catch (error) {
        console.error('加载分类数据失败：', error);
        if (axios.isAxiosError(error)) {
          console.error('错误码：', error.code);
          console.error('响应状态码：', error.response?.status);
          console.error('后端错误信息：', error.response?.data);
        }
        // 失败时仅保留默认分类
        this.categories = [{ id: 0, name: '全部' }];
      }
    }

    // 2. 尝试从缓存获取药品数据
    const cachedMedicineList = AppStorage.Get<IMedicine[]>('cachedMedicineList');
    if (cachedMedicineList && cachedMedicineList.length > 0) {
      console.log('使用缓存的药品数据');
      this.medicineList = cachedMedicineList;
      this.onFilterChange();
    } else {
      try {
        await axios.get(`${Constants.BASE_URL}/medicine/medicineList`)
          .then((res: AxiosResponse<IMedicine[]>) => {
            if (Array.isArray(res.data)) {
              // 映射后端数据到前端模型
              this.medicineList = res.data.map((item: IMedicine) => {
                return {
                  id: item.id,
                  name: item.name,
                  manufacturer: item.manufacturer,
                  price: item.price,
                  unit: item.unit,
                  // 如果是字符串路径，尝试转换为 Resource，否则保留
                  image:item.image,
                  description: item.description,
                  efficacy: item.efficacy,
                  // 映射 prescription (0/1) 到 isPrescription (boolean)
                  isPrescription: item.prescription === 1,
                  // 映射 categoryId 到 category，处理 null 情况
                  category: item.categoryId ? item.categoryId : 0,
                  prescription: item.prescription,
                  categoryId: item.categoryId
                } as IMedicine;
              });
              // 存入缓存
              AppStorage.SetOrCreate('cachedMedicineList', this.medicineList);
              console.log('药品列表加载成功，数量：', this.medicineList.length);
              // 初始化数据源
              this.onFilterChange();
            }
          })
      } catch (error) {
        console.error('加载药品列表数据失败：', error);
        if (axios.isAxiosError(error)) {
          console.error('错误码：', error.code);
          console.error('响应状态码：', error.response?.status);
          console.error('后端错误信息：', error.response?.data);
        }
      }
    }
  }

  build() {
    Column() {
      // 顶部水平滚动的分类标签栏
      Scroll(this.categoryScroller) {
        Row({ space: 12 }) {
          ForEach(this.categories, (cat: ICategory, catIndex: number) => {
            Text(cat.name)
              .fontSize(14)
              // 选中状态颜色高亮
              .fontColor(this.curCategoryIndex === catIndex ? '#FFFFFF' : '#64748B')
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .backgroundColor(this.curCategoryIndex === catIndex ? '#4CD9C0' : '#FFFFFF')
              .borderRadius(16)
              .border({ width: 1, color: this.curCategoryIndex === catIndex ? '#4CD9C0' : '#E2E8F0' })
              .onClick(() => {
                this.updateCategory(catIndex) 
              })
          })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      }
      .scrollable(ScrollDirection.Horizontal) 
      .scrollBar(BarState.Off) 
      .width('100%')

      // 药品展示网格
      Grid() {
        ForEach(this.filteredList, (med: IMedicine) => {
          GridItem() {
            Column() {
              Stack({ alignContent: Alignment.TopStart }) {
                Image(med.image)
                  .width('100%')
                  .height(100)
                  .objectFit(ImageFit.Contain)
                  .margin({ top: 16, bottom: 12 })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/component/Medicine/MedicineDetail',
                      params: { medicine: med }
                    }).catch((err:Error) => {
                       // ... error handling
                    })
                  })

                // Rx / OTC Icon
                if (med.isPrescription) {
                  Text('Rx')
                    .fontSize(10)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                    .backgroundColor('#EF4444') // 危险红
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius({ topLeft: 8, bottomRight: 8 })
                    .margin({ top: 8, left: 8 })
                } else {
                  Text('OTC')
                    .fontSize(10)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                    .backgroundColor('#4CD9C0') // 薄荷绿
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius({ topLeft: 8, bottomRight: 8 })
                    .margin({ top: 8, left: 8 })
                }
              }
              .width('100%')

              Column() {
                this.HighlightText(med.name)

                Text(med.manufacturer)
                  .fontSize(12)
                  .fontColor('#94A3B8')
                  .margin({ top: 4, bottom: 12 })
                  .width('100%')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Row() {
                  Text() {
                    Span('¥').fontSize(12)
                    Span(med.price.toString()).fontSize(18)
                    Span(` /${med.unit}`).fontSize(12).fontColor('#94A3B8')
                  }
                  .fontColor('#FF6D00') // 价格橙色更显眼
                  .fontWeight(FontWeight.Bold)

                  // Add Button with Quantity Display
                  Row() {
                    if (this.getCartQuantity(med.id) > 0) {
                      Button() {
                        Text('-')
                          .fontSize(16)
                          .fontColor('#4CD9C0')
                          .fontWeight(FontWeight.Bold)
                          .offset({ y: -1 })
                      }
                      .width(24)
                      .height(24)
                      .backgroundColor('#FFFFFF')
                      .border({ width: 1, color: '#4CD9C0' })
                      .type(ButtonType.Circle)
                      .onClick(() => {
                        this.removeFromCart(med)
                      })
                      .margin({ right: 8 })

                      Text(`${this.getCartQuantity(med.id)}`)
                        .fontSize(14)
                        .fontColor('#1E293B')
                        .margin({ right: 8 })
                    }

                    Button() {
                      Text('+')
                        .fontSize(16)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Bold)
                        .offset({ y: -1 })
                    }
                    .width(24)
                    .height(24)
                    .backgroundColor('#4CD9C0')
                    .type(ButtonType.Circle)
                    .onClick(() => {
                      this.addToCart(med)
                    })
                  }
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .padding({ left: 12, right: 12, bottom: 16 })
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
          }
        }, (item: IMedicine) => `${item.id}_${this.getCartQuantity(item.id)}`)
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .padding({ left: 16, right: 16, top: 4, bottom: 80 }) 
      .height('100%')
      .cachedCount(4) 
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180, 
      colors: [['#D1F2EB', 0.0], ['#E0F7FA', 0.3], ['#FFFFFF', 1.0]] 
    })
  }
}