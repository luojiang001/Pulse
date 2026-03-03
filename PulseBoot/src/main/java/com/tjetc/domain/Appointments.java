package com.tjetc.domain;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 挂号预约表
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Appointments implements Serializable {
    /**
    * 预约ID
    */
    private Long id;

    /**
    * 用户ID
    */
    private Integer userId;

    /**
    * 医生ID
    */
    private Integer doctorId;

    /**
    * 关联的时段ID
    */
    private Long scheduleTimeId;

    /**
    * 状态: 0-待支付, 1-待就诊, 2-已完成, 3-已取消
    */
    private Byte status;

    /**
    * 支付金额
    */
    private BigDecimal amount;

    private Date createdAt;
}