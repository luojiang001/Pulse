package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
@RedisHash("registrationRecord")
public class RegistrationRecord implements Serializable {
    private Long id;
    private Long userId;
    private Long patientId;
    private Long doctorId;
    private String scheduleDate;
    private String scheduleTime;
    private BigDecimal amount;
    private Integer status;
    private Date createTime;
    private Integer visitStatus;
    private String regNo;
}