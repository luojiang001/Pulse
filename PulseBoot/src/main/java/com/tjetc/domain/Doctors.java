package com.tjetc.domain;

import com.baomidou.mybatisplus.annotation.TableName;
import com.tjetc.service.DoctorService;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;

@Data
@AllArgsConstructor
@NoArgsConstructor
@RedisHash("doctors")
@Accessors(chain=true)
@TableName("doctors")
@EqualsAndHashCode(callSuper = false)
public class Doctors implements Serializable {
    private Integer id;

    private String name;

    private String title;

    private String department;

    private String specialty;

    private Double rating;

    private Double price;

    private String image;

    private Integer isreserve;

    private String hospital;

    private String experience;

    private int consultationCount;

    private String education;
}