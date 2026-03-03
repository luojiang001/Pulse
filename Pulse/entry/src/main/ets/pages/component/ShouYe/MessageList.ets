import router from '@ohos.router';
import axios, { AxiosResponse } from '@ohos/axios';
import { Constants } from '../../../common/Constants';
import { PreferencesUtil } from '../../utils/fileUtils';
import { User } from '../../data/Data';

interface ConversationVO {
    userId: number;
    username: string;
    nickname: string;
    avatar: string;
    lastMessage: string;
    lastTime: string;
    unreadCount: number;
}

@Entry
@Component
struct MessageList {
    @State conversations: ConversationVO[] = [];
    @State isLoading: boolean = false;
    private readonly BASE_URL: string = Constants.BASE_URL;

    onPageShow() {
        console.info('MessageList onPageShow triggered');
        this.fetchConversations();
    }

    async fetchConversations() {
        this.isLoading = true;
        try {
            const user = await PreferencesUtil.getUserData();
            console.info('MessageList fetchConversations user:', JSON.stringify(user));
            if (user) {
                const url = `${this.BASE_URL}/chat/conversations`;
                console.info('MessageList requesting:', url, 'userId:', user.id);
                const response: AxiosResponse = await axios.get(url, {
                    params: { userId: user.id }
                });
                console.info('MessageList response:', JSON.stringify(response.data));
                if (response.status === 200 && response.data.code === 200) {
                    this.conversations = response.data.data;
                    console.info('MessageList conversations set:', this.conversations.length);
                }
            } else {
                console.warn('MessageList: User not logged in');
            }
        } catch (error) {
            console.error('Fetch conversations failed:', JSON.stringify(error));
        } finally {
            this.isLoading = false;
        }
    }

    build() {
        Column() {
            // Header
            Row() {
                Text('<') 
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .margin({ right: 16 })
                    .onClick(() => router.back())
                Text('消息列表')
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .border({ width: { bottom: 1 }, color: '#f5f5f5' })

            if (this.isLoading) {
                Column() {
                    Text('加载中...').fontSize(16).fontColor('#999')
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
            } else if (this.conversations.length === 0) {
                 Column() {
                    Text('暂无消息')
                       .fontSize(16)
                       .fontColor('#999')
                 }
                 .width('100%')
                 .height('100%')
                 .justifyContent(FlexAlign.Center)
            } else {
                List() {
                    ForEach(this.conversations, (item: ConversationVO) => {
                        ListItem() {
                            Row() {
                                Stack({ alignContent: Alignment.TopEnd }) {
                                    Image(item.avatar || $r('app.media.logo')) // Use logo as default
                                        .width(50)
                                        .height(50)
                                        .borderRadius(25)
                                    
                                    if (item.unreadCount > 0) {
                                        Text(item.unreadCount > 99 ? '99+' : item.unreadCount.toString())
                                            .fontSize(10)
                                            .fontColor(Color.White)
                                            .backgroundColor('#FF4D4F')
                                            .borderRadius(10)
                                            .padding({ left: 5, right: 5 })
                                            .height(16)
                                            .textAlign(TextAlign.Center)
                                            .margin({ top: 0, right: 0 })
                                    }
                                }
                                .width(55)
                                .height(55)
                                .margin({ right: 12 })

                                Column() {
                                    Row() {
                                        Text(item.nickname || item.username)
                                            .fontSize(16)
                                            .fontWeight(FontWeight.Medium)
                                            .fontColor('#333')
                                        Blank()
                                        Text(this.formatTime(item.lastTime))
                                            .fontSize(12)
                                            .fontColor('#999')
                                    }
                                    .width('100%')
                                    .margin({ bottom: 4 })

                                    Text(item.lastMessage)
                                        .fontSize(14)
                                        .fontColor('#666')
                                        .maxLines(1)
                                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                                        .width('100%')
                                }
                                .layoutWeight(1)
                            }
                            .width('100%')
                            .padding({ top: 12, bottom: 12, left: 16, right: 16 })
                            .backgroundColor(Color.White)
                            .onClick(() => {
                                const targetUser: User = {
                                    id: item.userId,
                                    username: item.username,
                                    nickname: item.nickname,
                                    avatar: item.avatar,
                                    // other fields dummy
                                    password: '', phone: '', gender: 0, birth: '', intro: '', cratedAt: new Date()
                                };
                                router.pushUrl({
                                    url: 'pages/component/ShouYe/Chat',
                                    params: { user: targetUser }
                                })
                            })
                        }
                    })
                }
                .width('100%')
                .layoutWeight(1)
                .divider({ strokeWidth: 1, color: '#f5f5f5', startMargin: 70, endMargin: 0 })
            }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
    }

    formatTime(timeStr: string): string {
        if (!timeStr) return '';
        const date = new Date(timeStr);
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const day = date.getDate().toString().padStart(2, '0');
        return `${year}-${month}-${day}`;
    }
}
