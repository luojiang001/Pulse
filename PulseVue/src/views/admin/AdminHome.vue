<script setup lang="ts">
import router from "@/router";
import {ArrowRightBold, HomeFilled} from "@element-plus/icons-vue";
import {onMounted, ref, watch} from "vue";
import { useRoute } from "vue-router";

const route = useRoute();

const handleLogout = () => {
  sessionStorage.removeItem('adminInfo');
  router.push('/');
};
const activeMenu = ref<string>('home');

const handleMenuClick = (menuKey: string) => {
  activeMenu.value = menuKey;
  router.push(`/admin/${menuKey}`);
};

// 监听路由变化，同步高亮菜单
watch(() => route.path, (newPath) => {
  const pathParts = newPath.split('/');
  if (pathParts.length > 2 && pathParts[1] === 'admin') {
    activeMenu.value = pathParts[2] as string;
  }
}, { immediate: true });

const adminList = [
  { key: 'home', icon: HomeFilled, title: '首页', path: '/admin/home' },
  { key: 'register', icon: HomeFilled, title: '挂号管理', path: '/admin/register' },
  { key: 'medicine', icon: HomeFilled, title: '药品管理', path: '/admin/medicine' },
  { key: 'user', icon: HomeFilled, title: '用户管理', path: '/admin/user' },
  { key: 'doctor', icon: HomeFilled, title: '医生管理', path: '/admin/doctor' },
  { key: 'order', icon: HomeFilled, title: '订单管理', path: '/admin/order' },
  { key: 'announcement', icon: HomeFilled, title: '公告发布', path: '/admin/announcement' },
  { key: 'setting', icon: HomeFilled, title: '系统设置', path: '/admin/setting' },
];
const admin = ref({
  username: '',
  data: {}
});

onMounted(() => {
    const login=sessionStorage.getItem('adminInfo')
    if (login){
      const userInfo = JSON.parse(login);
      admin.value.username=userInfo.username
      admin.value.data=userInfo.token
    }
  });
</script>

<template>
  <div class="body">
    <div class="common-layout">
      <el-container>
        <el-header class="top">
          <div class="title">
            <el-icon :size="30" color="#4B90E0" class="icon"><HomeFilled /></el-icon>
            <span>智慧医院后台管理系统</span>
          </div>
          <div class="top-right">
            <div class="user-info">
              <span class="s1">{{ admin.username.substring(0, 1) }}</span>
              <span> {{ admin.username }} (管理员)</span>
            </div>
            <div class="logout" @click="handleLogout">
              <el-icon :size="20" color="#666"><ArrowRightBold /></el-icon>
            </div>
          </div>
        </el-header>
        <el-container>
          <el-aside class="aside">

            <div
                v-for="item in adminList"
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
  width: 20%;
  display: flex;
  align-items: center;
  justify-content: space-around;
}
.user-info{
  width: 70%;
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
.aside{
  height: calc(100vh);
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
  height: 100%;
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