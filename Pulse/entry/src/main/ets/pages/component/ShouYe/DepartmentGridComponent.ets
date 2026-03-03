
import axios, { AxiosResponse } from '@ohos/axios';
import { Constants } from '../../../common/Constants';

// 接口定义在struct外部（ArkTS规范）
export interface Department {
  id?: number;        // 数据库ID
  name: string;       // 科室名称
  icon: string;       // 图标资源路径（占位）
}

@Component
export struct DepartmentGridComponent {
  @State departments: Array<Department> = [

  ];

  @Prop selectedDepartment: string = '全部'; // 接收父组件传递的选中状态
  onSelect: (name: string) => void = () => {}; // 接收父组件的回调函数

  aboutToAppear() {
    this.getDepartmentList();
  }

  // 获取科室列表接口
  getDepartmentList() {
    // 1. 尝试从缓存获取
    const cachedDepartments = AppStorage.Get<Department[]>('cachedDepartments');
    if (cachedDepartments && cachedDepartments.length > 0) {
      console.info('使用缓存的科室数据');
      this.departments = cachedDepartments;
      return;
    }

    // 2. 缓存不存在，请求网络
    // 替换为实际的后端接口地址
    axios.get(`${Constants.BASE_URL}/department/list`)
      .then((res: AxiosResponse) => {
        console.info('Department list response:', JSON.stringify(res.data));

        // 后端直接返回 List<Department>，且已包含"全部"
        if (Array.isArray(res.data)) {
           this.departments = res.data as Department[];
           // 存入缓存
           AppStorage.SetOrCreate('cachedDepartments', this.departments);
        }
      })
      .catch((err: Error) => {
        console.error('Get department list failed:', JSON.stringify(err));
        // 接口失败时保持使用默认本地数据
      });
  }

  build() {
    Column() {
      // 标题
      Text('选择科室')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24, bottom: 16, left: 24 }) // 模块间距 24vp
        .alignSelf(ItemAlign.Start);

      // 科室网格
      Grid() {
        ForEach(
          this.departments,
          (item: Department) => {
            GridItem() {
              Column() {
                // 使用 item.icon 作为图片源，如果为空则使用默认图
                Image(item.icon ? item.icon : $rawfile('Pulse/Common/foreground.png'))
                  .width(40) // 调整为合适大小 40vp
                  .height(40)
                  .objectFit(ImageFit.Contain)
                  .margin({ bottom: 8 }) 
                  .fillColor(this.selectedDepartment === item.name ? Color.White : undefined)

                Text(item.name)
                  .fontSize(14) // 调整为标准字号 14fp
                  .fontColor(this.selectedDepartment === item.name ? '#ff070707' : '#1E293B')
                  .fontWeight(FontWeight.Normal)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis }) // 防止文字换行撑破布局
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height(100) // 调整高度适配内容
              .backgroundColor(this.selectedDepartment === item.name ? '#E8F4F8' : '#F8FAFC')
              .borderRadius(12) 
              .padding(8) // 减小内边距
              .onClick(() => {
                if (this.onSelect) {
                  this.onSelect(item.name);
                }
              })
            }
          },
          (item: Department) => item.name 
        )
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12) 
      .columnsGap(12) 
      .height(240) // 调整总高度
      .margin({ left: 16, right: 16 });
    }
    .width('100%')
    .backgroundColor('#FFFFFF'); // 保持白色背景
  }
}