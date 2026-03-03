package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
@RedisHash("prescription")
public class Prescription implements Serializable {
    private Integer id;
    private String prescriptionNo;
    private Integer patientId;
    private Integer doctorId;
    private String msg;
    private Date createTime;
}
