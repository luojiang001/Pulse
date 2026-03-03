
import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { User } from '../../data/Data';
import { PreferencesUtil } from '../../utils/fileUtils';
import { Constants } from '../../../common/Constants';
import router from '@ohos.router';
import axios, { AxiosResponse } from '@ohos/axios';

interface ChatMessage {
  id: number;
  senderId: number;
  receiverId: number;
  content: string;
  createTime: string;
}

@Entry
@Component
struct Chat {
  @State messages: ChatMessage[] = [];
  @State inputMessage: string = '';
  @State currentUser: User | null = null;
  @State isConnected: boolean = false;
  
  // Config
  private baseUrl: string = Constants.BASE_URL;
  private wsUrl: string = `${Constants.WS_URL}/ws/echo`;
  
  ws = webSocket.createWebSocket();
  controller: TextInputController = new TextInputController();
  private scroller: Scroller = new Scroller()
  
  @State receiveUser: User = {
    id: 1,
    username: 'admin',
    password: '',
    nickname: '在线客服',
    avatar: '', 
    gender: 0,
    birth: '',
    intro: '',
    phone: '',
    cratedAt: new Date()
  } as User;

  async aboutToAppear(): Promise<void> {
    try {
      console.info('Chat aboutToAppear started');
      // Get current user
      try {
        this.currentUser = await PreferencesUtil.getUserData();
        console.info('Chat fetched currentUser:', JSON.stringify(this.currentUser));
      } catch (e) {
        console.error('PreferencesUtil.getUserData failed:', JSON.stringify(e));
        return;
      }

      if (!this.currentUser) {
         console.error('User not logged in or PreferencesUtil context missing');
         return;
      }
  
      let params: Record<string, User> | undefined;
      try {
        params = router.getParams() as Record<string, User>;
      } catch (e) {
        console.error('router.getParams() failed:', JSON.stringify(e));
      }

      if (params && params['user']) {
        this.receiveUser = params['user'];
        console.info('Chat receiveUser from params:', JSON.stringify(this.receiveUser));
      } else {
        console.info('Chat receiveUser using default (admin)');
      }
      
      this.connectWebSocket();
      await this.fetchHistory();
    } catch (err) {
      console.error('Chat aboutToAppear error:', JSON.stringify(err));
    }
  }
  
  async fetchHistory() {
    if (!this.currentUser) return;
    try {
      const res: AxiosResponse = await axios.get(`${this.baseUrl}/chat/history`, {
        params: {
          userId: this.currentUser.id,
          otherId: this.receiveUser.id
        }
      });
      if (res.status === 200 && res.data.code === 200) {
        this.messages = res.data.data as ChatMessage[];
        setTimeout(() => {
          this.scroller.scrollTo({ yOffset: Number.MAX_SAFE_INTEGER, xOffset: 0 })
        }, 100)
        
        // Mark as read
        axios.post(`${this.baseUrl}/chat/read`, null, {
          params: {
            userId: this.currentUser.id,
            otherId: this.receiveUser.id
          }
        });
      }
    } catch (e) {
      console.error('Fetch history failed:', JSON.stringify(e));
    }
  }

  onDisappear() {
    this.closeWebSocket();
  }


  connectWebSocket() {
    this.ws.on('open', (err: BusinessError, value: Object) => {
      if (!err) {
        console.log('连接成功')
        this.isConnected = true;
      } else {
        console.log('连接失败: ' + JSON.stringify(err))
        this.isConnected = false;
      }
    });

    this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      if (!err && typeof value === 'string') {
        // Backend sends: content-senderId
        const lastDash = value.lastIndexOf('-');
        if (lastDash !== -1) {
             const content = value.substring(0, lastDash);
             const senderId = Number(value.substring(lastDash + 1));
             
             // If message is from current chat user
             if (senderId === this.receiveUser.id) {
                this.addMessage({
                  id: 0,
                  senderId: senderId,
                  receiverId: this.currentUser?.id || 0,
                  content: content,
                  createTime: new Date().toISOString(),
                })
                setTimeout(() => {
                  this.scroller.scrollTo({ yOffset: Number.MAX_SAFE_INTEGER, xOffset: 0 })
                }, 100)
             }
        }
      } else {
        console.log('接收消息错误'+ JSON.stringify(err))
      }
    });

    this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
      this.isConnected = false;
      if (!err) {
        console.log("连接关闭")
      } else {
        console.log("关闭连接错误")
      }
    });

    this.ws.on('error', (err: BusinessError) => {
      this.isConnected = false;
      console.log('WebSocket 错误: ' + JSON.stringify(err))
    });

    const url = `${this.wsUrl}?userId=${this.currentUser?.id}`;
    console.log('Attempting to connect to: ' + url);
    this.ws.connect(url, (err: BusinessError, value: boolean) => {
      if (err) {
        console.log('无法连接到服务器: ' + JSON.stringify(err))
      }
    });
  }

  closeWebSocket() {
    if (this.ws) {
      this.ws.close((err: BusinessError, value: boolean) => {
        if (!err) {
          console.log('WebSocket 已关闭')

        } else {
          console.log('关闭 WebSocket 失败')
        }
      });
    }
  }

  // 发送消息
  sendMessage() {
    if (this.inputMessage.trim() === '') {
      AlertDialog.show({message:'请输入消息'})
      return;
    }

    if (!this.isConnected) {
       AlertDialog.show({message:'连接已断开，正在重连...'})
       this.connectWebSocket();
       return;
    }

    // Format: content-receiverId
    const message = this.inputMessage + '-' + this.receiveUser.id;
    const content = this.inputMessage;
    
    this.inputMessage = ''; // 清空输入框
    
    this.ws.send(message, (err: BusinessError, value: boolean) => {
      if (!err) {
        this.addMessage({
          id: 0,
          senderId: this.currentUser?.id || 0,
          receiverId: Number(this.receiveUser.id),
          content: content,
          createTime: new Date().toISOString(),
        })
      } else {
        console.log('消息发送失败:' + JSON.stringify(err))
        // Restore input message if failed
        this.inputMessage = content;
        AlertDialog.show({message:'消息发送失败，请重试'})
      }
    });
  }

  // 添加消息到列表
  addMessage(msg: ChatMessage) {
    this.messages = [...this.messages, msg];
  }

  build() {
    Column(){
      Row(){
        Column(){
          Image("http://47.101.196.181:9000/department-grid/return.png").width(30).height(30)
        }.width("15%")
        .onClick(() => {
          router.back()
        })
        Row({space:10}){
          Image(this.receiveUser.avatar || $r('app.media.kefu')).width(40).height(40).borderRadius("50%")
          Text(this.receiveUser.nickname || this.receiveUser.username).fontSize(16).fontWeight('bold')
        }
      }.width('98%').height("10%")
      Column() {
        List({scroller:this.scroller,space:15}){
          ForEach(this.messages, (item: ChatMessage) => {
            ListItem(){
              if(item.senderId == this.currentUser?.id){
                Row({space:10}){
                  Text(item.content).width('70%').textOverflow({overflow: TextOverflow.Ellipsis}).backgroundColor("#3896FC").borderRadius(10).padding(15).fontColor(Color.White).fontWeight('bold')
                  Image(this.currentUser?.avatar).width(40).height(40).borderRadius('50%')
                }.width('100%').align(Alignment.End).margin({left:"16%"})
              }else {
                Row({space:10}){
                  Image(this.receiveUser.avatar || $r('app.media.kefu')).width(40).height(40).borderRadius('50%')
                  Text(item.content).width('70%').textOverflow({overflow: TextOverflow.Ellipsis}).backgroundColor(Color.White).borderRadius(10).padding(15).fontColor(Color.Black).fontWeight('bold')
                }.width('100%').align(Alignment.Start)
              }
            }.width('100%')
          })
        }
        .width('100%')
        .height('90%')
        .scrollBar(BarState.Off)
        Row() {
          TextInput({
            placeholder:"输入消息",
            controller:this.controller,
            text:this.inputMessage
          })
            .onChange((value) => {
              this.inputMessage = value;
            })
            .width('70%')
            .height(40);
          Button("发送")
            .onClick(() => {
              if (this.inputMessage.trim()) {
                this.sendMessage();
                setTimeout(()=>{
                  this.scroller.scrollTo({yOffset:Number.MAX_SAFE_INTEGER,xOffset:0})
                }, 100)
              }
            })
            .width('20%')
            .margin({ left: 10 });
        }
        .width('100%')
        .height("10%")
      }.width('98%').justifyContent(FlexAlign.Center).height('90%').backgroundColor("#f3f3f3")
    }.width('100%').height('100%')
  }
}
