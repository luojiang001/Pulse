package com.tjetc.domain;

import java.io.Serializable;
import java.util.Date;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 医生排班表
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class DoctorSchedules implements Serializable {
    /**
    * 排班ID
    */
    private Long id;

    /**
    * 医生ID
    */
    private Integer doctorId;

    /**
    * 出诊日期
    */
    private Date workDate;

    /**
    * 星期 (如: 周四)
    */
    private String dayOfWeek;

    /**
    * 状态: 1-正常, 0-停诊
    */
    private Byte status;
}