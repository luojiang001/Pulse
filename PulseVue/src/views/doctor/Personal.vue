<script setup lang="ts">
import { ref, onMounted, reactive } from "vue";
import axios from "axios";
import { User, Lock } from "@element-plus/icons-vue";
import router from "@/router";

// 医生信息接口定义
interface DoctorInfo {
  id: number;
  username: string;
  name: string;
  phone?: string;
  departmentName?: string;
  title?: string; // 职称
}

const doctor = ref<DoctorInfo>({
  id: 0,
  username: "",
  name: "",
});

// 密码表单
const passwordForm = reactive({
  oldPassword: "",
  newPassword: "",
  confirmPassword: "",
});

const formRef = ref();

// 表单校验规则
const rules = {
  oldPassword: [{ required: true, message: "请输入旧密码", trigger: "blur" }],
  newPassword: [
    { required: true, message: "请输入新密码", trigger: "blur" },
    { min: 6, message: "密码长度不能少于6位", trigger: "blur" },
  ],
  confirmPassword: [
    { required: true, message: "请再次输入新密码", trigger: "blur" },
    {
      validator: (rule: any, value: string, callback: any) => {
        if (value !== passwordForm.newPassword) {
          callback(new Error("两次输入密码不一致"));
        } else {
          callback();
        }
      },
      trigger: "blur",
    },
  ],
};

onMounted(() => {
  const doctorInfoStr = sessionStorage.getItem("doctorInfo");
  if (doctorInfoStr) {
    const info = JSON.parse(doctorInfoStr);
    // 根据 Login.vue，token 字段存储了 doctor 对象的详细信息
    if (info.token) {
      doctor.value = {
        id: info.token.id,
        username: info.token.username,
        name: info.token.name || info.username, // 优先使用 token 中的 name
        phone: info.token.phone,
        departmentName: info.token.departmentName,
        title: info.token.title
      };
    }
  }
});

const handleChangePassword = async () => {
  if (!formRef.value) return;
  
  await formRef.value.validate(async (valid: boolean) => {
    if (valid) {
      try {
        // 假设后端修改密码接口为 doctor/updatePassword
        // 参数通常需要 id, oldPassword, newPassword
        const res = await axios.get(`doctor/updatePassword?id=${doctor.value.id}&oldPassword=${passwordForm.oldPassword}&newPassword=${passwordForm.newPassword}`);
        if (res.data.code === 200) {
          alert("密码修改成功，请重新登录");
          sessionStorage.removeItem("doctorInfo");
          router.push('/login')
        } else {
          alert(res.data.msg || "密码修改失败");
        }
      } catch (error) {
        console.error("修改密码出错", error);
        alert("系统错误，请稍后重试");
      }
    }
  });
};

const resetForm = () => {
  if (formRef.value) {
    formRef.value.resetFields();
  }
};
</script>

<template>
  <div class="body">
    <div class="top">
      <div class="left">
        <span class="s1">个人中心</span>
      </div>
    </div>
    
    <div class="content-container">
      <el-row :gutter="20">
        <!-- 左侧：个人信息卡片 -->
        <el-col :span="8">
          <el-card class="box-card info-card">
            <template #header>
              <div class="card-header">
                <el-icon><User /></el-icon>
                <span>基本信息</span>
              </div>
            </template>
            <div class="user-avatar">
               <div class="avatar-circle">{{ doctor.name.charAt(0) }}</div>
               <h3>{{ doctor.name }}</h3>
               <p class="role-tag">医生</p>
            </div>
            
            <div class="info-list">
              <div class="info-item">
                <span class="label">账号：</span>
                <span class="value">{{ doctor.username }}</span>
              </div>
              <div class="info-item" v-if="doctor.departmentName">
                <span class="label">科室：</span>
                <span class="value">{{ doctor.departmentName }}</span>
              </div>
              <div class="info-item" v-if="doctor.title">
                <span class="label">职称：</span>
                <span class="value">{{ doctor.title }}</span>
              </div>
              <div class="info-item" v-if="doctor.phone">
                <span class="label">电话：</span>
                <span class="value">{{ doctor.phone }}</span>
              </div>
            </div>
          </el-card>
        </el-col>

        <!-- 右侧：修改密码卡片 -->
        <el-col :span="16">
          <el-card class="box-card">
            <template #header>
              <div class="card-header">
                <el-icon><Lock /></el-icon>
                <span>修改密码</span>
              </div>
            </template>
            
            <div class="form-wrapper">
              <el-form
                ref="formRef"
                :model="passwordForm"
                :rules="rules"
                label-width="100px"
                status-icon
              >
                <el-form-item label="旧密码" prop="oldPassword">
                  <el-input 
                    v-model="passwordForm.oldPassword" 
                    type="password" 
                    placeholder="请输入当前使用的密码"
                    show-password
                  />
                </el-form-item>
                
                <el-form-item label="新密码" prop="newPassword">
                  <el-input 
                    v-model="passwordForm.newPassword" 
                    type="password" 
                    placeholder="请输入新密码（至少6位）"
                    show-password
                  />
                </el-form-item>
                
                <el-form-item label="确认密码" prop="confirmPassword">
                  <el-input 
                    v-model="passwordForm.confirmPassword" 
                    type="password" 
                    placeholder="请再次输入新密码"
                    show-password
                  />
                </el-form-item>
                
                <el-form-item>
                  <el-button type="primary" @click="handleChangePassword">确认修改</el-button>
                  <el-button @click="resetForm">重置</el-button>
                </el-form-item>
              </el-form>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<style scoped>
.body {
  width: 100%;
  height: 100%;
  background-color: #f5f7fa;
  display: flex;
  flex-direction: column;
}

.top {
  height: 60px;
  background-color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  border-bottom: 1px solid #e4e7ed;
  flex-shrink: 0;
}

.top .left {
  display: flex;
  align-items: center;
}

.s1 {
  font-size: 18px;
  font-weight: bold;
  color: #303133;
}

.content-container {
  padding: 20px;
  flex: 1;
  overflow-y: auto;
}

.box-card {
  margin-bottom: 20px;
  border-radius: 8px;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: bold;
  color: #303133;
}

/* 个人信息卡片样式 */
.user-avatar {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px 0;
  border-bottom: 1px solid #EBEEF5;
  margin-bottom: 20px;
}

.avatar-circle {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background-color: #4B90E0;
  color: white;
  font-size: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 15px;
  box-shadow: 0 4px 10px rgba(75, 144, 224, 0.3);
}

.user-avatar h3 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

.role-tag {
  margin-top: 5px;
  font-size: 14px;
  color: #909399;
  background-color: #f4f4f5;
  padding: 2px 10px;
  border-radius: 12px;
}

.info-list {
  padding: 0 10px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 15px;
  font-size: 14px;
}

.info-item .label {
  color: #909399;
}

.info-item .value {
  color: #606266;
  font-weight: 500;
}

/* 表单样式 */
.form-wrapper {
  padding: 20px 40px 20px 0;
}
</style>
