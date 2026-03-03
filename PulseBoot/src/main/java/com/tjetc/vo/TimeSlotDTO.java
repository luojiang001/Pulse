package com.tjetc.vo;

import lombok.Data;
import lombok.AllArgsConstructor;

import java.io.Serializable;

@Data
@AllArgsConstructor
public class TimeSlotDTO implements Serializable {
    private String time;         // "09:00-10:00"
    private Boolean isAvailable; // true/false
    private String room;
}