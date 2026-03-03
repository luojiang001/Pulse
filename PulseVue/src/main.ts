import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
/* 引入Element-Plus插件 */
import ElementPlus from 'element-plus'
/* 引入Element-Plus样式 */
import 'element-plus/dist/index.css'
/*解决Element-plus默认分页文字为英文*/
import locale from "element-plus/es/locale/lang/zh-cn";
import axios from "axios";
// axios.defaults.baseURL='http://47.101.196.181:8080'
import { BASE_URL } from './config'
axios.defaults.baseURL=BASE_URL


const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(ElementPlus,{locale})
app.mount('#app')
