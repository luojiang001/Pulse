<script setup lang="ts">
import { ref, onMounted, nextTick, onUnmounted } from 'vue';
import { ElMessage } from 'element-plus';
import axios from 'axios';

// Interfaces
interface User {
  id: number;
  username: string;
  nickname: string;
  avatar: string;
}

interface ChatMessage {
  id: number;
  senderId: number;
  receiverId: number;
  content: string;
  createTime: string;
}

// State
const contacts = ref<User[]>([]);
const currentChatUser = ref<User | null>(null);
const messages = ref<ChatMessage[]>([]);
const inputMessage = ref('');
const scrollbarRef = ref();
const innerRef = ref();

// WebSocket
const adminId = ref<number>(0);

onMounted(() => {
  const doctorInfoStr = sessionStorage.getItem('doctorInfo');
  if (doctorInfoStr) {
    const doctorInfo = JSON.parse(doctorInfoStr);
    adminId.value = doctorInfo.token.id;
  }
  
  if (adminId.value) {
    connectWebSocket();
    fetchContacts();
  } else {
    ElMessage.error('Doctor info not found, please login again');
  }
});
  
import { BASE_URL, WS_URL } from '../../config';

// ...

let ws: WebSocket | null = null;
const baseURL = WS_URL; 
const apiBaseUrl = BASE_URL;

// Methods
const connectWebSocket = () => {
  ws = new WebSocket(`${baseURL}?userId=${adminId.value}`);
  
  ws.onopen = () => {
    console.log('WS Connected');
  };
  
  ws.onmessage = (event) => {
    const data = event.data; 
    // Format: content-senderId
    const lastDash = data.lastIndexOf('-');
    if (lastDash !== -1) {
       const content = data.substring(0, lastDash);
       const senderId = parseInt(data.substring(lastDash + 1));
       
       // If chatting with this user, add to messages
       if (currentChatUser.value && currentChatUser.value.id === senderId) {
         messages.value.push({
           id: Date.now(), 
           senderId: senderId,
           receiverId: adminId.value,
           content: content,
           createTime: new Date().toISOString()
         });
         scrollToBottom();
         // Mark as read immediately
      axios.post(`${apiBaseUrl}/chat/read?userId=${adminId.value}&otherId=${senderId}`);
    } else {
      fetchContacts(); 
      ElMessage.info(`New message from user ID: ${senderId}`);
    }
  }
};

ws.onclose = () => {
  console.log('WS Closed');
};
};

const fetchContacts = async () => {
try {
  const res = await axios.get(`${apiBaseUrl}/chat/contacts?userId=${adminId.value}`);
  if (res.data.code === 200) {
    contacts.value = res.data.data;
  }
} catch (e) {
  console.error(e);
}
};

const selectUser = async (user: User) => {
currentChatUser.value = user;
await fetchHistory(user.id);
};

const fetchHistory = async (otherId: number) => {
try {
  const res = await axios.get(`${apiBaseUrl}/chat/history?userId=${adminId.value}&otherId=${otherId}`);
  if (res.data.code === 200) {
    messages.value = res.data.data;
    scrollToBottom();
    
    // Mark as read
    axios.post(`${apiBaseUrl}/chat/read?userId=${adminId.value}&otherId=${otherId}`);
  }
} catch (e) {
  console.error(e);
}
};

const sendMessage = () => {
  if (!inputMessage.value.trim() || !currentChatUser.value) return;
  
  const content = inputMessage.value;
  const receiverId = currentChatUser.value.id;
  
  // Format: content-receiverId
  const payload = `${content}-${receiverId}`;
  
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(payload);
    
    // Add to local list
    messages.value.push({
      id: Date.now(),
      senderId: adminId.value,
      receiverId: receiverId,
      content: content,
      createTime: new Date().toISOString()
    });
    
    inputMessage.value = '';
    scrollToBottom();
  } else {
    ElMessage.error('Connection lost');
  }
};

const scrollToBottom = async () => {
  await nextTick();
  if (scrollbarRef.value) {
    scrollbarRef.value.setScrollTop(innerRef.value.clientHeight);
  }
};

const formatTime = (timeStr: string) => {
  if (!timeStr) return '';
  const date = new Date(timeStr);
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
};

onMounted(() => {
  const doctorInfoStr = sessionStorage.getItem('doctorInfo');
  if (doctorInfoStr) {
    const doctorInfo = JSON.parse(doctorInfoStr);
    adminId.value = doctorInfo.token.id;
  }
  
  if (adminId.value) {
    connectWebSocket();
    fetchContacts();
  } else {
    ElMessage.error('Doctor info not found, please login again');
  }
});

onUnmounted(() => {
  if (ws) ws.close();
});
</script>

<template>
  <div class="chat-container">
    <el-card class="chat-card" body-style="padding: 0; display: flex; height: 100%;">
      <!-- Sidebar -->
      <div class="sidebar">
         <div class="sidebar-header">Recent Contacts</div>
         <div v-if="contacts.length === 0" class="no-contacts">No contacts yet</div>
         <div 
           v-for="user in contacts" 
           :key="user.id" 
           class="contact-item"
           :class="{ active: currentChatUser?.id === user.id }"
           @click="selectUser(user)"
         >
           <el-avatar :size="40" :src="user.avatar || ''">{{ user.nickname?.charAt(0) || user.username?.charAt(0) || 'U' }}</el-avatar>
           <div class="contact-info">
             <div class="nickname">{{ user.nickname || user.username }}</div>
             <div class="uid">ID: {{ user.id }}</div>
           </div>
         </div>
      </div>
      
      <!-- Main Chat -->
      <div class="main-chat">
         <div v-if="!currentChatUser" class="empty-state">
           <p>Select a user to start chatting</p>
         </div>
         <template v-else>
           <div class="chat-header">
              Chatting with: {{ currentChatUser.nickname || currentChatUser.username }}
           </div>
           <div class="messages-area">
              <el-scrollbar ref="scrollbarRef">
                <div ref="innerRef" class="messages-inner">
                   <div 
                     v-for="msg in messages" 
                     :key="msg.id" 
                     class="message-row"
                     :class="{ 'me': msg.senderId === adminId, 'other': msg.senderId !== adminId }"
                   >
                      <div class="bubble">
                        <div class="bubble-content">{{ msg.content }}</div>
                        <div class="bubble-time">{{ formatTime(msg.createTime) }}</div>
                      </div>
                   </div>
                </div>
              </el-scrollbar>
           </div>
           <div class="input-area">
              <el-input 
                v-model="inputMessage" 
                @keyup.enter="sendMessage" 
                placeholder="Type a message..." 
                class="msg-input"
              />
              <el-button type="primary" @click="sendMessage">Send</el-button>
           </div>
         </template>
      </div>
    </el-card>
  </div>
</template>

<style scoped>
.chat-container {
  height: calc(100vh - 120px);
  padding: 10px;
  box-sizing: border-box;
}
.chat-card {
  height: 100%;
}
.sidebar {
  width: 250px;
  border-right: 1px solid #eee;
  display: flex;
  flex-direction: column;
  background: #f9f9f9;
}
.sidebar-header {
  padding: 15px;
  font-weight: bold;
  border-bottom: 1px solid #eee;
  background: #fff;
}
.contact-item {
  padding: 10px 15px;
  display: flex;
  align-items: center;
  cursor: pointer;
  transition: background 0.2s;
}
.contact-item:hover {
  background: #e6f7ff;
}
.contact-item.active {
  background: #bae7ff;
}
.contact-info {
  margin-left: 10px;
}
.nickname {
  font-weight: 500;
}
.uid {
  font-size: 12px;
  color: #999;
}
.no-contacts {
  padding: 20px;
  text-align: center;
  color: #999;
}

.main-chat {
  flex: 1;
  display: flex;
  flex-direction: column;
}
.chat-header {
  padding: 15px;
  border-bottom: 1px solid #eee;
  font-weight: bold;
  background: #fff;
}
.messages-area {
  flex: 1;
  background-color: #f5f7fa;
  overflow: hidden;
}
.messages-inner {
  padding: 20px;
}
.message-row {
  display: flex;
  margin-bottom: 15px;
}
.message-row.me {
  justify-content: flex-end;
}
.message-row.other {
  justify-content: flex-start;
}
.bubble {
  max-width: 70%;
  padding: 10px 15px;
  border-radius: 8px;
  font-size: 14px;
  line-height: 1.5;
  display: flex;
  flex-direction: column;
}
.bubble-content {
  word-break: break-word;
}
.bubble-time {
  font-size: 10px;
  opacity: 0.7;
  text-align: right;
  margin-top: 4px;
}
.me .bubble {
  background-color: #95d475;
  color: #303133;
}
.other .bubble {
  background-color: #fff;
  color: #303133;
  box-shadow: 0 1px 2px rgba(0,0,0,0.1);
}

.input-area {
  padding: 15px;
  border-top: 1px solid #eee;
  background: #fff;
  display: flex;
  gap: 10px;
}
.msg-input {
  flex: 1;
}
.empty-state {
  flex: 1;
  display: flex;
  justify-content: center;
  align-items: center;
  color: #999;
}
</style>
