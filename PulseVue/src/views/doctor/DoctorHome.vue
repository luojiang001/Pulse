<script setup lang="ts">
import router from "@/router";
import {ArrowRightBold, HomeFilled, Bell} from "@element-plus/icons-vue";
import {onMounted, ref} from "vue";

const handleLogout = () => {
  router.push('/');
  sessionStorage.removeItem('doctorInfo');
};
const activeMenu = ref<string>('work');

const handleMenuClick = (menuKey: string) => {
  activeMenu.value = menuKey;
  router.push(`/doctor/${menuKey}`);
};
const doctorList = [
  { key: 'work', icon: HomeFilled, title: '叫号工作台', path: '/doctor/work' },
  { key: 'schedule', icon: HomeFilled, title: '我的排班', path: '/doctor/schedule' },
  { key: 'record', icon: HomeFilled, title: '挂号记录', path: '/doctor/record' },
  { key: 'chat', icon: HomeFilled, title: '对话', path: '/doctor/chat' },
  { key: 'personal', icon: HomeFilled, title: '个人信息', path: '/doctor/personal' },

];
onMounted(() => {
  const currentPath = router.currentRoute.value.path;
  if (currentPath.startsWith('/doctor') && 
      !['/doctor/work', '/doctor/schedule', '/doctor/record', '/doctor/personal'].some(path => currentPath.includes(path))) {
    router.push('/doctor/work');
  }
  const login=sessionStorage.getItem('doctorInfo')
  if (login){
    const userInfo = JSON.parse(login);
    doctor.value.username=userInfo.username
    doctor.value.data=userInfo.token
  }

  loadAnnouncement();
});
const doctor=ref({
  username:'默认用户',
  data:{}
})
const announcement = ref<{ show: boolean; title: string; content: string }>({
  show: false,
  title: '',
  content: ''
});
const annVisible = ref(false);
const loadAnnouncement = () => {
  try {
    const s = localStorage.getItem('systemAnnouncement');
    if (s) {
      const ann = JSON.parse(s);
      announcement.value = {
        show: !!ann.show,
        title: ann.title || '',
        content: ann.content || ''
      };
    }
  } catch {}
};
</script>

<template>
  <div class="body">
    <el-dialog v-model="annVisible" title="系统公告" width="480px" append-to-body>
      <div style="font-weight:600; margin-bottom:6px;">{{ announcement.title || '暂无公告' }}</div>
      <div style="white-space: pre-wrap; color:#666;">{{ announcement.content || '管理员未发布公告' }}</div>
      <template #footer>
        <el-button type="primary" @click="annVisible = false">我知道了</el-button>
      </template>
    </el-dialog>
    <div class="common-layout">
      <el-container style="gap: 0;">
        <el-header class="top">
          <div class="title">
            <el-icon :size="30" color="#4B90E0" class="icon"><HomeFilled /></el-icon>
            <span>智慧医院后台管理系统</span>
          </div>
          <div class="top-right">
            <div class="notify" :class="{ active: announcement.show }" @click="annVisible = true" title="系统公告">
              <el-icon :size="20"><Bell /></el-icon>
              <span v-if="announcement.show" class="dot"></span>
            </div>
            <div class="user-info">
              <span class="s1">{{ doctor.username.substring(0, 1) }}</span>
              <span> {{ doctor.username }} (医生)</span>
            </div>
            <div class="logout" @click="handleLogout">
              <el-icon :size="20" color="#666"><ArrowRightBold /></el-icon>
            </div>
          </div>
        </el-header>
        <el-container style="gap: 0;">
          <el-aside class="aside">

            <div
                v-for="item in doctorList"
                :key="item.key"
                class="menu-item"
                :class="{ active: activeMenu === item.key }"
                @click="handleMenuClick(item.key)"
            >
              <el-icon :size="25" class="icon">
                <component :is="item.icon" /> <!-- 动态渲染图标（优化） -->
              </el-icon>
              <span>{{ item.title }}</span>
            </div>

          </el-aside>
          <el-main class="main-content">
            <Transition name="page-fade" mode="out-in">
              <router-view></router-view>
            </Transition>
          </el-main>
        </el-container>
      </el-container>
    </div>
  </div>
</template>

<style scoped>
.body{
  width: 100%;
  height: 100vh;
  background-color: #F2F5F8;
  margin: 0;
  padding: 0;
}
.top {
  height: 60px;
  width: 100%;
  line-height: 60px;
  background-color: #FBFCFD;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;
  z-index: 10;
  box-shadow: 0 5px 10px -2px rgba(0, 0, 0, 0.1);
}
.top-right{
  min-width: 240px;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 20px;
}
.user-info{
  display: flex;
  align-items: center;
}
.user-info .s1{
  width: 30px;
  height: 30px;
  line-height: 30px;
  text-align: center;
  border-radius: 50%;
  background-color: #E8F4F8;
  color: #4B90E0;
  font-size: 18px;
  font-weight: bold;
  margin-right: 10px;
}



.title{
  display: flex;
  align-items: center;
  color: #4B90E0;
  font-weight: bold;
  font-size: 18px;
}
.logout{
  display: flex;
  align-items: center;
  cursor: pointer;
}
.notify{
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background-color: #F2F5F8;
  color: #666;
  cursor: pointer;
}
.notify.active{
  color: #4B90E0;
}
.notify .dot{
  position: absolute;
  top: 6px;
  right: 6px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #F56C6C;
}
.aside{
  height: calc(100vh - 60px);
  width: 200px;
  background-color: #FBFCFD;
  position: relative;
  z-index: 1;
  box-shadow: 5px 0 10px -2px rgba(0, 0, 0, 0.1);
  margin: 0 !important; /* 新增 */
  padding: 0 !important; /* 新增 */
}
.aside .menu-item{
  height: 50px;
  width: 80%;
  display: flex;
  align-items: center;
  justify-content: start;
  cursor: pointer;
  border-radius: 10px;
  margin: 15px 0;
  padding-left: 20px;
  color: #666666;
  border: #EAF2FA 1px solid;
  transition:
      transform 0.3s ease,
      background-color 0.3s ease,
      color 0.3s ease,
      border-color 0.3s ease;

  transform: translateX(0);
}

.aside .menu-item.active {
  transform: translateX(10px);
  background-color: #4B90E0;
  color: #FBFCFD;

  border-left: 4px solid #EAF2FA;
  padding-left: 16px;
}
.aside .menu-item span{
  font-size: 17px;
  font-weight: bold;
  margin-left: 10px;
}

.aside .menu-item:hover {
  transform: translateX(10px);
  background-color: #EAF2FA;
  color: #4B90E0;
  border-color: #4B90E0;
}
.aside .menu-item.active {
  transform: translateX(10px);
  background-color: #4B90E0 !important;
  color: #FBFCFD !important;
  border-left: 4px solid #EAF2FA;
  padding-left: 16px;
}
.main-content {
  background-color: #fff;
  height: calc(100vh - 60px);
  box-sizing: border-box;
  overflow: hidden;

}
:deep(.el-container) {
  margin: 0 !important;
  padding: 0 !important;
  gap: 0 !important;
}
:deep(.el-aside) {
  margin: 0 !important;
  padding: 0 !important;
  border: none !important;
}
:deep(.el-main) {
  margin: 0 !important;
  padding: 0 !important;
  border: none !important;
}
/* 核心新增：页面渐变消失动画样式 */
:deep(.page-fade-enter-from) {
  opacity: 0;
  transform: translateX(20px); /* 进入时从右侧淡入 */
}
:deep(.page-fade-leave-to) {
  opacity: 0;
  transform: translateX(-20px); /* 消失时向左淡出 */
}
:deep(.page-fade-enter-active),
:deep(.page-fade-leave-active) {
  transition: all 0.4s ease; /* 动画时长和缓动效果 */
}
:deep(.page-fade-enter-to),
:deep(.page-fade-leave-from) {
  opacity: 1;
  transform: translateX(0);
}
</style>
