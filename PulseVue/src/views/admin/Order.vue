<script lang="ts" setup>
import { onMounted, ref } from "vue";
import axios from "axios";

// 1. 定义订单状态枚举（映射英文状态码和中文显示名）
const orderStatusOptions = [
  { value: "", label: "所有状态" }, // 空值表示不筛选
  { value: "pending", label: "待付款" },
  { value: "paid", label: "已付款" },
  { value: "cancelled", label: "已取消" },
  { value: "completed", label: "已完成" },
];

// 分页 & 筛选
const searchKey = ref(""); // 订单号搜索
const pageSize = ref(8); // 每页条数
const selectedStatus = ref(""); // 选中的状态（默认所有）
const page = ref({
  pageNum: 1,
  pageSize: 10,
  list: [],
  total: 0,
}); // 分页对象
const dropdownVisible = ref(false); // 下拉面板显隐

// 每页条数改变
const handleSizeChange = (ps: number) => {
  pageSize.value = ps;
  paging(1);
};

// 切换选中状态
const selectStatus = (status: string) => {
  selectedStatus.value = status;
  dropdownVisible.value = false; // 选中后关闭下拉
  paging(1); // 重新分页查询
};

onMounted(() => {
  paging(1);
});

// 分页查询（新增status筛选参数）
const paging = (pageNum: number) => {

  axios.get("order/page?status=" + selectedStatus.value+"&id=" + searchKey.value+"&pageNum=" + pageNum+"&pageSize=" + pageSize.value).then((res) => {
    page.value = res.data;
  });
};

// 点击空白处关闭下拉面板（可选优化）
const closeDropdown = () => {
  dropdownVisible.value = false;
};

const payOrder=(id:string) => {
  window.location.href = `http://192.168.140.198:8080/alipay/pay?orderId=${id}`;
}



// 详情弹窗相关
const detailVisible = ref(false);
const detailData = ref<any>({});

const showDetail = (id: string) => {
  axios.get(`order/detail/${id}`).then((res) => {
    if (res.data.code === 200) {
      detailData.value = res.data.data;
      detailVisible.value = true;
    } else {
      alert(res.data.msg || "获取详情失败");
    }
  });
};
</script>

<template>
  <div class="body" @click="closeDropdown">
    <div class="top">
      <div class="left">
        <span class="s1">订单管理/交易记录</span>
        <div class="search-box">
          <input
              type="search"
              class="search"
              placeholder="请输入订单号"
              v-model="searchKey"
          />
          <el-button type="primary" @click="paging(1)">查询</el-button>
        </div>
      </div>

      <!-- 2. 下拉筛选：所有状态 -->
      <div class="right" @click.stop="dropdownVisible = !dropdownVisible">
        <span>{{ orderStatusOptions.find(item => item.value === selectedStatus)?.label }}</span>
        <i class="el-icon-arrow-down" style="margin-left: 5px"></i>

        <!-- 下拉面板 -->
        <div class="status-dropdown" v-show="dropdownVisible">
          <div
              class="status-item"
              v-for="item in orderStatusOptions"
              :key="item.value"
              @click="selectStatus(item.value)"
              :class="{ active: selectedStatus === item.value }"
          >
            {{ item.label }}
          </div>
        </div>
      </div>
    </div>

    <el-table :data="page.list" style="width: 100%">
      <el-table-column prop="id" label="订单号" width="300px"></el-table-column>
      <el-table-column prop="name" label="用户昵称"></el-table-column>
      <el-table-column prop="price" label="金额"></el-table-column>
      <el-table-column prop="payMethod" label="支付方式"></el-table-column>
      <el-table-column prop="createTime" label="创建时间"></el-table-column>
      <el-table-column prop="status" label="状态">
        <!-- 状态中文显示优化（可选） -->
        <template v-slot="scope">
          {{ orderStatusOptions.find(item => item.value === scope.row.status)?.label || scope.row.status }}
        </template>
      </el-table-column>
      <el-table-column
          header-align="center"
          align="center"
          label="操作"
          width="250px"
      >
        <template v-slot="scope">
          <el-button type="danger" size="small" @click="payOrder(scope.row.id)">支付</el-button>
          <el-button type="warning" size="small" @click="showDetail(scope.row.id)">查看详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
        @size-change="handleSizeChange"
        @current-change="paging"
        :current-page="page.pageNum"
        :page-sizes="[4, 6, 8]"
        :page-size="page.pageSize"
        layout="total, sizes, prev, pager, next, jumper"
        :total="page.total"
    ></el-pagination>

    <!-- 详情弹窗 -->
    <el-dialog title="订单详情" v-model="detailVisible" width="60%">
      <div v-if="detailData.id" class="detail-content">
        <div class="info-row">
          <div class="info-item"><strong>订单号：</strong>{{ detailData.id }}</div>
          <div class="info-item"><strong>下单时间：</strong>{{ new Date(detailData.createTime).toLocaleString() }}</div>
        </div>
        <div class="info-row">
           <div class="info-item"><strong>状态：</strong>
             <el-tag :type="detailData.status === 'paid' ? 'success' : detailData.status === 'pending' ? 'warning' : 'info'">
               {{ orderStatusOptions.find(item => item.value === detailData.status)?.label || detailData.status }}
             </el-tag>
           </div>
           <div class="info-item"><strong>支付方式：</strong>{{ detailData.payMethod }}</div>
        </div>
        <div class="info-row">
          <div class="info-item"><strong>总金额：</strong><span style="color: red; font-weight: bold;">¥{{ detailData.totalAmount }}</span></div>
        </div>

        <el-divider content-position="left">商品清单</el-divider>
        
        <el-table :data="detailData.items" border stripe style="width: 100%;">
          <el-table-column label="商品图片" width="100" align="center">
            <template #default="scope">
              <el-image 
                :src="scope.row.image" 
                style="width: 60px; height: 60px; border-radius: 4px;" 
                :preview-src-list="[scope.row.image]"
                fit="cover">
              </el-image>
            </template>
          </el-table-column>
          <el-table-column prop="name" label="商品名称"></el-table-column>
          <el-table-column prop="price" label="单价" width="120" align="center">
             <template #default="scope">¥{{ scope.row.price }}</template>
          </el-table-column>
          <el-table-column prop="quantity" label="数量" width="100" align="center"></el-table-column>
          <el-table-column label="小计" width="120" align="center">
            <template #default="scope">
              <span style="color: red;">¥{{ (scope.row.price * scope.row.quantity).toFixed(2) }}</span>
            </template>
          </el-table-column>
        </el-table>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="detailVisible = false">关闭</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.body {
  width: 100%;
  height: calc(100%);
  background-color: #EBEFF6;
  margin: 0;
  padding: 0;
  padding: 20px; /* 新增内边距，避免内容贴边 */
  box-sizing: border-box;
}

.top {
  height: 100px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.top .left {
  height: 100%;
  width: 300px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-around;
}

.top .left .s1 {
  font-size: 15px;
  color: #333333;
  margin-left: -35%;
}

.top .left .search-box {
  display: flex;
  flex-direction: row;
  height: 40px; /* 固定搜索框高度 */
  width: 100%;
}

.top .left .search {
  height: 100%;
  width: 80%;
  border-radius: 5px 0 0 5px; /* 优化圆角 */
  border: 1px solid #e6e6e6;
  padding-left: 10px;
  outline: none;
}

.top .left .search-box .el-button {
  border-radius: 0 5px 5px 0; /* 按钮圆角匹配 */
  height: 100%;
  width: 20%;
}

/* 下拉筛选样式 */
.top .right {
  height: 50px;
  width: 150px; /* 固定宽度，避免变形 */
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  background-color: #FCFDFE;
  margin-top: 10px;
  margin-right: 20px;
  border-radius: 20px;
  cursor: pointer;
  position: relative; /* 相对定位，用于下拉面板绝对定位 */
  border: 1px solid #e6e6e6;
}

/* 下拉面板样式 */
.status-dropdown {
  position: absolute;
  top: 60px; /* 位于按钮下方 */
  left: 0;
  width: 100%;
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  padding: 10px 0;
  z-index: 999; /* 置顶显示 */
}

/* 状态选项样式 */
.status-item {
  height: 40px;
  line-height: 40px;
  padding: 0 20px;
  cursor: pointer;
}

.status-item:hover {
  background-color: #f5f7fa;
}

/* 选中状态样式 */
.status-item.active {
  color: #409eff;
  font-weight: bold;
}

/* 表格样式优化 */
.el-table {
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
}

/* 分页样式 */
.el-pagination {
  margin-top: 20px;
  text-align: right;
}

/* 详情弹窗样式 */
.detail-content {
  padding: 0 10px;
}
.info-row {
  display: flex;
  margin-bottom: 15px;
}
.info-item {
  flex: 1;
  font-size: 14px;
}
</style>