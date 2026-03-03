import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

export interface Location {
  latitude: number;
  longitude: number;
}

export interface TitleOptions {
  name: string;
  strokeColor: number;
}

export interface TravelMapOptions {
  location: Location;
  icon: Resource;
  titleOptions: TitleOptions;
  cameraSpeed: number;
  zoom: number;
  height: string | number;
  pointClickCallBack: () => void;
}

@Component
export struct CommonMap {
  @Prop travelMapOptions: TravelMapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;

  aboutToAppear(): void {
    // 初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        // 地图加载完成后，添加标记点
        this.addMarker();
      }
    };
  }

  addMarker() {
    if (this.mapController) {
      // 创建 Marker
      let markerOptions: mapCommon.MarkerOptions = {
        position: {
          latitude: this.travelMapOptions.location.latitude,
          longitude: this.travelMapOptions.location.longitude
        },
        title: this.travelMapOptions.titleOptions?.name,
        clickable: true
      };
      
      this.mapController.addMarker(markerOptions);
      
      // 设置点击监听
      this.mapController.on("markerClick", (marker: map.Marker) => {
         if (this.travelMapOptions.pointClickCallBack) {
           this.travelMapOptions.pointClickCallBack();
         }
      });
      
      // 移动相机
      let cameraPosition: mapCommon.CameraPosition = {
        target: {
          latitude: this.travelMapOptions.location.latitude,
          longitude: this.travelMapOptions.location.longitude
        },
        zoom: this.travelMapOptions.zoom || 10,
        tilt: 0,
        bearing: 0
      };
      
      let cameraUpdate = map.newCameraPosition(cameraPosition);
      this.mapController.moveCamera(cameraUpdate);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 使用鸿蒙原生 MapComponent
      MapComponent({ 
        mapOptions: {
          position: {
            target: {
              latitude: this.travelMapOptions.location.latitude,
              longitude: this.travelMapOptions.location.longitude
            },
            zoom: this.travelMapOptions.zoom || 10
          }
        },
        mapCallback: this.callback 
      })
      .width('100%')
      .height(this.travelMapOptions.height || '100%')
    }
    .width('100%')
    .height(this.travelMapOptions.height || '100%')
    .clip(true)
  }
}