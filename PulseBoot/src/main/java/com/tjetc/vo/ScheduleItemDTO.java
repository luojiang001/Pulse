package com.tjetc.vo;

import lombok.Data;

import java.io.Serializable;
import java.util.List;

@Data
public class ScheduleItemDTO implements Serializable {
    private String date;      // "2024-01-24"
    private String week;      // "周三"
    private String room;      // "诊室302"
    private List<TimeSlotDTO> times;
}