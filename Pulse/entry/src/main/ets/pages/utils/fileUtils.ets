// utils/PreferencesUtil.ets
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { User } from '../data/Data';

export class PreferencesUtil {
  private static context: common.UIAbilityContext;

  // 需要先在 EntryAbility 或页面中初始化 Context
  static init(context: common.UIAbilityContext) {
    PreferencesUtil.context = context;
  }

  // 初始化Preferences实例（全局唯一）
  private static async getPreferencesInstance(): Promise<dataPreferences.Preferences> {
    if (!PreferencesUtil.context) {
      throw new Error("Context not initialized. Call PreferencesUtil.init(context) first.");
    }
    // "user_info"是存储文件名，自定义即可
    return await dataPreferences.getPreferences(PreferencesUtil.context, 'user_info');
  }

  /**
   * 存储用户数据（核心方法）
   * @param userData 后端返回的用户数据
   */
  static async saveUserData(userData: User): Promise<boolean> {
    try {
      const preferences = await PreferencesUtil.getPreferencesInstance();
      // Preferences 不支持直接存储对象，需要序列化为 JSON 字符串
      await preferences.put('user_data', JSON.stringify(userData));
      await preferences.flush(); // 强制持久化到本地
      return true;
    } catch (error) {
      console.error('存储用户数据失败：', error);
      return false;
    }
  }

  /**
   * 读取用户数据（目标页面调用）
   * @returns 用户数据 | null
   */
  static async getUserData(): Promise<User | null> {
    try {
      const preferences = await PreferencesUtil.getPreferencesInstance();
      // 读取时返回的是字符串，默认值为空字符串
      const userDataStr = await preferences.get('user_data', '') as string;

      if (!userDataStr) {
        return null;
      }

      // 反序列化 JSON 字符串
      const userData = JSON.parse(userDataStr) as User;
      return userData;
    } catch (error) {
      console.error('读取用户数据失败：', error);
      return null;
    }
  }

  /**
   * 清空用户数据（如退出登录时调用）
   */
  static async clearUserData(): Promise<boolean> {
    try {
      const preferences = await PreferencesUtil.getPreferencesInstance();
      await preferences.delete('user_data');
      await preferences.flush();
      return true;
    } catch (error) {
      console.error('清空用户数据失败：', error);
      return false;
    }
  }
}