package com.tjetc.domain;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class OrderItem implements java.io.Serializable {
    private Integer id;
    private String orderId;
    private Integer medicineId;
    private String name;
    private BigDecimal price;
    private Integer quantity;
    private String image;
    private Integer prescriptionId;
}