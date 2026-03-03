import { componentSnapshot, promptAction } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

@CustomDialog
export struct ImageCropDialog {
  controller: CustomDialogController
  imageUri: string = ''
  onConfirm: (base64: string) => void = () => {}
  
  @State scaleValue: number = 1
  @State pinchValue: number = 1
  @State offsetX: number = 0
  @State offsetY: number = 0
  @State positionX: number = 0
  @State positionY: number = 0

  build() {
    Column() {
      Text('移动和缩放以裁剪')
        .fontSize(16)
        .fontColor(Color.White)
        .margin({ top: 20, bottom: 20 })

      Stack({ alignContent: Alignment.Center }) {
        // Image to crop
        Image(this.imageUri)
          .objectFit(ImageFit.Contain)
          .scale({ x: this.scaleValue, y: this.scaleValue })
          .translate({ x: this.offsetX, y: this.offsetY })
          .gesture(
            GestureGroup(GestureMode.Parallel,
              PinchGesture()
                .onActionStart(() => {
                  this.pinchValue = this.scaleValue
                })
                .onActionUpdate((event) => {
                  this.scaleValue = this.pinchValue * event.scale
                }),
              PanGesture()
                .onActionStart(() => {
                  this.positionX = this.offsetX
                  this.positionY = this.offsetY
                })
                .onActionUpdate((event) => {
                  this.offsetX = this.positionX + event.offsetX
                  this.offsetY = this.positionY + event.offsetY
                })
            )
          )
          .width('100%')
          .height('100%')

        // Circular Mask
        Canvas(new CanvasRenderingContext2D())
          .onReady(() => {}) // Placeholder, just using for overlay effect if needed, or use simple border
          .width('100%')
          .height('100%')
          .hitTestBehavior(HitTestMode.None)
        
        // Circular border overlay
        Column()
          .width(280)
          .height(280)
          .borderRadius(140)
          .border({ width: 2, color: Color.White })
          .hitTestBehavior(HitTestMode.None)
      }
      .width(300)
      .height(300)
      .clip(true)
      .backgroundColor(Color.Black)
      .id('cropArea') // ID for snapshot

      Row() {
        Button('取消')
          .onClick(() => {
            this.controller.close()
          })
          .backgroundColor(Color.Gray)
          .margin({ right: 20 })
        
        Button('确定')
          .onClick(async () => {
            try {
              // Snapshot the crop area
              const pixelMap = await componentSnapshot.get('cropArea')
              // Convert to Base64
              const imagePacker = image.createImagePacker();
              const packOpts: image.PackingOption = { format: "image/jpeg", quality: 98 };
              const data = await imagePacker.packing(pixelMap, packOpts);
              
              const helper = new util.Base64Helper();
              const base64Str = helper.encodeToStringSync(new Uint8Array(data));
              const fullBase64 = 'data:image/jpeg;base64,' + base64Str;
              
              this.onConfirm(fullBase64)
              this.controller.close()
            } catch (e) {
              console.error('Crop failed:', JSON.stringify(e))
              promptAction.showToast({ message: '裁剪失败' })
            }
          })
      }
      .margin({ top: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
