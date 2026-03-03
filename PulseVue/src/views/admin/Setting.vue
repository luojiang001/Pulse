<script setup lang="ts">
import { onMounted, ref } from "vue";
import router from "@/router";

const announcementForm = ref<{ show: boolean; title: string; content: string }>({
  show: false,
  title: "",
  content: "",
});

const refreshMs = ref<number>(30000);
const themeColor = ref<string>("#4B90E0");
const defaultOrderStatus = ref<string>("");
const orderStatusOptions = [
  { value: "", label: "所有状态" },
  { value: "pending", label: "待付款" },
  { value: "paid", label: "已付款" },
  { value: "cancelled", label: "已取消" },
  { value: "completed", label: "已完成" },
];

const load = () => {
    const annStr = localStorage.getItem("systemAnnouncement");
    if (annStr) {
      const ann = JSON.parse(annStr);
      announcementForm.value = {
        show: !!ann.show,
        title: ann.title || "",
        content: ann.content || "",
      };
    }
    const msStr = localStorage.getItem("dashboardRefreshMs");
    if (msStr) {
      const n = parseInt(msStr);
      if (!Number.isNaN(n)) {
        refreshMs.value = n;
      }
    }
    const colorStr = localStorage.getItem("themeColor");
    if (colorStr) {
      themeColor.value = colorStr;
    }
    const statusStr = localStorage.getItem("defaultOrderStatus");
    if (statusStr !== null) {
      defaultOrderStatus.value = statusStr;
    }
    document.documentElement.style.setProperty("--brand-color", themeColor.value);

};

const saveAnnouncement = () => {
  localStorage.setItem("systemAnnouncement", JSON.stringify(announcementForm.value));
  alert("公告设置已保存");
};

const saveRefreshMs = () => {
  if (refreshMs.value < 5000) {
    alert("刷新间隔不得小于 5000 ms");
    return;
  }
  localStorage.setItem("dashboardRefreshMs", String(refreshMs.value));
  alert("数据刷新设置已保存");
};

const saveTheme = () => {
  localStorage.setItem("themeColor", themeColor.value);
  document.documentElement.style.setProperty("--brand-color", themeColor.value);
  alert("主题色已保存");
};

const saveDefaultStatus = () => {
  localStorage.setItem("defaultOrderStatus", defaultOrderStatus.value);
  alert("默认订单筛选已保存");
};

const clearCache = () => {
  if (!confirm("确定清除本地缓存吗？这将删除登录信息与设置。")) return;
  localStorage.clear();
  sessionStorage.clear();
  alert("缓存已清除");
};

const logout = () => {
  sessionStorage.removeItem("adminInfo");
  router.push("/");
};

onMounted(() => {
  load();
});

</script>

<template>
  <div class="body">
    <div class="top">
      <div class="left">
        <span class="s1">系统设置/配置</span>
      </div>
      <div class="right"></div>
    </div>

    <el-row :gutter="20">
      <!-- 左侧主要设置区 -->
      <el-col :xs="24" :lg="16">
        <el-card class="setting-card">
          <template #header>
            <div class="card-header">
              <span>系统偏好设置</span>
            </div>
          </template>
          <el-form label-width="120px" label-position="left">
            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="主题色">
                  <el-color-picker v-model="themeColor" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="数据刷新间隔">
                  <el-input-number v-model="refreshMs" :min="5000" :step="5000" controls-position="right" />
                  <span class="ms-tip">毫秒</span>
                </el-form-item>
              </el-col>




            </el-row>
            <div class="form-actions">
              <el-button type="primary" @click="() => { saveTheme(); saveRefreshMs(); saveDefaultStatus(); }">保存偏好设置</el-button>
            </div>
          </el-form>
        </el-card>

        <el-card class="setting-card" style="margin-top: 20px;">
          <template #header>
            <div class="card-header">
              <span>系统公告配置</span>
              <el-switch v-model="announcementForm.show" active-text="启用" inactive-text="禁用" />
            </div>
          </template>
          <el-form label-width="100px" :model="announcementForm" label-position="top">
            <el-form-item label="公告标题">
              <el-input v-model="announcementForm.title" placeholder="例如：系统维护通知" />
            </el-form-item>
            <el-form-item label="公告内容">
              <el-input
                type="textarea"
                v-model="announcementForm.content"
                :rows="4"
                placeholder="请输入公告正文内容..."
              />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="saveAnnouncement">发布公告</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <!-- 右侧操作与导航区 -->
      <el-col :xs="24" :lg="8">
        <el-card class="setting-card">
          <template #header>
            <div class="card-header">
              <span>系统维护</span>
            </div>
          </template>
          <div class="maintenance-box">
            <div class="maintenance-item">
              <div class="m-info">
                <div class="m-title">本地缓存</div>
                <div class="m-desc">清除本地存储的配置与登录状态</div>
              </div>
              <el-button type="danger" plain size="small" @click="clearCache">清除</el-button>
            </div>
            <div class="maintenance-item">
              <div class="m-info">
                <div class="m-title">账号安全</div>
                <div class="m-desc">退出当前管理员账号</div>
              </div>
              <el-button type="warning" plain size="small" @click="logout">退出</el-button>
            </div>
          </div>
        </el-card>

        <el-card class="setting-card" style="margin-top: 20px;">
          <template #header>
            <div class="card-header">
              <span>快捷导航</span>
            </div>
          </template>
          <div class="quick-nav-grid">
            <div class="nav-item" @click="router.push('/admin/register')">挂号管理</div>
            <div class="nav-item" @click="router.push('/admin/doctor')">医生管理</div>
            <div class="nav-item" @click="router.push('/admin/medicine')">药品管理</div>
            <div class="nav-item" @click="router.push('/admin/order')">订单管理</div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped>
.body {
  width: 100%;
  height: 100%;
  overflow-y: auto;
  background-color: #EBEFF6;
  margin: 0;
  padding: 20px;
  padding-bottom: 40px;
  box-sizing: border-box;
  scrollbar-width: none;
  -ms-overflow-style: none;
}
.body::-webkit-scrollbar {
  display: none;
}
.top {
  height: 60px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}
.top .left .s1 {
  font-size: 15px;
  color: #333333;
}
.section-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 12px;
  color: #333;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 600;
  font-size: 16px;
  color: #333;
}
.setting-card {
  border-radius: 8px;
  border: none;
  box-shadow: 0 2px 12px 0 rgba(0,0,0,0.05);
}
.ms-tip {
  margin-left: 10px;
  color: #999;
  font-size: 12px;
}
.form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  border-top: 1px solid #f0f2f5;
  padding-top: 20px;
}
.maintenance-box {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.maintenance-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px;
  background-color: #f8f9fa;
  border-radius: 6px;
}
.m-info {
  display: flex;
  flex-direction: column;
}
.m-title {
  font-size: 14px;
  font-weight: 600;
  color: #333;
}
.m-desc {
  font-size: 12px;
  color: #999;
  margin-top: 2px;
}
.quick-nav-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.nav-item {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f8f9fa;
  border-radius: 6px;
  color: #555;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid transparent;
}
.nav-item:hover {
  background-color: #fff;
  border-color: var(--brand-color, #4B90E0);
  color: var(--brand-color, #4B90E0);
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}
.action-grid {
  display: flex;
  gap: 12px;
}
.quick-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.quick-item {
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #eef2f7;
  border-radius: 8px;
  background-color: #fff;
  color: var(--brand-color, #4B90E0);
  font-weight: 600;
  cursor: pointer;
}
.quick-item:hover {
  background-color: #EAF2FA;
}
</style>

