package com.tjetc.vo;

import com.tjetc.domain.Doctors;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;
import org.springframework.data.annotation.Id; // 关键：正确导入@Id注解

import java.io.Serializable;
@Data
@AllArgsConstructor
@NoArgsConstructor
@RedisHash("registration")
public class Registration implements Serializable {
    private Integer Id;
    @Id
    private String regNo;
    private Long userId;
    private Long patientId;
    private String name;
    private Integer age;
    private String gender;
    private String department;
    private Doctors doctor;
    private String scheduleDate;
    private String scheduleTime;
    private String createTime;
    private Integer visitStatus;
    private Integer payStatus;
    private double amount;
}
