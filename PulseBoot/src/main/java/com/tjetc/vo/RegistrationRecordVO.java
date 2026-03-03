package com.tjetc.vo;

import lombok.Data;

@Data
public class RegistrationRecordVO {
    // 对应 SQL 中的 id (reg_no)
    private String id;
    
    // 对应 SQL 中的 doctorName
    private String doctorName;
    
    // 对应 SQL 中的 department
    private String department;
    
    // 对应 SQL 中的 time
    private String time;
    
    // 对应 SQL 中的 status ("upcoming" | "completed" | "cancelled")
    private String status;
    
    // 对应 SQL 中的 createTime (毫秒时间戳)
    private Long createTime;

    private Integer doctorId;
    private String doctorAvatar;
}