# Pulse 医疗健康平台

## 项目简介

Pulse 是一个综合医疗健康平台，包含三个主要项目：

- **Pulse**：基于鸿蒙操作系统的移动应用，使用 ArkTS 开发
- **PulseBoot**：后端服务，基于 Spring Boot 3.5.9 开发
- **PulseVue**：Web 前端，基于 Vue 3 + TypeScript 开发

## 技术栈

### 后端 (PulseBoot)
- Spring Boot 3.5.9
- Java 17
- MyBatis-Plus
- MySQL
- Redis + Redisson
- RabbitMQ
- Elasticsearch
- WebSocket
- Spring AI (Ollama, OpenAI)
- MinIO (对象存储)
- 支付宝 SDK

### Web 前端 (PulseVue)
- Vue 3
- TypeScript
- Element Plus
- Pinia (状态管理)
- Vue Router
- Axios

### 移动应用 (Pulse)
- 鸿蒙操作系统
- ArkTS
- Map Kit

## 项目结构

```
Pulse/
├── AppScope/            # 应用配置和资源
├── entry/               # 应用入口
│   └── src/main/ets/    # ArkTS 代码
│       ├── common/      # 通用常量
│       ├── entryability/ # 应用能力
│       └── pages/       # 页面组件
│           ├── Ai/      # AI 相关页面
│           ├── component/ # 通用组件
│           │   ├── Map/  # 地图相关组件
│           │   ├── Medicine/ # 药品相关组件
│           │   └── ShouYe/ # 首页相关组件
│           ├── LoginView.ets # 登录页面
│           └── Main.ets # 主页面
└── build-profile.json5  # 构建配置

PulseBoot/
├── src/main/java/com/tjetc/ # Java 代码
│   ├── config/          # 配置类
│   ├── controller/      # 控制器
│   ├── dao/             # 数据访问层
│   ├── domain/          # 实体类
│   ├── service/         # 服务层
│   └── utils/           # 工具类
├── src/main/resources/  # 资源文件
│   ├── com/tjetc/dao/   # MyBatis XML
│   └── application.yml  # 应用配置
└── pom.xml              # Maven 配置

PulseVue/
├── src/                 # 源代码
│   ├── router/          # 路由配置
│   ├── stores/          # Pinia 状态管理
│   ├── views/           # 页面组件
│   │   ├── admin/       # 管理员页面
│   │   ├── doctor/      # 医生页面
│   │   └── login.vue    # 登录页面
│   ├── App.vue          # 根组件
│   └── main.ts          # 入口文件
└── package.json         # 依赖配置
```

## 功能特性

### 核心功能

1. **用户管理**
   - 患者注册与登录
   - 医生注册与登录
   - 管理员登录

2. **预约管理**
   - 患者预约挂号
   - 医生排班管理
   - 预约记录查询

3. **医疗服务**
   - 在线问诊
   - 电子处方
   - 药品配送

4. **药品管理**
   - 药品目录
   - 药品详情
   - 订单管理

5. **AI 辅助**
   - 智能问诊
   - 医疗建议
   - 健康管理

6. **支付功能**
   - 支付宝集成
   - 订单支付
   - 支付记录

7. **通知系统**
   - 预约提醒
   - 消息通知
   - 系统公告

### 技术亮点

- **微服务架构**：模块化设计，易于扩展
- **AI 集成**：集成多种 AI 模型，提供智能医疗服务
- **实时通信**：基于 WebSocket 的实时聊天功能
- **分布式缓存**：使用 Redis 提升性能
- **弹性搜索**：基于 Elasticsearch 的药品搜索
- **对象存储**：使用 MinIO 存储医疗相关文件
- **响应式设计**：适配不同设备屏幕

## 安装部署

### 后端部署 (PulseBoot)

1. **环境准备**
   - JDK 17+
   - Maven 3.6+
   - MySQL 8.0+
   - Redis 7.0+
   - RabbitMQ 3.8+
   - Elasticsearch 7.17+
   - MinIO

2. **配置修改**
   - 修改 `src/main/resources/application.yml` 中的数据库、Redis、RabbitMQ 等配置

3. **构建部署**
   ```bash
   # 构建
   mvn clean package
   
   # 运行
   java -jar target/PulseBoot-0.0.1-SNAPSHOT.jar
   ```

### Web 前端部署 (PulseVue)

1. **环境准备**
   - Node.js 20.19.0+ 或 22.12.0+
   - npm 9.0+

2. **安装依赖**
   ```bash
   npm install
   ```

3. **开发环境运行**
   ```bash
   npm run dev
   ```

4. **生产环境构建**
   ```bash
   npm run build
   ```

### 移动应用部署 (Pulse)

1. **环境准备**
   - 鸿蒙开发工具 (DevEco Studio)
   - 鸿蒙 SDK

2. **构建运行**
   - 使用 DevEco Studio 打开项目
   - 配置签名信息
   - 构建并运行到设备

## 项目配置

### 后端配置

主要配置文件：`PulseBoot/src/main/resources/application.yml`

配置项包括：
- 数据库连接
- Redis 连接
- RabbitMQ 连接
- Elasticsearch 连接
- MinIO 配置
- 支付宝配置
- AI 模型配置

### 前端配置

主要配置文件：`PulseVue/src/config.ts`

配置项包括：
- API 接口地址
- 路由配置
- 全局常量

## 开发指南

### 后端开发

1. **代码结构**
   - 控制器：处理 HTTP 请求
   - 服务层：实现业务逻辑
   - 数据访问层：与数据库交互
   - 实体类：定义数据模型

2. **API 接口**
   - RESTful 风格
   - 统一响应格式
   - 异常处理

### 前端开发

1. **组件开发**
   - 页面组件：`src/views/`
   - 通用组件：`src/components/`

2. **状态管理**
   - 使用 Pinia 进行状态管理

3. **路由配置**
   - 基于 Vue Router 的路由管理

### 移动应用开发

1. **页面开发**
   - 使用 ArkTS 开发页面组件
   - 响应式布局

2. **能力集成**
   - 地图能力
   - 消息通知
   - 本地存储

## 数据库设计

主要数据表包括：
- 管理员表 (admins)
- 用户表 (users)
- 患者信息表 (patient_info)
- 用户黑名单表 (user_blacklist)
- 科室表 (departments)
- 楼层表 (floors)
- 诊室表 (consulting_rooms)
- 医生信息表 (doctor_info)
- 医生账号表 (doctor_accounts)
- 医生排班表 (doctor_schedules)
- 挂号记录表 (registration_records)
- 问诊历史表 (consult_histories)
- 聊天消息表 (chat_messages)
- 药品分类表 (medicine_categories)
- 药品表 (medicines)
- 处方表 (prescriptions)
- 处方药品明细表 (prescription_medicine_items)
- 订单主表 (orders)
- 订单明细表 (order_items)
- 通知表 (notices)

## 安全措施

1. **认证与授权**
   - JWT 令牌验证
   - 角色权限控制

2. **数据安全**
   - 密码加密存储
   - 敏感数据脱敏
   - HTTPS 传输

3. **防攻击措施**
   - SQL 注入防护
   - XSS 攻击防护
   - CSRF 攻击防护

## 监控与日志

1. **系统监控**
   - 应用性能监控
   - 数据库监控
   - 服务可用性监控

2. **日志管理**
   - 业务日志
   - 错误日志
   - 访问日志

## 未来规划

1. **功能扩展**
   - 健康档案管理
   - 远程医疗
   - 智能诊断

2. **技术升级**
   - 微服务拆分
   - 容器化部署
   - 云原生架构

3. **生态建设**
   - 第三方服务集成
   - 开发者平台
   - 社区建设

## 团队协作

1. **代码规范**
   - 后端：Java 代码规范
   - 前端：ESLint + Prettier
   - 移动应用：ArkTS 代码规范

2. **版本控制**
   - Git 工作流
   - 分支管理
   - 代码审查

3. **文档管理**
   - 技术文档
   - API 文档
   - 部署文档

## 联系方式

- 项目地址：https://github.com/luojiang001/Pulse
- 问题反馈：https://github.com/luojiang001/Pulse/issues

---

**Pulse 医疗健康平台** - 让健康管理更智能、更便捷！