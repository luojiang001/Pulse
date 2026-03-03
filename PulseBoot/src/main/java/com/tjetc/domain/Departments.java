package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;

/**
 * 科室分类表
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
@RedisHash("departments")
public class Departments implements Serializable {
    /**
    * 科室ID
    */
    private Integer id;

    /**
    * 科室名称
    */
    private String name;

    /**
    * 图标资源路径
    */
    private String icon;


}