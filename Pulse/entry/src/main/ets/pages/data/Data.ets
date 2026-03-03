export interface INotification {
  id: number;
  title: string;
  content: string;
  type: string;
  targetUserId?: number;
  createTime: string;
}

export interface User{
  id:number;
  username:string,
  password:string,
  nickname:string,
  avatar:string,
  phone:string,
  intro?: string,
  gender?: number,
  birth?: Date | string,
  cratedAt:Date
}

export interface Patient {
  id: number;
  name: string;
  age: number;
  gender: '男' | '女';
  phone: string;
  idCard: string;
  isDefault: boolean;
}

// 主页标签栏接口
export interface ITab_main{
  id: number | string
  name:string
  photo:ResourceStr
}
//
export interface ICategory{
  id:number //分类id
  name:string//分类名称
}

// 药品信息接口
export interface IMedicine {
  id: number | string
  name:string
  image: ResourceStr | string // 药品图片
  manufacturer: string     // 生产厂家
  price: number            // 价格
  unit: string             // 单位（如：盒、瓶）
  description?: string     // 详细描述
  efficacy?: string        // 功效
  isPrescription?: boolean // 是否为处方药
  prescription?: number    // 后端返回的处方药标识 (0/1)
  category: number         // 分类
  categoryId?: number | null // 后端返回的分类ID
}
// 购物车商品项接口，继承自药品信息
export interface ICartItem extends IMedicine {
  quantity: number         // 购买数量
  prescriptionId?: string  // 关联的处方ID (新增)
}

// 订单接口
export interface IOrder {
  id: string               // 订单ID
  items: ICartItem[]       // 订单包含的商品列表
  totalAmount: number      // 订单总金额
  createTime: number       // 创建时间戳
  status: 'pending' | 'completed' | 'cancelled' | 'paid' // 订单状态
}

// 挂号记录接口
export interface IRegistrationRecord {
  id: string
  doctorName: string
  department: string
  time: string // e.g. "明天 09:00"
  status: 'upcoming' | 'completed' | 'cancelled'
  createTime: number
  doctorId?: number
  doctorAvatar?: string
}

export interface MedicineItem {
  medicineName: string;
  count: number;      // 总处方量
  usedCount?: number; // 已购买数量
  prescription?: number;
}

// 处方记录接口
export interface IPrescriptionRecord {
  id: string
  doctorName: string
  department: string
  time: string
  status: 'valid' | 'invalid' | 'used'
  createTime: number
  diagnosis?: string
  medicines?: MedicineItem[]
}

// 请求体类定义 (用于解决 ArkTS 对象字面量报错)
export class OrderItemRequest {
  medicineId: number | string = 0
  name: string = ''
  price: number = 0
  quantity: number = 0
  image: string = ''
  prescriptionId?: number = undefined
}

export class OrderRequest {
  userId: number = 0
  totalAmount: number = 0
  items: OrderItemRequest[] = []
}

export class OrderItemResponse {
  id: number | string = ''
  medicineId: number | string = ''
  name: string = ''
  price: number = 0
  quantity: number = 0
  image: string = ''
}

// 处方验证结果接口
export interface PrescriptionCheckResult {
  hasPrescription: boolean
  maxCount: number
}

export class OrderResponse {
  id: string = ''
  totalAmount: number = 0
  createTime: number = 0
  status: string = ''
  items: OrderItemResponse[] = []
}

export class ApiResponse<T> {
  code: number = 0
  msg: string = ''
  data: T | null = null
}


// 默认值常量
export const DEFAULT_MEDICINE: IMedicine = {
  id: 0,
  name: '',
  image: '',
  manufacturer: '',
  price: 0,
  unit: '',
  category: 0
}

export const DEFAULT_CART_ITEM: ICartItem = {
  id: DEFAULT_MEDICINE.id,
  name: DEFAULT_MEDICINE.name,
  image: DEFAULT_MEDICINE.image,
  manufacturer: DEFAULT_MEDICINE.manufacturer,
  price: DEFAULT_MEDICINE.price,
  unit: DEFAULT_MEDICINE.unit,
  category: DEFAULT_MEDICINE.category,
  quantity: 0
}

export const DEFAULT_ORDER: IOrder = {
  id: '',
  items: [],
  totalAmount: 0,
  createTime: 0,
  status: 'pending'
}

export const DEFAULT_REGISTRATION_RECORD: IRegistrationRecord = {
  id: '',
  doctorName: '',
  department: '',
  time: '',
  status: 'upcoming',
  createTime: 0
}
