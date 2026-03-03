<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { ElMessage } from 'element-plus';
import axios from 'axios';

const form = ref({
  title: '',
  content: '',
  type: 'ALL', // ALL or USER
  nickname: ''
});

const nicknames = ref<string[]>([]);

const fetchNicknames = async () => {
  try {
    const res = await axios.get('notification/nicknames');
    console.log('Nicknames response:', res.data);
    if (res.data.code === 200) {
      nicknames.value = res.data.data;
    }
  } catch (error) {
    console.error(error);
  }
};

const handleSubmit = async () => {
  if (!form.value.title || !form.value.content) {
    ElMessage.warning('请填写标题和内容');
    return;
  }
  if (form.value.type === 'USER' && !form.value.nickname) {
    ElMessage.warning('请选择接收用户');
    return;
  }

  try {
    const res = await axios.post('notification/send', form.value);
    if (res.data.code === 200) {
      ElMessage.success('发布成功');
      form.value = { title: '', content: '', type: 'ALL', nickname: '' };
    } else {
      ElMessage.error(res.data.msg || '发布失败');
    }
  } catch (error) {
    ElMessage.error('网络错误');
  }
};

onMounted(() => {
  fetchNicknames();
});
</script>

<template>
  <div class="announcement-container">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span>发布公告</span>
        </div>
      </template>
      <el-form :model="form" label-width="120px">
        <el-form-item label="公告标题">
          <el-input v-model="form.title" placeholder="请输入标题" />
        </el-form-item>
        <el-form-item label="公告内容">
          <el-input v-model="form.content" type="textarea" :rows="5" placeholder="请输入内容" />
        </el-form-item>
        <el-form-item label="发送对象">
          <el-radio-group v-model="form.type">
            <el-radio label="ALL">所有用户</el-radio>
            <el-radio label="USER">特定用户</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.type === 'USER'" label="选择用户">
          <el-select v-model="form.nickname" filterable placeholder="请选择用户昵称" style="width: 100%;">
            <el-option
                v-for="name in nicknames"
                :key="name"
                :label="name"
                :value="name"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSubmit">发布公告</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<style scoped>
.announcement-container {
  padding: 20px;
}
.box-card {
  max-width: 800px;
  margin: 0 auto;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
