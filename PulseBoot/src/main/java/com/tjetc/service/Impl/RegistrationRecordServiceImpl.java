package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.tjetc.dao.RegistrationMapper;
import com.tjetc.domain.RegistrationRecord;
import com.tjetc.repository.RegistrationRepository;
import com.tjetc.service.DoctorService;
import com.tjetc.service.PatientService;
import com.tjetc.service.RegistrationRecordService;
import com.tjetc.utils.RegistrationNoGenerator;
import com.tjetc.vo.PrescriptionVO;
import com.tjetc.vo.Registration;
import com.tjetc.vo.RegistrationRecordVO;
import com.tjetc.vo.Result;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Date;
import java.util.Calendar;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
@Transactional(rollbackFor = Exception.class)
public class RegistrationRecordServiceImpl extends ServiceImpl<RegistrationMapper, RegistrationRecord> implements RegistrationRecordService {
    private static final Logger log = LoggerFactory.getLogger(RegistrationRecordServiceImpl.class);

    @Autowired
    private RegistrationMapper registrationMapper;
    @Autowired
    private com.tjetc.dao.UserBlacklistMapper userBlacklistMapper;
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    @Autowired
    private RegistrationRepository registrationRepository;
    @Autowired
    private RegistrationNoGenerator registrationNoGenerator;


    // 分页列表缓存前缀
    private static final String REGISTRATION_KEY = "registration:list:";

    // findAll专用缓存Key（核心新增）
    private static final String REGISTRATION_ALL_KEY = "registration:list:all";
    // 缓存有效期（小时）
    private static final long LIVE_HOURS = 1;
    @Override
    public Result detail(String regNo){
        Result result = new Result();
        PrescriptionVO prescriptionVO = registrationMapper.findByRegNo(regNo);
        if(prescriptionVO == null){
            result.setCode(500).setMsg("挂号记录不存在");
        }else {
            result.setCode(200).setMsg("查询成功").setData(prescriptionVO);
        }
        return result;
    }
    @Override
    public Result del(String regNo) {
        Result result = new Result();
        int rows=registrationMapper.del(regNo);
        if(rows>0){
            registrationRepository.deleteByRegNo(regNo);
            clearListCache();
            result.setCode(200).setMsg("删除成功");
        }else {
            result.setCode(500).setMsg("删除失败");
        }
        return result;

    }

    @Override
    public Result add(Registration registration) {
        Result result = new Result();
        try {
            // 黑名单检查
            if (registration != null && registration.getUserId() != null) {
                com.tjetc.domain.UserBlacklist blacklist = userBlacklistMapper.findActiveBlacklist(Long.valueOf(registration.getUserId()), new Date());
                if (blacklist != null) {
                    result.setCode(500).setMsg("您已被限制挂号，解封时间：" + blacklist.getBlockedUntil());
                    return result;
                }
            }

            if (registration == null) {
                result.setCode(500).setMsg("挂号信息不能为空");
                return result;
            }
            if (registration.getDoctor() == null || registration.getDoctor().getId() == null) {
                result.setCode(500).setMsg("就诊医生不能为空");
                return result;
            }
            if (!StringUtils.hasText(registration.getScheduleDate()) || !StringUtils.hasText(registration.getScheduleTime())) {
                result.setCode(500).setMsg("预约日期和时段不能为空");
                return result;
            }

            RegistrationRecord record = new RegistrationRecord();
            record.setDoctorId(Long.valueOf(registration.getDoctor().getId()));
            record.setUserId(registration.getUserId());
            record.setPatientId(registration.getPatientId());
            record.setScheduleDate(registration.getScheduleDate());
            record.setScheduleTime(registration.getScheduleTime());
            record.setAmount(BigDecimal.valueOf(registration.getAmount()));
            record.setStatus(0);
            record.setVisitStatus(0);
            record.setCreateTime(new Date());

            String regNo = registrationNoGenerator.generateRegistrationNo();
            record.setRegNo(regNo);
            log.info("生成挂号单号：{}，开始添加挂号记录", regNo);


            int rows = registrationMapper.insert(record);
            if (rows > 0) {
                clearListCache();

                result.setCode(200).setMsg("挂号添加成功");
                log.info("挂号记录添加成功，单号：{}", regNo);
            } else {
                result.setCode(500).setMsg("添加失败：数据库插入无影响行数");
                log.error("挂号记录添加失败，单号：{}，数据库插入行数为0", regNo);
            }
        } catch (Exception e) {
            log.error("添加挂号记录异常", e);
            result.setCode(500).setMsg("添加失败：" + e.getMessage());
        }
        return result;
    }

    @Override
    public Result update(Registration registration) {
        Result result = new Result();

        int rows=registrationMapper.update(registration);
        if (rows>0){
            clearListCache();
            result.setCode(200).setMsg("修改成功");
        }else {
            result.setCode(500).setMsg("修改失败");
        }
        return result;

    }

    @Override
    public List<RegistrationRecordVO> getRecordList(long userId) {
        return registrationMapper.getRecordList(userId);
    }


    @Override
    public Result updateVisitStatus(String regNo, Integer visitStatus){
        Result result = new Result();

        // 处理爽约逻辑
        if (visitStatus == 3) { // 3 代表爽约
            RegistrationRecord record = registrationMapper.selectByRegNo(regNo);
            if (record != null) {
                // 更新状态
                int rows = registrationMapper.updateVisitStatus(regNo, visitStatus);
                if (rows > 0) {
                    clearListCache();

                    // 检查是否需要拉黑
                    // 统计过去30天内的爽约次数
                    Date now = new Date();
                    Calendar calendar = Calendar.getInstance();
                    calendar.setTime(now);
                    calendar.add(Calendar.DAY_OF_YEAR, -30);
                    Date startDate = calendar.getTime();

                    int missedCount = registrationMapper.countMissedAppointments(record.getUserId(), startDate);
                    if (missedCount >= 3) {
                        // 拉黑90天
                        calendar.setTime(now);
                        calendar.add(Calendar.DAY_OF_YEAR, 90);
                        Date blockedUntil = calendar.getTime();

                        com.tjetc.domain.UserBlacklist blacklist = new com.tjetc.domain.UserBlacklist();
                        blacklist.setUserId(record.getUserId());
                        blacklist.setBlockedUntil(blockedUntil);
                        blacklist.setReason("30天内连续爽约3次");
                        blacklist.setCreateTime(now);

                        userBlacklistMapper.insert(blacklist);
                        log.info("用户ID:{} 因爽约被拉黑至 {}", record.getUserId(), blockedUntil);
                    }

                    result.setCode(200).setMsg("更新成功，已标记爽约");
                    return result;
                }
            }
        }

        int rows=registrationMapper.updateVisitStatus(regNo,visitStatus);
        if (rows>0){
            clearListCache();

            result.setCode(200).setMsg("更新成功");
        }else {
            result.setCode(500).setMsg("更新失败");
        }
        return result;
    }


    @Override
    public PageInfo<Registration> list(String name, Integer pageNum, Integer pageSize, Integer doctorId) {
        String cacheKey = REGISTRATION_ALL_KEY +
                (StringUtils.hasText(name) ? name : "null") + "_" +
                pageNum + "_" + pageSize + "_" +
                (doctorId != null ? doctorId : "all");

        // 优先读Redis缓存
        PageInfo<Registration> pageInfo = (PageInfo<Registration>) redisTemplate.opsForValue().get(cacheKey);
        if (pageInfo != null) {
            log.info("从Redis读取分页列表缓存，Key：{}", cacheKey);
            return pageInfo;
        }

        // 缓存未命中，查数据库
        PageHelper.startPage(pageNum, pageSize);
        List<Registration> list = registrationMapper.list(name, doctorId);
        pageInfo = new PageInfo<>(list);

        // 写入Redis缓存
        redisTemplate.opsForValue().set(cacheKey, pageInfo, LIVE_HOURS, TimeUnit.HOURS);
        log.info("分页列表写入Redis缓存，Key：{}，数据量：{}", cacheKey, list.size());

        return pageInfo;
    }

    // 删除列表缓存（供其他服务调用）
    public void clearListCache() {
        // 1. 删除分页列表缓存
        redisTemplate.delete(redisTemplate.keys(REGISTRATION_KEY + "*"));
        // 2. 删除findAll专用缓存（核心新增）
        redisTemplate.delete(REGISTRATION_ALL_KEY);
        log.info("已清空挂号列表Redis缓存（分页+全量）");

        // 3. 清空JPA缓存（关键：解决Repository数据不更新问题）
        registrationRepository.deleteAll();
        log.info("已清空JPA Repository缓存");
    }

    @Override
    public List<Registration> findAll(Integer doctorId, String date) {
        String cacheKey = REGISTRATION_ALL_KEY;
        if (doctorId != null) {
            cacheKey += ":" + doctorId;
        }
        if (date != null) {
            cacheKey += ":" + date;
        }

        // ========== 核心修复1：优先读Redis全量缓存 ==========
        List<Registration> registrationList = (List<Registration>) redisTemplate.opsForValue().get(cacheKey);
        if (registrationList != null && !registrationList.isEmpty()) {
            log.info("从Redis读取列表，Key：{}，数据量：{}", cacheKey, registrationList.size());
            return registrationList;
        }

        // ========== 核心修复2：放弃优先读JPA，改为优先读MyBatis（最新数据） ==========
        // 步骤1：先查MyBatis（直接查数据库表，获取最新预约数据）
        if (doctorId != null) {
            if (date != null) {
                registrationList = registrationMapper.findByDoctorIdAndDate(doctorId, date);
            } else {
                registrationList = registrationMapper.findByDoctorId(doctorId);
            }
        } else {
            registrationList = registrationMapper.findAll();
        }

        if (registrationList == null || registrationList.isEmpty()) {
            log.info("数据库中暂无患者数据");
            return List.of();
        }
        log.info("从MyBatis读取列表，数据量：{}", registrationList.size());

        // 步骤2：同步更新JPA Repository（解决原JPA数据不更新问题）
        // 仅当查询全量数据时同步JPA，避免覆盖
        if (doctorId == null && date == null) {
            registrationRepository.deleteAll(); // 清空旧数据
            registrationRepository.saveAll(registrationList); // 写入最新数据
            log.info("已同步最新患者数据到JPA Repository，数据量：{}", registrationList.size());
        }

        // 步骤3：写入Redis全量缓存（核心修复2）
        redisTemplate.opsForValue().set(cacheKey, registrationList, LIVE_HOURS, TimeUnit.HOURS);
        log.info("患者列表写入Redis缓存，Key：{}", cacheKey);

        return registrationList;
    }
}