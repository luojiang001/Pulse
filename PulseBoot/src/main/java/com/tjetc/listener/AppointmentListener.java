package com.tjetc.listener;

import com.tjetc.config.RabbitConfig;
import com.tjetc.dao.DoctorScheduleMapper;
import com.tjetc.dao.RegistrationMapper;
import com.tjetc.domain.RegistrationRecord;
import com.tjetc.utils.RegistrationNoGenerator;
import com.tjetc.vo.AppointmentParams;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;
import java.util.concurrent.TimeUnit;

@Component
public class AppointmentListener {
    private static final Logger log = LoggerFactory.getLogger(AppointmentListener.class);

    @Autowired
    private RegistrationNoGenerator registrationNoGenerator;
    @Autowired
    private RegistrationMapper registrationMapper;
    @Autowired
    private DoctorScheduleMapper doctorScheduleMapper;
    @Autowired
    private RedissonClient redissonClient;
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    @Autowired
    private com.tjetc.dao.UserBlacklistMapper userBlacklistMapper;

    // 单条挂号记录的Redis Key前缀
    private static final String REG_DETAIL_KEY = "registration:detail:";
    // 医生维度患者列表Key前缀（核心新增）
    private static final String REG_LIST_BY_DOCTOR_KEY = "registration:list:all:";
    // 通用挂号列表前缀（保留原逻辑）
    private static final String REG_LIST_KEY = "registration:list:";

    @RabbitListener(queues = RabbitConfig.QUEUE_APPOINTMENT)
    public void handleAppointment(AppointmentParams params) {
        log.info(">>> 收到预约请求: {}", params);
        String lockKey = "lock:schedule:" + params.getDoctorId() + ":" +
                params.getScheduleDate() + ":" + params.getScheduleTime();
        RLock lock = redissonClient.getLock(lockKey);

        try {
            boolean isLocked = lock.tryLock(5, 10, TimeUnit.SECONDS);
            if (isLocked) {
                try {

                    processBooking(params);
                } finally {
                    if (lock.isHeldByCurrentThread()) {
                        lock.unlock();
                        log.info(">>> 释放分布式锁：{}", lockKey);
                    }
                }
            } else {
                log.error(">>> 获取锁失败，系统繁忙，稍后重试: {}", lockKey);
                throw new RuntimeException("系统繁忙，请稍后重试"); // 触发MQ重试
            }
        } catch (InterruptedException e) {
            log.error(">>> 获取分布式锁时线程中断", e);
            Thread.currentThread().interrupt();
        }
    }

    /**
     * 核心业务逻辑：扣库存+写记录+更新Redis缓存（事务内）
     */
    @Transactional(rollbackFor = Exception.class)
    public void processBooking(AppointmentParams params) {
        try {
            Long doctorId = params.getDoctorId();
            log.info("开始处理预约请求，医生ID：{}，日期：{}，时间：{}",
                    doctorId, params.getScheduleDate(), params.getScheduleTime());

            // 0. 黑名单检查
            com.tjetc.domain.UserBlacklist blacklist = userBlacklistMapper.findActiveBlacklist(Long.valueOf(params.getUserId()), new Date());
            if (blacklist != null) {
                log.warn("用户{}在黑名单中，拒绝预约", params.getUserId());
                throw new RuntimeException("您已被限制挂号，解封时间：" + blacklist.getBlockedUntil());
            }

            // 1. 扣减库存
            int rows = doctorScheduleMapper.decreaseStock(doctorId, params.getScheduleDate(), params.getScheduleTime());
            log.info("库存扣减结果：影响行数{}", rows);

            if (rows <= 0) {
                log.warn("[分布式锁模式] 预约失败：无号源");
                throw new RuntimeException("预约失败：无号源");
            }

            // 2. 生成挂号记录
            RegistrationRecord record = buildRegistrationRecord(params);
            // 3. 插入数据库
            int insertRows = registrationMapper.insert(record);
            if (insertRows <= 0) {
                throw new RuntimeException("挂号记录插入数据库失败，影响行数：" + insertRows);
            }
            log.info("挂号记录插入数据库成功，ID：{}，单号：{}", record.getId(), record.getRegNo());

            // 4. 更新Redis缓存（核心修复：完整的缓存更新逻辑）
            updateRedisCache(record, doctorId);

            log.info("[分布式锁模式] 预约成功！单号: {}", record.getRegNo());
        } catch (Exception e) {
            log.error("处理预约请求失败", e);
            throw e; // 抛出异常触发事务回滚 + Redis操作回滚（若需）
        }
    }

    /**
     * 构建挂号记录对象
     */
    private RegistrationRecord buildRegistrationRecord(AppointmentParams params) {
        RegistrationRecord record = new RegistrationRecord();
        record.setUserId(params.getUserId());
        record.setPatientId(params.getPatientId());
        record.setDoctorId(params.getDoctorId());
        record.setScheduleDate(params.getScheduleDate());
        record.setScheduleTime(params.getScheduleTime());
        record.setAmount(params.getAmount());
        record.setStatus(0);
        record.setVisitStatus(0);

        // 生成挂号单号
        String regNo = registrationNoGenerator.generateRegistrationNo();
        if (regNo == null || regNo.isEmpty()) {
            throw new RuntimeException("生成的挂号单号为空");
        }
        record.setRegNo(regNo);
        return record;
    }

    private void updateRedisCache(RegistrationRecord record, Long doctorId) {
        String regNo = record.getRegNo();
        String doctorListKey = REG_LIST_BY_DOCTOR_KEY + doctorId;

        try {
            redisTemplate.opsForValue().set(REG_DETAIL_KEY + regNo, record, 24, TimeUnit.HOURS);
            log.info("挂号记录已存入Redis: {}", REG_DETAIL_KEY + regNo);


            redisTemplate.opsForSet().add(doctorListKey, record);

            redisTemplate.expire(doctorListKey, 24, TimeUnit.HOURS);
            log.info("新增患者到医生{}的Redis列表：{}", doctorId, doctorListKey);


            redisTemplate.delete(redisTemplate.keys(REG_LIST_KEY + "*"));
            log.info("已删除Redis中通用挂号列表缓存：{}*", REG_LIST_KEY);

        } catch (Exception e) {
            log.error("更新Redis缓存失败", e);
        }
    }
}