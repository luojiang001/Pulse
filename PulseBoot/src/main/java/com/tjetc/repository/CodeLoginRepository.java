package com.tjetc.repository;

import jakarta.annotation.Resource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Repository;
import java.util.concurrent.TimeUnit;

/**
 * Redis版验证码存储Repository（替代原数据库版）
 * 核心：key=username，value=code，过期时间5分钟
 */
@Repository
public class CodeLoginRepository {
    @Resource
    private StringRedisTemplate stringRedisTemplate;

    // 过期时间：5分钟（固定值）
    private static final long EXPIRE_SECONDS = 5 * 60;

    /**
     * 存储验证码（key=username，value=code，5分钟过期）
     * @param username 用户名（作为Redis的key）
     * @param code 验证码（作为Redis的value）
     */
    public void save(String username, String code) {
        // 核心：Redis SET命令 + EX过期时间（原子操作）
        stringRedisTemplate.opsForValue()
                .set(username, code, EXPIRE_SECONDS, TimeUnit.SECONDS);
    }

    /**
     * 根据username查询验证码
     * @param username 用户名（Redis的key）
     * @return 验证码（过期/不存在返回null）
     */
    public String findById(String username) {
        // 读取Redis中的值，过期后会返回null
        return stringRedisTemplate.opsForValue().get(username);
    }


    public void delete(String username) {
        stringRedisTemplate.delete(username);
    }
}