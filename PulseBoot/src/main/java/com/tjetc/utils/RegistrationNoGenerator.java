package com.tjetc.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * 医院挂单号生成服务
 * 单号格式：GH + 年月日 + 雪花算法ID（如：GH20240126145896354789）
 */
@Service
public class RegistrationNoGenerator {
    private static final Logger log = LoggerFactory.getLogger(RegistrationNoGenerator.class);

    private final SnowflakeIdGenerator snowflakeIdGenerator;

    // 日期格式化器（线程安全）
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd");

    // 修复：构造器注入 + 初始化校验（替代@PostConstruct）
    @Autowired
    public RegistrationNoGenerator(SnowflakeIdGenerator snowflakeIdGenerator) {
        if (snowflakeIdGenerator == null) {
            log.error("SnowflakeIdGenerator 注入失败！");
            throw new RuntimeException("SnowflakeIdGenerator 注入失败，请检查Spring配置");
        }
        this.snowflakeIdGenerator = snowflakeIdGenerator;
        log.info("RegistrationNoGenerator 初始化成功");
    }

    /**
     * 生成唯一挂单号
     * @return 不重复的挂单号
     */
    public String generateRegistrationNo() {
        try {
            // 1. 获取当前日期前缀（如20240126）
            String datePrefix = LocalDate.now().format(DATE_FORMATTER);
            // 2. 生成雪花算法唯一ID
            long uniqueId = snowflakeIdGenerator.nextId();
            // 3. 组合成最终挂单号（GH为挂号首字母）
            String regNo = "GH" + datePrefix + uniqueId;
            log.info("生成挂号单号成功：{}", regNo);
            return regNo;
        } catch (Exception e) {
            log.error("生成挂号单号失败", e);
            throw new RuntimeException("生成挂号单号失败", e);
        }
    }

    /**
     * 重载方法：支持指定日期生成（如补录历史挂号单）
     * @param date 指定日期
     * @return 不重复的挂单号
     */
    public String generateRegistrationNo(LocalDate date) {
        try {
            String datePrefix = date.format(DATE_FORMATTER);
            long uniqueId = snowflakeIdGenerator.nextId();
            String regNo = "GH" + datePrefix + uniqueId;
            log.info("生成指定日期挂号单号成功：{}，日期：{}", regNo, date);
            return regNo;
        } catch (Exception e) {
            log.error("生成指定日期挂号单号失败，日期：{}", date, e);
            throw new RuntimeException("生成指定日期挂号单号失败", e);
        }
    }
}