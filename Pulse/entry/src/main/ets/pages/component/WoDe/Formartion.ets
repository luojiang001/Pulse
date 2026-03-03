import { FormGroup, FormType, ObservedInfoItem, PersonalInfoView } from 'collect_personal_info'
import { PreferencesUtil } from '../../utils/fileUtils'
import { User } from '../../data/Data'
import promptAction from '@ohos.promptAction'
import { common } from '@kit.AbilityKit'
import router from '@ohos.router'
import axios, { AxiosResponse } from '@ohos/axios'
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { Constants } from '../../../common/Constants';

@Entry
@ComponentV2
export struct PersonalSettings {
  @Local currentUser: User | null = null
  build() {
    Column() {
      Row() {
        Image("http://47.101.196.181:9000/department-grid/return.png")
          .width(24)
          .height(24)
          .onClick(() => router.back())
          .margin({ right: 10 });
        Text('个人信息设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
      .zIndex(1)

      PersonalInfoView({
        list: this.list,
        themeColor: $r('sys.color.multi_color_07'),
      })
      .layoutWeight(1)

      Button('保存')
        .width('80%')
        .margin({ top: 16, bottom: 16 })
        .onClick(async () => {
          await this.saveProfile()
        })
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Local avatarItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.CHOOSE_AVATAR,
    label: '头像',
    value: 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/news-hnp2d/avatar%2Favatar_12.jpg',
    onChange: async (param?: Object) => {
      console.info('Avatar onChange param:', JSON.stringify(param));
      // param is now Base64 string from ChooseAvatar -> ImageCropDialog
      let v = param as string;
      this.avatarItem.value = v;
      // Do NOT upload immediately. Just update the UI state.
      // Upload happens in saveProfile.
    },
  });
  @Local nickNameItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.TEXT_INPUT,
    label: '姓名',
    value: '咚咚锵锵',
    minLength: 2,
    maxLength: 10,
    placeholderText: '姓名',
    invocation: (param: Object) => {
      return Promise.resolve();
    },
    validMessageText: '内容为空，请输入后保存',
    onChange: (param?: Object) => {
      this.nickNameItem.value = param as string;
    },
  })
  @Local genderItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.DROP_SELECT,
    label: '性别',
    selectOptions: [
      {
        id: 0,
        value: 0,
        label: '男',
      },
      {
        id: 1,
        value: 1,
        label: '女',
      },
      {
        id: 2,
        value: 2,
        label: '保密',
      },
    ],
    value: 2,
    onChange: (param?: Object) => {
      this.genderItem.value = param as number;
    },
  });
  @Local birthItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.DATE_SELECT,
    label: '出生日期',
    onChange: (param?: Object) => {
      this.birthItem.value = param as Date;
    },
  });
  // @Local phoneItem: ObservedInfoItem = new ObservedInfoItem({
  //   type: FormType.PHONE_INPUT,
  //   label: '手机号码',
  //   value: '10000001111',
  //   phoneInfo: {
  //     codeLength: 6,
  //     sendCode: (phone: string) => {
  //       return new Promise((resolve, reject) => {
  //         setTimeout(() => {
  //           resolve()
  //         }, 1000)
  //       })
  //     },
  //     verifyCode: (phone: string, code: string) => {
  //       return new Promise((resolve, reject) => {
  //         setTimeout(() => {
  //           resolve()
  //         }, 1000)
  //       })
  //     },
  //   },
  //   onChange: (param?: Object) => {
  //     this.phoneItem.value = param as string;
  //   },
  // })
  @Local introItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.TEXTAREA,
    maxLength: 50,
    label: '个人简介',
    placeholderText: '简单介绍一下自己吧~~',
    showValue: false,
    onChange: (param?: Object) => {
      this.introItem.value = param as string;
    },
  });
  
  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext
    PreferencesUtil.init(context)
    let user = await PreferencesUtil.getUserData()
    if (user) {
      // Fetch fresh user data from backend
      try {
        const freshUser = await getUserInfo(user.id)
        if (freshUser) {
          // Merge fresh data into user object
          user.intro = freshUser.intro
          user.gender = freshUser.gender
          user.birth = freshUser.birth
          user.nickname = freshUser.nickname
          user.avatar = freshUser.avatar
          // Update local storage
          await PreferencesUtil.saveUserData(user)
        }
      } catch (e) {
        console.error('Failed to fetch fresh user info:', JSON.stringify(e))
      }

      this.currentUser = user
      this.avatarItem.value = user.avatar
      this.nickNameItem.value = user.nickname || user.username
      this.introItem.value = user.intro || ''
      if (user.gender !== undefined) this.genderItem.value = user.gender
      if (user.birth) this.birthItem.value = typeof user.birth === 'string' ? new Date(user.birth) : user.birth
      // this.phoneItem.value = user.phone
    }
  }
  
  async saveProfile() {
    const payload = new ProfileUpdateRequest()
    payload.nickname = this.nickNameItem.value as string
    // payload.phone = this.phoneItem.value as string
    payload.gender = this.genderItem.value as number
    
    // Convert Date to string to avoid serialization issues
    const birthValue = this.birthItem.value;
    if (birthValue instanceof Date) {
      payload.birth = birthValue.toISOString();
    } else if (typeof birthValue === 'string') {
      payload.birth = birthValue;
    }
    
    payload.intro = this.introItem.value as string
    
    if (this.currentUser) {
      payload.userId = this.currentUser.id
    }

    console.info('Saving profile payload:', JSON.stringify(payload));

    let currentAvatarValue = this.avatarItem.value as string;
    let isBase64 = isDataUrl(currentAvatarValue);

    try {
      // 1. If avatar is Base64, upload it first
      if (isBase64) {
         console.info('Uploading Base64 avatar before saving profile...');
         const avReq = new AvatarUploadBase64Request();
         if (this.currentUser) {
           avReq.userId = this.currentUser.id;
         }
         avReq.avatarBase64 = currentAvatarValue;
         await updateUserAvatarBase64(avReq);
         // Do NOT set payload.avatar to Base64 string to avoid DB column overflow or error
         // The avatar is already updated in DB by uploadAvatarBase64
      } else {
         payload.avatar = currentAvatarValue;
      }

      // 2. Update other profile info
      await updateUserProfile(payload)
      
      // 3. Save to local preferences (use Base64 for immediate preview if updated)
      if (this.currentUser) {
        const updated: User = {
          id: this.currentUser.id,
          username: this.currentUser.username,
          password: this.currentUser.password,
          nickname: payload.nickname,
          avatar: isBase64 ? currentAvatarValue : (payload.avatar || this.currentUser.avatar),
          phone: this.currentUser.phone,
          intro: payload.intro,
          cratedAt: this.currentUser.cratedAt
        }
        await PreferencesUtil.saveUserData(updated)
        AppStorage.setOrCreate('userData', updated)
      }
      promptAction.showToast({ message: '已保存' })
      router.back()
    } catch (e) {
      console.error('Save profile failed details:', JSON.stringify(e));

      if (e.response) {

         console.error('Server response:', JSON.stringify(e.response.data));

         console.error('Server status:', e.response.status);
      }

      promptAction.showToast({ message: '保存失败: ' + (e.message || '未知错误') })
    }
  }
  @Local list: FormGroup[] = [
    {
      list: [this.avatarItem],
    },
    {
      list: [
        this.nickNameItem,
        this.genderItem,
        this.birthItem,
        // this.phoneItem,
      ],
    },
    {
      list: [
        this.introItem,
      ],
    },
  ];
}
export class ProfileUpdateRequest {
  nickname: string = ''
  phone: string = ''
  gender: number = 0
  userId: number = 0
  birth?: Date | string
  intro?: string
  avatar?: string
}
export function updateUserProfile(req: ProfileUpdateRequest): Promise<boolean> {
  return new Promise<boolean>((resolve, reject) => {
    axios.post(`${Constants.BASE_URL}/user/updateProfile`, req)
      .then((res: AxiosResponse) => {
        if (res.status === 200) {
          resolve(true)
        } else {
          reject(new Error('bad status'))
        }
      })
      .catch((err: Error) => reject(err))
  })
}
export function updateUserAvatar(userId: number, url: string): Promise<boolean> {
  return new Promise<boolean>((resolve, reject) => {
    const req = new AvatarUpdateRequest()
    req.userId = userId
    req.avatar = url
    axios.post(`${Constants.BASE_URL}/user/updateAvatar`, req)
      .then((res: AxiosResponse) => {
        if (res.status === 200) {
          resolve(true)
        } else {
          reject(new Error('bad status'))
        }
      })
      .catch((err: Error) => reject(err))
  })
}
export class AvatarUpdateRequest {
  userId: number = 0
  avatar: string = ''
}

export function updateUserAvatarBase64(req: AvatarUploadBase64Request): Promise<boolean> {
  return new Promise<boolean>((resolve, reject) => {
    axios.post(`${Constants.BASE_URL}/user/uploadAvatarBase64`, req)
      .then((res: AxiosResponse) => {
        if (res.status === 200) {
          resolve(true)
        } else {
          reject(new Error('bad status'))
        }
      })
      .catch((err: Error) => reject(err))
  })
}
export class AvatarUploadBase64Request {
  userId: number = 0
  avatarBase64: string = ''
}

function isDataUrl(value: string): boolean {
  const prefix = 'data:image/';
  return typeof value === 'string' && value.indexOf(prefix) === 0;
}

export function getUserInfo(userId: number): Promise<User> {
  return new Promise<User>((resolve, reject) => {
    axios.get(`${Constants.BASE_URL}/user/${userId}`)
      .then((res: AxiosResponse) => {
        if (res.status === 200 && res.data.code === 200) {
          resolve(res.data.data)
        } else {
          reject(new Error(res.data.msg || 'Fetch failed'))
        }
      })
      .catch((err: Error) => reject(err))
  })
}
