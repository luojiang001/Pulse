package com.tjetc.vo;

import lombok.Data;

import java.time.LocalDate;

@Data
public class DoctorScheduleInfoVO {
    private Integer id;
    private String name;           // 医生姓名
    private String title;          // 职称
    private String department;     // 科室
    private String specialty;      // 专业
    private Double rating;         // 评分
    private Double price;          // 价格
    private String image;          // 头像

    private LocalDate workDate;    // 排班日期
    private String timePeriod;     // 时间段
    private Boolean isAvailable;   // 是否可约
    private Integer availableCount;// 剩余号源
    private String roomName;       // 诊室名称
}