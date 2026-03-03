package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;
@Data
@NoArgsConstructor
@AllArgsConstructor
@RedisHash("consultationRoom")
public class ConsultationRoom implements Serializable {
    private Integer id;
    private Integer doctorId;
    private Integer floorId;
    private String roomNo;
    private Integer dutyStatus;
}
