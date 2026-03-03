package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;
import java.util.Date;

@Data
@AllArgsConstructor
@NoArgsConstructor
@RedisHash("userBlacklist")
public class UserBlacklist implements Serializable {
    private Long id;
    private Long userId;
    private Date blockedUntil;
    private String reason;
    private Date createTime;
}
