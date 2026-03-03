<script setup lang="ts">
import { ref, onMounted, computed, watch } from "vue";
import { ArrowLeft, ArrowRight, Check } from "@element-plus/icons-vue";
import axios from "axios";

// 工具函数：获取指定日期所在周的7天（周二到下周一）
interface DayItem {
  date: Date;
  dayName: string;
  shortDate: string;
  isCurrent: boolean;
}

const getWeekDays = (date: Date = new Date()): DayItem[] => {
  const day = date.getDay() || 7; // 周日转为7
  const startDay = new Date(date);
  startDay.setDate(date.getDate() - day + 2); // 本周二

  const weekDays: DayItem[] = [];
  for (let i = 0; i < 7; i++) {
    const current = new Date(startDay);
    current.setDate(startDay.getDate() + i);

    // 判断是否是今天
    const today = new Date();
    const isToday = current.getDate() === today.getDate() &&
        current.getMonth() === today.getMonth() &&
        current.getFullYear() === today.getFullYear();

    weekDays.push({
      date: current,
      dayName: ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"][current.getDay()] || "",
      shortDate: `${String(current.getMonth() + 1).padStart(2, "0")}-${String(current.getDate()).padStart(2, "0")}`,
      isCurrent: isToday
    });
  }
  return weekDays;
};

// 格式化日期为YYYY-MM-DD
const formatDate = (date: Date) => {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
};

// 获取周范围文本（YYYY-MM-DD 至 YYYY-MM-DD）
const getWeekRangeText = (date: Date) => {
  const weekDays:any = getWeekDays(date);
  return `${formatDate(weekDays[0].date)} 至 ${formatDate(weekDays[6].date)}`;
};

// 响应式数据
const currentDate = ref(new Date());
const weekDays = computed(() => getWeekDays(currentDate.value));
const currentWeekText = computed(() => getWeekRangeText(currentDate.value));
const scheduleData = ref<any[]>([]);

// 定义后端数据接口类型
interface TimeSlot {
  time: string;
  isAvailable: boolean;
  room?: string;
}

interface ScheduleItem {
  date: string;
  week: string;
  room: string;
  times: TimeSlot[];
}

// 转换数据格式
const transformData = (backendData: ScheduleItem[], weekDays: DayItem[]) => {
  const result = [
    { timeSlot: "上午(08:00 - 12:00)", days: [] },
    { timeSlot: "下午(14:00 - 18:00)", days: [] },
    { timeSlot: "晚上(19:00 - 22:00)", days: [] }
  ];

  const getTimeSlotIndex = (timeStr: string) => {
    const hour = parseInt(timeStr.split(':')[0] || "0");
    if (hour < 12) return 0;
    if (hour < 18) return 1;
    return 2;
  };

  const scheduleMap = new Map();
  backendData.forEach(item => {
    scheduleMap.set(item.date, item);
  });

  result.forEach((slotRow: any, slotIndex: number) => {
    slotRow.days = weekDays.map(day => {
        const dateStr = formatDate(day.date);
        const schedule = scheduleMap.get(dateStr);
        
        let status = "";
        let room = "";

        if (schedule) {
            const slotData = schedule.times.find((t: TimeSlot) => getTimeSlotIndex(t.time) === slotIndex);
            if (slotData && slotData.isAvailable) {
                status = "值班";
                room = slotData.room || schedule.room || "";
            }
        }

        return {
            date: day.shortDate,
            fullDate: dateStr,
            status: status,
            room: room
        };
    });
  });
  
  return result;
}

// 从后端获取排班数据
const fetchScheduleData = async () => {
    try {
        const doctorInfoStr = sessionStorage.getItem('doctorInfo');
        if (!doctorInfoStr) {
            console.error("未找到医生登录信息");
            return;
        }
        const doctorInfo = JSON.parse(doctorInfoStr);
        const doctorId = doctorInfo.token.id; 

        const startDay = weekDays.value[0];
        const endDay = weekDays.value[6];

        if (!startDay || !endDay) return;

        const startDate = formatDate(startDay.date);
        const endDate = formatDate(endDay.date);

        const res = await axios.get(`doctor/schedule?doctorId=${doctorId}&startDate=${startDate}&endDate=${endDate}`);
        if (res.data.code === 200) {
            scheduleData.value = transformData(res.data.data, weekDays.value);
        }
    } catch (error) {
        console.error("获取排班数据失败", error);
    }
};

// 切换周次
const prevWeek = () => {
  currentDate.value = new Date(currentDate.value.setDate(currentDate.value.getDate() - 7));
};

const nextWeek = () => {
  currentDate.value = new Date(currentDate.value.setDate(currentDate.value.getDate() + 7));
};

// 监听周次变化
watch(currentDate, () => {
  fetchScheduleData();
});

onMounted(() => {
  fetchScheduleData();
  fetchRooms();
  fetchColleagues();
});

// 基础数据
const rooms = ref<any[]>([]);
const colleagues = ref<any[]>([]);

const fetchRooms = async () => {
  try {
    const doctorInfoStr = sessionStorage.getItem('doctorInfo');
    if (!doctorInfoStr) return;
    const doctorId = JSON.parse(doctorInfoStr).token.id;
    const res = await axios.get(`consultation_room/list?doctorId=${doctorId}`);
    if (res.data.code === 200) {
      rooms.value = res.data.data;
    }
  } catch (e) { console.error(e); }
};

const fetchColleagues = async () => {
  try {
    const doctorInfoStr = sessionStorage.getItem('doctorInfo');
    if (!doctorInfoStr) return;
    const doctorId = JSON.parse(doctorInfoStr).token.id;
    const res = await axios.get(`doctor/colleagues?doctorId=${doctorId}`);
    if (res.data.code === 200) {
      colleagues.value = res.data.data;
    }
  } catch (e) { console.error(e); }
};

// 交互逻辑
const dialogVisible = ref(false);
const dialogTitle = ref("");
const selectedInfo = ref<any>(null);

// 换班相关
const exchangeData = ref({
  targetDoctorId: ''
});

// 选中的诊室
const selectedRoomId = ref('');

const handleCellClick = (slotIndex: number, dayIndex: number) => {
  const cellData = scheduleData.value[slotIndex].days[dayIndex];
  const periodTypes = ["morning", "afternoon", "evening"];
  const periodTexts = ["上午", "下午", "晚上"];
  
  // 重置表单
  exchangeData.value = { targetDoctorId: '' };
  selectedRoomId.value = '';

  selectedInfo.value = {
    ...cellData,
    periodType: periodTypes[slotIndex],
    periodText: periodTexts[slotIndex],
    // 默认动作：有班则显示菜单（请假/换班），无班则添加
    action: cellData.status === "值班" ? "menu" : "add" 
  };

  if (cellData.status === "值班") {
      dialogTitle.value = "排班管理";
      // 默认选中请假，用户可切换到换班
      selectedInfo.value.action = "leave"; 
  } else {
      dialogTitle.value = "申请排班";
  }
  
  dialogVisible.value = true;
};

const confirmAction = async () => {
  if (!selectedInfo.value) return;

  try {
    const doctorInfoStr = sessionStorage.getItem('doctorInfo');
    if (!doctorInfoStr) return;
    const doctorInfo = JSON.parse(doctorInfoStr);
    const doctorId = doctorInfo.token.id;

    const { fullDate, periodType, action } = selectedInfo.value;
    
    // 构建 URL 参数
    const params = new URLSearchParams();
    
    let res;
    if (action === 'leave') {
      params.append('doctorId', doctorId);
      params.append('date', fullDate);
      params.append('periodType', periodType);
      res = await axios.post(`doctor/schedule/leave?${params.toString()}`);
    } else if (action === 'add') {
      params.append('doctorId', doctorId);
      params.append('date', fullDate);
      params.append('periodType', periodType);
      if (selectedRoomId.value) {
          params.append('roomId', selectedRoomId.value);
      }
      res = await axios.post(`doctor/schedule/add?${params.toString()}`);
    } else if (action === 'exchange') {
      // 换班
      if (!exchangeData.value.targetDoctorId) {
          alert("请完善换班信息");
          return;
      }
      params.append('fromDoctorId', doctorId);
      params.append('fromDate', fullDate);
      params.append('fromPeriodType', periodType);
      params.append('toDoctorId', exchangeData.value.targetDoctorId);
      res = await axios.post(`doctor/schedule/exchange?${params.toString()}`);
    }

    if (res && res.data.code === 200) {
      // 成功后刷新数据
      fetchScheduleData();
      dialogVisible.value = false;
      alert(res.data.msg); 
    } else {
      alert("操作失败: " + (res?.data?.msg || "未知错误"));
    }
  } catch (error) {
    console.error("操作出错", error);
    alert("系统错误");
  }
};
</script>

<template>
  <div class="body">
    <!-- 顶部标题和日期切换 -->
    <div class="top">
      <div class="left">
        <span class="s1">我的排班</span>
      </div>
      <div class="right">
        <div class="controls">
          <button class="btn-icon" @click="prevWeek">
            <ArrowLeft />
          </button>
          <span class="current-week">{{ currentWeekText }}</span>
          <button class="btn-icon" @click="nextWeek">
            <ArrowRight />
          </button>
        </div>
      </div>
    </div>

    <!-- 排班表格 -->
    <div class="context">
      <div class="schedule-table">
        <!-- 表头：动态渲染星期和日期 -->
        <div class="table-header">
          <div class="time-slot-header">时段</div>
          <div
              v-for="(day, index) in weekDays"
              :key="index"
              class="day-header"
              :class="{ 'current-day': day.isCurrent }"
          >
            <div class="day-name">{{ day.dayName }}</div>
            <div class="day-date">{{ day.shortDate }}</div>
          </div>
        </div>

        <!-- 表格内容：动态渲染排班数据 -->
        <div class="table-body">
          <div v-for="(slot, slotIndex) in scheduleData" :key="slotIndex" class="time-slot-row">
            <div class="time-slot-cell">{{ slot.timeSlot }}</div>
            <div
                v-for="(day, dayIndex) in slot.days"
                :key="dayIndex"
                class="day-cell"
                :class="{ 'has-duty': day.status === '值班' }"
                @click="handleCellClick(slotIndex, dayIndex as number)"
            >
              <div v-if="day.status === '值班'" class="duty-content">
                <el-icon class="duty-icon"><Check /></el-icon>
                <div class="duty-text">值班</div>
                <div class="room-info" v-if="day.room">诊室 {{ day.room }}</div>
                <div class="room-info" v-else>诊室 302</div> <!-- 默认显示 -->
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="400px"
    >
      <div v-if="selectedInfo" class="dialog-content">
        <div class="info-row">
          <span class="label">日期：</span>
          <span class="value">{{ selectedInfo.fullDate }}</span>
        </div>
        <div class="info-row">
          <span class="label">时段：</span>
          <span class="value">{{ selectedInfo.periodText }}</span>
        </div>

        <!-- 申请排班 -->
        <div v-if="selectedInfo.action === 'add'">
          <div class="form-item">
            <span class="label">选择诊室：</span>
            <el-select v-model="selectedRoomId" placeholder="默认诊室" style="width: 100%">
              <el-option
                v-for="room in rooms"
                :key="room.id"
                :label="room.roomNo"
                :value="room.id"
              />
            </el-select>
          </div>
          <p class="tip">确定要申请该时段的排班吗？</p>
        </div>

        <!-- 已有排班的管理 -->
        <div v-else>
          <el-radio-group v-model="selectedInfo.action" style="margin-bottom: 20px">
            <el-radio-button label="leave">申请请假</el-radio-button>
            <el-radio-button label="exchange">申请换班</el-radio-button>
          </el-radio-group>

          <div v-if="selectedInfo.action === 'leave'">
            <p class="warning-text">确定要申请请假吗？该时段的所有排班将被取消。</p>
          </div>

          <div v-if="selectedInfo.action === 'exchange'">
            <div class="form-item">
              <span class="label">目标医生：</span>
              <el-select v-model="exchangeData.targetDoctorId" placeholder="选择同事" style="width: 100%">
                <el-option
                  v-for="doc in colleagues"
                  :key="doc.id"
                  :label="doc.name"
                  :value="doc.id"
                />
              </el-select>
            </div>
          </div>
        </div>

      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="confirmAction">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
/* 保持原有样式，新增以下样式 */
.duty-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  color: #67c23a;
}
.duty-icon {
  font-size: 20px;
  margin-bottom: 4px;
  background-color: #67c23a;
  color: white;
  border-radius: 50%;
  padding: 2px;
}
.duty-text {
  font-weight: bold;
  font-size: 14px;
}
.room-info {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.day-cell.has-duty {
  background-color: #f0f9eb; /* 浅绿色背景 */
}
.day-cell:hover {
  background-color: #e1f3d8 !important;
}

.table-header {
  background-color: #f5f7fa;
}
.current-day {
  background-color: #e6f7ff; /* 当前日期高亮 */
  color: #1890ff;
}

.form-item {
  margin-bottom: 15px;
}
.form-item .label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}
.tip {
  color: #606266;
}
.warning-text {
  color: #f56c6c;
}
.info-row {
  margin-bottom: 10px;
  display: flex;
  justify-content: space-between;
}
</style>

<style scoped>
/* 全局安全区域适配 */
:root {
  --safe-area-inset-bottom: env(safe-area-inset-bottom);
  --primary-color: #e6f7f0;
  --current-day-bg: #e6f3ff;
  --text-color: #333;
  --light-text: #999;
  --border-color: #EEEFF0; /* 核心修改：将边框颜色改为#EEEFF0 */
  --border-width: 1px; /* 统一边框宽度 */
  --border-style: solid; /* 统一边框样式 */
}

.body {
  width: 100%;
  height: 100vh;
  min-height: -webkit-fill-available;
  background-color: #f5f7fa;
  margin: 0;
  padding: 0 0 var(--safe-area-inset-bottom) 0;
  overflow: hidden;
  box-sizing: border-box;
}

/* 顶部区域 */
.top {
  height: 80px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  box-sizing: border-box;
  background-color: #F1F4F7;
  border-bottom: var(--border-width) var(--border-style) var(--border-color);
}

.top .left .s1 {
  font-size: 24px;
  font-weight: 600;
  color: var(--text-color);
}

.top .right {
  height: 48px;
  display: flex;
  align-items: center;
  background-color: #fff;
  border-radius: 8px;
  padding: 0 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  border: var(--border-width) var(--border-style) var(--border-color);
}

.controls {
  display: flex;
  align-items: center;
  gap: 16px;
}

.btn-icon {
  width: 32px;
  height: 32px;
  border: var(--border-width) var(--border-style) var(--border-color);
  background: #f5f7fa;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-icon:hover {
  background: #e8e8e8;
}

.current-week {
  font-size: 14px;
  color: var(--text-color);
  font-weight: 500;
}

/* 主体内容 */
.context {
  height: calc(100vh - 100px - var(--safe-area-inset-bottom));
  width: 100%;
  padding: 24px;
  box-sizing: border-box;
  overflow-y: auto;
}

.schedule-table {
  width: 100%;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  overflow: hidden;
}

.table-header {
  display: flex;
  background: #fafafa;
}

.time-slot-header {
  width: 160px;
  padding: 16px;
  font-size: 14px;
  font-weight: 500;
  color: var(--text-color);
  display: flex;
  align-items: center;
  justify-content: center;
}

.day-header {
  flex: 1;
  padding: 16px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  border: #EEEFF0 1px solid;
}

.day-header:last-child {
  border-right: none;
}

.day-header.current-day {
  background-color: var(--current-day-bg);
  color: #1890ff;
}

.day-name {
  font-size: 14px;
  font-weight: 500;
}

.day-date {
  font-size: 12px;
  color: var(--light-text);
}

/* 表格内容 */
.table-body {
  width: 100%;
}

.time-slot-row {
  display: flex;
}

.time-slot-row:last-child {
  border-bottom: none;
}

.time-slot-cell {
  width: 160px;
  padding: 24px 16px;
  font-size: 14px;
  color: var(--text-color);
  display: flex;
  align-items: center;
  justify-content: center;
  border: #EEEFF0 1px solid;
  background: #fafafa;
}

.day-cell {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px;
  border-left: var(--border-width) var(--border-style) var(--border-color);
  min-height: 80px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.day-cell:hover {
  background-color: #f0f9ff;
}

.day-cell:first-child {
  border-left: var(--border-width) var(--border-style) var(--border-color);
}

.day-cell:last-child {
  border-right: none;
}

.day-cell.on-duty {
  background-color: var(--primary-color);
}

.duty-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  color: #52c41a;
}

.check-icon {
  font-size: 20px;
}

.duty-text {
  font-size: 14px;
  font-weight: 500;
}

.room-text {
  font-size: 12px;
}
</style>