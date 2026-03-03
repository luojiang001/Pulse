<script setup lang="ts">
import axios from "axios";
import {HomeFilled, UserFilled} from "@element-plus/icons-vue";
import {onMounted, ref} from "vue";
import router from "@/router";
onMounted(()=>{//登录页面加载时，默认激活管理员登录
  activeRole.value = 'admin';
})
const activeRole = ref<string>('');

//激活状态
const handleItemClick = (role: string) => {
  activeRole.value = role;
};
const username = ref<string>('');
const password = ref<string>('');
//登录事件
const handleLogin = () => {
  if (!username.value || !password.value) {
    alert('请输入用户名和密码');
    return;
  }

  if (activeRole.value === 'admin') {
    axios.get('admin/login?username='+username.value+'&password='+password.value).then(res=>{
      const data = res.data;
      alert("信息码:"+data.code+"\n"+data.msg+"\n欢迎: "+data.data.username+"管理员");
      if(data.code===200){
        sessionStorage.setItem('adminInfo', JSON.stringify({
          username: data.data.username,
          token: data.data
        }));
        router.push('/admin/home');
      }
    })
  }

  if (activeRole.value === 'doctor') {
    axios.get('doctor/login?username='+username.value+'&password='+password.value).then(res=>{
      const data = res.data;
      alert("信息码:"+data.code+"\n"+data.msg+"\n欢迎: "+data.data.name+"医生");
      if(data.code===200){
        sessionStorage.setItem('doctorInfo', JSON.stringify({
          username: data.data.name,
          token: data.data
        }));
        router.push('/doctor/work');
      }
    })
  }
};
</script>

<template>
  <div class="body">
    <div class="login">
      <div class="top">
        <el-icon :size="80" color="#4B90E0" class="icon"><HomeFilled /></el-icon>
          <p class="p1">智慧医院后台管理系统</p>
          <p class="p2">Smart Hospital Management System</p>

      </div>
      <div class="center">
        <div
            class="item"
            :class="{ active: activeRole === 'admin' }"
            @click="handleItemClick('admin')"
        >
          <el-icon :size="30" ><UserFilled /></el-icon>
          <br>
          <span>管理员</span>
        </div>
        <div
            class="item"
            :class="{ active: activeRole === 'doctor' }"
            @click="handleItemClick('doctor')"
        >
          <el-icon :size="30"><UserFilled /></el-icon>
          <br>
          <span>医生</span>
        </div>
      </div>
      <div class="bottom">
        <div class="item">
          <input type="text" name="username" id="" v-model="username" placeholder="请输入用户名">
        </div>
        <div class="item">
          <input type="password" name="password" id="" v-model="password" placeholder="请输入密码">
        </div>
        <button @click="handleLogin()">登录系统</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.body{
  height: 100vh;
  width: 100%;
  background-color: #F3F6FA;
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 0;
  padding: 0;
}
.login{
  height: 530px;
  width: 380px;
  background-color: #FDFDFE;
  border-radius: 20px;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
}
.top{
  padding-top: 15px;
  height: 35%;
  width: 100%;
  text-align: center;
}

.login .top .p1{
  font-size: 24px;
  font-weight: bold;
}
.login .top .p2{
  font-size: 16px;
  color: #858585;
  margin-top: -10px;
}
.center{
  height: 25%;
  width: 100%;
  border-radius: 20px;
  display: flex;
  justify-content: space-evenly;
}
.center .item {
  font-size: 18px;
  height: 100px;
  width: 120px;
  border-radius: 20px;
  border: #d3d3d3 2px solid;
  align-content: center;
  text-align: center;
  margin-top: 20px;
  cursor: pointer;/*鼠标悬停时显示为手型*/
  transition:
      border-color 0.3s ease,
      color 0.3s ease,
      transform 0.2s ease;
  color: #666666;
  position: relative;
}
.center .item.active span {
  color: #4B90E0;
}
.center .item.active {
  border-color: #4B90E0;
  color: #4B90E0;
  transform: scale(1.02);
}

.center .item :deep(.el-icon) {
  color: inherit;
  transition: color 0.3s ease;
}

.center .item.active :deep(.el-icon) {
  color: inherit !important;
}

.center .item:hover {
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
}
.bottom{
  height: 35%;
  width: 100%;
  border-radius: 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.bottom .item input{
  height: 35px;
  width: 250px;
  border-radius: 20px;
  border: #FFFFFF 1px solid;
  padding: 0 15px;
  margin-top: 15px;
  cursor: text; /* 输入框鼠标改为文本光标，更符合习惯 */
  transition: border-color 0.5s ease, box-shadow 0.5s ease;
  color: #666666;
  outline: none;
  box-shadow: 0 0 0 rgba(75, 144, 224, 0);
}

.bottom .item input:focus {
  border: #4B90E0 1px solid;
  box-shadow: 0 0 5px rgba(75, 144, 224, 0.3);
  color: #4B90E0;
}
.bottom .item input:hover {
  border-color: #a0b8d8;
  box-shadow: 0 0 8px rgba(160, 184, 216, 0.2);
}
.bottom button{
  height: 40px;
  width: 280px;
  border-radius: 20px;
  border: #d3d3d3 2px solid;
  align-content: center;
  text-align: center;
  cursor: pointer;/*鼠标悬停时显示为手型*/
  transition: all 0.3s ease;
  color: #fff;
  font-size: 18px;
  font-weight: bold;
  margin-top: 15px;
  background-color: #4B90E0;
}
</style>