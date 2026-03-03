<script lang="ts" setup>
import {onMounted, ref} from "vue";
import axios from "axios";

//分页
const searchKey=ref('')
const pageSize=ref(10) //每页显示的条数
const page=ref({pageNum:1,pageSize:10,list:[],total:0}) //分页对象
const form=ref({
  id:-1,
  username:'',
  password:'',
  nickname:'',
  avatar:'',
  gender:0,
  phone:'',
  birth:'',
  intro:'',
  createdAt:''
})

const doctorForm=ref() //引用el-form组件
const formLabelWidth=ref('100px') //表单左列的宽度


const resetForm = () => {
  form.value = {
    id:-1,
    username:'',
    password:'',
    nickname:'',
    avatar:'',
    gender:0,
    phone:'',
    birth:'',
    intro:'',
    createdAt:''
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
  username:'',
  password:'',
  nickname:'',
  avatar:'',
  gender:0,
  phone:'',
  birth:'',
  intro:'',
  createdAt:''
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
      axios.post("user/save",form.value).then(res=>{
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
  axios.post("user/del/"+id).then(res=>{
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

  paging(1)
})

const paging = (pageNum:number) => {
  axios.get("user/list?username="+searchKey.value+"&pageNum="+pageNum+"&pageSize="+pageSize.value).then(res=>{
    page.value=res.data
  })
}


</script>
<template>
  <div class="body">
    <div class="top">
      <div class="left">
        <span class="s1">用户管理/用户列表</span>
        <div class="search-box">
          <input type="search" class="search" placeholder="请输入用户名称" v-model="searchKey">
          <el-button type="primary" @click="paging(1)">查询</el-button>
        </div>
      </div>
      <div class="right" @click="add()">
        <span>+ 新增用户</span>
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
          prop="username"
          label="账号">
      </el-table-column>
      <el-table-column
          prop="password"
          label="密码">
      </el-table-column>
      <el-table-column
          prop="nickname"
          label="昵称">
      </el-table-column>
      <el-table-column
          prop="gender"
          label="性别">
        <template v-slot="scope">
          {{scope.row.gender==0?'男':(scope.row.gender==1?'女':'未知')}}
        </template>
      </el-table-column>
      <el-table-column
          prop="avatar"
          label="头像">
        <template v-slot="scope">
          <img :src="scope.row.avatar" alt="用户头像" style="width: 40px; height: 40px; border-radius: 50%;">
        </template>
      </el-table-column>
      <el-table-column
          prop="createdAt"
          label="注册时间">
        <template v-slot="scope">
          {{scope.row.createdAt.split('T')[0]}}
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
    <el-dialog title="用户信息" v-model="dialogFormVisible" :before-close="clear">
      <el-form :model="form" ref="doctorForm">
        <el-form-item label="用户账号" :label-width="formLabelWidth" prop="username">
          <el-input v-model="form.username" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="用户密码" :label-width="formLabelWidth" prop="password">
          <el-input v-model="form.password" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="用户昵称" :label-width="formLabelWidth" prop="nickname">
          <el-input v-model="form.nickname" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="用户性别" :label-width="formLabelWidth" prop="gender">
          <el-radio-group v-model="form.gender">
            <el-radio label="0">男</el-radio>
            <el-radio label="1">女</el-radio>
            <el-radio label="2">未知</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="用户注册时间" :label-width="formLabelWidth" prop="gender">
          <el-date-picker
              v-model="form.createdAt"
              type="datetime"
              value-format="yyyy-MM-dd"
              placeholder="选择注册时间"
          />
        </el-form-item>
        <el-form-item label="用户头像" :label-width="formLabelWidth" prop="title">
          <img :src="detailForm.avatar" alt="用户头像" style="width: 40px; height: 40px; border-radius: 50%;">
        </el-form-item>
        <el-form-item label="手机号" :label-width="formLabelWidth" prop="phone">
          <el-input v-model="form.phone" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="生日" :label-width="formLabelWidth" prop="isReserve">
          <el-date-picker
            v-model="form.birth"
            type="date"
            value-format="yyyy-MM-dd"
            placeholder="选择生日"
          />
        </el-form-item>
        <el-form-item label="简介" :label-width="formLabelWidth" prop="introduction">
          <el-input v-model="form.intro" auto-complete="off"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="clear">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>
    <!--用户详情对话框 -->
    <el-dialog
        title="用户详情"
        v-model="detailDialogVisible"
        width="600px"
        :before-close="closeDetail"
        destroy-on-close
    >
      <el-form :model="detailForm" label-width="120px" disabled> <!-- disabled让表单只读 -->
        <el-row :gutter="20">
          <!-- 左列 -->
          <el-col :span="10">
            <el-form-item label="用户账号">
              <span>{{detailForm.username}}</span>
            </el-form-item>
            <el-form-item label="用户密码">
              <span>{{detailForm.password}}</span>
            </el-form-item>
            <el-form-item label="用户昵称">
              <span>{{detailForm.nickname}}</span>
            </el-form-item>
            <el-form-item label="用户性别">
              <span>{{ detailForm.gender == 0 ? '男' : (detailForm.gender == 1 ? '女' : '未知') }}</span>
            </el-form-item>
            <el-form-item label="用户注册时间">
              <span>{{detailForm.createdAt}}</span>
            </el-form-item>
          </el-col>
          <!-- 右列 -->
          <el-col :span="14">
            <el-form-item label="头像">
              <img :src="detailForm.avatar" alt="用户头像" style="width: 40px; height: 40px; border-radius: 50%;">
            </el-form-item>
            <el-form-item label="手机号">
              <span>{{detailForm.phone}}</span>
            </el-form-item>
            <el-form-item label="出生日期">
              <span>{{detailForm.birth}}</span>
            </el-form-item>
            <el-form-item label="简介">
              <span>{{detailForm.intro}}</span>
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