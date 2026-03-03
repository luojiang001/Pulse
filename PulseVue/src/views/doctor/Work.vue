<script setup lang="ts">
import { HomeFilled, Delete, Plus } from "@element-plus/icons-vue";
import { onMounted, ref, nextTick } from "vue";
import axios from "axios";

const isShowCon = ref<boolean>(true);
const patientList = ref<Array<{
  regNo: string; // 挂单号
  name: string; // 姓名
  gender: string; // 性别
  age: number; // 年龄
  status: string; // 就诊状态
  id: number; // 唯一ID
}>>([]);

const doctor = ref({
  username: '默认用户',
  data: {
    id: '',
    username: '',
    token: ''
  }
});

const handleNext = () => {
  if (!isShowCon.value) {
    alert('当前已有患者就诊，请先完成当前就诊');
    return;
  }
  if (patientList.value.length === 0) {
    alert('暂无患者');
    return;
  }
  const firstPatient = patientList.value[0];
  if (!firstPatient) {
    alert('暂无患者');
    return;
  }
  axios.get("registrationRecord/updateVisitStatus?regNo=" + firstPatient.regNo+"&visitStatus=1").then((res:any)=>{
    if(res.data.code === 200){
      alert(`请：${firstPatient.name} 到就诊室就诊`);
      isShowCon.value = false;
      firstPatient.status = '就诊中';
    }
  })
};

const handleMissed = () => {
  if (patientList.value.length === 0) {
    alert('暂无患者');
    return;
  }
  const firstPatient = patientList.value[0];
  if (!firstPatient) {
    alert('暂无患者');
    return;
  }
  // visitStatus=3 for Missed
  axios.get("registrationRecord/updateVisitStatus?regNo=" + firstPatient.regNo+"&visitStatus=3").then((res:any)=>{
    if(res.data.code === 200){
      alert(`患者：${firstPatient.name} 已标记为爽约`);
      patientList.value.shift();
      nextTick(() => {
        const scrollContainer = document.querySelector('.scroll-container');
        scrollContainer && (scrollContainer.scrollTop = 0);
      });
      isShowCon.value = true;
    }
  })
};


const dialogFormVisible=ref(false) //不显示对话框
const form=ref({
  name:'',
  age:0,
  gender:'',
  msg:''
})

// 药品相关状态
const categoryList = ref<Array<{id: number, name: string}>>([]);
const medicineList = ref<Array<any>>([]); // 当前展示的药品列表
const allMedicines = ref<Array<any>>([]); // 所有药品缓存
const prescriptionList = ref<Array<any>>([]); // 已选药品列表

const currentMedicine = ref({
  categoryId: '',
  medicineId: '',
  quantity: 1
});

const clear=()=>{
  form.value={name:'',age:0,gender:'',msg:''}
  prescriptionList.value = [];
  currentMedicine.value = { categoryId: '', medicineId: '', quantity: 1 };
  dialogFormVisible.value=false
}
const formLabelWidth=ref('100px') //表单左列的宽度
const handleConfirm=()=>{
  if (isShowCon.value) {
    alert('当前无就诊患者，无需完成就诊');
    return;
  }
  if (patientList.value.length === 0) {
    alert('暂无患者');
    return;
  }
  const firstPatient = patientList.value[0];
  if (!firstPatient) {
    alert('暂无患者');
    return;
  }
  dialogFormVisible.value=true
}

// 获取分类
const fetchCategories = async () => {
  try {
    const res = await axios.get("medicine/categoryList");
    if (res.data) {
      categoryList.value = res.data;
    }
  } catch (error) {
    console.error("获取药品分类失败", error);
  }
};

// 获取所有药品
const fetchMedicines = async () => {
  try {
    // 尝试获取较多药品用于前端筛选
    const res = await axios.get("medicine/medicineList");
    if (res.data && res.data) {
      allMedicines.value = res.data;
      medicineList.value = allMedicines.value;
    }
  } catch (error) {
    console.error("获取药品列表失败", error);
  }
};

// 分类改变时筛选药品
const handleCategoryChange = (val: any) => {
  currentMedicine.value.medicineId = ''; // 重置药品选择
  if (val) {
    medicineList.value = allMedicines.value.filter(m => m.categoryId === val);
  } else {
    medicineList.value = allMedicines.value;
  }
};

// 添加药品到处方列表
const addMedicine = () => {
  if (!currentMedicine.value.medicineId) {
    alert("请选择药品");
    return;
  }
  if (currentMedicine.value.quantity <= 0) {
    alert("药品数量必须大于0");
    return;
  }
  
  const med = allMedicines.value.find(m => m.id === currentMedicine.value.medicineId);
  if (med) {
    const existing = prescriptionList.value.find(item => item.id === med.id);
    if (existing) {
      existing.quantity += Number(currentMedicine.value.quantity);
    } else {
      prescriptionList.value.push({
        ...med,
        quantity: Number(currentMedicine.value.quantity)
      });
    }
    // 重置数量，保留分类方便继续添加同类药
    currentMedicine.value.quantity = 1;
    currentMedicine.value.medicineId = '';
  }
};

// 移除药品
const removeMedicine = (index: number) => {
  prescriptionList.value.splice(index, 1);
};

const save = async () => {
  const firstPatient = patientList.value[0];
  if (!firstPatient) {
    alert('暂无患者');
    return;
  }
  const { regNo, name, age, gender } = firstPatient;
  const doctorId = doctor.value.data.id;
  const msg = form.value.msg || "无";

  try {
    const resVisit=await axios.get(`registrationRecord/updateVisitStatus?regNo=${regNo}&visitStatus=2`)
    if (resVisit.data.code == 200) {
      const resPrescription = await axios.get(`prescription/confirm?doctorId=${doctorId}&name=${name}&age=${age}&gender=${gender}&msg=${msg}&regNo=${regNo}`)
      const result=resPrescription.data
      if (result.code == 200) {
        const prescriptionId = result.data.id;
        if (prescriptionList.value.length > 0 && prescriptionId) {
          const payloads = prescriptionList.value.map(item => ({
            prescriptId: Number(prescriptionId),
            medicineId: Number(item.id),
            count: Number(item.quantity)
          }));
          await Promise.allSettled(payloads.map(p => axios.post("prescription/addPrescriptionMedicine", p)));
        }
        alert(`已完成患者【${name}】的就诊确认和处方确认`);
        patientList.value.shift();
        nextTick(() => {
          const scrollContainer = document.querySelector('.scroll-container');
          scrollContainer && (scrollContainer.scrollTop = 0);
        });
        isShowCon.value = true;
        clear();
      }else {
        alert(`患者【${name}】的处方确认失败，请重试！\n${result.msg || ''}`);
      }
    }else {
      alert(`患者【${name}】的就诊确认失败，请重试！`);
    }
  } catch (error) {
    console.error('操作失败：', error);
    alert(`患者【${name}】的就诊/处方确认失败，请重试！`);
  }
};

const loadPatientList = async () => {
  try {
    const currentDocId = Number(doctor.value.data.id);
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const dateStr = `${year}-${month}-${day}`;
    
    console.log(`正在加载患者列表，医生ID: ${currentDocId}, 日期: ${dateStr}`);
    
    const res = await axios.get("registrationRecord/findAll", {
      params: { doctorId: currentDocId, date: dateStr }
    });
    const rawData = res.data;
    console.log('API返回原始数据:', rawData);

    if (!Array.isArray(rawData)) {
      alert('患者数据格式错误');
      return;
    }

    patientList.value = rawData
        .filter((item: any) => {
          const doctorId = Number(item.doctor?.id);
          const currentDocId = Number(doctor.value.data.id);
          
          // Time filtering
          const now = new Date();
          const currentHour = now.getHours();
          const currentMinute = now.getMinutes();
          const currentTimeVal = currentHour * 60 + currentMinute;
          
          let isFutureOrCurrent = true;
          if (item.scheduleTime) {
              const parts = item.scheduleTime.split('-');
              if (parts.length > 1) {
                  const endTimeStr = parts[1]; // "09:00"
                  const [endH, endM] = endTimeStr.split(':').map(Number);
                  const endTimeVal = endH * 60 + endM;
                  // If slot end time is before current time, it's a past slot
                  if (endTimeVal <= currentTimeVal) {
                      isFutureOrCurrent = false;
                  }
              }
          }

          return (doctorId === currentDocId) && (item.visitStatus === 0 || item.visitStatus === 1) && isFutureOrCurrent;
        })
        .map((item: any) => ({
          regNo: item.regNo || "未知单号",
          name: item.name || "未知姓名",
          gender: item.gender || "未知",
          age: item.age || 0,
          status: item.visitStatus === 0 ? "待就诊" : "就诊中",
          id: item.id || 0
        }));

    console.log('过滤后的患者列表：', patientList.value);
    nextTick(() => {
      const scrollContainer = document.querySelector('.scroll-container');
      if (scrollContainer) scrollContainer.scrollTop = 0;
    });
  } catch (error) {
    console.error("加载患者列表失败：", error);
    alert("加载患者列表失败，请重试");
  }
};

onMounted(() => {
  const login = sessionStorage.getItem('doctorInfo');
  if (login) {
    const userInfo = JSON.parse(login);
    doctor.value.username = userInfo.username;
    doctor.value.data = userInfo.token;
  }
  loadPatientList();
  fetchCategories();
  fetchMedicines();
});
</script>

<template>
  <div class="body">
    <div class="top">
      <div class="left">
        <span class="s1">叫号工作台</span>
        <span class="s2">今天是 {{ new Date().toLocaleDateString() }},祝您工作愉快</span>
      </div>
      <div class="right">
        <div class="d1">
          <span class="s1">当前就诊</span>
          <span class="s2">{{ isShowCon ? '无' : patientList[0]?.name }}</span>
        </div>
        <div class="d2">
          <span class="s1">等待人数</span>
          <span class="s2">{{ patientList.length }}</span>
        </div>
      </div>
    </div>
    <div class="context">
      <div class="left">
        <div class="top">
          <span>当前就诊信息</span>
          <div class="status">{{ isShowCon ? '空闲' : '就诊中' }}</div>
        </div>
        <div class="con" v-if="isShowCon">
          <el-icon :size="150" color="#DEDEDF" class="icon"><HomeFilled /></el-icon>
          <span>暂无患者，请叫号</span>
        </div>
        <div class="con" v-else>
          <span class="name">{{ patientList[0]?.name.substring(0,1) }}</span>
          <div class="list">
            <div class="item-name item">
              <span class="s1">姓名</span>
              <span class="s2">{{ patientList[0]?.name }}</span>
            </div>
            <div class="item-reg item">
              <span class="s1">挂号单</span>
              <span class="s2">{{ patientList[0]?.regNo }}</span>
            </div>
            <div class="item-gender item">
              <span class="s1">性别</span>
              <span class="s2">{{ patientList[0]?.gender }}</span>
            </div>
            <div class="item-age item">
              <span class="s1">年龄</span>
              <span class="s2">{{ patientList[0]?.age }}</span>
            </div>
          </div>
        </div>
        <div class="bottom">
          <div
              class="next"
              @click="handleNext"
              :class="{ disabled: !isShowCon || patientList.length === 0 }"
              :style="{ pointerEvents: (!isShowCon || patientList.length === 0) ? 'none' : 'auto' }"
          >
            <el-icon :size="25" color="#fff" class="icon"><Microphone /></el-icon>
            <span>叫号下一位</span>
          </div>
          <div
              class="next"
              @click="handleMissed"
              :class="{ disabled: !isShowCon || patientList.length === 0 }"
              style="background-color: #F56C6C; margin-top: 10px;"
              :style="{ pointerEvents: (!isShowCon || patientList.length === 0) ? 'none' : 'auto' }"
          >
            <el-icon :size="25" color="#fff" class="icon"><Delete /></el-icon>
            <span>标记爽约</span>
          </div>
          <div
              class="confirm"
              @click="handleConfirm"
              :class="{ disabled: isShowCon }"
              :style="{ pointerEvents: isShowCon ? 'none' : 'auto' }"
          >
            <el-icon :size="25" color="#fff" class="icon"><HomeFilled /></el-icon>
            <span>完成就诊</span>
          </div>
        </div>
      </div>
      <div class="right">
        <div class="top">
          <span>候诊队列({{ patientList.length }})</span>
        </div>
        <div class="scroll-container">
          <div
              class="list-item"
              v-for="(item, index) in patientList"
              :key="item.id"
          >
            <div class="item">
              <span class="ss1"> {{ index + 1 }} </span>
              <div class="d">
                <span class="s1"> {{ item.name }} </span>
                <span class="s2"> {{ item.regNo }}</span>
              </div>
              <span class="s3">{{ item.status }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 处方对话框 -->
    <el-dialog title="患者处方" v-model="dialogFormVisible" :before-close="clear" width="60%">
      <el-form :model="form" ref="medicineForm">
        <!-- 患者基础信息 -->
        <div style="display: flex; gap: 20px; margin-bottom: 20px; background: #f5f7fa; padding: 10px; border-radius: 4px;">
          <el-form-item label="患者姓名" style="margin-bottom: 0;">
            <span style="font-weight: bold;">{{ patientList[0]?.name }}</span>
          </el-form-item>
          <el-form-item label="年龄" style="margin-bottom: 0;">
            <span style="font-weight: bold;">{{ patientList[0]?.age }}</span>
          </el-form-item>
          <el-form-item label="性别" style="margin-bottom: 0;">
            <span style="font-weight: bold;">{{ patientList[0]?.gender }}</span>
          </el-form-item>
        </div>

        <!-- 药品选择区域 -->
        <el-card shadow="never" style="margin-bottom: 20px;">
          <template #header>
            <div class="card-header">
              <span>添加药品</span>
            </div>
          </template>
          <el-row :gutter="10">
            <el-col :span="6">
              <el-select v-model="currentMedicine.categoryId" placeholder="选择分类" @change="handleCategoryChange" clearable>
                <el-option v-for="item in categoryList" :key="item.id" :label="item.name" :value="item.id" />
              </el-select>
            </el-col>
            <el-col :span="10">
              <el-select v-model="currentMedicine.medicineId" placeholder="选择药品" filterable clearable>
                <el-option 
                  v-for="item in medicineList" 
                  :key="item.id" 
                  :label="`${item.name} (${item.stock}${item.unit})`" 
                  :value="item.id" 
                  :disabled="item.status == 0 || item.stock <= 0"
                >
                  <span style="float: left">{{ item.name }}</span>
                  <span style="float: right; color: #8492a6; font-size: 13px">
                    {{ item.price }}元/{{ item.unit }}
                  </span>
                </el-option>
              </el-select>
            </el-col>
            <el-col :span="4">
              <el-input-number v-model="currentMedicine.quantity" :min="1" :max="100" style="width: 100%" />
            </el-col>
            <el-col :span="4">
              <el-button type="primary" :icon="Plus" @click="addMedicine" style="width: 100%">添加</el-button>
            </el-col>
          </el-row>
        </el-card>

        <!-- 已选药品列表 -->
        <el-table :data="prescriptionList" border style="width: 100%; margin-bottom: 20px;" max-height="250">
          <el-table-column prop="name" label="药品名称" />
          <el-table-column prop="price" label="单价" width="100">
            <template #default="scope">{{ scope.row.price }}元</template>
          </el-table-column>
          <el-table-column prop="quantity" label="数量" width="120">
             <template #default="scope">{{ scope.row.quantity }}{{ scope.row.unit }}</template>
          </el-table-column>
          <el-table-column label="小计" width="100">
             <template #default="scope">{{ (scope.row.price * scope.row.quantity).toFixed(2) }}元</template>
          </el-table-column>
          <el-table-column label="操作" width="80" align="center">
            <template #default="scope">
              <el-button type="danger" :icon="Delete" circle size="small" @click="removeMedicine(scope.$index)" />
            </template>
          </el-table-column>
        </el-table>

        <el-form-item label="医嘱/备注" prop="msg">
          <el-input type="textarea" :rows="3" v-model="form.msg" placeholder="请输入医嘱或备注信息"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer" style="text-align: right;">
        <el-button @click="clear">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<style scoped>
/* 全局安全区域适配 */
:root {
  --safe-area-inset-bottom: env(safe-area-inset-bottom);
}

.body {
  width: 100%;
  height: 100vh;
  min-height: -webkit-fill-available; /* 适配iOS安全区域 */
  background-color: #F2F5F8;
  margin: 0;
  padding: 0 var(--safe-area-inset-bottom) var(--safe-area-inset-bottom) 0;
  overflow: hidden;
  box-sizing: border-box;
}

/* 顶部区域 */
.top {
  height: 100px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  box-sizing: border-box;
}

.top .left {
  height: 100%;
  width: auto;
  display: flex;
  flex-direction: column;
  align-items: start;
  justify-content: end;
  padding-left: 10px;
  padding-bottom: 10px;
}

.top .left .s1 {
  font-size: 25px;
  font-weight: bold;
  color: #333333;
}

.top .left .s2 {
  font-size: 15px;
  color: #AA9C82;
}

.top .right {
  height: 80%;
  width: 250px;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  background-color: #FCFDFE;
  margin-top: 10px;
  margin-right: 10px;
  border-radius: 20px;
  padding: 0 15px;
  box-sizing: border-box;
}

.top .right .d1, .top .right .d2 {
  height: 100%;
  width: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.top .right .d1 .s1, .top .right .d2 .s1 {
  font-size: 13px;
  color: #333333;
}

.top .right .d1 .s2, .top .right .d2 .s2 {
  font-size: 20px;
  font-weight: bold;
  color: #4B90E0;
}

.top .right .d2 .s2 {
  color: #333333;
}

/* 主体内容 */
.context {
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  justify-content: space-evenly;
  height: calc(100vh - 130px);
  width: 100%;
  padding: 10px 20px var(--safe-area-inset-bottom) 20px;
  box-sizing: border-box;
}

.context .left {
  height: 100%;
  width: 65%;
  border-radius: 20px;
  background-color: #fff;
  padding: 10px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.context .left .top {
  height: 80px;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  border-radius: 20px;
  padding: 0 20px;
}

.context .left .top span {
  font-size: 18px;
  font-weight: bold;
  color: #333333;
  margin-left: 0;
}

.context .left .top .status {
  padding: 5px 10px;
  border-radius: 20px;
  font-size: 14px;
  color: #333333;
  margin-right: 0;
  background-color: #EFF0F1;
}

.context .left .con {
  flex: 1;
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.context .left .con .name {
  padding: 25px;
  font-size: 30px;
  font-weight: bold;
  color: #fff;
  border-radius: 50px;
  background-color: #78ACE7;
  margin-bottom: 20px;
}

.context .left .con .list {
  height: 100%;
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.context .left .con .list .item {
  width: 60%;
  height: 55px;
  color: #333333;
  border-bottom: #F0F1F1 1px solid;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
}

.context .left .con .list .item .s1 {
  font-size: 16px;
  color: #333333;
}

.context .left .con .list .item .s2 {
  font-size: 18px;
  color: #333333;
}

.context .left .con span {
  font-size: 18px;
  color: #333333;
}

.context .left .bottom {
  height: 100px;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-around;
  margin-top: 10px;
  padding-bottom: 10px;
}

.context .left .bottom .next, .context .left .bottom .confirm {
  height: 50%;
  width: 40%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  border-radius: 20px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.context .left .bottom .next {
  background-color: #4B90E0;
}

.context .left .bottom .next.disabled {
  background-color: #99b9e9;
}

.context .left .bottom .confirm {
  background-color: #A6E193;
}

.context .left .bottom .confirm.disabled {
  background-color: #c9f0be;
}

.context .left .bottom .next span, .context .left .bottom .confirm span {
  font-size: 15px;
  color: #fff;
}

/* 右侧候诊列表 */
.context .right {
  height: 100%;
  width: 30%;
  border-radius: 20px;
  background-color: #fff;
  display: flex;
  flex-direction: column;
  padding: 10px;
  box-sizing: border-box;
}

.context .right .top {
  height: 60px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: start;
  flex-shrink: 0;
  padding: 0 10px;
}

.context .right .top span {
  font-size: 16px;
  font-weight: bold;
  color: #333333;
  margin-left: 10px;
}

.context .right .scroll-container {
  flex: 1;
  overflow-y: auto;
  padding: 5px 10px 20px 10px;
  margin: 0;
  scrollbar-width: thin;
  scrollbar-color: #4B90E0 #f1f1f1;
  height: calc(100% - 60px);
}

.context .right .scroll-container::-webkit-scrollbar {
  width: 6px;
}

.context .right .scroll-container::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.context .right .scroll-container::-webkit-scrollbar-thumb {
  background: #4B90E0;
  border-radius: 3px;
}

.context .right .scroll-container::-webkit-scrollbar-thumb:hover {
  background: #3a7bc8;
  border-radius: 3px;
}

.context .right .list-item {
  height: 60px;
  width: 100%;
  margin-bottom: 2px;
  box-sizing: border-box;
}

.context .right .list-item .item {
  height: 100%;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-evenly;
  padding: 0 5px;
  box-sizing: border-box;
}

.context .right .list-item .item .d {
  height: 100%;
  width: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.context .right .list-item .item .d .s1 {
  font-size: 15px;
  font-weight: bold;
  color: #333333;
}

.context .right .list-item .item .d .s2 {
  font-size: 9px;
  color: #333333;
}

.context .right .list-item .item .ss1 {
  font-size: 12px;
  color: #333333;
  background-color: #F1F2F2;
  padding: 4px 12px;
  border-radius: 100px;
  margin-left: 5px;
}

.context .right .list-item .item .s3 {
  font-size: 12px;
  color: #BDAAE7;
  background-color: #EBF3FB;
  padding: 4px 12px;
  border-radius: 10px;
  margin-right: 5px;
  cursor: pointer;
}
</style>
