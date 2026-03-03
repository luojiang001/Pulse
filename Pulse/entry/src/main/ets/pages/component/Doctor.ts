export class Doctor {
  id: number;
  name: string;
  title: string;
  department: string;
  specialty: string;
  rating: number;
  price: number;
  image: string;
  isreserve: number; // 0: 不可预约, 1: 可预约
  // 新增字段 (与数据库保持一致)
  hospital: string;
  experience: string;
  consultationCount: number;
  education: string;

  constructor(
    id: number, 
    name: string, 
    title: string, 
    department: string, 
    specialty: string, 
    rating: number, 
    price: number, 
    image: string, 
    isreserve: number = 1,
    hospital: string = '默认医院',
    experience: string = '未知',
    consultationCount: number = 0,
    education: string = ''
  ) {
    this.id = id;
    this.name = name;
    this.title = title;
    this.department = department;
    this.specialty = specialty;
    this.rating = rating;
    this.price = price;
    this.image = image;
    this.isreserve = isreserve;
    this.hospital = hospital;
    this.experience = experience;
    this.consultationCount = consultationCount;
    this.education = education;
  }
}

export const sampleDoctors: Doctor[] = [
  new Doctor(1, '张医生', '主任医师', '内科', '高血压、糖尿病、冠心病', 4.9, 50, 'app.media.doctor1', 1, '第一人民医院', '20年', 5000, '博士'),
  new Doctor(2, '李医生', '副主任医师', '儿科', '儿童呼吸道感染、过敏', 4.8, 40, 'app.media.doctor2', 1, '儿童医院', '10年', 3000, '硕士')
];
