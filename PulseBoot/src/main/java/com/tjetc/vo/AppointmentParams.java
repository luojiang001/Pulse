package com.tjetc.vo;

import lombok.Data;
import java.io.Serializable;
import java.math.BigDecimal;

@Data
public class AppointmentParams implements Serializable {
    private Long userId;
    private Long patientId;
    private Long doctorId;
    private String scheduleDate;
    private String scheduleTime;
    private BigDecimal amount;
}