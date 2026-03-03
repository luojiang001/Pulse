package com.tjetc.vo;

import com.tjetc.domain.MedicineItem;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PrescriptionVO  implements Serializable {
    private String id;
    private String doctorName;
    private String department;
    private String time;
    private String status;
    private Long createTime;
    private String diagnosis;
    private List<MedicineItem> medicines = new ArrayList<>();
}

