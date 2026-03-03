import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { ImageCropDialog } from './ImageCropDialog';
import { AppStorageV2 } from '@kit.ArkUI';
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Constants } from '../common/Constant';
import { ConfigInfo } from '../common/ConfigModel';
import { ERROR_MSG_MAP } from '../common/ErrorMsgMap';

const DOMAIN = 0xff00;
const TAG = '[ChooseAvatar]';

@ComponentV2
export struct ChooseAvatar {
  /**
   * 传入的头像地址
   */
  @Param url: ResourceStr = '';
  /**
   * 头像高度
   */
  @Param avatarH: Length = 48;
  /**
   * 选择头像的回调
   */
  @Event onChooseAvatar: (url: string) => void;
  @Local configInfo: ConfigInfo = AppStorageV2.connect(ConfigInfo, () => new ConfigInfo())!;

  @Local tempImageUri: string = ''
  dialogController: CustomDialogController | null = null;

  build() {
    Stack() {
      Image(this.url)
        .width(this.avatarH)
        .height(this.avatarH)
        .borderRadius(Constants.HALF_PERCENT)
        .objectFit(ImageFit.Cover)
        .backgroundColor(this.configInfo.themeColor)
    }
    .onClick(() => {
      this.selectImage();
    })
  }

  async selectImage() {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);
      if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
        this.tempImageUri = photoSelectResult.photoUris[0];
        
        this.dialogController = new CustomDialogController({
          builder: ImageCropDialog({
            imageUri: this.tempImageUri,
            onConfirm: (base64: string) => {
              this.onChooseAvatar(base64);
            }
          }),
          autoCancel: true,
          customStyle: true
        });
        
        this.dialogController.open();
      }
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  handleError(error: BusinessError) {
    hilog.error(DOMAIN, TAG, 'onChooseAvatar failed, error: ' + JSON.stringify(error));
    const errorMsg: string = ERROR_MSG_MAP[error.code] ?? '';
    if (errorMsg) {
      this.getUIContext().getPromptAction().showDialog({
        title: '温馨提示',
        message: errorMsg,
        buttons: [
          { text: '确定', color: this.configInfo.themeColor },
        ],
      })
    }
  }
}
