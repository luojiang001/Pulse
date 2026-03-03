package com.tjetc.domain;

import com.tjetc.domain.OrderItem;
import lombok.Data;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Data
public class Orders implements java.io.Serializable {
    private String id;
    private Long userId;
    private BigDecimal totalAmount;
    private String status;
    private Long createTime;
    private String payMethod;
    private Date payTime;

    // 既用于接收前端传来的商品列表，也用于返回查询结果
    // MyBatis 默认不会映射数据库不存在的列，除非在 @Results 中显式配置，所以这里很安全
    private List<OrderItem> items;
}