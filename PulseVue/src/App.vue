<script setup lang="ts">
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

onMounted(() => {
  const adminInfo = sessionStorage.getItem('adminInfo');
  const doctorInfo = sessionStorage.getItem('doctorInfo');

  if (adminInfo) {
    router.push('/admin/home');
  } else if (doctorInfo) {
    router.push('/doctor/work');
  }
});
</script>

<template>
  <router-view/>
</template>

<style scoped></style>
