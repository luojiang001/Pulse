<script lang="ts" setup>
import { onMounted, ref } from "vue";
import axios from "axios";
import type { FormInstance, FormRules } from "element-plus";

//分页
const searchKey = ref('')
const pageSize = ref(10) //每页显示的条数
const page = ref({ pageNum: 1, pageSize: 10, list: [], total: 0 }) //分页对象
const form = ref({
  regNo: 'GH00001',
  name: '默认患者',
  department: '科室',
  doctor: { name: '' },
  scheduleDate: '', // 存储格式化后的日期字符串
  createdAt: '',
  visitStatus: 0,
  payStatus: 0,
  scheduleTime: '',
  amount: 0
}) //表单的数据对象

// 表单引用
const medicineForm = ref<FormInstance>()
const formLabelWidth = ref('100px') //表单左列的宽度

// 表单验证规则（新增日期验证）
const rules = ref<FormRules>({
  scheduleDate: [{ required: true, message: '预约日期不能为空', trigger: 'change' }],
  scheduleTime: [{ required: true, message: '预约时段不能为空', trigger: 'blur' }],
  amount: [{
    required: true,
    message: '挂号费不能为空',
    trigger: 'blur'
  }, {
    type: 'number',
    min: 0.01,
    message: '挂号费必须大于0',
    trigger: 'blur'
  }]
});

// 重置表单
const resetForm = () => {
  form.value = {
    regNo: 'GH00001',
    name: '默认患者',
    department: '科室',
    doctor: { name: '' },
    scheduleDate: '',
    createdAt: '',
    visitStatus: 0,
    payStatus: 0,
    scheduleTime: '',
    amount: 0
  }

  // 重置表单验证
  if (medicineForm.value) {
    medicineForm.value.clearValidate()
  }
}

const departmentList = ref([
  {
    id: 0,
    name: '科室1'
  }
])
const doctorList = ref([
  {
    id: 0,
    name: '医生1'
  }
])

const dialogFormVisible = ref(false)

//改
const update = (row: any) => {
  form.value = { ...row }
  if (!form.value.doctor) {
    form.value.doctor = { name: '' }
  }
  dialogFormVisible.value = true
}

//保存
const save = () => {
  if (!medicineForm.value) return

  medicineForm.value.validate((valid: boolean) => {
    if (valid) {
      axios.post("registrationRecord/save", form.value).then(res => {
        alert(res.data.msg)
        if (res.data.code == 200) {
          dialogFormVisible.value = false
          paging(1)
        }
      }).catch(err => {
        console.error('保存失败:', err)
        alert('保存失败：' + (err.response?.data?.msg || '网络异常'))
      })
    }
  })
}

//删
const del = (regNo: string) => {
  if (!confirm("确定删除吗？")) {
    return
  }
  axios.post('registrationRecord/del/'+regNo).then(res => {
    alert(res.data.msg)
    if (res.data.code == 200) {
      paging(1)
    }
  }).catch(err => {
    console.error('删除失败:', err)
    if (err.response?.status === 404) {
      alert('删除失败：接口不存在，请检查后端接口地址是否正确')
    } else if (err.response?.data?.msg) {
      alert('删除失败：' + err.response.data.msg)
    } else {
      alert('删除失败：网络异常或服务器错误')
    }
  })
}

const clear = () => {
  dialogFormVisible.value = false
  resetForm()
  paging(1)
}

const handleSizeChange = (ps: number) => {
  pageSize.value = ps
  paging(1)
}

onMounted(() => {
  axios.get("department/list").then(res => {
    departmentList.value = res.data
  }).catch(() => {
    console.warn('获取科室列表失败，使用默认数据')
  })

  axios.get("doctor/list").then(res => {
    doctorList.value = res.data
  }).catch(() => {
    console.warn('获取医生列表失败，使用默认数据')
  })

  paging(1)
})

const paging = (pageNum: number) => {
  axios.get(`registrationRecord/list`, {
    params: {
      name: searchKey.value,
      pageNum: pageNum,
      pageSize: pageSize.value
    }
  }).then(res => {
    page.value = res.data
  }).catch(err => {
    console.error('分页查询失败:', err)
    alert('数据加载失败，请刷新重试')
  })
}
const timeSlotOptions = ref([
  { label: '08:00 - 12:00', value: '08:00 - 12:00' },
  { label: '14:00 - 18:00', value: '14:00 - 18:00' },
  { label: '19:00 - 22:00', value: '19:00 - 22:00' }
])

//详情
const detailForm=ref({
  doctorName: '',
  department: '',
  time:'',
  status: '',
  diagnosis: '',
  medicines: []
})
const detailDialogVisible=ref(false) // 详情对话框显示状态
const showDetail = (row:any) => {
  axios.get(`registrationRecord/detail/${row.regNo}`).then(res => {
    if (res.data.code === 200) {
      detailForm.value = res.data.data;
      detailDialogVisible.value = true;
    } else {
      alert(res.data.msg || '获取详情失败');
    }
  }).catch(err => {
    console.error('获取详情失败:', err)
    alert('数据加载失败，请刷新重试')
  })
}
const closeDetail = () => {
  detailDialogVisible.value = false;
  // 清空详情数据
  detailForm.value = {
    doctorName: '',
    department: '',
    time:'',
    status: '',
    diagnosis: '',
    medicines: []
  };
}
</script>

<template>
  <div class="body">
    <div class="top">
      <div class="left">
        <span class="s1">挂号管理/列表</span>
        <div class="search-box">
          <input type="search" class="search" placeholder="请输入患者姓名" v-model="searchKey">
          <el-button type="primary" @click="paging(1)">查询</el-button>
        </div>
      </div>
      <div class="right"></div>
    </div>

    <el-table
        :data="page.list"
        style="width: 100%"
        border
        stripe
    >
      <el-table-column prop="regNo" label="单号" min-width="100" />
      <el-table-column prop="name" label="患者姓名" min-width="100" />
      <el-table-column prop="department" label="科室" min-width="100" />
      <el-table-column prop="doctor" label="医生" min-width="100">
        <template v-slot="scope">
          {{ scope.row.doctor?.name || '-' }}
        </template>
      </el-table-column>
      <el-table-column prop="createTime" label="挂号时间" min-width="180" />
      <el-table-column prop="visitStatus" label="就诊状态" min-width="100">
        <template v-slot="scope">
          {{ scope.row.visitStatus == 0 ? '未就诊' : '已就诊' }}
        </template>
      </el-table-column>
      <el-table-column prop="status" label="支付状态" min-width="100">
        <template v-slot="scope">
          {{ scope.row.status == 0 ? '未支付' : '已支付' }}
        </template>
      </el-table-column>
      <el-table-column
          header-align="center"
          align="center"
          label="操作"
          min-width="120"
      >
        <template v-slot="scope">
          <el-button type="warning" size="small" @click="showDetail(scope.row)">详</el-button>
          <el-button type="primary" size="small" @click="update(scope.row)">改</el-button>
          <el-button type="danger" size="small" @click="del(scope.row.regNo)">删</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
        @size-change="handleSizeChange"
        @current-change="paging"
        :current-page="page.pageNum"
        :page-sizes="[6, 8, 10]"
        :page-size="page.pageSize"
        layout="total, sizes, prev, pager, next, jumper"
        :total="page.total"
        style="margin-top: 20px; text-align: right; padding-right: 20px;"
    >
    </el-pagination>

    <el-dialog title="挂号信息" v-model="dialogFormVisible" :before-close="clear" width="600px">
      <el-form
          :model="form"
          ref="medicineForm"
          :rules="rules"
          label-width="100px"
      >
        <el-form-item label="患者姓名" prop="name">
          <el-text type="info">{{ form.name }}</el-text>
        </el-form-item>

        <el-form-item label="科室" prop="department">
          <el-text type="info">{{ form.department }}</el-text>
        </el-form-item>

        <el-form-item label="医生" prop="doctor">
          <el-text type="info">{{ form.doctor.name }}</el-text>
        </el-form-item>

        <el-form-item label="挂号时间" prop="createTime">
          <el-input v-model="form.createdAt" disabled></el-input>
        </el-form-item>

        <el-form-item label="就诊状态" prop="visitStatus">
          <el-radio-group v-model="form.visitStatus">
            <el-radio :label="0">未就诊</el-radio>
            <el-radio :label="1">已就诊</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="支付状态" prop="payStatus">
          <el-radio-group v-model="form.payStatus">
            <el-radio :label="0">未支付</el-radio>
            <el-radio :label="1">已支付</el-radio>
          </el-radio-group>
        </el-form-item>

        <!-- 核心修改：日期输入框改为日期选择器 -->
        <el-form-item label="预约日期" prop="scheduleDate">
          <el-date-picker
              v-model="form.scheduleDate"
              type="date"
              placeholder="请选择预约日期"
              style="width: 100%;"
              format="YYYY-MM-DD"
              value-format="YYYY-MM-DD"
              :disabled-date="(date:any) => date < new Date(new Date().setHours(0, 0, 0, 0))"
          ></el-date-picker>
        </el-form-item>

        <el-form-item label="预约时段" prop="scheduleTime">
          <el-select
              v-model="form.scheduleTime"
              placeholder="请选择预约时段"
              style="width: 100%;"
          >
            <el-option
                v-for="item in timeSlotOptions"
                :key="item.value"
                :label="item.label"
                :value="item.value"
            ></el-option>
          </el-select>
        </el-form-item>

        <el-form-item label="挂号费" prop="amount">
          <el-input
              v-model.number="form.amount"
              placeholder="请输入挂号费"
              type="number"
              min="0.01"
              step="0.01"
              suffix="元"
          ></el-input>
        </el-form-item>
      </el-form>

      <div slot="footer" class="dialog-footer">
        <el-button @click="clear">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>
    <!--挂号详情对话框 -->
    <el-dialog
        title="处方详情"
        v-model="detailDialogVisible"
        width="800px"
        :before-close="closeDetail"
        destroy-on-close
        class="custom-dialog"
    >
      <div class="detail-container">
        <!-- 基础信息区域 -->
        <div class="info-section">
          <div class="info-item">
            <span class="label">医生姓名：</span>
            <span class="value">{{ detailForm.doctorName }}</span>
          </div>
          <div class="info-item">
            <span class="label">科室：</span>
            <span class="value">{{ detailForm.department }}</span>
          </div>
          <div class="info-item">
            <span class="label">就诊时间：</span>
            <span class="value">{{ detailForm.time }}</span>
          </div>
          <div class="info-item">
            <span class="label">状态：</span>
            <span class="value">
              <el-tag :type="detailForm.status === '已开方' ? 'success' : 'info'">
                {{ detailForm.status }}
              </el-tag>
            </span>
          </div>
        </div>

        <!-- 诊断信息 -->
        <div class="diagnosis-section">
          <span class="label">诊断结果：</span>
          <div class="diagnosis-content">{{ detailForm.diagnosis || '暂无诊断信息' }}</div>
        </div>

        <!-- 药品列表 -->
        <div class="medicine-section">
          <div class="section-title">药品清单</div>
          <el-table :data="detailForm.medicines" border stripe style="width: 100%">
            <el-table-column prop="medicineName" label="药品名称" />
            <el-table-column prop="count" label="数量" width="100" align="center" />
            <el-table-column prop="prescription" label="是否处方药" width="120" align="center">
              <template #default="scope">
                <el-tag :type="scope.row.prescription === 1 ? 'warning' : 'success'" size="small">
                  {{ scope.row.prescription === 1 ? '是' : '否' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button type="primary" @click="closeDetail">关 闭</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.body {
  width: 100%;
  height: calc(100vh - 20px);
  background-color: #EBEFF6;
  margin: 0;
  padding: 10px;
  box-sizing: border-box;
}

.top {
  height: 100px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
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

.top .left .search {
  height: 36px;
  width: 80%;
  border-radius: 5px;
  border: 1px solid #ddd;
  padding-left: 10px;
  outline: none;
}

.search-box {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.top .right {
  height: 50%;
  width: 15%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  margin-top: 10px;
  margin-right: 20px;
  border-radius: 20px;
  cursor: pointer;
}

:deep(.el-dialog__body) {
  padding: 20px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
}

:deep(.el-form-item__content) {
  color: #666;
}

/* 优化日期选择器样式 */
:deep(.el-date-editor) {
  width: 100%;
}

/* 详情弹窗样式 */
.detail-container {
  padding: 10px;
}

.info-section {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
  margin-bottom: 25px;
  background-color: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
}

.info-item {
  display: flex;
  align-items: center;
}

.info-item .label {
  font-weight: bold;
  color: #606266;
  width: 80px;
}

.info-item .value {
  color: #303133;
}

.diagnosis-section {
  margin-bottom: 25px;
  background-color: #fff6f6;
  padding: 15px;
  border-radius: 8px;
  border: 1px dashed #ffcccc;
}

.diagnosis-section .label {
  font-weight: bold;
  color: #f56c6c;
  display: block;
  margin-bottom: 8px;
}

.diagnosis-content {
  color: #303133;
  line-height: 1.6;
}

.medicine-section {
  margin-top: 20px;
}

.section-title {
  font-size: 16px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 15px;
  padding-left: 10px;
  border-left: 4px solid #409eff;
}

:deep(.el-dialog__body) {
  padding: 20px 30px;
}
</style>