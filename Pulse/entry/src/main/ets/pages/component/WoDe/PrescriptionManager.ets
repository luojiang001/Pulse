import { IPrescriptionRecord, User } from '../../data/Data';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import axios, { AxiosResponse } from '@ohos/axios';
import { Constants } from '../../../common/Constants';

interface MedicineItem {
  medicineName: string;
  count: number;
  prescription?: number;
}

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

@Entry
@Component
struct PrescriptionManager {
  @State prescriptions: IPrescriptionRecord[] = [];
  @StorageLink('userData') currentUser: User | null = null;
  @State isLoading: boolean = false;
  @State detailDialogVisible: boolean = false;
  @State selectedPrescription: IPrescriptionRecord | null = null;

  aboutToAppear() {
    if (this.currentUser) {
        this.fetchPrescriptions(this.currentUser.id);
    } else {
        promptAction.showToast({ message: '请先登录' });
        // 实际场景可能需要跳转登录，这里仅提示
    }
  }

  // 预留接口：向后端传递 UserId 获取处方列表
  async fetchPrescriptions(userId: number) {
    this.isLoading = true;
    try {
        console.info(`正在获取用户 ${userId} 的处方记录...`);
        const url = `${Constants.BASE_URL}/prescription/list`;
        
        const response: AxiosResponse = await axios.get(url, {
            params: { userId: userId },
            timeout: 60000
        });
        
        if (response.status === 200 && response.data.code === 200) {
            // 处理后端返回的数据，拼接 diagnosis
            const rawList: BackendPrescription[] = response.data.data;
            this.prescriptions = rawList.map((item: BackendPrescription) => {
                // 拼接药品信息字符串
                let medicinesStr = '';
                if (item.medicines && Array.isArray(item.medicines)) {
                    medicinesStr = item.medicines.map((m: MedicineItem) => {
                        return `${m.medicineName}(${m.count})`;
                    }).join('\n');
                }
                
                // 组合最终的诊断展示文本
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
        }

    } catch (err) {
        console.error('Fetch prescriptions failed:', JSON.stringify(err));
        promptAction.showToast({ message: '获取处方记录失败' });
    } finally {
        this.isLoading = false;
    }
  }

  openDetail(item: IPrescriptionRecord) {
    this.selectedPrescription = item;
    this.detailDialogVisible = true;
  }

  closeDetail() {
    this.detailDialogVisible = false;
    this.selectedPrescription = null;
  }

  getStatusText(status: string): string {
      switch(status) {
          case 'valid': return '有效';
          case 'used': return '已使用';
          case 'invalid': return '已失效';
          default: return status;
      }
  }

  getStatusColor(status: string): string {
      switch(status) {
          case 'valid': return '#4CD9C0'; // Green
          case 'used': return '#94A3B8'; // Gray
          case 'invalid': return '#FF5252'; // Red
          default: return '#333333';
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
            try {
              router.back();
            } catch (e) {
              console.error('router back error:', JSON.stringify(e));
            }
          })
          .margin({ right: 10 });
        Text('处方管理')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
            .fontColor('#333')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
      .zIndex(1)

      if (this.isLoading) {
        Column() {
            LoadingProgress().width(40).height(40).color('#4CD9C0')
            Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.prescriptions.length === 0) {
        // 空状态
        Column() {
            Image($rawfile('Pulse/Common/foreground.png')) // 可以换成专门的空状态图
                .width(120).height(120)
                .opacity(0.3)
                .grayscale(1)
            Text('暂无处方记录')
                .fontSize(16)
                .fontColor('#94A3B8')
                .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 处方列表
        List({ space: 16 }) {
            ForEach(this.prescriptions, (item: IPrescriptionRecord) => {
                ListItem() {
                    this.PrescriptionItem(item)
                }
            }, (item: IPrescriptionRecord) => item.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding(16)
        
        if (this.detailDialogVisible && this.selectedPrescription) {
          Column() {
            Row() {
              Text('处方详情').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333')
              Blank()
              Button('关闭').fontSize(12).backgroundColor('transparent').fontColor('#999').onClick(() => this.closeDetail())
            }
            .width('100%')
            .padding(12)
            .border({ width: { bottom: 1 }, color: '#eee' })

            Scroll() {
              Column() {
                Row() {
                  Text('医生：').fontSize(14).fontColor('#64748B')
                  Text(this.selectedPrescription.doctorName).fontSize(14).fontColor('#333')
                }.width('100%').margin({ bottom: 8 })
                Row() {
                  Text('科室：').fontSize(14).fontColor('#64748B')
                  Text(this.selectedPrescription.department).fontSize(14).fontColor('#333')
                }.width('100%').margin({ bottom: 8 })
                Row() {
                  Text('时间：').fontSize(14).fontColor('#64748B')
                  Text(this.selectedPrescription.time).fontSize(14).fontColor('#333')
                }.width('100%').margin({ bottom: 8 })
                Row() {
                  Text('状态：').fontSize(14).fontColor('#64748B')
                  Text(this.getStatusText(this.selectedPrescription.status)).fontSize(14).fontColor(this.getStatusColor(this.selectedPrescription.status))
                }.width('100%').margin({ bottom: 12 })
                Row() {
                  Text('诊断信息：').fontSize(14).fontColor('#64748B')
                  Text(this.selectedPrescription.diagnosis || '无').fontSize(14).fontColor('#333')
                }.width('100%').margin({ bottom: 12 })
                if (this.selectedPrescription.medicines && this.selectedPrescription.medicines.length > 0) {
                  List() {
                    ForEach(this.selectedPrescription.medicines!, (m: MedicineItem) => {
                      ListItem() {
                        Row() {
                          Text(m.medicineName).fontSize(14).fontColor('#333').layoutWeight(1)
                          Text(`${m.count}`).fontSize(14).fontColor('#333').width(80).alignSelf(ItemAlign.End)
                        }.width('100%').padding(8)
                      }
                    })
                  }.width('100%')
                }
              }
              .padding(16)
            }
            .layoutWeight(1)
            .width('100%')
          }
          .width('80%')
          .height('60%')
          .backgroundColor('#fff')
          .borderRadius(12)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 2 })
          .alignSelf(ItemAlign.Center)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder PrescriptionItem(item: IPrescriptionRecord) {
     Column() {
        // 头部：医生和科室
        Row() {
            Row() {
                Text(item.department)
                    .fontSize(14)
                    .fontColor('#4CD9C0')
                    .backgroundColor('#E0F2F1')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(4)
                    .margin({ right: 8 })
                Text(item.doctorName)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333')
            }
            
            Text(this.getStatusText(item.status))
                .fontSize(14)
                .fontColor(this.getStatusColor(item.status))
                .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 12 })

        Divider().color('#F1F5F9').margin({ bottom: 12 })

        // 诊断信息
        Row() {
            Text('临床诊断：')
                .fontSize(14)
                .fontColor('#64748B')
            Text(item.diagnosis || '无')
                .fontSize(14)
                .fontColor('#333')
                .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin({ bottom: 8 })

        // 时间
        Row() {
            Text('开具时间：')
                .fontSize(14)
                .fontColor('#64748B')
            Text(item.time)
                .fontSize(14)
                .fontColor('#333')
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 底部按钮
        Row() {
            Blank()
            Button('查看详情')
                .type(ButtonType.Normal)
                .borderRadius(20)
                .backgroundColor(Color.White)
                .fontColor('#4CD9C0')
                .border({ width: 1, color: '#4CD9C0' })
                .height(32)
                .fontSize(13)
                .onClick(() => this.openDetail(item))
        }
        .width('100%')
     }
     .width('100%')
     .backgroundColor(Color.White)
     .borderRadius(16)
     .padding(16)
     .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
  }
}
