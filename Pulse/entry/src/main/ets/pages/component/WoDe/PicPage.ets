import { BusinessError, request } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { JSON } from '@kit.ArkTS';
import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { Constants } from '../../../common/Constants';

@Entry
@Component
struct PicPage {
  @State message: string = 'Hello World';
  @State selectImageUrl: string | undefined = '';


  build() {
    Column() {
      Button("test").onClick((event: ClickEvent) => {
        // 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext
        let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        let uploadTask: request.UploadTask;
        const imgName=Date.now()
        const data=fs.openSync(this.selectImageUrl,fs.OpenMode.READ_ONLY)
        const newDir=`${context.cacheDir}/${imgName}.jpg`
        fs.copyFileSync(data.fd,newDir)
        const uploadURI=`internal://cache/${newDir.split("cache/")[1]}`
        let uploadConfig: request.UploadConfig = {
          url: `${Constants.BASE_URL}/photo`, // 需要手动将url替换为真实服务器的HTTP协议地址
          header: { 'Accept': '*/*' ,'Content-Type':'multipart/form-data'},
          method: "POST",
          files: [{ filename: "photo", name: "photo", uri: uploadURI, type: "image/jpeg" }], // 建议type填写HTTP协议规范的MIME类型
          data: [{ name: "name123", value: "123" }],
        };
        try {
          request.uploadFile(context, uploadConfig).then((data: request.UploadTask) => {
            uploadTask = data;
          }).catch((err: BusinessError) => {
            console.error(`Failed to request the upload. Code: ${err.code}, message: ${err.message}`);
          });
        } catch (err) {
          console.error(`Failed to request the upload. err: ${JSON.stringify(err)}`);
        }
      })
      Button('从相册选择照片').onClick((event: ClickEvent) => {
        this.selectPhoto()
      })
      Image(this.selectImageUrl).width(200)


    }
    .height('100%')
    .width('100%')
  }
  async selectPhoto(){
    let photoSelectOptions=new picker.PhotoSelectOptions();
    photoSelectOptions.MIMEType=picker.PhotoViewMIMETypes.IMAGE_TYPE
    photoSelectOptions.maxSelectNumber=1
    let photoPicker=new picker.PhotoViewPicker();
    photoPicker.select(photoSelectOptions).then(result=>{
      // this.message=JSON.stringify(result)
      this.selectImageUrl=result.photoUris[0]
    })
  }
  async takePhoto(){
    const context=getContext(this) as common.UIAbilityContext
    try {
      const captureResult=await context.startAbilityForResult({
        action:'ohos.want.action.imageCapture',
        parameters:{}
      })
      this.message=JSON.stringify(captureResult.want)
      this.selectImageUrl=captureResult.want?.uri
    } catch (e) {
      console.error('takePhoto error:', JSON.stringify(e));
    }
  }
}