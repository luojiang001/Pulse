import router from '@ohos.router';
import { IMedicine, ICartItem, DEFAULT_MEDICINE, IPrescriptionRecord, PrescriptionCheckResult, MedicineItem, User } from '../../data/Data';
import { StorageUtil, STORAGE_KEYS } from '../../utils/StorageUtil';
import promptAction from '@ohos.promptAction';
import axios, { AxiosResponse } from '@ohos/axios';
import { Constants } from '../../../common/Constants';

interface BackendPrescription {
  id: string;
  doctorName: string;
  department: string;
  time: string;
  status: 'valid' | 'invalid' | 'used';
  createTime: number;
  diagnosis: string;
  medicines?: MedicineItem[];
}

// 处方选择项接口
interface PrescriptionOption {
  record: IPrescriptionRecord;
  item: MedicineItem;
  remaining: number;
}

@CustomDialog
struct PrescriptionSelectDialog {
  controller?: CustomDialogController
  options: PrescriptionOption[] = []
  @State selectedIndex: number = -1
  confirm: (selected: PrescriptionOption) => void = () => {}

  build() {
    Column() {
      Text('请选择处方')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      Text('购买处方药需关联有效处方，且购买数量不能超过处方余量。')
        .fontSize(14)
        .fontColor('#666')
        .margin({ bottom: 20 })
        .padding({ left: 20, right: 20 })

      List() {
        ForEach(this.options, (option: PrescriptionOption, index: number) => {
          ListItem() {
            Row() {
              // 单选框
              Radio({ value: 'prescription_' + index, group: 'prescriptions' })
                .checked(this.selectedIndex === index)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.selectedIndex = index
                  }
                })
                .margin({ right: 10 })

              Column() {
                Text(`${option.record.time} | ${option.record.doctorName}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                
                Text(`诊断: ${option.record.diagnosis || '无'}`)
                  .fontSize(14)
                  .fontColor('#666')
                  .margin({ top: 4 })

                Row() {
                  Text(`余量: `)
                    .fontSize(14)
                    .fontColor('#666')
                  Text(`${option.remaining}`)
                    .fontSize(16)
                    .fontColor('#FF9800')
                    .fontWeight(FontWeight.Bold)
                  Text(` / ${option.item.count}`)
                    .fontSize(14)
                    .fontColor('#999')
                }
                .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              this.selectedIndex = index
            })
          }
        })
      }
      .width('100%')
      .height(200) // 限制列表高度
      .padding({ left: 20, right: 20 })

      Row() {
        Button('取消')
          .onClick(() => {
            this.controller?.close()
          })
          .backgroundColor('#F5F5F5')
          .fontColor('#666')
          .width('40%')
        
        Button('下一步')
          .onClick(() => {
            if (this.selectedIndex === -1) {
              promptAction.showToast({ message: '请选择一个处方' })
              return
            }
            this.confirm(this.options[this.selectedIndex])
            this.controller?.close()
          })
          .backgroundColor('#007fff')
          .width('40%')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(20)
    }
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }
}

@CustomDialog
struct QuantityDialog {
  controller?: CustomDialogController
  // 传入的药品信息，设置默认值以防空
  medicine: IMedicine = DEFAULT_MEDICINE
  @State quantity: number = 1
  // 最大购买数量
  maxQuantity: number = 99
  // 确认回调函数
  confirm: (quantity: number) => void = () => {}

  build() {
    Column() {
      // 头部：商品信息展示
      Row() {
        Image(this.medicine.image)
          .width(60)
          .height(60)
          .objectFit(ImageFit.Contain)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
        
        Column() {
          Text(this.medicine.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          
          Text(`¥${this.medicine.price}`)
            .fontSize(18)
            .fontColor('#FF0000')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 8 })
          
          if (this.medicine.isPrescription) {
             Text(`处方限购: ${this.maxQuantity}`)
               .fontSize(12)
               .fontColor('#FF9800')
               .margin({ top: 4 })
          }
        }
        .layoutWeight(1)
        .padding({ left: 10 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ bottom: 20 })
      .border({ width: { bottom: 1 }, color: '#f0f0f0' })

      // 数量选择器
      Row() {
        Text('购买数量')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        
        Row() {
          Text('-')
            .fontSize(20)
            .width(30)
            .height(30)
            .textAlign(TextAlign.Center)
            .backgroundColor('#f5f5f5')
            .borderRadius({ topLeft: 4, bottomLeft: 4 })
            .onClick(() => {
              if (this.quantity > 1) this.quantity--
            })
          
          Text(this.quantity.toString())
            .fontSize(16)
            .width(40)
            .height(30)
            .textAlign(TextAlign.Center)
            .backgroundColor('#f5f5f5')
          
          Text('+')
            .fontSize(20)
            .width(30)
            .height(30)
            .textAlign(TextAlign.Center)
            .backgroundColor('#f5f5f5')
            .borderRadius({ topRight: 4, bottomRight: 4 })
            .onClick(() => {
              if (this.quantity < this.maxQuantity) {
                 this.quantity++
              } else {
                 if (this.medicine.isPrescription) {
                   promptAction.showToast({ message: `处方限制最多购买 ${this.maxQuantity} 件` })
                 } else {
                   promptAction.showToast({ message: `最多购买 ${this.maxQuantity} 件` })
                 }
              }
            })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 20, bottom: 30 })

      // 确认按钮
      Button('确认')
        .width('100%')
        .height(40)
        .backgroundColor('#007fff')
        .onClick(() => {
          this.confirm(this.quantity)
          this.controller?.close()
        })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }
}

@Entry
@Component
struct MedicineDetail {
  @State medicine: IMedicine = DEFAULT_MEDICINE;
  @StorageLink('cart') cart: ICartItem[] = []
  @StorageLink('prescriptions') prescriptions: IPrescriptionRecord[] = []
  @StorageLink('userData') currentUser: User | null = null;
  
  dialogController: CustomDialogController | undefined = undefined
  prescriptionSelectController: CustomDialogController | undefined = undefined
  @State validPrescriptions: PrescriptionOption[] = []
  @State selectedPrescriptionId: string = ''
  @State isLoading: boolean = false;

  // 获取路由参数并初始化弹窗控制器
  async aboutToAppear() {
    // 1. 优先加载本地缓存，快速展示
    const saved = await StorageUtil.getData<IPrescriptionRecord[]>(STORAGE_KEYS.PRESCRIPTIONS, []);
    const isDataValid = saved.length > 0 && saved.some(p => p.medicines && p.medicines.length > 0);
    
    if (isDataValid) {
      this.prescriptions = saved;
      AppStorage.SetOrCreate('prescriptions', saved);
      console.info(`Loaded ${saved.length} prescriptions from storage (validated).`);
    }

    // 2. 无论本地是否有数据，都强制从后端获取最新数据 (解决用户刚开处方但缓存未更新导致无法购买的问题)
    if (this.currentUser) {
       console.info('Triggering background prescription refresh...');
       this.fetchPrescriptions(this.currentUser.id);
    }

    this.loadMedicineInfo();
  }

  onPageShow() {
    // 再次尝试加载药品信息，防止第一次进入时路由参数获取失败
    if (this.medicine.id === 0) {
      this.loadMedicineInfo();
    }
  }

  loadMedicineInfo() {
    // 获取从列表页传递过来的药品对象
    const params = router.getParams() as Record<string, IMedicine>;
    if (params && params.medicine) {
      let med = params.medicine;
      // 兼容逻辑：如果后端没有 isPrescription 字段，但有 prescription (0/1) 字段，则进行转换
      if (med.prescription === 1) {
        med.isPrescription = true;
      }
      this.medicine = med;
      console.info(`Loaded medicine info: ${med.name}, isPrescription=${med.isPrescription}`);
      // 初始化默认控制器
      this.initDialogController(99);
    } else {
      console.warn('MedicineDetail: No medicine params found in route');
    }
  }

  initDialogController(maxQty: number) {
    this.dialogController = new CustomDialogController({
        builder: QuantityDialog({
          medicine: this.medicine!,
          maxQuantity: maxQty,
          confirm: (quantity: number) => {
            // 确认回调：将选择的数量加入购物车
            // 如果是处方药，使用 selectedPrescriptionId
            this.processAddToCart(quantity, this.medicine.isPrescription ? this.selectedPrescriptionId : undefined)
          }
        }),
        alignment: DialogAlignment.Bottom, // 底部弹窗
        customStyle: true,
        autoCancel: true // 点击遮罩层关闭
      })
  }

  // 从后端获取处方数据
  async fetchPrescriptions(userId: number) {
    this.isLoading = true;
    try {
        console.info(`Fetching prescriptions for user ${userId} in MedicineDetail...`);
        const url = `${Constants.BASE_URL}/prescription/list`;
        
        const response: AxiosResponse = await axios.get(url, {
            params: { userId: userId },
            timeout: 60000
        });
        
        if (response.status === 200 && response.data.code === 200) {
                    console.info('Raw prescription response:', JSON.stringify(response.data));
                    const rawList: BackendPrescription[] = response.data.data;
            const newPrescriptions = rawList.map((item: BackendPrescription) => {
                let medicinesStr = '';
                if (item.medicines && Array.isArray(item.medicines)) {
                    medicinesStr = item.medicines.map((m: MedicineItem) => {
                        return `${m.medicineName}(${m.count})`;
                    }).join('，');
                }
                const fullDiagnosis = `医嘱：${item.diagnosis || '无'}\n处方药：${medicinesStr || '无'}`;
                
                return {
                    id: item.id,
                    doctorName: item.doctorName,
                    department: item.department,
                    time: item.time,
                    status: item.status,
                    createTime: item.createTime,
                    diagnosis: fullDiagnosis,
                    medicines: item.medicines
                } as IPrescriptionRecord;
            });
            
            this.prescriptions = newPrescriptions;
            AppStorage.SetOrCreate('prescriptions', newPrescriptions);
            StorageUtil.saveData(STORAGE_KEYS.PRESCRIPTIONS, newPrescriptions);
            console.info(`Fetched ${newPrescriptions.length} prescriptions.`);
        }
    } catch (err) {
        console.error('Fetch prescriptions failed in MedicineDetail:', JSON.stringify(err));
    } finally {
        this.isLoading = false;
    }
  }

  // 查找所有包含当前药品的有效处方
  findValidPrescriptions(medicineName: string): PrescriptionOption[] {
    const options: PrescriptionOption[] = [];
    console.info(`Checking prescriptions for medicine: ${medicineName}. Total prescriptions: ${this.prescriptions?.length || 0}`);
    
    if (this.prescriptions && this.prescriptions.length > 0) {
      for (const record of this.prescriptions) {
        console.info(`Checking record ${record.id}: status=${record.status}, medicines count=${record.medicines?.length}`);
        // 只检查有效处方
        if (record.status === 'valid' && record.medicines) {
          console.info(`Record ${record.id} medicines: ${JSON.stringify(record.medicines)}`);
          // 宽松匹配逻辑：只要名称有包含关系就算匹配 (解决 "阿莫西林" vs "阿莫西林胶囊" 的问题)
          const match = record.medicines.find(m => {
            if (!m.medicineName || !medicineName) return false;
            const isMatch = m.medicineName === medicineName || 
            m.medicineName.includes(medicineName) || 
            medicineName.includes(m.medicineName);
            if (isMatch) console.info(`Match found in record ${record.id}: ${m.medicineName} matches ${medicineName}`);
            return isMatch;
          });
          
          // 必须匹配药品，且剩余额度 > 0
          if (match) {
             const used = match.usedCount || 0;
             // 扣减购物车中已存在的数量
             let inCartQuantity = 0;
             if (this.cart && this.cart.length > 0) {
                const cartItem = this.cart.find(c => 
                  c.name === medicineName && 
                  c.prescriptionId === record.id
                );
                if (cartItem) {
                  inCartQuantity = cartItem.quantity;
                }
             }
             
             const remaining = match.count - used - inCartQuantity;
             console.info(`Record ${record.id} calculation: count=${match.count}, used=${used}, inCart=${inCartQuantity}, remaining=${remaining}`);
             
             if (remaining > 0) {
               options.push({
                 record: record,
                 item: match,
                 remaining: remaining
               });
             } else {
               console.info(`Record ${record.id} skipped due to no remaining quantity`);
             }
          }
        } else {
            console.info(`Record ${record.id} skipped: status not valid or no medicines`);
        }
      }
    }
    return options;
  }

  // 打开处方选择弹窗
  openPrescriptionSelectDialog() {
    this.prescriptionSelectController = new CustomDialogController({
      builder: PrescriptionSelectDialog({
        options: this.validPrescriptions,
        confirm: (selected: PrescriptionOption) => {
          // 记录选中的处方ID
          this.selectedPrescriptionId = selected.record.id;
          // 打开数量选择弹窗，限制最大数量为剩余量
          this.initDialogController(selected.remaining);
          this.dialogController?.open();
        }
      }),
      alignment: DialogAlignment.Center,
      customStyle: true,
      autoCancel: true
    });
    this.prescriptionSelectController.open();
  }

  // 点击加入购物车按钮的处理逻辑
  addToCart() {
    if (this.isLoading) {
       promptAction.showToast({ message: '正在加载处方信息，请稍候...' });
       return;
    }
    if (this.medicine.id === 0) return;

    // 处方药购买限制逻辑
    if (this.medicine.isPrescription) {
      // 1. 查找所有可用处方
      this.validPrescriptions = this.findValidPrescriptions(this.medicine.name);
      
      if (this.validPrescriptions.length === 0) {
          AlertDialog.show({
            title: '无法购买',
            message: '未找到该药品的有效处方，或处方额度已用完。请前往医院就诊开具新处方。',
            confirm: {
              value: '知道了',
              action: () => {}
            }
          })
          return;
      }
      
      // 2. 打开处方选择弹窗
      this.openPrescriptionSelectDialog();
      
    } else {
      // 非处方药直接打开数量选择弹窗，默认限制 99
      this.selectedPrescriptionId = '';
      this.initDialogController(99);
      if (this.dialogController) {
        this.dialogController.open()
      }
    }
  }

  // 处理实际加入购物车的操作
  async processAddToCart(quantity: number = 1, prescriptionId?: string) {
    if (this.medicine.id === 0) return;
    
    // 检查购物车中是否已存在该商品 (如果是处方药，还需要匹配 prescriptionId)
    // 逻辑变更：同一个药，如果处方不同，应该视为不同的购物车条目吗？
    // 通常是的，因为结算时要分别扣减额度。
    const existingItem = this.cart.find(item => 
      item.id === this.medicine.id && 
      (!this.medicine.isPrescription || item.prescriptionId === prescriptionId)
    )

    if (existingItem) {
      // 已存在：更新数量
      // 检查是否超过限额（如果是处方药）
      if (this.medicine.isPrescription && prescriptionId) {
         // 需要重新计算当前剩余额度吗？这里简单处理，假设用户不会恶意操作
         // 严谨逻辑应该检查 (existingItem.quantity + quantity) <= remaining
         // 但 remaining 在弹窗时已确定，这里暂时略过再次校验
      }

      existingItem.quantity += quantity
      // 强制更新数组项以触发视图更新
      const index = this.cart.indexOf(existingItem)
      // ArkTS compatible update
      this.cart[index] = {
        id: existingItem.id,
        name: existingItem.name,
        image: existingItem.image,
        manufacturer: existingItem.manufacturer,
        price: existingItem.price,
        unit: existingItem.unit,
        description: existingItem.description,
        efficacy: existingItem.efficacy,
        isPrescription: existingItem.isPrescription,
        prescription: existingItem.prescription,
        category: existingItem.category,
        categoryId: existingItem.categoryId,
        quantity: existingItem.quantity,
        prescriptionId: existingItem.prescriptionId
      }
    } else {
      // 不存在：创建新项并加入购物车
      this.cart.push({
        id: this.medicine.id,
        name: this.medicine.name,
        manufacturer: this.medicine.manufacturer,
        price: this.medicine.price,
        unit: this.medicine.unit,
        image: this.medicine.image,
        quantity: quantity,
        isPrescription: this.medicine.isPrescription,
        prescriptionId: prescriptionId, // 保存处方ID
        description: this.medicine.description,
        efficacy: this.medicine.efficacy,
        category: this.medicine.category
      })
    }
    await StorageUtil.saveData(STORAGE_KEYS.CART, this.cart);
    promptAction.showToast({ message: `已加入购物车 x${quantity}` })
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image("http://47.101.196.181:9000/department-grid/return.png")
          .width(24)
          .height(24)
          .onClick(() => {
                    router.back();
          })
        
        Text('药品详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

      if (this.medicine.id !== 0) {
        Scroll() {
          Column() {
            // 商品图片
            Image(this.medicine.image)
              .width('100%')
              .height(300)
              .objectFit(ImageFit.Contain)
              .backgroundColor('#fff')
              .margin({ bottom: 16 })

            // 基本信息
            Column() {
              Row() {
                Text(this.medicine.name)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333')
                  .layoutWeight(1)
                
                if (this.medicine.isPrescription) {
                  Text('Rx')
                    .fontSize(12)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                    .backgroundColor(Color.Red)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .margin({ left: 10 })
                } else {
                  Text('OTC')
                    .fontSize(12)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                    .backgroundColor('#00AA00')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .margin({ left: 10 })
                }
              }
              .width('100%')
              .margin({ bottom: 8 })

              Text(this.medicine.manufacturer)
                .fontSize(14)
                .fontColor('#666')
                .margin({ bottom: 16 })

              Row() {
                Text() {
                  Span('¥').fontSize(16)
                  Span(this.medicine.price.toString()).fontSize(28)
                  Span(` /${this.medicine.unit}`).fontSize(14).fontColor('#999')
                }
                .fontColor('#FF0000')
                .fontWeight(FontWeight.Bold)
              }
              .margin({ bottom: 24 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })

            // 药效 / 介绍
            Column() {
              Text('药品介绍 / 药效')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })
                .width('100%')

              Text(this.medicine.efficacy || '暂无详细介绍')
                .fontSize(16)
                .fontColor('#666')
                .lineHeight(24)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)
          }
          .padding(16)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F7FA')
        
        // 底部操作栏
        Row() {
          Column() {
            Image($rawfile('Pulse/Common/foreground.png'))
              .width(24)
              .height(24)
            Text('购物车')
              .fontSize(10)
              .fontColor('#666')
              .margin({ top: 2 })
          }
          .width(60)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            router.back()
            // 注：理想情况下应跳转到购物车标签页，但目前简单的返回即可
          })

          Button('加入购物车')
            .backgroundColor('#FF9800')
            .fontColor(Color.White)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 10, right: 5 })
            .onClick(() => {
              this.addToCart()
            })

          Button('立即购买')
            .backgroundColor('#FF0000')
            .fontColor(Color.White)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 5 })
            .onClick(() => {
              this.addToCart()
              // 在真实应用中，这里应跳转到结算页
            })
        }
        .width('100%')
        .height(60)
        .backgroundColor(Color.White)
        .padding({ left: 16, right: 16 })
        .shadow({ radius: 5, color: 'rgba(0,0,0,0.1)', offsetY: -2 })
      } else {
        Column() {
          Text('未找到药品信息')
            .fontSize(16)
            .fontColor('#999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}