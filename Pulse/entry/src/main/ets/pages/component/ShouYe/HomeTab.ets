import { HomeHeaderComponent } from './HomeHeaderComponent';
import { DepartmentGridComponent } from './DepartmentGridComponent';
import { DoctorListComponent } from './DoctorListComponent';

@Component
export struct HomeTab {
  @State selectedDept: string = '全部';
  @State searchKeyword: string = ''; // 新增搜索关键字状态

  build() {
    Scroll() {
      Column() {
        HomeHeaderComponent({
          onSearch: (keyword: string) => {
            this.searchKeyword = keyword; // 更新搜索关键字
          }
        })

        DepartmentGridComponent({
          selectedDepartment: this.selectedDept,
          onSelect: (name: string) => {
            this.selectedDept = name; // 更新父组件状态
          }
        })

        DoctorListComponent({
          filterDepartment: this.selectedDept, // 传递给医生列表组件
          searchKeyword: this.searchKeyword    // 传递搜索关键字
        })
      }
      .width('100%')
      // Removed .height('100%') to allow scrolling

    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .linearGradient({
      angle: 180, // 从上到下
      colors: [['#D1F2EB', 0.0], ['#E0F7FA', 0.3], ['#FFFFFF', 1.0]] // 薄荷绿渐变到白
    })
    .height('100%') // Ensure background covers full height
  }
}
