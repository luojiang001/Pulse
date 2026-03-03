import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import axios, { AxiosResponse } from '@ohos/axios';
import { Constants } from '../../../common/Constants';
import { PreferencesUtil } from '../../utils/fileUtils';
import common from '@ohos.app.ability.common';
import { User } from '../../data/Data';

interface PatientAddParams {
  userId: number;
  name: string;
  idCard: string;
  phone: string;
  age: number;
  gender: string;
  isDefault: boolean;
}

interface AxiosErrorResponse {
  data: Record<string, Object>;
  status: number;
}

interface SimpleAxiosError {
  response?: AxiosErrorResponse;
  code?: string;
  message?: string;
}

interface ToastOptions {
  message: string;
}

interface PromptAction {
  showToast: (options: ToastOptions) => void;
}

interface Router {
  back: () => void;
}

interface UIContextCompat {
  getPromptAction(): PromptAction;
  getRouter(): Router;
}

interface ComponentCompat {
  getUIContext?(): UIContextCompat;
}

@Entry
@Component
struct PatientAdd {
  @State name: string = '';
  @State idCard: string = '';
  @State phone: string = '';
  @State age: number = 0;
  @State gender: string = '男';
  @State isDefault: boolean = false;
  @State currentUser: User | null = null;

  async aboutToAppear() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      PreferencesUtil.init(context);
      this.currentUser = await PreferencesUtil.getUserData();
    } catch (e) {
      console.error('Context init failed:', e);
    }
  }

  submit() {
    if (!this.name || !this.idCard || !this.phone) {
      promptAction.showToast({ message: '请填写完整信息' });
      return;
    }
    if (!this.currentUser) {
      promptAction.showToast({ message: '请先登录' });
      return;
    }

    // 构造请求参数
    const params: PatientAddParams = {
        userId: this.currentUser.id,
        name: this.name,
        idCard: this.idCard,
        phone: this.phone,
        age: this.age,
        gender: this.gender,
        isDefault: this.isDefault
      };

    console.info('提交添加就诊人请求:', JSON.stringify(params));

    // 调用后端接口
    axios.post(`${Constants.BASE_URL}/patient/add`, params)
      .then((res: AxiosResponse) => {
        console.info('添加就诊人响应:', JSON.stringify(res));
        if (res.data && res.data.code === 200) {
          // 使用 getUIContext() 确保在 UI 线程执行
          try {
            const that = this as Object as ComponentCompat;
            if (that.getUIContext) {
               const uiContext = that.getUIContext();
               if (uiContext) {
                 uiContext.getPromptAction().showToast({ message: '添加成功' });
                 setTimeout(() => {
                   uiContext.getRouter().back();
                 }, 500);
               }
            } else {
               // Fallback for older API versions
               promptAction.showToast({ message: '添加成功' });
               setTimeout(() => {
                 router.back();
               }, 500);
            }
          } catch (e) {
            console.error('UI Operation failed:', JSON.stringify(e));
            // 最后的尝试
            try {
               router.back();
            } catch (e2) {
               console.error('Final router back failed:', JSON.stringify(e2));
            }
          }
        } else {
          const msg = (res.data as Record<string, Object>).msg as string;
          try {
            const that = this as Object as ComponentCompat;
            if (that.getUIContext) {
               const uiContext = that.getUIContext();
               if (uiContext) {
                  uiContext.getPromptAction().showToast({ message: msg || '添加失败' });
               }
            } else {
               promptAction.showToast({ message: msg || '添加失败' });
            }
          } catch (e) {
             console.error('Error toast failed:', JSON.stringify(e));
          }
        }
      })
      .catch((err: Error) => {
        console.error('添加失败 error object:', JSON.stringify(err));
        // 使用自定义接口绕过类型检查
        const error = err as SimpleAxiosError;
        
        if (error.response) {
            console.error('Response status:', error.response.status);
            console.error('Response data:', JSON.stringify(error.response.data));
        }
        if (error.code) {
             console.error('Error code:', error.code);
        }
        if (error.message) {
             console.error('Error message:', error.message);
        }
        promptAction.showToast({ message: '网络请求失败: ' + JSON.stringify(err) });
      });
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image("http://47.101.196.181:9000/department-grid/return.png")
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('添加就诊人')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      // 表单区域
      Column({ space: 15 }) {
        // 姓名
        TextInput({ placeholder: '请输入真实姓名' })
          .onChange((value) => this.name = value)
          .width('100%')
          .height(50)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15 })

        // 身份证
        TextInput({ placeholder: '请输入身份证号' })
          .onChange((value) => this.idCard = value)
          .width('100%')
          .height(50)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15 })

        // 手机号
        TextInput({ placeholder: '请输入手机号' })
          .onChange((value) => this.phone = value)
          .type(InputType.PhoneNumber)
          .width('100%')
          .height(50)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15 })

        // 年龄
        TextInput({ placeholder: '请输入年龄' })
          .onChange((value) => this.age = parseInt(value) || 0)
          .type(InputType.Number)
          .width('100%')
          .height(50)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15 })

        // 性别选择
        Row() {
          Text('性别：').fontSize(16).fontColor('#333')
          Row() {
            Radio({ value: '男', group: 'gender' })
              .checked(this.gender === '男')
              .onChange((isChecked) => { if(isChecked) this.gender = '男' })
            Text('男').fontSize(16).margin({ right: 20 })
            
            Radio({ value: '女', group: 'gender' })
              .checked(this.gender === '女')
              .onChange((isChecked) => { if(isChecked) this.gender = '女' })
            Text('女').fontSize(16)
          }
        }
        .width('100%')
        .padding({ left: 5 })

        // 设为默认
        Row() {
          Text('设为默认就诊人').fontSize(16).fontColor('#333')
          Toggle({ type: ToggleType.Switch, isOn: this.isDefault })
            .onChange((isOn) => this.isDefault = isOn)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ top: 10, bottom: 10 })

      }
      .padding(20)
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ top: 10 })

      Blank().layoutWeight(1)

      // 保存按钮
      Button('保存')
        .width('90%')
        .height(45)
        .backgroundColor('#007DFF')
        .margin({ bottom: 30 })
        .onClick(() => this.submit())
    }
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}