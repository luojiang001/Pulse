import axios, { AxiosResponse } from '@ohos/axios';
import promptAction from '@ohos.promptAction';
import { PreferencesUtil } from '../utils/fileUtils';
import { Constants } from '../../common/Constants';
import { User } from '../data/Data';
import { common } from '@kit.AbilityKit';

interface ChatMessage {
  id: string;
  content: string;
  role: 'user' | 'ai';
  timestamp: number;
}

interface ChatSession {
  id: string;
  title: string;
  timestamp: number;
  messages: ChatMessage[];
}

interface ServerMessageVO {
  role: string;
  content: string;
  createTime: number;
}

class FetchResult {
  cid: string = '';
  data: ServerMessageVO[] = [];
}

@Component
export struct AI {
  @State userId: number = -1;
  @State chatId: string = '';
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State showHistory: boolean = false;
  @State chatHistory: ChatSession[] = [];
  private scroller: Scroller = new Scroller();
  private readonly BASE_URL: string = Constants.BASE_URL;

  aboutToAppear() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      PreferencesUtil.init(context);
    } catch (e) {
      console.error('AI context init error:', JSON.stringify(e));
    }
    this.loadUser();
  }

  async loadUser() {
    let user: User | null = null;
    if (AppStorage.Has('userData')) {
      user = AppStorage.Get<User>('userData') || null;
    }
    if (!user) {
      user = await PreferencesUtil.getUserData();
    }
    if (user) {
      this.userId = user.id;
      this.initChat();
      this.fetchServerHistory();
    } else {

      this.initChat();
    }
  }

  async fetchServerHistory() {
    if (this.userId === -1) return;
    try {
      // 1. Get list of chat IDs
      console.info(`Fetching history list for user ${this.userId} from ${this.BASE_URL}`);
      const res: AxiosResponse<string[]> = await axios.get(`${this.BASE_URL}/ai/history/${this.userId}`, { timeout: 5000 });
      console.info(`History list response status: ${res.status}, data length: ${Array.isArray(res.data) ? res.data.length : 'not array'}`);
      
      if (res.status === 200 && Array.isArray(res.data)) {
        const serverChatIds = res.data;
        const newHistory: ChatSession[] = [];


        console.info(`Starting to fetch details for ${serverChatIds.length} chats`);
        const promises: Promise<FetchResult>[] = serverChatIds.map(async (cid: string): Promise<FetchResult> => {
          try {
            const msgRes: AxiosResponse<ServerMessageVO[]> = await axios.get(`${this.BASE_URL}/ai/history/${this.userId}/${cid}`, { timeout: 5000 });
            if (msgRes.status === 200 && Array.isArray(msgRes.data)) {
              let res: FetchResult = { cid: cid, data: msgRes.data };
              return res;
            }
          } catch (err) {
            console.error(`Failed to fetch history for chat ${cid}`, JSON.stringify(err));
          }
          let res: FetchResult = { cid: cid, data: [] };
          return res;
        });

        const results = await Promise.all(promises);
        console.info(`Finished fetching details. Results count: ${results.length}`);

        for (const result of results) {
          const cid = result.cid;
          const data = result.data;
          if (data.length > 0) {
            const msgs: ChatMessage[] = data.map((vo, index): ChatMessage => {
              let roleType: 'user' | 'ai' = vo.role === 'assistant' ? 'ai' : 'user';
              let msg: ChatMessage = {
                id: `${cid}_${index}`,
                content: vo.content,
                role: roleType,
                timestamp: vo.createTime || Date.now()
              };
              return msg;
            });

            let title = '新对话';
            const firstUserMsg = msgs.find(m => m.role === 'user');
            if (firstUserMsg) {
              title = firstUserMsg.content.length > 15
                ? firstUserMsg.content.substring(0, 15) + '...'
                : firstUserMsg.content;
            } else if (msgs.length > 0) {
                title = msgs[0].content.length > 15 
                    ? msgs[0].content.substring(0, 15) + '...' 
                    : msgs[0].content;
            }

            newHistory.push({
              id: cid,
              title: title,
              timestamp: msgs.length > 0 ? msgs[msgs.length - 1].timestamp : Date.now(),
              messages: msgs
            });
          } else {
             console.info(`Skipping chat ${cid} because it has no messages`);
          }
        }

        console.info(`Parsed ${newHistory.length} valid history sessions`);
        if (newHistory.length > 0) {
          // 按时间倒序排序（最新的在前）
          newHistory.sort((a, b) => b.timestamp - a.timestamp);

          this.chatHistory = newHistory;
          
          // 如果当前会话存在于新的历史记录中，即使更新当前显示的消息
          const currentSession = this.chatHistory.find(s => s.id === this.chatId);
          if (currentSession) {
            this.messages = currentSession.messages;
            this.scrollToBottom();
          }
        }
      }
    } catch (e) {
      console.error('Fetch history failed', JSON.stringify(e));
    }
  }

  initChat() {
    let id = AppStorage.Get<string>('ai_chat_id');
    if (!id) {
      id = this.generateId();
      AppStorage.SetOrCreate('ai_chat_id', id);
    }
    this.chatId = id;


    const session = this.chatHistory.find(s => s.id === id);
    if (session) {
      this.messages = session.messages;
    } else if (this.messages.length === 0) {
      this.messages.push({
        id: 'init',
        content: '你好！我是你的健康助手，有什么可以帮你的吗？',
        role: 'ai',
        timestamp: Date.now()
      });

    }
  }

  generateId(): string {
    return Math.random().toString(36).substring(2, 15);
  }

  saveSession() {
    let title = '新对话';
    const firstUserMsg = this.messages.find(m => m.role === 'user');
    if (firstUserMsg) {
      title = firstUserMsg.content.length > 15
        ? firstUserMsg.content.substring(0, 15) + '...'
        : firstUserMsg.content;
    }

    const session: ChatSession = {
      id: this.chatId,
      title: title,
      timestamp: Date.now(),
      messages: this.messages
    };

    const index = this.chatHistory.findIndex(s => s.id === this.chatId);
    if (index > -1) {
      this.chatHistory.splice(index, 1);
    }
    this.chatHistory.unshift(session);

    this.chatHistory = [...this.chatHistory];
  }

  startNewChat() {
    const newId = this.generateId();
    this.chatId = newId;
    AppStorage.SetOrCreate('ai_chat_id', newId);
    this.messages = [];
    this.messages.push({
      id: 'init',
      content: '你好！我是你的健康助手，有什么可以帮你的吗？',
      role: 'ai',
      timestamp: Date.now()
    });

    this.showHistory = false;
    promptAction.showToast({ message: '已开启新对话' });
  }

  async switchSession(session: ChatSession) {
    this.chatId = session.id;
    AppStorage.SetOrCreate('ai_chat_id', session.id);
    this.showHistory = false;
    const msgs = await this.fetchSessionMessages(session.id);
    if (msgs.length > 0) {
      this.messages = msgs;
      const index = this.chatHistory.findIndex(s => s.id === session.id);
      if (index > -1) {
        this.chatHistory[index] = {
          id: session.id,
          title: session.title,
          timestamp: session.timestamp,
          messages: msgs
        };
        this.chatHistory = [...this.chatHistory];
      }
    } else {
      this.messages = session.messages;
    }
    this.scrollToBottom();
  }

  deleteSession(id: string) {
    const index = this.chatHistory.findIndex(s => s.id === id);
    if (index > -1) {
      this.chatHistory.splice(index, 1);
      this.chatHistory = [...this.chatHistory];

      if (this.chatId === id) {
        if (this.chatHistory.length > 0) {
          this.switchSession(this.chatHistory[0]);
        } else {
          this.startNewChat();
        }
      }
    }
  }

  async fetchSessionMessages(cid: string): Promise<ChatMessage[]> {
    if (this.userId === -1) return [];
    try {
      const msgRes: AxiosResponse<ServerMessageVO[]> = await axios.get(`${this.BASE_URL}/ai/history/${this.userId}/${cid}`);
      if (msgRes.status === 200 && Array.isArray(msgRes.data)) {
        const vos = msgRes.data;
        return vos.map((vo, index): ChatMessage => ({
          id: `${cid}_${index}`,
          content: vo.content,
          role: vo.role === 'assistant' ? 'ai' : 'user',
          timestamp: Date.now()
        }));
      }
    } catch (err) {
      console.error(`Fetch session messages failed: ${cid}`, JSON.stringify(err));
    }
    return [];
  }

  clearHistory() {
    this.messages = [];
    promptAction.showToast({ message: '已清空记录' });
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 标题栏
        Column() {
          Row() {
            Button('历史')
              .fontSize(12)
              .height(28)
              .backgroundColor('#67C23A')
              .margin({ right: 10 })
              .onClick(() => {
                this.showHistory = !this.showHistory;
                if (this.showHistory) {
                   this.fetchServerHistory();
                }
              })

            Text('AI 健康助手')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')

            Blank()

            Text(`ID: ${this.chatId}`)
              .fontSize(12)
              .fontColor('#999')
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            Button('新建对话')
              .fontSize(12)
              .height(28)
              .backgroundColor('#409EFF')
              .margin({ right: 10 })
              .onClick(() => this.startNewChat())

            Button('清空记录')
              .fontSize(12)
              .height(28)
              .backgroundColor('#909399')
              .onClick(() => this.clearHistory())
          }
          .width('100%')
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#fff')
        .shadow({ radius: 2, color: '#eee', offsetY: 1 })
        .zIndex(1)

        // 聊天列表
        List({ scroller: this.scroller }) {
          ForEach(this.messages, (msg: ChatMessage) => {
            ListItem() {
              this.MessageBubble(msg)
            }
          })
        }
        .layoutWeight(1)
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')

        // 输入区域
        Row() {
          TextInput({ text: this.inputText, placeholder: '请输入您的问题...' })
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#fff')
            .borderRadius(20)
            .padding({ left: 15, right: 15 })
            .onChange((value) => {
              this.inputText = value;
            })
            .onSubmit(() => {
              this.sendMessage();
            })

          Button('发送')
            .height(40)
            .width(70)
            .margin({ left: 10 })
            .borderRadius(20)
            .backgroundColor(this.inputText.trim() && !this.isLoading ? '#FE6E04' : '#ccc')
            .enabled(!!this.inputText.trim() && !this.isLoading)
            .onClick(() => {
              this.sendMessage();
            })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 20 })
        .backgroundColor('#fff')
        .alignItems(VerticalAlign.Center)
      }
      .height('100%')
      .width('100%')


      if (this.showHistory) {
        Column() {
          Row() {
            Text('历史会话')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
            Blank()
            Button('关闭')
              .fontSize(12)
              .backgroundColor('transparent')
              .fontColor('#999')
              .onClick(() => this.showHistory = false)
          }
          .width('100%')
          .padding(15)
          .border({ width: { bottom: 1 }, color: '#eee' })

          List() {
            ForEach(this.chatHistory, (session: ChatSession) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(session.title || '新对话')
                      .fontSize(14)
                      .fontColor(this.chatId === session.id ? '#409EFF' : '#333')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(new Date(session.timestamp).toLocaleString())
                      .fontSize(10)
                      .fontColor('#999')
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Button('删除')
                    .fontSize(10)
                    .backgroundColor('#F56C6C')
                    .height(24)
                    .onClick(() => this.deleteSession(session.id))
                }
                .width('100%')
                .padding(15)
                .backgroundColor(this.chatId === session.id ? '#ecf5ff' : '#fff')
                .onClick(() => this.switchSession(session))
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('70%')
        .height('100%')
        .backgroundColor('#fff')
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetX: 2 })
        .transition({ type: TransitionType.Insert, translate: { x: -200, y: 0 } })
        .transition({ type: TransitionType.Delete, translate: { x: -200, y: 0 } })


        Column()
          .width('30%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.3)')
          .onClick(() => this.showHistory = false)
          .margin({ left: '70%' })
      }
    }
    .height('100%')
    .width('100%')
  }

  @Builder MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.role === 'ai') {
        Image($rawfile('Pulse/Common/foreground.png'))
          .width(40)
          .height(40)
          .borderRadius(20)
          .margin({ right: 10 })
          .backgroundColor('#eee')
      }

      Text(msg.content)
        .fontSize(16)
        .fontColor(msg.role === 'user' ? '#fff' : '#333')
        .backgroundColor(msg.role === 'user' ? '#FE6E04' : '#fff')
        .padding(12)
        .borderRadius(10)
        .constraintSize({ maxWidth: '70%' })

      if (msg.role === 'user') {
        Image($rawfile('Pulse/Common/foreground.png'))
          .width(40)
          .height(40)
          .borderRadius(20)
          .margin({ left: 10 })
          .backgroundColor('#eee')
      }
    }
    .width('100%')
    .justifyContent(msg.role === 'user' ? FlexAlign.End : FlexAlign.Start)
    .padding({ top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Top)
  }

  async sendMessage() {
    if (!this.inputText.trim() || this.isLoading) return;

    const userMsgContent = this.inputText.trim();
    this.inputText = '';

    // 添加用户消息
    const userMsg: ChatMessage = {
      id: Date.now().toString(),
      content: userMsgContent,
      role: 'user',
      timestamp: Date.now()
    };
    this.messages.push(userMsg);
    this.saveSession();
    this.scrollToBottom();

    // 准备 AI 消息占位符
    this.isLoading = true;
    const aiMsgId = (Date.now() + 1).toString();
    const aiMsg: ChatMessage = {
      id: aiMsgId,
      content: 'Thinking...',
      role: 'ai',
      timestamp: Date.now()
    };
    this.messages.push(aiMsg);
    this.scrollToBottom();

    try {
      const res: AxiosResponse<string | Object> = await axios.get(`${this.BASE_URL}/ai/service`, {
        params: {
          prompt: userMsgContent,
          chatId: this.chatId,
          userId: this.userId
        },
        timeout: 60000
      });

      if (res.status === 200) {
        let content: string | Object = res.data;
        let msgContent: string = '';
        if (typeof content === 'string') {
          msgContent = content;
        } else {
          msgContent = JSON.stringify(content);
        }
        this.updateAiMessage(aiMsgId, msgContent);
      } else {
        this.updateAiMessage(aiMsgId, '抱歉，AI 服务暂时不可用。');
      }
    } catch (err) {
      console.error('AI Request Error:', JSON.stringify(err));
      this.updateAiMessage(aiMsgId, '网络连接异常，请检查网络设置。');
    } finally {
      this.isLoading = false;
      this.saveSession();
      this.scrollToBottom();
    }
  }

  updateAiMessage(id: string, newContent: string) {
    const index = this.messages.findIndex(m => m.id === id);
    if (index !== -1) {
      const oldMsg = this.messages[index];
      // 替换对象以触发 UI 更新
      this.messages[index] = {
        id: oldMsg.id,
        content: newContent,
        role: oldMsg.role,
        timestamp: oldMsg.timestamp
      };
    }
  }

  scrollToBottom() {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);
  }
}
