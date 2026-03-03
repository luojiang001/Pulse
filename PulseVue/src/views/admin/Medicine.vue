<script lang="ts" setup>
import {onMounted, ref} from "vue";
import axios from "axios";

//分页
const searchKey=ref('')
const pageSize=ref(10) //每页显示的条数
const page=ref({pageNum:1,pageSize:10,list:[],total:0}) //分页对象
const form=ref({id:-1,name:'',categoryId:0,prescription:0,price:0,stock:0,payStatus:0,image:'',manufacturer:'',unit:'',description:'',efficacy:''}) //表单的数据对象

const medicineForm=ref() //引用el-form组件
const formLabelWidth=ref('100px') //表单左列的宽度



//查看详情
// 新增：详情对话框相关
const detailDialogVisible=ref(false) // 详情对话框显示状态
const detailForm=ref({ // 详情数据对象（和表单字段一致）
  id:-1,name:'',categoryId:0,prescription:0,price:0,stock:0,payStatus:0,
  image:'',manufacturer:'',unit:'',description:'',efficacy:''
})
const closeDetail = () => {
  detailDialogVisible.value = false;
  // 清空详情数据
  detailForm.value = {id:-1,name:'',categoryId:0,prescription:0,price:0,stock:0,payStatus:0,image:'',manufacturer:'',unit:'',description:'',efficacy:''};
}
const showDetail = (row:any) => {
  detailForm.value = {...row};
  detailDialogVisible.value = true;
}






const dialogFormVisible=ref(false) //不显示对话框

//增
const add = () => {
  form.value={id:-1,name:'',categoryId:0,prescription:0,price:0,stock:0,payStatus:0,image:'',manufacturer:'',unit:'',description:'',efficacy:''}
  dialogFormVisible.value=true

}
//改
const update = (row:any) => {
  form.value=row
  dialogFormVisible.value=true
}
//保存
const save = () => {
  medicineForm.value.validate((valid:boolean)=>{
    if(valid){
      axios.post("medicine/save",form.value).then(res=>{
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
  axios.post("medicine/del/"+id).then(res=>{
    alert(res.data.msg)
    if(res.data.code==200){
      paging(1)
    }
  })
}

const clear = () => {
  dialogFormVisible.value=false
  form.value={id:-1,name:'',categoryId:0,prescription:0,price:0,stock:0,payStatus:0,image:'',manufacturer:'',unit:'',description:'',efficacy:''}
  paging(1)
}
const handleSizeChange = (ps:number) => {
  pageSize.value=ps
  paging(1)
}
const categoryList=ref([
  {
    id:0,
    name:'全部'
  }
])
onMounted(()=>{
  axios.get("medicine/categoryList").then(res=>{
    categoryList.value=res.data
  })
  paging(1)
})

const paging = (pageNum:number) => {
  axios.get("medicine/list?name="+searchKey.value+"&pageNum="+pageNum+"&pageSize="+pageSize.value).then(res=>{
    page.value=res.data
  })
}


</script>
<template>
  <div class="body">
    <div class="top">
      <div class="left">
        <span class="s1">药品管理/库存管理</span>
        <div class="search-box">
          <input type="search" class="search" placeholder="请输入药品名称" v-model="searchKey">
          <el-button type="primary" @click="paging(1)">查询</el-button>
        </div>
      </div>
      <div class="right" @click="add()">
        <span>+ 新增药品</span>
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
          label="药品名称">
        <template v-slot="scope">
          <span v-html="scope.row.name"></span>
        </template>
      </el-table-column>
      <el-table-column
          prop="categoryId"
          label="分类">
        <template v-slot="scope">
          {{categoryList.find((item:any)=>item.id==scope.row.categoryId)?.name}}
        </template>
      </el-table-column>
      <el-table-column
          prop="prescription"
          label="处方">
        <template v-slot="scope">
          {{scope.row.prescription==0?'非处方':'处方'}}
        </template>
      </el-table-column>
      <el-table-column
          prop="price"
          label="单价">
      </el-table-column>
      <el-table-column
          prop="stock"
          label="库存数量">
        <template v-slot="scope">
          {{scope.row.stock}}/{{scope.row.unit}}
        </template>
      </el-table-column>
      <el-table-column
          prop="status"
          label="状态">
        <template v-slot="scope">
          {{scope.row.status==0?'停售':'在售'}}
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
    <el-dialog title="医药" v-model="dialogFormVisible" :before-close="clear">
      <el-form :model="form" ref="medicineForm">
        <el-form-item label="药品名称" :label-width="formLabelWidth" prop="name">
          <el-input v-model="form.name" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="分类" :label-width="formLabelWidth" prop="categoryId">
          <el-select v-model="form.categoryId" placeholder="请选择分类">
            <el-option v-for="item in categoryList" :key="item.id" :label="item.name" :value="item.id"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="处方" :label-width="formLabelWidth" prop="prescription">
          <el-radio-group v-model="form.prescription">
            <el-radio label="0">非处方</el-radio>
            <el-radio label="1">处方</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="单价" :label-width="formLabelWidth" prop="price">
          <el-input v-model.number="form.price" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="库存数量" :label-width="formLabelWidth" prop="stock">
          <el-input v-model.number="form.stock" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="状态" :label-width="formLabelWidth" prop="status">
          <el-radio-group v-model="form.payStatus">
            <el-radio label="0">停售</el-radio>
            <el-radio label="1">在售</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="图片路径" :label-width="formLabelWidth" prop="image">
          <el-input v-model="form.image" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="制药公司" :label-width="formLabelWidth" prop="manufacturer">
          <el-input v-model="form.manufacturer" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="单位" :label-width="formLabelWidth" prop="unit">
          <el-input v-model="form.unit" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="描述" :label-width="formLabelWidth" prop="description">
          <el-input v-model="form.description" auto-complete="off"></el-input>
        </el-form-item>
        <el-form-item label="功效" :label-width="formLabelWidth" prop="efficacy">
          <el-input v-model="form.efficacy" auto-complete="off"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="clear">取 消</el-button>
        <el-button type="primary" @click="save">确 定</el-button>
      </div>
    </el-dialog>
    <!--药品详情对话框 -->
    <el-dialog
        title="药品详情"
        v-model="detailDialogVisible"
        width="600px"
        :before-close="closeDetail"
        destroy-on-close
    >
    <el-form :model="detailForm" label-width="120px" disabled> <!-- disabled让表单只读 -->
      <el-row :gutter="20">
        <!-- 左列 -->
        <el-col :span="10">
          <el-form-item label="药品ID">
            <span>{{detailForm.id}}</span>
          </el-form-item>
          <el-form-item label="药品名称">
            <span>{{detailForm.name}}</span>
          </el-form-item>
          <el-form-item label="药品分类">
            <span>{{categoryList.find((item:any)=>item.id==detailForm.categoryId)?.name || '未知分类'}}</span>
          </el-form-item>
          <el-form-item label="处方类型">
            <span>{{detailForm.prescription==0?'非处方':'处方'}}</span>
          </el-form-item>
          <el-form-item label="单价">
            <span>{{detailForm.price}} 元/{{detailForm.unit}}</span>
          </el-form-item>
          <el-form-item label="库存数量">
            <span>{{detailForm.stock}} {{detailForm.unit}}</span>
          </el-form-item>
          <el-form-item label="药品状态">
            <span>{{ detailForm.payStatus == 0 ? '停售' : '在售' }}</span>
          </el-form-item>
          <el-form-item label="制药厂家">
            <span>{{detailForm.manufacturer}}</span>
          </el-form-item>
        </el-col>
        <!-- 右列 -->
        <el-col :span="14">
          <el-form-item label="药品图片"><br>
            <img :src="detailForm.image" alt="药品" style="max-width: 100%; height: auto;">
          </el-form-item>
          <el-form-item label="药品描述">
            <span>{{detailForm.description}}</span>
          </el-form-item>
          <el-form-item label="药品功效">
            <span style="white-space: pre-wrap; word-break: break-all;">{{detailForm.efficacy}}</span>
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