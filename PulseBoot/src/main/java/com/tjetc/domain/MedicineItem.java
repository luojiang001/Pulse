package com.tjetc.domain;


import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class MedicineItem implements Serializable {
    private String medicineName;
    private Integer count;
    private Integer prescription; // 0:非处方, 1:处方
    private Integer usedCount;
}