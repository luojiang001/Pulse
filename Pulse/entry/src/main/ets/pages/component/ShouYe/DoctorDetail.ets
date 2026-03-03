// pages/DoctorDetail.ets
import router from '@ohos.router';
import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import axios, { AxiosResponse } from '@ohos/axios';
import { Constants } from '../../../common/Constants';
import common from '@ohos.app.ability.common';
import { Doctor } from '../Doctor';
import { PreferencesUtil } from '../../utils/fileUtils';
import { User, Patient } from '../../data/Data';

interface DoctorDetailParams {
  id: number;
}

interface AppointmentParams {
  userId: number;
  patientId: number;
  doctorId: number;
  scheduleDate: string;
  scheduleTime: string;
  amount: number;
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

// 1. 重命名数据接口（避免与组件同名）
interface ScheduleTimeData {
  time: string;        // 时段（如"09:00-10:00"）
  isAvailable: boolean;// 是否可预约
}

interface ScheduleItemData {
  date: string;        // 日期（如"2026-01-23"）
  week: string;        // 星期（如"周四"）
  times: ScheduleTimeData[];// 时段列表
}

// 核心：数据接口命名为 DoctorDetailData（避免与组件struct冲突）
// 让详情数据接口继承通用的 Doctor 类，保持字段一致性
class DoctorDetailData extends Doctor {
  schedule: ScheduleItemData[] = []; // 出诊安排 (Doctor类中没有的字段)
  constructor(
    id: number, 
    name: string, 
    title: string, 
    department: string, 
    specialty: string, 
    rating: number, 
    price: number, 
    image: string, 
    isreserve: number = 1,
    hospital: string = '默认医院',
    experience: string = '未知',
    consultationCount: number = 0,
    education: string = '',
    schedule: ScheduleItemData[] = []
  ) {
    super(id, name, title, department, specialty, rating, price, image, isreserve, hospital, experience, consultationCount, education);
    this.schedule = schedule;
  }
}

// 临时接口：用于处理后端返回的宽泛数据结构（包含可能的嵌套和字段差异）
interface RawDoctorInfo {
  id?: number;
  doctorId?: number;
  name?: string;
  title?: string;
  hospital?: string;
  department?: string;
  rating?: number;
  experience?: string;
  consultationCount?: number;
  specialty?: string;
  education?: string;
  image?: string;
  price?: number;
  isreserve?: number;
  schedule?: ScheduleItemData[];
  data?: RawDoctorInfo; // 处理可能的 response.data.data 嵌套结构
}

// 2. 组件struct名称保留 DoctorDetail（无冲突）
@Entry
@Component
struct DoctorDetail {
  // 医生详情数据（使用重命名后的接口）
  @State doctorDetail: DoctorDetailData = new DoctorDetailData(
    0, '', '', '', '', 0, 0, '', 1, '', '', 0, '', []
  );
  @State selectedDateIndex: number = 0; // 当前选中的日期索引
  @State selectedTimeIndex: number = -1; // 当前选中的时段索引（-1=未选）
  @State currentUser: User | null = null; // 当前登录用户
  @State patients: Patient[] = []; // 就诊人列表

  // 就诊人选择弹窗控制器
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PatientSelectDialog({
      patients: $patients,
      onConfirm: (patient: Patient): void => this.onPatientSelected(patient)
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    customStyle: false
  })

  // 页面显示时加载数据
  async onPageShow() {
    // 1. 初始化 Context (防止未初始化)
    try {
      const context = getContext(this) as common.UIAbilityContext;
      PreferencesUtil.init(context);
    } catch (e) {
      console.error('Context init failed:', e);
    }

    // 2. 获取路由参数 (优先执行，确保能加载医生数据)
    const params = router.getParams() as DoctorDetailParams;
    if (params && params.id) {
      const doctorId = params.id as number;
      // 异步加载医生详情，不阻塞后续逻辑
      this.loadDoctorDetail(doctorId);
    } else {
        console.error('DoctorDetail: No doctor id found in params');
        promptAction.showToast({ message: '参数错误：未获取到医生ID' });
    }

    // 3. 获取当前用户信息 (异步并行执行)
    PreferencesUtil.getUserData().then(user => {
        this.currentUser = user;
    }).catch((err: Error) => {
        console.error('Failed to load user data:', err);
    });
  }

  // 模拟加载医生详情（实际项目替换为真实接口）
  private loadDoctorDetail(doctorId: number) {
    // 使用 axios 请求后端接口
    // 假设接口地址为 /doctor/detail，参数为 id
    axios.get(`${Constants.BASE_URL}/doctor/detail`, {
      params: { id: doctorId }
    })
    .then((res: AxiosResponse) => {
      console.info('Doctor detail response:', JSON.stringify(res.data));
      if (res.data) {
        // 假设后端返回的数据结构直接匹配 DoctorDetailData
        // 如果后端返回的数据字段名不同，这里需要进行手动映射
        // 例如：this.doctorDetail = this.mapBackendData(res.data);
        
        // 这里做一个简单的防御性处理，防止后端返回null字段导致崩溃
        const rawResponse = res.data as RawDoctorInfo;
        const data = rawResponse.data || rawResponse;
        
        this.doctorDetail = new DoctorDetailData(
          data.id || data.doctorId || doctorId,
          data.name || '',
          data.title || '',
          data.department || '',
          data.specialty || '',
          data.rating || 5.0,
          data.price || 0,
          data.image || '',
          data.isreserve !== undefined ? data.isreserve : 1, // isreserve
          data.hospital || '默认医院',
          data.experience || '未知',
          data.consultationCount || 0,
          data.education || '',
          data.schedule || []
        );

        // 如果后端没有返回排班数据，尝试单独请求排班接口
        if (!this.doctorDetail.schedule || this.doctorDetail.schedule.length === 0) {
           this.loadSchedule(doctorId);
        }
      }
    })
    .catch((err: Error) => {
      console.error('Get doctor detail failed:', JSON.stringify(err));
      promptAction.showToast({ message: '获取医生详情失败，使用默认数据' });
      // 失败时加载 Mock 数据作为兜底，方便演示
      this.loadMockData(doctorId);
    });
  }

  // 预留接口：独立获取排班数据 (如果后端将详情和排班分开接口)
  private loadSchedule(doctorId: number) {
    axios.get(`${Constants.BASE_URL}/doctor/schedule`, {
      params: { doctorId: doctorId }
    })
    .then((res: AxiosResponse) => {
      if (res.data && res.data.code === 200 && res.data.data) {
        // 假设后端返回的数据结构已经是 ScheduleItemData[]
        // 或者是扁平结构，这里需要转换
        this.doctorDetail.schedule = res.data.data;
      } else {
        // 如果接口也无数据，生成伪数据
        this.generateMockSchedule();
      }
    })
    .catch((err: Error) => {
      console.info('Get schedule failed, using mock data');
      this.generateMockSchedule();
    });
  }

  // 生成伪排班数据（当后端未返回排班时使用）
  private generateMockSchedule() {
     // 这里可以根据需要生成未来几天的排班
     // 生成未来3天的排班
     const schedule: ScheduleItemData[] = [];
     const today = new Date();
     const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

     for (let i = 0; i < 3; i++) {
        const date = new Date(today.getTime() + i * 24 * 60 * 60 * 1000);
        const dateStr = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
        const week = weekDays[date.getDay()];
        
        schedule.push({
          date: dateStr,
          week: week,
          times: [
            { time: '09:00-10:00', isAvailable: true },
            { time: '10:00-11:00', isAvailable: true },
            { time: '14:00-15:00', isAvailable: true },
            { time: '15:00-16:00', isAvailable: false }
          ]
        });
     }
     
     // 仅更新 schedule 字段，而不是覆盖整个 doctorDetail
     this.doctorDetail.schedule = schedule;
  }

  // 加载 Mock 数据（兜底用）
  private loadMockData(doctorId: number) {
    // 模拟后端返回的医生详情数据（含出诊安排）
    const mockData = new DoctorDetailData(
      doctorId,
      '示例医生',
      '主任医师',
      '全科',
      '常见病诊治',
      5.0,
      50,
      'app.media.doctor1',
      1,
      '示例医院',
      '10年',
      1000,
      '博士',
      []
    );
    this.doctorDetail = mockData;
  }

  // 日期选择事件（核心逻辑）
  private onDateSelect(index: number) {
    this.selectedDateIndex = index; // 切换选中日期
    this.selectedTimeIndex = -1;    // 切换日期后清空已选时段
  }

  // 时段选择事件（核心逻辑）
  private onTimeSelect(index: number) {
    // 只有可预约的时段才能选中
    const currentTimes = this.doctorDetail.schedule[this.selectedDateIndex]?.times || [];
    if (currentTimes[index]?.isAvailable) {
      this.selectedTimeIndex = this.selectedTimeIndex === index ? -1 : index; // 选中/取消
    }
  }

  // 提交预约 (预留接口)
  private async submitAppointment() {
    console.info('submitAppointment start');
    if (this.selectedDateIndex < 0 || this.selectedTimeIndex < 0) {
      promptAction.showToast({ message: '请先选择就诊时间' });
      return;
    }

    if (!this.currentUser) {
      console.warn('submitAppointment: No current user');
      promptAction.showToast({ message: '请先登录' });
      return;
    }

    // 提示正在加载
    promptAction.showToast({ message: '正在获取就诊人信息...' });

    // 加载就诊人列表
    await this.loadPatients();
    console.info(`submitAppointment: loaded ${this.patients.length} patients`);

    // 如果没有就诊人，提示去添加
    if (this.patients.length === 0) {
      console.info('submitAppointment: No patients found, showing add dialog');
      promptAction.showDialog({
        title: '提示',
        message: '您还没有添加就诊人，请先添加',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '去添加', color: '#007DFF' }
        ]
      }).then(res => {
        if (res.index === 1) {
          router.pushUrl({ url: 'pages/component/WoDe/PatientManager' });
        }
      });
      return;
    }
    
    // 打开选择弹窗
    console.info('submitAppointment: Opening selection dialog');
    if (this.dialogController) {
      this.dialogController.open();
    } else {
      console.error('submitAppointment: dialogController is null');
    }
  }

  // 加载就诊人
  private async loadPatients() {
    if (!this.currentUser) return;
    try {
      console.info(`loadPatients: fetching for user ${this.currentUser.id}`);
      const res: AxiosResponse = await axios.get(`${Constants.BASE_URL}/patient/list`, { 
        params: { userId: this.currentUser.id },
        timeout: 3000 // 3秒超时，防止无响应
      });
      console.info(`loadPatients response: ${JSON.stringify(res.data)}`);
      if (res.data.code === 200) {
        this.patients = res.data.data || [];
      } else {
        this.patients = [];
      }
    } catch (err) {
      console.error('Load patients error:', JSON.stringify(err));
      this.patients = [];
      promptAction.showToast({ message: '获取就诊人失败，请检查网络' });
    }
  }

  // 选中就诊人后的回调
  private onPatientSelected(patient: Patient) {
    const selectedDay = this.doctorDetail.schedule[this.selectedDateIndex];
    const selectedTime = selectedDay.times[this.selectedTimeIndex];
    
    promptAction.showDialog({
      title: '确认预约',
      message: `您即将为 ${patient.name} 预约 \n${selectedDay.date} ${selectedTime.time} \n${this.doctorDetail.name} 医生，是否确认？`,
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确认预约', color: '#007DFF' }
      ]
    }).then(result => {
      if (result.index === 1) {
        this.doBook(patient);
      }
    });
  }

  // 执行预约请求
  private doBook(patient: Patient) {
    if (!this.currentUser) {
       promptAction.showToast({ message: '请先登录' });
       return;
    }
    
    const selectedDay = this.doctorDetail.schedule[this.selectedDateIndex];
    const selectedTime = selectedDay.times[this.selectedTimeIndex];

    const appointmentParams: AppointmentParams = {
      userId: this.currentUser.id,
      patientId: patient.id,
      doctorId: this.doctorDetail.id,
      scheduleDate: selectedDay.date,
      scheduleTime: selectedTime.time,
      amount: this.doctorDetail.price
    };

    console.info(`发起预约请求: ${JSON.stringify(appointmentParams)}`);

    axios.post(`${Constants.BASE_URL}/appointment/book`, appointmentParams)
      .then((res: AxiosResponse) => {
        // 兼容处理：后端虽然返回 code 100001，但实际业务已成功（如MQ发送失败但不影响预约）
        if (res.data.code === 200 || res.data.code === 100001 || res.data.code === '100001') {
          promptAction.showToast({ message: '预约申请已提交' });
          // 延迟跳转返回，提升体验
          setTimeout(() => {
             router.back();
          }, 1000);
        } else {
          const msg = (res.data as Record<string, Object>).msg as string;
          promptAction.showToast({ message: msg || '预约失败' });
        }
      })
      .catch((err: Error) => {
        console.error('预约请求失败:', JSON.stringify(err));
        
        let isSuccess = false;
        try {
           const errStr = JSON.stringify(err);
           // 宽松判断：只要错误信息里包含 100001，就认为是业务成功但返回了错误码
           if (errStr.includes('100001')) {
              isSuccess = true;
           }
        } catch (e) {
           console.error('Check failed:', JSON.stringify(e));
        }

        if (isSuccess) {
           console.info('判定为预约成功 (兼容 100001)');
           try {
              // 尝试使用 UIContext 确保 UI 更新和跳转
              const that = this as Object as ComponentCompat;
              if (that.getUIContext) {
                 const uiContext = that.getUIContext();
                 if (uiContext) {
                    uiContext.getPromptAction().showToast({ message: '预约申请已提交' });
                    setTimeout(() => {
                      uiContext.getRouter().back();
                    }, 1000);
                    return;
                 }
              }
           } catch (e) {
              console.error('UIContext operation failed:', JSON.stringify(e));
           }

           // 降级方案
           promptAction.showToast({ message: '预约申请已提交' });
           setTimeout(() => {
              router.back();
           }, 1000);
           return;
        }

        promptAction.showToast({ message: '网络请求失败' });
      });
  }

  build() {
    Column() {
      // 1. 顶部导航栏 (固定)
      Row() {
        // 替换为你的返回图标资源，若无则用Text替代
        Image("http://47.101.196.181:9000/department-grid/return.png")
          .width(24)
          .height(24)
          .onClick(() => router.back())
          .margin({ right: 10 });
        Text('医生详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
        // 占位符，保持导航栏居中
        Text('')
          .width(24)
          .height(24);
      }
      .padding({ top: 10, bottom: 10, left: 15, right: 15 })
      .backgroundColor(Color.White)
      .width('100%')
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
      .zIndex(1);

      // 2. 可滚动内容区域
      Scroll() {
        Column() {
          // 医生基本信息
          Column() {
            Row() {
              // 头像
              Image("http://47.101.196.181:9000/department-grid/yisheng.png")// 兼容网络图片和本地资源
                .width(80)
                .height(80)
                .borderRadius(40)
                .backgroundColor('#E3F2FD')
                .margin({ right: 15 })
                .onError(() => {
                  console.info('Image load failed, using placeholder');
                })

              Column() {
                Text(this.doctorDetail.name)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold);
                Text(this.doctorDetail.title)
                  .fontSize(14)
                  .fontColor(Color.White)
                  .backgroundColor('#007DFF')
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(4)
                  .margin({ bottom: 5 });
                Text(`${this.doctorDetail.hospital || '暂无医院信息'} · ${this.doctorDetail.department}`)
                  .fontSize(14)
                  .fontColor('#666666');
                Row() {
                  Text('★ ' + this.doctorDetail.rating)
                  .fontSize(14)
                  .fontColor('#FFB300')
                  .margin({ right: 10 });
                  Text(`从业${this.doctorDetail.experience} · ${this.doctorDetail.consultationCount}次问诊`)
                  .fontSize(14)
                  .fontColor('#999999');
                }
              }
            }
          }
          .padding(20)
          .width('100%')
          .backgroundColor('#E3F2FD');

          // 擅长领域
          Column() {
            Row() {
              Text('擅长领域')
                .fontSize(16)
                .fontWeight(FontWeight.Bold);
            }
            .margin({ bottom: 10 })
            .width('100%')
            .padding({ left: 15, top: 15 });
            Text(this.doctorDetail.specialty)
              .fontSize(14)
              .fontColor('#666666')
              .lineHeight(20)
              .padding({ left: 15, right: 15, bottom: 15 });
          }
          .backgroundColor(Color.White)
          .margin({ top: 10 })
          .borderRadius(10);

          // 教育背景
          Column() {
            Text('教育背景')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })
              .padding({ left: 15, top: 15 });
            Text(this.doctorDetail.education)
              .fontSize(14)
              .fontColor('#666666')
              .padding({ left: 15, right: 15, bottom: 15 });
          }
          .backgroundColor(Color.White)
          .margin({ top: 10 })
          .borderRadius(10);

          // 出诊安排卡片（核心：日期+时段选择）
          Column() {
            // 标题
            Text('出诊安排')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 15, left: 15, top: 15 })
              .width('100%');

            // 日期选择栏
            if (this.doctorDetail.schedule.length === 0) {
              // 无出诊数据兜底
              Text('暂无出诊安排')
                .fontSize(14)
                .fontColor('#999999')
                .padding(20)
                .width('100%');
            } else {
              // 日期横向滚动选择
              Scroll() {
                Row() {
                  ForEach(this.doctorDetail.schedule, (item: ScheduleItemData, index: number) => {
                    Text(`${item.date} ${item.week}`)
                      .fontSize(12)
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .borderRadius(20)
                      // 选中态样式
                      .backgroundColor(index === this.selectedDateIndex ? '#007DFF' : '#F5F5F5')
                      .fontColor(index === this.selectedDateIndex ? Color.White : '#666666')
                      .margin({ right: 10, left: 5 })
                      .onClick(() => this.onDateSelect(index)); // 绑定日期选择事件
                  });
                }
                .padding({ left: 10 });
              }
              .scrollable(ScrollDirection.Horizontal)
              .margin({ bottom: 15, left: 10, right: 10 })
              .width('100%');

              // 时段选择区域
              Text('可预约时段')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 10, left: 15 })
                .width('100%');

              // 获取当前选中日期的时段列表
              if ((this.doctorDetail.schedule[this.selectedDateIndex]?.times || []).length === 0) {
                Text('当日无可用时段')
                  .fontSize(14)
                  .fontColor('#999999')
                  .padding(10)
                  .width('100%')
                  .textAlign(TextAlign.Center);
              } else {
                // 时段网格布局
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(this.doctorDetail.schedule[this.selectedDateIndex]?.times || [], (timeItem: ScheduleTimeData, index: number) => {
                    Text(timeItem.time)
                      .fontSize(12)
                      .padding({ left: 15, right: 15, top: 8, bottom: 8 })
                      .borderRadius(4)
                      // 样式逻辑：选中/不可预约/未选中
                      .backgroundColor(!timeItem.isAvailable ? '#EEEEEE' : (this.selectedTimeIndex === index ? '#007DFF' : '#F5F5F5'))
                      .fontColor(!timeItem.isAvailable ? '#CCCCCC' : (this.selectedTimeIndex === index ? Color.White : '#666666'))
                      .margin({ right: 10, bottom: 10, left: 15 })
                      .onClick(() => this.onTimeSelect(index)); // 绑定时段选择事件
                  });
                }
              }
            }
          }
          .backgroundColor(Color.White)
          .margin({ top: 10, bottom: 20 })
          .borderRadius(10)
          .padding({ bottom: 15 });
        }
        .width('100%')
      }
      .layoutWeight(1) // 占据剩余空间
      .backgroundColor('#F5F7FA')
      .edgeEffect(EdgeEffect.Spring);

      // 底部预约栏
      Row() {
        Column() {
          Text('¥' + this.doctorDetail.price)
            .fontSize(20)
            .fontColor('#FF5252')
            .fontWeight(FontWeight.Bold);
          Text('挂号费')
            .fontSize(12)
            .fontColor('#999999');
        }
        .alignItems(HorizontalAlign.Start);

        Button('立即预约')
          .backgroundColor(this.doctorDetail.isreserve === 1 ? '#007DFF' : '#CCCCCC')
          .fontColor(Color.White)
          .height(40)
          .width(120)
          .enabled(this.doctorDetail.isreserve === 1)
          .onClick(() => {
            this.submitAppointment();
          });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.SpaceBetween)
      .shadow({ radius: 5, color: 'rgba(0,0,0,0.1)', offsetY: -2 });

    }
    .backgroundColor('#F5F7FA')
    .width('100%')
    .height('100%');
  }
}

@CustomDialog
  struct PatientSelectDialog {
    @Link patients: Patient[]
    controller?: CustomDialogController
    onConfirm: (patient: Patient) => void = (patient: Patient) => {}
  
    build() {
    Column() {
      Text('请选择就诊人')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 15 })
        .width('100%')
        .textAlign(TextAlign.Center)
        
      List() {
        ForEach(this.patients, (item: Patient) => {
          ListItem() {
             Row() {
               Text(item.name).fontSize(16).fontColor('#333')
               Blank()
               if (item.isDefault) {
                 Text('默认').fontSize(12).fontColor('#999').margin({ right: 10 })
               }
             }
             .width('100%')
             .padding({ left: 20, right: 20, top: 15, bottom: 15 })
             .onClick(() => {
               this.onConfirm(item)
               if (this.controller) {
                 this.controller.close()
               }
             })
          }
        })
      }
      .width('100%')
      .height(200)
      .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 20, endMargin: 20 })

      Button('添加就诊人')
        .width('90%')
        .height(40)
        .backgroundColor('#F5F5F5')
        .fontColor('#007DFF')
        .margin({ top: 10, bottom: 15 })
        .onClick(() => {
           if (this.controller) {
             this.controller.close()
           }
           router.pushUrl({ url: 'pages/component/WoDe/PatientAdd' })
        })
    }
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .width('100%')
  }
}