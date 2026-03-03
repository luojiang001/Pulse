package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * 排班时段详情表
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ScheduleTimes implements Serializable {
    /**
    * 时段ID
    */
    private Long id;

    /**
    * 排班ID
    */
    private Long scheduleId;

    /**
    * 时段 (如 09:00-10:00)
    */
    private String timePeriod;

    /**
    * 总号源
    */
    private Integer totalQuota;

    /**
    * 剩余号源
    */
    private Integer remainingQuota;

    /**
    * 是否可约
    */
    private Boolean isAvailable;
}