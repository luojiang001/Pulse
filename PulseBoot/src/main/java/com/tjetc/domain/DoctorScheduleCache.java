package com.tjetc.domain;


import com.tjetc.vo.ScheduleItemDTO;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.redis.core.RedisHash;
import org.springframework.data.redis.core.index.Indexed;

import java.util.List;

/**
 * 对应 Redis key: "doctor_schedule:{doctorId}"
 * timeToLive = 3600 秒 (1小时过期)
 */
@Data
@RedisHash(value = "doctor_schedule", timeToLive = 3600)
public class DoctorScheduleCache {
    
    @Id // 对应RedisKey的ID部分
    private Integer doctorId;
    
    // 直接缓存组装好的列表
    private List<ScheduleItemDTO> scheduleList;
}