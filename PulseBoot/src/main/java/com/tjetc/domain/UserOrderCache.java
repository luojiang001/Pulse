package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.redis.core.RedisHash;

import java.util.List;

// @RedisHash("user_orders") 指定 key 的前缀，例如 user_orders:1001
// timeToLive = 1800 设置过期时间为 1800秒 (30分钟)
@RedisHash(value = "user_orders", timeToLive = 1800)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserOrderCache {

    @Id // 标记为主键，对应 Redis key 中的 ID 部分
    private Long userId;

    private List<Orders> orders;
}