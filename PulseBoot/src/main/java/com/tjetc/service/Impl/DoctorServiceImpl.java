package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.tjetc.dao.DoctorsMapper;
import com.tjetc.domain.DoctorScheduleSlot;
import com.tjetc.domain.DoctorUser;
import com.tjetc.domain.Doctors;
import com.tjetc.domain.Medicine;
import com.tjetc.domain.query.DoctorsQuery;
import com.tjetc.repository.DoctorRepository;
import com.tjetc.service.DoctorService;
import com.tjetc.vo.DoctorScheduleInfoVO;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ScanOptions;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
@Transactional(rollbackFor = Exception.class)
public class DoctorServiceImpl extends ServiceImpl<DoctorsMapper, Doctors> implements DoctorService {

    @Autowired
    private DoctorsMapper  doctorsMapper;
    @Autowired
    private DoctorRepository doctorRepository;
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    private static final String doctorKey = "doctor:list:";
    private static final long live = 1;

    public Result deleteAllDoctorRedisCache() {
        Result result = new Result();
        try {
            // 构造ScanOptions，匹配doctorKey前缀的所有key（doctor:list:*）
            ScanOptions scanOptions = ScanOptions.scanOptions()
                    .match(doctorKey + "*") // 通配符*匹配前缀后所有字符
                    .count(1000) // 每次扫描1000个key，避免一次性扫描过多导致Redis阻塞
                    .build();

            // 获取Redis连接并执行扫描
            Iterator<String> keyIterator = redisTemplate.opsForSet().getOperations().scan(scanOptions);
            List<String> delKeys = new ArrayList<>();
            // 遍历所有匹配的key，加入删除列表
            while (keyIterator.hasNext()) {
                delKeys.add(keyIterator.next());
            }

            // 批量删除（比单个删除高效，减少Redis交互）
            if (!delKeys.isEmpty()) {
                redisTemplate.delete(delKeys);
            }

            result.setCode(200).setMsg("医生业务Redis缓存删除成功，共清理" + delKeys.size() + "个缓存key");
        } catch (Exception e) {
            e.printStackTrace();
            result.setCode(500).setMsg("医生业务Redis缓存删除失败：" + e.getMessage());
        }
        return result;
    }

    @Override
    public Result del(Integer id){
        Result result = new Result();
        int rows=doctorsMapper.del(id);
        if(rows>0){
            result.setCode(200).setMsg("删除成功");
        }else {
            result.setCode(500).setMsg("删除失败");
        }
        deleteAllDoctorRedisCache();
        return result;
    }

    @Override
    public Result update(Doctors doctors){
        Result result = new Result();
        int rows=doctorsMapper.update(doctors);
        if(rows>0){
            result.setCode(200).setMsg("修改成功");
        }else {
            result.setCode(500).setMsg("修改成功");
        }
        deleteAllDoctorRedisCache();
        return result;
    }
    @Override
    public Result add(Doctors doctors){
        Result result = new Result();
        int rows=doctorsMapper.add(doctors);
        if(rows>0){
            result.setCode(200).setMsg("添加成功");
        }else {
            result.setCode(500).setMsg("添加失败");
        }
        deleteAllDoctorRedisCache();
        return result;
    }

    // 实现：直接调用Mapper的联表查询方法
    @Override
    public List<DoctorScheduleInfoVO> selectDoctorWithSchedule(DoctorsQuery query, LocalDate scheduleDate) {
        return doctorsMapper.selectDoctorWithSchedule(query, scheduleDate);
    }

    @Override
    public void refreshDoctorReserveStatus() {
        doctorsMapper.resetAllDoctorsReserveStatus();
        doctorsMapper.updateDoctorsReserveStatusBasedOnSchedule();
    }


    @Override
    public Result updatePassword(Integer id, String oldPassword, String newPassword){
        Result result = new Result();
        DoctorUser doctorUser = doctorsMapper.findByDId(id);
        if (!doctorUser.getPassword().equals(oldPassword)){
            result.setCode(500).setMsg("原密码错误，请重试");
            return result;
        }
        int rows=doctorsMapper.updatePassword(id,newPassword);
        if(rows>0){
            result.setCode(200).setMsg("修改密码成功");
        }else {
            result.setCode(500).setMsg("修改密码失败");
        }
        return result;
    }
    @Override
    public PageInfo<Doctors> page(String name, Integer pageNum, Integer pageSize){
        String cacheKey = doctorKey +
                (StringUtils.hasText(name) ? name : "null") + "_" +
                pageNum + "_" + pageSize;

        PageInfo<Doctors> pageInfo = (PageInfo<Doctors>) redisTemplate.opsForValue().get(cacheKey);
        if (pageInfo != null) {
            return pageInfo;
        }

        PageHelper.startPage(pageNum, pageSize);
        List<Doctors> list = doctorsMapper.page(name);
        pageInfo = new PageInfo<>(list);

        redisTemplate.opsForValue().set(cacheKey, pageInfo, live, TimeUnit.HOURS);

        return pageInfo;
    }

    @Override
    public Result login(String username, String password) {
        Result result = new Result();
        DoctorUser doctorUser = doctorsMapper.findByUsername(username);
        if (doctorUser == null) {
            result.setCode(500).setMsg("该账户不存在");
            return result;
        }
        if (!doctorUser.getPassword().equals(password)) {
            result.setCode(500).setMsg("密码错误");
            return result;
        }
        Doctors doctors = doctorsMapper.findById(doctorUser.getDoctorsId());
        result.setCode(200).setMsg("登录成功").setData(doctors);
        return result;
    }



    @Override
    public List<Doctors> list() {
        List<Doctors> doctorList = doctorsMapper.findAll(doctorsMapper);
        if (doctorList != null && !doctorList.isEmpty()) {return null;
        }
        return doctorList == null ? List.of() : doctorList;
    }

    @Override
    public List<Doctors> findByDepartMentName(String department) {
        if (department == null || department.isEmpty()) {
            return List.of();
        }
        //先查自定义的findByDepartment
        List<Doctors> doctorList = doctorRepository.findByDepartment(department);

        if (!doctorList.isEmpty()) {
            return doctorList;
        }
        doctorList = doctorsMapper.findByDepartment(department);
        if (doctorList != null && !doctorList.isEmpty()) {
            doctorRepository.saveAll(doctorList);
        }
        return doctorList == null ? List.of() : doctorList;
    }

    @Override
    public Doctors getDetailById(Integer id) {
        if (id == null || id <= 0) {
            return null;
        }
        // 先查Repository
        Doctors doctor = doctorRepository.findById(id).orElseGet(() -> {
            Doctors dbDoctor = doctorsMapper.findById(id);
            if (dbDoctor != null) {
                doctorRepository.save(dbDoctor);
            }
            return dbDoctor;
        });
        return doctor;
    }
}