<script lang="ts" setup>
import {onMounted, ref} from "vue";
import axios from "axios";

//分页
const searchKey=ref('')
const pageSize=ref(8) //每页显示的条数
const page=ref({pageNum:1,pageSize:10,list:[],total:0}) //分页对象
const form=ref({
  id:-1,
  name:'',
  department:'',
  title:'',
  specialty:'',
  isReserve:0,
  price:0,
  image:'',
  hospital:'',
  experience:'',
  consultationCount:0,
  education:''

})

const doctorForm=ref() //引用el-form组件
const formLabelWidth=ref('100px') //表单左列的宽度
const departmentList=ref([
  {
    id:0,
    name:'全部'
  }
])

const resetForm = () => {
  form.value = {
    id:-1,
    name:'',
    department:'',
    title:'',
    specialty:'',
    isReserve:0,
    price:0,
    image:'',
    hospital:'',
    experience:'',
    consultationCount:0,
    education:''
  };

  // 重置表单验证
  if (doctorForm.value) {
    doctorForm.value.clearValidate()
  }
}

//查看详情
// 新增：详情对话框相关
const detailDialogVisible=ref(false) // 详情对话框显示状态
const detailForm=ref({
  id:-1,
  name:'',
  department:'',
  title:'',
  specialty:'',
  isReserve:0,
  price:0,
  image:'',
  hospital:'',
  experience:'',
  consultationCount:0,
  education:''
})
const closeDetail = () => {
  detailDialogVisible.value = false;
  // 清空详情数据
  resetForm()
}
const showDetail = (row:any) => {
  detailForm.value = {...row};
  detailDialogVisible.value = true;
}






const dialogFormVisible=ref(false) //不显示对话框

//增
const add = () => {
  resetForm()
  dialogFormVisible.value=true

}
//改
const update = (row:any) => {
  form.value=row
  dialogFormVisible.value=true
}
//保存
const save = () => {
  doctorForm.value.validate((valid:boolean)=>{
    if(valid){
      axios.post("doctor/save",form.value).then(res=>{
        alert(res.data.msg)
        if(res.data.code==200){
          dialogFormVisible.value=false
          paging(1)
        }
      })
    }
  })
}
//删
const del = (id:number) => {
  if(!confirm("确定删除吗？")){
    return
  }
  axios.post("doctor/del/"+id).then(res=>{
    alert(res.data.msg)
    if(res.data.code==200){
      paging(1)
    }
  })
}

const clear = () => {
  dialogFormVisible.value=false
  resetForm()
  paging(1)
}
const handleSizeChange = (ps:number) => {
  pageSize.value=ps
  paging(1)
}
onMounted(()=>{

  axios.get("department/list").then(res=>{
    departmentList.value=res.data
  })
  paging(1)
})

const paging = (pageNum:number) => {
  axios.get("doctor/page?name="+searchKey.value+"&pageNum="+pageNum+"&pageSize="+pageSize.value).then(res=>{
    page.value=res.data
  })
}


</script>
<template>
  <div class="body">
    <div class="top">
      <div class="left">
        <span class="s1">医生管理/医生列表</span>
        <div class="search-box">
          <input type="search" class="search" placeholder="请输入医生名称" v-model="searchKey">
          <el-button type="primary" @click="paging(1)">查询</el-button>
        </div>
      </div>
      <div class="right" @click="add()">
        <span>+ 新增医生</span>
      </div>
    </div>
    <el-table
        :data="page.list"
        style="width: 100%">
      <el-table-column
          prop="id"
          label="序号">
      </el-table-column>
      <el-table-column
          prop="name"
          label="医生信息">
      </el-table-column>
      <el-table-column
          prop="department"
          label="科室">
      </el-table-column>
      <el-table-column
          prop="title"
          label="职称">
      </el-table-column>
      <el-table-column
          prop="specialty"
          label="专长">
      </el-table-column>
      <el-table-column
          prop="isServe"
          label="状态">
        <template v-slot="scope">
          {{scope.row.isServe==0?'休息':'在职'}}
        </template>
      </el-table-column>
      <el-table-column
          header-align="center"
          align="center"
          label="操作"
          width="250px">
        <template v-slot="scope">
          <el-button type="warning" @click="showDetail(scope.row)">详</el-button>
          <el-button type="primary" @click="update(scope.row)">改</el-button>
          <el-button type="danger" @click="del(scope.row.id)">删</el-button>
        </template>
      </el-table-column>

    </el-table>

    <el-pagination
        @size-change="handleSizeChange"
        @current-change="paging"
        :current-page="page.pageNum"
        :page-sizes="[6, 8,10]"
        :page-size="page.pageSize"
        layout="total, sizes, prev, pager, next, jumper"
        :total="page.total">
    </el-pagination>
    <el-dialog title="医生信息" v-model="dialogFormVisible" :before-close="clear">
      <el-form :model="form" ref="doctorForm">
        <el-form-item label="医生姓名" :label-width="formLabelWidth" prop="name">
          <el-input v-model="form.name" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="科室" :label-width="formLabelWidth" prop="departmentId">
          <el-select v-model="form.department" placeholder="请选择科室">
            <el-option v-for="item in departmentList" :key="item.id" :label="item.name" :value="item.name"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="职称" :label-width="formLabelWidth" prop="title">
          <el-radio-group v-model="form.title">
            <el-radio label="主任医师">主任医师</el-radio>
            <el-radio label="副主任医师">副主任医师</el-radio>
            <el-radio label="主治医师">主治医师</el-radio>
            <el-radio label="医师">医师</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="专长" :label-width="formLabelWidth" prop="specialty">
          <el-input v-model="form.specialty" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="挂号费" :label-width="formLabelWidth" prop="price">
          <el-input v-model="form.price" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="头像" :label-width="formLabelWidth" prop="image">
          <el-input v-model="form.image" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="就职医院" :label-width="formLabelWidth" prop="hospital">
          <el-input v-model="form.hospital" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="从业年限" :label-width="formLabelWidth" prop="experience">
          <el-input v-model="form.experience" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="问诊次数" :label-width="formLabelWidth" prop="consultationCount">
          <el-input v-model="form.consultationCount" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="教育背景" :label-width="formLabelWidth" prop="education">
          <el-input v-model="form.education" auto-complete="off"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="clear">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>
    <el-dialog
        title="医生详情"
        v-model="detailDialogVisible"
        width="600px"
        :before-close="closeDetail"
        destroy-on-close
    >
      <el-form :model="detailForm" label-width="120px" disabled> <!-- disabled让表单只读 -->
        <el-row :gutter="20">
          <!-- 左列 -->
          <el-col :span="10">
            <el-form-item label="医生姓名">
              <span>{{detailForm.name}}</span>
            </el-form-item>
            <el-form-item label="科室">
              <span>{{detailForm.department}}</span>
            </el-form-item>
            <el-form-item label="职称">
              <span>{{detailForm.title}}</span>
            </el-form-item>
            <el-form-item label="专长">
              <span>{{detailForm.specialty}}</span>
            </el-form-item>
            <el-form-item label="状态">
              <span>{{ detailForm.isReserve == 0 ? '休息' : '在职' }}</span>
            </el-form-item>
            <el-form-item label="挂号费">
              <span>{{detailForm.price}} 元</span>
            </el-form-item>
          </el-col>
          <!-- 右列 -->
          <el-col :span="14">
            <el-form-item label="头像">
              <span>{{detailForm.image}}</span>
            </el-form-item>
            <el-form-item label="就职医院">
              <span>{{detailForm.hospital}}</span>
            </el-form-item>
            <el-form-item label="从业年限">
              <span>{{detailForm.experience}}</span>
            </el-form-item>
            <el-form-item label="问诊次数">
              <span>{{detailForm.consultationCount}}</span>
            </el-form-item>
            <el-form-item label="教育背景">
              <span>{{detailForm.education}}</span>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="closeDetail">关 闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<style scoped>
.body{
  width: 100%;
  height: calc(100% );
  background-color: #EBEFF6;
  margin: 0;
  padding: 0;
}
.top{
  height: 100px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.top .left{
  height: 100%;
  width: 300px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-around;
}
.top .left .s1{
  font-size: 15px;
  color: #333333;
  margin-left: -35%;
}
.top .left .search{
  height: 100%;
  width: 80%;
  border-radius: 5px;
  border: none;
  padding-left: 10px;
}
.search-box{
  display: flex;
  flex-direction: row;

}
.top .right{
  height: 50%;
  width: 15%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  background-color: #FCFDFE;
  margin-top: 10px;
  margin-right: 20px;
  border-radius: 20px;
  cursor: pointer;
}

.top .right .d1 .s1{
  font-size: 13px;
  color: #333333;
}

.top .right .d2 .s1 {
  font-size: 13px;
  color: #333333;
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
</style>