import { CommonMap, TravelMapOptions } from './CommonMap'; 
import { promptAction } from '@kit.ArkUI'; 

@Component 
export struct MapComponent { 
  build() { 
    Column() { 
      // 顶部标题栏 (可选，保持风格一致)
      Row() {
          Text('周边导航')
            .fontSize(24)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 12, bottom: 12 })
      .justifyContent(FlexAlign.Start)

      // 地图组件
      CommonMap({ 
        travelMapOptions: { 
          location: {
            //经纬度
            latitude: 39.2,
            longitude: 117.43,
          }, 
          icon: $r('app.media.background'), // 使用存在的资源
          titleOptions: { 
            name: '一间民宿', 
            strokeColor: 0xFFFFFFFF, 
          }, 
          cameraSpeed: 1000, 
          zoom: 10, 
          height: '100%', 
          pointClickCallBack: () => { 
            promptAction.showToast({ message: '点击标记点' }); 
          }, 
        }
      })
      .layoutWeight(1) // 占满剩余空间
      .borderRadius({ topLeft: 24, topRight: 24 }) // 顶部圆角，像卡片一样
      .clip(true)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
        angle: 180,
        colors: [['#4CD9C0', 0.0], ['#80CBC4', 0.15], ['#FFFFFF', 0.15]] // 顶部薄荷绿，下面白色
    })
  } 
}