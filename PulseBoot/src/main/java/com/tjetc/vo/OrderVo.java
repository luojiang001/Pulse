package com.tjetc.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@RedisHash("orderVo")
public class OrderVo implements Serializable {
    private String id;
    private String name;
    private BigDecimal price;
    private String payMethod;
    private String createTime;
    private String status;
}
