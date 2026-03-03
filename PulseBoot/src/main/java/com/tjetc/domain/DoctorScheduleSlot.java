package com.tjetc.domain;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "医生预约信息VO")
public class DoctorScheduleSlot {
    private Integer id;
    private Integer doctorId;
    private LocalDate workDate;   // 对应数据库 date 类型
    private String timePeriod;    // 对应 "09:00-10:00"
    private Boolean isAvailable;  // 对应 tinyint(1)
    private Date createAt;
    private Integer availableCount; // 对应 available_count
    private String roomName; // 对应 room_name
}