import { StorageUtil, STORAGE_KEYS } from '../../utils/StorageUtil';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import axios, { AxiosResponse } from '@ohos/axios';
import { PreferencesUtil } from '../../utils/fileUtils';
import common from '@ohos.app.ability.common';
import { User, Patient } from '../../data/Data';
import { Constants } from '../../../common/Constants';

@Entry
@Component
export struct PatientManager {
  @State patients: Patient[] = [];
  @State currentUser: User | null = null;

  onPageShow() {
     // 每次页面显示时重新加载数据（确保从添加页返回时刷新）
     this.initData();
  }

  async initData() {
    try {
      // 1. 初始化 Context (如果已初始化过也不会报错)
      const context = getContext(this) as common.UIAbilityContext;
      PreferencesUtil.init(context);

      // 2. 获取当前登录用户
      this.currentUser = await PreferencesUtil.getUserData();

      if (this.currentUser) {
         // 3. 从后端加载就诊人列表
         this.loadPatients();
      } else {
         promptAction.showToast({ message: '请先登录' });
      }
    } catch (e) {
      console.error('Init data failed:', e);
    }
  }

  async aboutToAppear() {
    // onPageShow 会负责加载，这里可以留空或做一次性初始化
  }

  // 从后端获取就诊人列表
  loadPatients() {
    if (!this.currentUser) return;
    
    axios.get(`${Constants.BASE_URL}/patient/list`, {
      params: { userId: this.currentUser.id }
    })
    .then((res: AxiosResponse) => {
      if (res.data && res.data.code === 200 && Array.isArray(res.data.data)) {
        this.patients = res.data.data;
      } else {
         // 处理空数据或格式不符
         this.patients = [];
      }
    })
    .catch((err: Error) => {
      console.error('Get patients failed:', JSON.stringify(err));
      this.patients = [];
      promptAction.showToast({ message: '获取就诊人失败，请检查网络或后端服务' });
    });
  }

  // 添加就诊人 (跳转到添加页面或弹出对话框)
  addPatient() {
     router.pushUrl({ url: 'pages/component/WoDe/PatientAdd' })
       .then(() => {
          // 跳转成功
       })
       .catch((err: Error) => {
          console.error('跳转失败', err);
       });
  }

  // 删除就诊人
  deletePatient(id: number) {
    promptAction.showDialog({
      title: '提示',
      message: '确定要删除该就诊人吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#FF4D4F' }
      ]
    })
    .then((result) => {
      if (result.index === 1) {
        // 用户点击确定
        axios.post(`${Constants.BASE_URL}/patient/del/${id}`)
          .then((res: AxiosResponse) => {
            if (res.data.code === 200) {
              promptAction.showToast({ message: '删除成功' });
              this.loadPatients(); // 刷新列表
            } else {
              promptAction.showToast({ message: res.data.msg || '删除失败' });
            }
          })
          .catch((err: Error) => {
            console.error('Delete patient failed:', JSON.stringify(err));
            promptAction.showToast({ message: '删除失败，请检查网络' });
          });
      }
    });
  }

  @Builder DeleteButton(item: Patient) {
    Button() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(14)
    }
    .type(ButtonType.Normal)
    .width(80)
    .height('100%')
    .backgroundColor('#FF4D4F')
    .onClick(() => {
       this.deletePatient(item.id);
    })
  }

  @Builder PatientItem(item: Patient) {
    Row() {
      Column() {
        Row() {
          Text(item.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ right: 10 })
          Text(item.gender + ' ' + item.age + '岁')
            .fontSize(14)
            .fontColor('#666')
        }
        .margin({ bottom: 5 })
        
        Text('身份证: ' + item.idCard)
            .fontSize(14)
            .fontColor('#999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (item.isDefault) {
          Text('默认')
            .fontSize(12)
            .fontColor('#007fff')
            .backgroundColor('#E3F2FD')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .margin({ bottom: 10 })
    .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image("http://47.101.196.181:9000/department-grid/return.png")
          .width(24)
          .height(24)
          .onClick(() => router.back())
          .margin({ right: 10 });
        
        Text('就诊人管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
          
        Blank()
        
        Text('添加')
            .fontSize(16)
            .fontColor('#007fff')
            .onClick(() => {
                this.addPatient();
            })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
      .zIndex(1)

      List() {
        ForEach(this.patients, (item: Patient) => {
          ListItem() {
            this.PatientItem(item)
          }
          .swipeAction({ end: this.DeleteButton(item) })
        })
      }
      .width('100%')
      .height('100%')
      .padding(15)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
