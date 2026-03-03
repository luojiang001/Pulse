package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;
@Data
@NoArgsConstructor
@AllArgsConstructor
@RedisHash("prescriptionMedicine")
public class PrescriptionMedicine implements Serializable {
    private Integer id;
    private Integer prescriptId;
    private Integer medicineId;
    private Integer count;
    private Integer usedCount;
}
