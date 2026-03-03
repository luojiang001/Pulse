package com.tjetc.domain;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@TableName("patients")
public class Patient {
    private Integer id;
    private Integer userId;
    private String name;
    private String idCard;
    private String phone;
    private Integer age;
    private String gender;
    private Boolean isDefault;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}