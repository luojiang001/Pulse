import { window } from '@kit.ArkUI';

@ObservedV2
export class WindowModel {
  @Trace windowBottomPadding: number = 0;
  /**
   * 获取底部避让区域高度
   */
  public getWindowBottomPadding: () => void = () => {
    window.getLastWindow(getContext()).then(currentWindow => {
      const area = currentWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.windowBottomPadding = px2vp(area.bottomRect.height);
    })
  }

  /**
   * 监听底部避让区域变化
   */
  public registerWindowBottomPadding() {
    this.getWindowBottomPadding();
    window.getLastWindow(getContext()).then(currentWindow => {
      currentWindow.on('avoidAreaChange', this.getWindowBottomPadding);
    })
  }

  /**
   * 取消监听底部避让区域变化
   */
  public unRegisterWindowBottomPadding() {
    window.getLastWindow(getContext()).then(currentWindow => {
      currentWindow.off('avoidAreaChange', this.getWindowBottomPadding);
    })
  }

  /**
   * 注册监听键盘区域变化
   */
  public registerKeyboardListener(callback: Callback<number>) {
    window.getLastWindow(getContext()).then(currentWindow => {
      const keyboardH = currentWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD).bottomRect.height;
      callback(keyboardH);
      currentWindow.on('keyboardHeightChange', callback);
    })
  }

  /**
   * 取消注册监听键盘区域变化
   */
  public unRegisterKeyboardListener(callback: Callback<number>) {
    window.getLastWindow(getContext()).then(currentWindow => {
      currentWindow.off('keyboardHeightChange', callback);
    })
  }
}
