<script setup lang="ts">
import { onMounted, onUnmounted, ref } from "vue";
import axios from "axios";
import router from "@/router";

const themeColor = ref<string>("#4B90E0");
const defaultOrderStatus = ref<string>("");

const doctorTotal = ref<number>(0);
const medicineTotal = ref<number>(0);
const orderTotal = ref<number>(0);
const registrationTotal = ref<number>(0);

const pendingCount = ref<number>(0);
const paidCount = ref<number>(0);
const cancelledCount = ref<number>(0);
const completedCount = ref<number>(0);

const recentOrders = ref<Array<any>>([]);
const recentRegs = ref<Array<any>>([]);

const announcement = ref<{ show: boolean; title: string; content: string }>({
  show: false,
  title: "",
  content: "",
});

const refreshMs = ref<number>(30000);
let timer: number | undefined;

const loadSettings = () => {

    const annStr = localStorage.getItem("systemAnnouncement");
    if (annStr) {
      const ann = JSON.parse(annStr);
      announcement.value = {
        show: !!ann.show,
        title: ann.title || "",
        content: ann.content || "",
      };
    }
    const msStr = localStorage.getItem("dashboardRefreshMs");
    if (msStr) {
      const n = parseInt(msStr);
      if (!Number.isNaN(n) && n >= 5000) {
        refreshMs.value = n;
      }
    }
    const statusStr = localStorage.getItem("defaultOrderStatus");
    if (statusStr !== null) {
      defaultOrderStatus.value = statusStr;
    }
    const colorStr = localStorage.getItem("themeColor");
    if (colorStr) {
      themeColor.value = colorStr;
    }
    document.documentElement.style.setProperty("--brand-color", themeColor.value);

};

const fetchMetrics = async () => {
  try {
            const results = await Promise.allSettled([
              axios.get("doctor/page?name=&pageNum=1&pageSize=1"),
              axios.get("medicine/list?name=&pageNum=1&pageSize=1"),
              axios.get("order/page?status=pending&pageNum=1&pageSize=100"),
              axios.get("order/page?status=paid&pageNum=1&pageSize=100"),
              axios.get("order/page?status=cancelled&pageNum=1&pageSize=100"),
              axios.get("order/page?status=completed&pageNum=1&pageSize=100"),

              axios.get("order/page?status=&id=&pageNum=1&pageSize=100"),
              axios.get("registrationRecord/list?pageNum=1&pageSize=100"),
            ]);

            const getVal = (res: any) => 
              res.status === 'fulfilled' ? res.value : null;

            const doctorRes = getVal(results[0]);
            const medRes = getVal(results[1]);
            const pendingRes = getVal(results[2]);
            const paidRes = getVal(results[3]);
            const cancelledRes = getVal(results[4]);
            const completedRes = getVal(results[5]);
            const orderAllRes = getVal(results[6]);
            const regAllRes = getVal(results[7]);

            doctorTotal.value = doctorRes?.data?.total ?? 0;
            medicineTotal.value = medRes?.data?.total ?? 0;
            

            orderTotal.value = orderAllRes?.data?.total ?? 0;
            registrationTotal.value = regAllRes?.data?.total ?? 0;

            pendingCount.value = pendingRes?.data?.total ?? 0;
            paidCount.value = paidRes?.data?.total ?? 0;
            cancelledCount.value = cancelledRes?.data?.total ?? 0;
            completedCount.value = completedRes?.data?.total ?? 0;


            const allOrders = orderAllRes?.data?.list ?? [];
            const allRegs = regAllRes?.data?.list ?? [];
            
            recentOrders.value = allOrders.slice(-5).reverse();
            recentRegs.value = allRegs.slice(-5).reverse();
          } catch (e) {

  }
};

const startAutoRefresh = () => {
  stopAutoRefresh();
  timer = window.setInterval(fetchMetrics, refreshMs.value);
};
const stopAutoRefresh = () => {
  if (timer) {
    clearInterval(timer);
    timer = undefined;
  }
};

const go = (path: string) => {
  router.push(path);
};

// 简易 SVG 折线图与柱状图数据处理
const chartWidth = 400;
const chartHeight = 120;
const getOrderAmountLinePoints = () => {
  const data = (recentOrders.value || []).map((o: any) => Number(o.price) || 0);
  if (data.length === 0) return "";
  const maxY = Math.max(...data, 1);
  const stepX = chartWidth / Math.max(data.length - 1, 1);
  return data
    .map((v, i) => {
      const x = i * stepX;
      const y = chartHeight - (v / maxY) * chartHeight;
      return `${x},${y}`;
    })
    .join(" ");
};
const getStatusBars = () => {
  const values = [
    { label: "待付款", value: pendingCount.value, color: "#E6A23C" },
    { label: "已付款", value: paidCount.value, color: "#67C23A" },
    { label: "已完成", value: completedCount.value, color: "#909399" },
    { label: "已取消", value: cancelledCount.value, color: "#F56C6C" },
  ];
  const maxV = Math.max(...values.map(v => v.value), 1);
  return { values, maxV };
};

onMounted(async () => {
  loadSettings();
  await fetchMetrics();
  startAutoRefresh();
});
onUnmounted(() => {
  stopAutoRefresh();
});

</script>

<template>
  <div class="body">
    <div class="top">
      <div class="left">
        <span class="s1">首页/概览</span>
      </div>
      <div class="right"></div>
    </div>

    <!-- 管理端首页不再展示系统公告，公告入口移至医生端 -->

    <el-row :gutter="20" class="kpi-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="kpi-card" @click="go('/admin/doctor')" shadow="hover">
          <div class="kpi-title">医生总数</div>
          <div class="kpi-value">{{ doctorTotal }}</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="kpi-card" @click="go('/admin/medicine')" shadow="hover">
          <div class="kpi-title">药品总数</div>
          <div class="kpi-value">{{ medicineTotal }}</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="kpi-card" @click="go('/admin/order')" shadow="hover">
          <div class="kpi-title">订单总数</div>
          <div class="kpi-value">{{ orderTotal }}</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="kpi-card" @click="go('/admin/register')" shadow="hover">
          <div class="kpi-title">挂号总数</div>
          <div class="kpi-value">{{ registrationTotal }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="status-row">
      <el-col :xs="24" :md="12">
        <el-card>
          <div class="section-title">订单状态分布</div>
          <div class="status-grid">
            <div class="status-item">
              <el-tag type="warning">待付款</el-tag>
              <span class="status-num">{{ pendingCount }}</span>
            </div>
            <div class="status-item">
              <el-tag type="success">已付款</el-tag>
              <span class="status-num">{{ paidCount }}</span>
            </div>
            <div class="status-item">
              <el-tag type="info">已完成</el-tag>
              <span class="status-num">{{ completedCount }}</span>
            </div>
            <div class="status-item">
              <el-tag type="danger">已取消</el-tag>
              <span class="status-num">{{ cancelledCount }}</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :md="12">
        <el-card>
          <div class="section-title">快捷入口</div>
          <div class="quick-grid">
            <div class="quick-item" @click="go('/admin/register')">挂号管理</div>
            <div class="quick-item" @click="go('/admin/doctor')">医生管理</div>
            <div class="quick-item" @click="go('/admin/medicine')">药品管理</div>
            <div class="quick-item" @click="go('/admin/order')">订单管理</div>
            <div class="quick-item" @click="go('/admin/setting')">系统设置</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="list-row">
      <el-col :xs="24" :md="12">
        <el-card>
          <div class="section-title">最近订单</div>
          <el-table :data="recentOrders" size="small" style="width: 100%">
            <el-table-column prop="id" label="订单号" width="220" />
            <el-table-column prop="name" label="用户" />
            <el-table-column prop="price" label="金额" />
            <el-table-column prop="status" label="状态" />
          </el-table>
          <div class="section-title" style="margin-top:12px;">订单金额折线图</div>
          <svg :width="chartWidth" :height="chartHeight" class="chart">
            <polyline
              :points="getOrderAmountLinePoints()"
              fill="none"
              :stroke="themeColor"
              stroke-width="2"
            />
          </svg>
        </el-card>
      </el-col>
      <el-col :xs="24" :md="12">
        <el-card>
          <div class="section-title">最近挂号</div>
          <el-table :data="recentRegs" size="small" style="width: 100%">
            <el-table-column prop="regNo" label="单号" width="120" />
            <el-table-column prop="name" label="患者姓名" />
            <el-table-column prop="department" label="科室" />
            <el-table-column prop="createTime" label="时间" />
          </el-table>
          <div class="section-title" style="margin-top:12px;">订单状态柱状图</div>
          <svg :width="chartWidth" :height="chartHeight" class="chart">
            <g v-for="(item, idx) in getStatusBars().values" :key="item.label">
              <rect
                :x="idx * (chartWidth / 4) + 20"
                :y="chartHeight - (item.value / getStatusBars().maxV) * chartHeight"
                :width="(chartWidth / 4) - 40"
                :height="(item.value / getStatusBars().maxV) * chartHeight"
                :fill="item.color"
                rx="4"
              />
              <text
                :x="idx * (chartWidth / 4) + (chartWidth / 8)"
                :y="chartHeight - 6"
                text-anchor="middle"
                font-size="12"
                fill="#666"
              >
                {{ item.label }}
              </text>
            </g>
          </svg>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped>
.body {
  width: 100%;
  height: calc(100vh - 60px);
  overflow-y: auto;
  background-color: #EBEFF6;
  margin: 0;
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

:root {
  --brand-color: #4B90E0;
}
.kpi-row,
.status-row,
.list-row {
  margin-bottom: 16px;
}
.kpi-card {
  cursor: pointer;
  text-align: center;
}
.kpi-title {
  color: #666;
  font-size: 14px;
}
.kpi-value {
  font-size: 28px;
  font-weight: bold;
  color: #333;
  margin-top: 6px;
}
.section-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 12px;
  color: #333;
}
.status-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.status-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border: 1px solid #eef2f7;
  border-radius: 8px;
  padding: 8px 12px;
  background-color: #fff;
}
.status-num {
  font-weight: bold;
  color: #333;
}
.quick-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
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
.chart {
  width: 100%;
  background: #fff;
  border: 1px solid #eef2f7;
  border-radius: 8px;
}
</style>

