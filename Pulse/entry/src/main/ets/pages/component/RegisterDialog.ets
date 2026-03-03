import { promptAction } from '@kit.ArkUI';
import axios, { AxiosResponse } from '@ohos/axios';
import { Constants } from '../../common/Constants';
import { common } from '@kit.AbilityKit';

@CustomDialog

@CustomDialog
export struct RegisterDialog {
  controller?: CustomDialogController;
  @State phoneNumber: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State code: string = '';
  @State countdown: number = 60;
  @State isCountingDown: boolean = false;
  
  onSuccess: (phone: string) => void = () => {};
  onFailure: (msg: string) => void = () => {};

  build() {
    Column() {
      Text('注册账号')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      TextInput({ placeholder: '请输入手机号' })
        .type(InputType.PhoneNumber)
        .maxLength(11) // 限制长度
        .height(50)
        .width('90%')
        .margin({ bottom: 15 })
        .onChange((value: string) => {
          this.phoneNumber = value;
        })

      // 验证码区域
      Row() {
        TextInput({ placeholder: '请输入验证码' })
          .type(InputType.Number)
          .height(50)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.code = value;
          })

        Text(this.isCountingDown ? `${this.countdown}s` : '获取验证码')
          .fontSize(14)
          .fontColor(this.isCountingDown ? '#999999' : '#2E7D32')
          .margin({ left: 10 })
          .onClick(() => {
            if (this.isCountingDown) return;
            if (!this.phoneNumber) {
              this.onFailure('请输入手机号');
              return;
            }
            // 手机号正则验证
            const phoneRegex = /^1[3-9]\d{9}$/;
            if (!phoneRegex.test(this.phoneNumber)) {
              this.onFailure('请输入正确的手机号');
              return;
            }

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

            // 生成6位随机数
            const code = Math.floor(Math.random() * 900000 + 100000).toString();

            // 发送验证码到后端
            axios.get(`${Constants.BASE_URL}/user/login/randomCode`, {
              params: {
                username: this.phoneNumber,
                code: code
              }
            }).then((res: AxiosResponse) => {
              console.info('Register Code response:', JSON.stringify(res.data));
              // 弹窗显示验证码（方便测试）
              AlertDialog.show({
                title: '验证码',
                message: `您的验证码是：${code}`,
                confirm: {
                  value: '复制',
                  action: () => {
                    this.code = code; // 自动填充
                  }
                }
              });
            }).catch((err: Error) => {
              console.error('Register Code failed:', JSON.stringify(err));
              promptAction.showToast({ message: '验证码发送失败' });
            });
          })
      }
      .width('90%')
      .margin({ bottom: 15 })

      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)
        .height(50)
        .width('90%')
        .margin({ bottom: 15 })
        .onChange((value: string) => {
          this.password = value;
        })

      TextInput({ placeholder: '请确认密码' })
        .type(InputType.Password)
        .height(50)
        .width('90%')
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.confirmPassword = value;
        })

      Row() {
        Button('取消')
          .onClick(() => {
            this.controller?.close();
          })
          .backgroundColor('#F5F5F5')
          .fontColor('#666')
          .width('40%')
          .margin({ right: 10 })

        Button('注册')
          .onClick(() => {
            if (!this.phoneNumber || !this.code || !this.password || !this.confirmPassword) {
              this.onFailure('请填写完整信息');
              return;
            }
            // 注册时再次验证手机号
            const phoneRegex = /^1[3-9]\d{9}$/;
            if (!phoneRegex.test(this.phoneNumber)) {
              this.onFailure('请输入正确的手机号');
              return;
            }
            if (this.password !== this.confirmPassword) {
              this.onFailure('两次密码不一致');
              return;
            }

            // 发送注册请求
            axios.post(`${Constants.BASE_URL}/user/register`, null, {
              params: {
                username: this.phoneNumber,
                password: this.password,
                code: this.code
              }
            }).then((res: AxiosResponse) => {
              console.info('Register response:', JSON.stringify(res.data));
              // 定义简单的 Result 接口结构用于类型推断
              interface Result {
                code: number;
                msg: string;
                data: object;
              }
              const result = res.data as Result;
              
              if (result.code === 200 || result.code === 100001) {
                 // 成功：使用 getContext(this).getUIContext() 或 runInMainThread 确保 UI 更新
                 // 在 CustomDialog 中，最稳妥的是直接操作 @State 或使用 AbilityContext 的 promptAction (如果可用)
                 // 但这里我们使用最基础的 AlertDialog，它在某些上下文中更稳健，或者直接只关闭
                 
                 console.info('Register success, trying to show toast or close.');
                 
                 // 方案：放弃 promptAction.showToast，直接使用 AlertDialog (如果之前没出来可能是时机问题)
                 // 或者直接关闭，在 LoginView 页面弹 Toast
                 
                 this.onSuccess(this.phoneNumber);
                 this.controller?.close();
                 
                 // 我们通过回调通知 LoginView 去弹窗，避免在 Dialog 销毁前夕弹窗失败
                 // 注意：onSuccess 的逻辑是在 LoginView 中定义的，我们可以在那里加 Toast

               } else {
                // 失败：通过回调通知父组件显示失败信息
                this.onFailure(result.msg || '未知错误');
              }
            }).catch((err: Error) => {
              console.error('Registration failed:', JSON.stringify(err));
              
              // 尝试解析错误对象中的 code，如果包含 100001 则视为成功
              const errStr = JSON.stringify(err);
              if (errStr.includes('100001')) {
                  console.info('Caught 100001 in catch block, treating as success');
                  
                  this.onSuccess(this.phoneNumber);
                  this.controller?.close();
                  return;
               }

              this.onFailure('注册请求发送失败');
            });
          })
          .backgroundColor('#2E7D32')
          .fontColor(Color.White)
          .width('40%')
      }
      .margin({ bottom: 20 })
    }
    .backgroundColor(Color.White)
    .borderRadius(12)
    .width('80%')
  }
}
