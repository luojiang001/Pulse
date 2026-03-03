package com.tjetc.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * 雪花算法ID生成器（适配医院挂号场景）
 * 生成规则：41位时间戳 + 10位机器ID + 12位序列号
 */
@Component
public class SnowflakeIdGenerator {
    private static final Logger log = LoggerFactory.getLogger(SnowflakeIdGenerator.class);

    // 开始时间戳 (2024-01-01 00:00:00)
    private final long twepoch = 1704067200000L;
    // 机器ID位数
    private final long workerIdBits = 10L;
    // 序列号位数
    private final long sequenceBits = 12L;
    // 机器ID最大值
    private final long maxWorkerId = -1L ^ (-1L << workerIdBits);
    // 序列号最大值
    private final long sequenceMask = -1L ^ (-1L << sequenceBits);
    // 机器ID左移位数
    private final long workerIdShift = sequenceBits;
    // 时间戳左移位数
    private final long timestampLeftShift = sequenceBits + workerIdBits;

    private long workerId = 1L; // 机器ID，分布式部署时需配置不同值
    private long sequence = 0L; // 序列号
    private long lastTimestamp = -1L; // 上次生成ID的时间戳

    // 构造方法（可通过配置注入机器ID）
    public SnowflakeIdGenerator() {
        if (workerId > maxWorkerId || workerId < 0) {
            throw new IllegalArgumentException(String.format("Worker ID不能大于%d或小于0", maxWorkerId));
        }
        log.info("雪花算法生成器初始化成功，机器ID：{}", workerId);
    }

    // 生成下一个ID
    public synchronized long nextId() {
        long timestamp = timeGen();

        // 时钟回拨处理：小幅度回拨（≤5ms）等待，大幅度回拨抛异常
        if (timestamp < lastTimestamp) {
            long offset = lastTimestamp - timestamp;
            if (offset <= 5) {
                try {
                    log.warn("检测到时钟小幅度回拨({}ms)，等待恢复...", offset);
                    Thread.sleep(offset + 1); // 等待时钟追上
                    timestamp = timeGen();
                } catch (InterruptedException e) {
                    log.error("时钟回拨等待时线程中断", e);
                    throw new RuntimeException(e);
                }
            } else {
                log.error("时钟回拨超过5ms，拒绝生成ID，上次时间：{}，当前时间：{}", lastTimestamp, timestamp);
                throw new RuntimeException(
                        String.format("时钟回拨拒绝生成ID，上次时间：%d，当前时间：%d", lastTimestamp, timestamp));
            }
        }

        // 同一毫秒内，序列号自增
        if (lastTimestamp == timestamp) {
            sequence = (sequence + 1) & sequenceMask;
            // 序列号溢出，等待下一毫秒
            if (sequence == 0) {
                timestamp = tilNextMillis(lastTimestamp);
                log.debug("同一毫秒序列号溢出，等待下一毫秒：{}", timestamp);
            }
        } else {
            // 不同毫秒，序列号重置为0
            sequence = 0L;
        }

        lastTimestamp = timestamp;

        // 组合ID：(时间戳-开始时间戳)左移 + 机器ID左移 + 序列号
        long id = ((timestamp - twepoch) << timestampLeftShift)
                | (workerId << workerIdShift)
                | sequence;
        log.debug("生成雪花算法ID：{}", id);
        return id;
    }

    // 等待下一毫秒
    private long tilNextMillis(long lastTimestamp) {
        long timestamp = timeGen();
        while (timestamp <= lastTimestamp) {
            timestamp = timeGen();
        }
        return timestamp;
    }

    // 获取当前时间戳（毫秒）
    private long timeGen() {
        return System.currentTimeMillis();
    }

    // 提供setter方法，支持外部配置机器ID（分布式部署用）
    public void setWorkerId(long workerId) {
        if (workerId > maxWorkerId || workerId < 0) {
            throw new IllegalArgumentException(String.format("Worker ID不能大于%d或小于0", maxWorkerId));
        }
        this.workerId = workerId;
        log.info("雪花算法机器ID更新为：{}", workerId);
    }
}