package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;
@Data
@NoArgsConstructor
@AllArgsConstructor
@RedisHash("floor")
public class Floor implements Serializable {
    private Integer id;
    private String name;
}
