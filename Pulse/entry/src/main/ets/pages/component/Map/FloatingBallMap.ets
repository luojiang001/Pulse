import { display, window } from '@kit.ArkUI';
import { MapComponent } from './MapPage';

@CustomDialog
struct MapDialog {
  controller?: CustomDialogController

  build() {
    Column() {
      // 顶部关闭按钮
      Row() {
        Blank()
        Text('×')
          .fontSize(30)
          .fontColor(Color.Black)
          .onClick(() => {
            this.controller?.close();
          })
          .padding({ right: 16, top: 8 })
      }
      .width('100%')
      .height(40)
      .justifyContent(FlexAlign.End)

      // 地图组件
      MapComponent()
        .layoutWeight(1)
        .width('100%')
    }
    .width('90%')
    .height('80%')
    .backgroundColor(Color.White)
    .borderRadius(24)
    .clip(true)
  }
}

@Component
export struct FloatingBallMap {
  @State ballPosition: Position = { x: 300, y: 500 };
  @State isDraggable: boolean = true;
  
  private winWidth: number = 720; // 默认值，防止获取失败
  private winHeight: number = 1280;
  private startX: number = 0;
  private startY: number = 0;
  private isClick: boolean = true;

  dialogController?: CustomDialogController = new CustomDialogController({
    builder: MapDialog(),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center
  });

  aboutToAppear() {
    try {
      // 获取窗口尺寸
      window.getLastWindow(getContext(this)).then((win) => {
        let properties = win.getWindowProperties();
        let rect = properties.windowRect;
        
        if (rect.width > 0 && rect.height > 0) {
          // 将px转换为vp
          this.winWidth = px2vp(rect.width);
          this.winHeight = px2vp(rect.height);
          
          // 初始位置设置在右侧中部
          this.ballPosition = { x: this.winWidth - 60, y: this.winHeight / 2 };
        }
      }).catch((err: Error) => {
        console.error('FloatingBallMap: Failed to get window. ' + JSON.stringify(err));
      });
    } catch (err) {
      console.error('FloatingBallMap: Error in aboutToAppear. ' + JSON.stringify(err));
    }
  }

  // 手势处理核心逻辑
  private onPanelTouch(event: TouchEvent) {
    if (event.type === TouchType.Down) {
      this.isClick = true;
      this.startX = event.touches[0].windowX;
      this.startY = event.touches[0].windowY;
    }
    else if (event.type === TouchType.Move && this.isDraggable) {
      const touch = event.touches[0];
      
      // 更新位置
      // touch.windowX/Y 单位通常为 vp，无需再次转换
      let targetX = touch.windowX - 25; // 减去半径
      let targetY = touch.windowY - 25;
      
      // 边界限制
      targetX = Math.max(0, Math.min(this.winWidth - 50, targetX));
      targetY = Math.max(0, Math.min(this.winHeight - 50, targetY));
      
      this.ballPosition = { x: targetX, y: targetY };
    }
    else if (event.type === TouchType.Up) {
      if (this.isClick) {
        // 点击事件：打开地图
        this.dialogController?.open();
      } else {
        // 拖拽结束：吸附边缘
        animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
          let currentX = this.ballPosition.x as number;
          this.ballPosition = { x: currentX > this.winWidth / 2 ? this.winWidth - 60 : 10, y: this.ballPosition.y };
        });
      }
    }
  }

  build() {
    Stack() {
      // 悬浮球外观
      Column() {
        Text('导')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
        Text('航')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(50)
      .height(50)
      .borderRadius(25)
      .backgroundColor('#4CD9C0') // 主题色
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 10, color: Color.Gray, offsetX: 5, offsetY: 5 })
    }
    .position(this.ballPosition)
    .zIndex(999) // 确保在最上层
    .onTouch((e) => this.onPanelTouch(e))
  }
}
