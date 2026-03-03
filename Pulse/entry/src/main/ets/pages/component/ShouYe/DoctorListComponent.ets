import { Doctor } from '../Doctor';
import { Constants } from '../../../common/Constants';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { StorageUtil, STORAGE_KEYS } from '../../utils/StorageUtil';
import { Patient } from '../../data/Data';
import axios, { AxiosResponse } from '@ohos/axios';

@Component
export struct DoctorListComponent {
  @State doctors: Doctor[] = [];
  @State allDoctors: Doctor[] = []; // 所有医生数据（全量）
  @Prop @Watch('onDepartmentChange') filterDepartment: string = '全部';
  @Prop @Watch('onSearchChange') searchKeyword: string = ''; //搜索关键字

  aboutToAppear() {
    this.initData();
  }

  // 监听科室变化
  onDepartmentChange() {
    this.applyFilters();
  }

  // 监听搜索词变化
  onSearchChange() {
    this.applyFilters();
  }

  // 统一过滤逻辑
  applyFilters() {
    let temp = this.allDoctors;

    // 1. 科室过滤
    if (this.filterDepartment && this.filterDepartment !== '全部') {
      temp = temp.filter(d => d.department === this.filterDepartment);
    }

    // 2. 关键词过滤
    if (this.searchKeyword) {
      const keyword = this.searchKeyword.trim();
      temp = temp.filter(doctor => 
        (doctor.name && doctor.name.includes(keyword)) ||
        (doctor.specialty && doctor.specialty.includes(keyword))
      );
    }

    this.doctors = temp;
  }

  // 初始化数据（不使用缓存，强制刷新以获取最新状态）
  async initData() {
    // 直接请求网络（获取全量数据）
    console.info('开始请求医生列表数据（全量）');
    // 不传参数，默认获取所有医生
    axios.get(`${Constants.BASE_URL}/doctor/list`)
      .then((res: AxiosResponse) => {
        console.info('Doctor list response:', JSON.stringify(res.data));
        
        let data: Doctor[] = [];
        // 兼容 Result 包装类结构 { code: 200, data: [...] } 或直接数组
        if (res.data && res.data.code === 200 && Array.isArray(res.data.data)) {
            data = res.data.data as Doctor[];
        } else if (Array.isArray(res.data)) {
            data = res.data as Doctor[];
        }

        if (data) {
          this.allDoctors = data;
          // 应用过滤
          this.applyFilters();
        } else {
            this.allDoctors = [];
            this.doctors = [];
        }
      })
      .catch((err: Error) => {
        console.error('Get doctor list failed:', JSON.stringify(err));
        this.allDoctors = [];
        this.doctors = [];
      });
  }

  private async goToDoctorDetail(id: number) {
    console.info(`尝试跳转到医生详情页, id: ${id}`);
    try {
        // 检查就诊人
        console.info('正在获取就诊人信息...');
        const patients = await StorageUtil.getData<Patient[]>(STORAGE_KEYS.USER_INFO, []);
        console.info(`获取就诊人信息完成, 数量: ${patients.length}`);
        
        if (patients.length === 0) {
           console.info('未找到就诊人，显示添加提示弹窗');
           AlertDialog.show({
             title: '提示',
             message: '您还没有添加就诊人，请先添加就诊人',
             primaryButton: {
               value: '取消',
               action: () => {
                 console.info('用户点击取消添加就诊人');
               }
             },
             secondaryButton: {
               value: '去添加',
               action: () => {
                 console.info('用户点击去添加就诊人');
                 router.pushUrl({ url: 'pages/component/WoDe/PatientManager' });
               }
             }
           });
           return;
        }

        console.info(`准备跳转到: pages/component/ShouYe/DoctorDetail, 参数: { id: ${id} }`);
        router.pushUrl({
          url: 'pages/component/ShouYe/DoctorDetail', // 详情页的路由路径
          params: {id: id } // 携带医生ID
        }).then(() => {
          console.info('跳转成功');
        }).catch((err: Error) => {
          console.error(`跳转失败，错误码: ${JSON.stringify(err)}`);
          promptAction.showToast({ message: `跳转失败: ${err.message || JSON.stringify(err)}` });
        })
    } catch (e) {
        console.error(`路由异常: ${JSON.stringify(e)}`);
        promptAction.showToast({ message: `路由异常: ${JSON.stringify(e)}` });
    }
  }
  build() {
    Column() {
      Text('推荐医生')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10, left: 20 })
        .alignSelf(ItemAlign.Start)

      // 使用 Column 代替 List，避免与外层 Scroll 冲突
      Column() {
        ForEach(this.doctors, (doctor: Doctor) => {
          // 列表项容器
          Column() {
            Row() {
              // Avatar
              Image('http://47.101.196.181:9000/department-grid/yisheng.png') 
                .width(60) // 调整回正常大小 60vp
                .height(60)
                .borderRadius(30) 
                .backgroundColor('#EEEEEE') 
                .margin({ right: 16 }) 
                .border({ width: 1, color: '#E2E8F0' }) 

              Column() {
                Row() {
                  Text(doctor.name)
                    .fontSize(18) // 调整为标准标题字号 18fp
                    .fontColor('#1E293B') 
                    .fontWeight(FontWeight.Bold)
                    .margin({ right: 8 })

                  Text(doctor.title)
                    .fontSize(12) // 调整为辅助字号 12fp
                    .fontColor('#0A59F7') 
                    .backgroundColor('#E3F2FD') // 恢复背景色标签样式，更美观
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                }
                .margin({ bottom: 6 })
                .width('100%') // 确保 Row 占满宽度以便子元素排列

                Text(`${doctor.hospital || '默认医院'} · ${doctor.department}`)
                  .fontSize(13) // 13fp
                  .fontColor('#64748B') 
                  .margin({ bottom: 6 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text('擅长: ' + doctor.specialty)
                  .fontSize(12) 
                  .fontColor('#94A3B8') 
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ bottom: 8 })

                Row() {
                  Text('★ ' + doctor.rating)
                    .fontSize(14) 
                    .fontColor('#FFAB00') 
                    .margin({ right: 12 })

                  Text('¥' + doctor.price + ' 起')
                    .fontSize(16) // 价格稍大 16fp
                    .fontColor('#0A59F7') 
                    .fontWeight(FontWeight.Bold)
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 状态标签 - 放在右上角或右侧垂直居中
              Column() {
                 Text(doctor.isreserve === 1 ? '可预约' : '暂不可约')
                  .fontSize(12) 
                  .fontColor(doctor.isreserve === 1 ? '#00C853' : '#94A3B8')
                  .backgroundColor(doctor.isreserve === 1 ? 'rgba(54, 211, 153, 0.1)' : 'rgba(148, 163, 184, 0.1)') // 浅色背景更优雅
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 }) 
                  .borderRadius(4)
              }
              .margin({ left: 8 })
              .justifyContent(FlexAlign.Start) // 顶部对齐
            }
            .width('100%') 
            .alignItems(VerticalAlign.Top) // 顶部对齐
          }
          .padding(16) // 标准内边距 16vp
          .backgroundColor(Color.White)
          .borderRadius(12) 
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 }) 
          .margin({ bottom: 12, left: 16, right: 16 })
          .onClick(() => {
             console.info('点击了医生列表项');
             this.goToDoctorDetail(doctor.id);
          })
        })
      }
    }
  }
}
