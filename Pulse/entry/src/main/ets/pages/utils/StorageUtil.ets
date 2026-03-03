import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class STORAGE_KEYS {
  static readonly CART = 'cart_data';
  static readonly ORDERS = 'order_data';
  static readonly REGISTRATIONS = 'registration_data';
  static readonly PRESCRIPTIONS = 'prescription_data';
  static readonly USER_INFO = 'user_info';
}

export class StorageUtil {
  private static PREFERENCES_NAME = 'pulse_preferences';
  private static context: common.UIAbilityContext;
  private static pref: preferences.Preferences | null = null;

  static async init(context: common.UIAbilityContext) {
    StorageUtil.context = context;
    try {
      StorageUtil.pref = await preferences.getPreferences(context, StorageUtil.PREFERENCES_NAME);
      console.info('StorageUtil initialized successfully');
    } catch (err) {
      console.error(`StorageUtil init failed: ${err}`);
    }
  }

  static async saveData<T>(key: string, value: T) {
    if (!StorageUtil.pref) {
      if (StorageUtil.context) {
        await StorageUtil.init(StorageUtil.context);
      } else {
        return; 
      }
    }
    try {
      await StorageUtil.pref?.put(key, JSON.stringify(value));
      await StorageUtil.pref?.flush();
    } catch (err) {
      console.error(`StorageUtil saveData failed: ${err}`);
    }
  }

  static async getData<T>(key: string, defaultValue: T): Promise<T> {
    if (!StorageUtil.pref) {
       if (StorageUtil.context) {
          await StorageUtil.init(StorageUtil.context);
       }
    }
    try {
      const value = await StorageUtil.pref?.get(key, '');
      if (value && typeof value === 'string') {
        return JSON.parse(value) as T;
      }
    } catch (e) {
      console.error(`StorageUtil get error: ${e}`);
    }
    return defaultValue;
  }
}
