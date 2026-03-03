import router from '@ohos.router';
import { RegisterDialog } from './component/RegisterDialog';
import axios, { AxiosResponse } from '@ohos/axios';
import { User } from './data/Data';
import { PreferencesUtil } from './utils/fileUtils';
import { Constants } from '../common/Constants';
import { common } from '@kit.AbilityKit';

interface Result {
  code: number;
  msg: string;
  data: User;
}

interface LoginParams {
  username: string;
  password?: string;
  code?: string;
}

@CustomDialog
struct UserAgreementDialog {
  controller: CustomDialogController

  build() {
    Column() {
      Text('用户协议')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 15 })
      
      Scroll() {
        Text('此处为用户协议详情...\n\n1. 服务条款\n本应用提供的服务...\n\n2. 用户责任\n用户在使用本应用时应遵守...\n\n3. 免责声明\n...')
          .fontSize(14)
          .fontColor('#666')
          .lineHeight(24)
          .padding({ left: 20, right: 20 })
      }
      .height(300)
      .margin({ bottom: 20 })

      Button('我已阅读')
        .onClick(() => {
          this.controller.close()
        })
        .width('80%')
        .height(40)
        .backgroundColor('#4CD9C0')
        .margin({ bottom: 20 })
    }
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('85%')
  }
}

@CustomDialog
struct PrivacyPolicyDialog {
  controller: CustomDialogController

  build() {
    Column() {
      Text('隐私政策')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 15 })
      
      Scroll() {
        Text('此处为隐私政策详情...\n\n1. 信息收集\n我们需要收集您的以下信息...\n\n2. 信息使用\n我们如何使用您的信息...\n\n3. 信息保护\n我们将采取措施保护您的信息安全...')
          .fontSize(14)
          .fontColor('#666')
          .lineHeight(24)
          .padding({ left: 20, right: 20 })
      }
      .height(300)
      .margin({ bottom: 20 })

      Button('我已阅读')
        .onClick(() => {
          this.controller.close()
        })
        .width('80%')
        .height(40)
        .backgroundColor('#4CD9C0')
        .margin({ bottom: 20 })
    }
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('85%')
  }
}

@Entry
@Component
struct LoginPage {
  @State loginType: number = 0; // 0: 账号密码登录, 1: 手机验证码登录
  @State phoneNumber: string = '';
  @State password: string = ''; // 密码或验证码
  @State isAgreed: boolean = false;
  @State countdown: number = 60;
  @State isCountingDown: boolean = false;
  @State isRemember: boolean = false; // 记住我
  
  // Toast 状态
  @State showSuccessToast: boolean = false;
  @State showFailureToast: boolean = false;
  @State toastMsg: string = '';

  private readonly BASE_URL: string = Constants.BASE_URL;

  userAgreementController: CustomDialogController = new CustomDialogController({
    builder: UserAgreementDialog(),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: false
  });

  privacyPolicyController: CustomDialogController = new CustomDialogController({
    builder: PrivacyPolicyDialog(),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: false
  });

  registerController: CustomDialogController = new CustomDialogController({
    builder: RegisterDialog({
      onSuccess: (phone: string): void => this.onRegisterSuccess(phone),
      onFailure: (msg: string): void => this.showToast(msg, false)
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    PreferencesUtil.init(context);
  }

  // 注册成功回调
  onRegisterSuccess(phone: string) {
    this.phoneNumber = phone;
    this.password = '';
    this.loginType = 0;
    this.showToast('注册成功，请登录', true);
  }

  // 统一显示 Toast
  showToast(msg: string, isSuccess: boolean) {
    this.toastMsg = msg;
    if (isSuccess) {
      this.showSuccessToast = true;
      setTimeout(() => { this.showSuccessToast = false; }, 2000);
    } else {
      this.showFailureToast = true;
      setTimeout(() => { this.showFailureToast = false; }, 2000);
    }
  }

  // 发送验证码逻辑
  async handleSendCode() {
    if (this.isCountingDown) return;
    
    if (!this.validatePhone()) return;

    // 开始倒计时
    this.isCountingDown = true;
    this.countdown = 60;
    const timer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        clearInterval(timer);
        this.isCountingDown = false;
        this.countdown = 60;
      }
    }, 1000);

    const code = Math.floor(Math.random() * 900000 + 100000).toString();

    axios.get(`${this.BASE_URL}/user/login/randomCode`, {
      params: { username: this.phoneNumber, code: code }
    }).catch((err: Error) => {
      console.error('Send code failed:', JSON.stringify(err));
      this.showToast('验证码发送失败，请检查网络', false);
    });
  }

  // 手机号校验
  validatePhone(): boolean {
    if (!this.phoneNumber) {
      this.showToast('请输入手机号', false);
      return false;
    }
    const phoneRegex = /^1[3-9]\d{9}$/;
    if (!phoneRegex.test(this.phoneNumber)) {
      this.showToast('请输入正确的手机号', false);
      return false;
    }
    return true;
  }

  // 登录主逻辑
  handleLogin() {
    if (!this.isAgreed) {
      this.showToast('请先阅读并同意用户协议', false);
      return;
    }
    
    if (!this.validatePhone()) return;

    if (!this.password) {
      this.showToast(this.loginType === 0 ? '请输入密码' : '请输入验证码', false);
      return;
    }

    const url = this.loginType === 0 
      ? `${this.BASE_URL}/user/login`
      : `${this.BASE_URL}/user/login/loginByCode`;
    
    const params: LoginParams = this.loginType === 0 
      ? { username: this.phoneNumber, password: this.password }
      : { username: this.phoneNumber, code: this.password };

    axios.get(url, { params })
      .then((res: AxiosResponse): void => this.processLoginResponse(res))
      .catch((err: Error) => {
        console.error('Login failed:', JSON.stringify(err));
        this.showToast('网络请求失败，请检查网络连接', false);
      });
  }

  processLoginResponse(res: AxiosResponse) {
    const result = res.data as Result;
    if (result.code === 200) {
      const user = result.data;
      
      // 存储用户信息
      AppStorage.SetOrCreate('isLoggedIn', true);
      if (user) {
        AppStorage.SetOrCreate('userData', user);
        PreferencesUtil.saveUserData(user);
      }

      this.showToast('登录成功', true);
      
      // 延迟跳转
      setTimeout(() => {
        router.replaceUrl({ url: 'pages/Main' });
      }, 500);
    } else {
      this.showToast(result.msg || '账号或密码错误', false);
    }
  }

  @Builder ToastView(msg: string, bgColor: string) {
    Row() {
      Text(msg)
        .fontColor(Color.White)
        .fontSize(16)
    }
    .backgroundColor(bgColor)
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .borderRadius(20)
    .position({ x: '50%', y: '80%' })
    .translate({ x: '-50%' })
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)' })
    .zIndex(999)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景 - 柔和的薄荷绿渐变
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180, // 从上到下
          colors: [['#D1F2EB', 0.0], ['#E0F7FA', 0.3], ['#FFFFFF', 1.0]] // 薄荷绿渐变
        })
      
      // 内容区域
      Column() {
        // 顶部欢迎语
        Column() {
          Row(){
            Text('欢迎登录')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 10 })
            Image($r('app.media.logo'))
              .height(100)
              .position({y:-40,x:140})

          }
          .width('100%')
          
          Text('安康随行医相伴！')
            .fontSize(16)
            .fontColor('#666666')
            .letterSpacing(1)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 30, top: 60, bottom: 20 })

        // 登录卡片整体 (Stack 叠加模式)
        Stack({ alignContent: Alignment.Top }) {
          // 1. 底层：背景图片 (充当卡片容器)
          // 如果 cl/cr 图片资源不存在，回退到 l3/r3，避免白屏
          Image(this.loginType === 0 ? $r('app.media.crr') : $r('app.media.cll'))
            .width(290.33)
            .height(350.33)
            .objectFit(ImageFit.Fill) // 确保图片填满区域
            .zIndex(0)
            .onError(() => {
              console.error('LoginView: Failed to load cl/cr images, fallback to l3/r3');
            })

          // 2. 上层：内容区域 (完全覆盖在图片上)
          Column() {
            // Tab 切换热区 (透明，仅用于占位和点击)
            Row() {
              this.TabItem('账号登录', 0)
              this.TabItem('免密登陆', 1)
            }
            .width('100%')
            .height(50) // 对应图片中 Tab 的高度区域

            // 输入表单区域
            Column({ space: 15 }) {
              // 稍微减小间距以适应高度
              this.PhoneInput()
              this.PasswordInput()
              
              // 记住我 & 忘记密码
              Row() {
                Row() {
                  Checkbox({ name: 'remember', group: 'login' })
                    .select(this.isRemember)
                    .selectedColor('#4CD9C0') 
                    .width(14)
                    .height(14)
                    .onChange((val) => this.isRemember = val)
                    .shape(CheckBoxShape.ROUNDED_SQUARE)
                  Text('记住我')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ left: 4 })

                }
                .onClick(() => this.isRemember = !this.isRemember)

                Blank()

                Text('忘记密码')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .width('100%')

              // 登录按钮
              Button('登 录', { type: ButtonType.Normal, stateEffect: true })
                .width('100%')
                .height(40) // 稍微调小按钮高度
                .borderRadius(20)
                .linearGradient({
                  angle: 90,
                  colors: [['#4CD9C0', 0.0], ['#80CBC4', 1.0]] 
                })
                .fontColor(Color.White)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .shadow({ radius: 8, color: 'rgba(76, 217, 192, 0.4)', offsetY: 4 })
                .onClick(() => this.handleLogin())

              // 协议
              this.AgreementSection()
              
              // 注册链接
              Row() {
                Text('还没有账户？')
                  .fontSize(12)
                  .fontColor('#999999')
                Text('去注册')
                  .fontSize(12)
                  .fontColor('#4CD9C0') 
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => this.registerController.open())
              }
              .margin({ top: 140 })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 10 }) // 调整内边距
          }
          .width(290.33)
          .height(244.33)
          .zIndex(1)
        }
        .width(290.33)
        .height(244.33)
        .shadow({ radius: 30, color: 'rgba(0,0,0,0.05)', offsetY: 10 }) // 给整体加个阴影
        .margin({ top: 20 }) // 与上方欢迎语的间距
      }
      .width('100%')
      .height('100%') // 层级 2：最上层，覆盖在插图之上
      
      // Toast 显示
      if (this.showSuccessToast) {
        this.ToastView(`✅ ${this.toastMsg || '操作成功'}`, '#4CAF50')
      }
      if (this.showFailureToast) {
        this.ToastView(`❌ ${this.toastMsg}`, '#F44336')
      }
    }
  }

  @Builder TabItem(text: string, type: number) {
    Column() {
      Text(text)
        .fontSize(16)
        .fontWeight(this.loginType === type ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.loginType === type ? '#333333' : '#666666')
        .padding({ top: 10, bottom: 10 })
    }
    .width('50%') // 均分宽度，对应图中的左右Tab区域
    .height(50) // 假设Tab高度
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.loginType = type)
  }

  @Builder PhoneInput() {
    Column({ space: 0 }) {
      TextInput({ placeholder: '请输入手机号', text: this.phoneNumber })
        .width('100%')
        .height(40) // 缩小高度
        .backgroundColor('#F5F7FA')
        .borderRadius(20) // 更加圆润
        .type(InputType.PhoneNumber)
        .placeholderColor('#BBBBBB')
        .padding({ left: 15 })
        .margin({top:20})
        .fontSize(14)
        .onChange((value) => this.phoneNumber = value)
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder PasswordInput() {
    Column({ space: 0 }) {
      Stack({ alignContent: Alignment.End }) {
        TextInput({ 
          placeholder: this.loginType === 0 ? '请输入密码' : '请输入验证码',
          text: this.password 
        })
          .width('100%')
          .height(40) // 缩小高度
          .backgroundColor('#F5F7FA')
          .borderRadius(20) // 更加圆润
          .type(this.loginType === 0 ? InputType.Password : InputType.Number)
          .placeholderColor('#BBBBBB')
          .padding({ left: 15, right: this.loginType === 1 ? 100 : 15 })
          .fontSize(14)
          .onChange((value) => this.password = value)

        if (this.loginType === 1) {
          Text(this.isCountingDown ? `${this.countdown}s` : '获取验证码')
            .fontSize(12)
            .fontColor(this.isCountingDown ? '#999999' : '#667eea')
            .margin({ right: 15 })
            .onClick(() => this.handleSendCode())
        }
      }
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder AgreementSection() {
    Row() {
      Checkbox({ name: 'agreement'})
        .select(this.isAgreed)
        .selectedColor('#4BDCBF')
        .onChange((value) => this.isAgreed = value)
        .width(14)
        .height(14)
        .shape(CheckBoxShape.ROUNDED_SQUARE)

      
      Text() {
        Span('我已阅读并同意 ')
        Span('《用户协议》')
          .fontColor('#667eea')
          .onClick(() => {
            this.userAgreementController.open()
          })
        Span(' 和 ')
        Span('《隐私授权》')
          .fontColor('#667eea')
          .onClick(() => {
            this.privacyPolicyController.open()
          })
      }
      .fontSize(11)
      .fontColor('#999999')
      .margin({ left: 8 })
    }
    .margin({ top: 10 })
    .width('100%')
  }
}
