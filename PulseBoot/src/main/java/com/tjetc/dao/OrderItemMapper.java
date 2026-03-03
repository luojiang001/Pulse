package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.OrderItem;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface OrderItemMapper extends BaseMapper<OrderItem> {

    // 使用 <script> 标签在注解中实现批量插入
    @Insert({
            "<script>",
            "INSERT INTO order_item (order_id, medicine_id, name, price, quantity, image) VALUES ",
            "<foreach collection='list' item='item' separator=',' >",
            "    (#{item.orderId}, #{item.medicineId}, #{item.name}, #{item.price}, #{item.quantity}, #{item.image})",
            "</foreach>",
            "</script>"
    })
    int insertBatch(@Param("list") List<OrderItem> list);

    // 根据订单ID查询详情（供 OrdersMapper 关联调用）
    @Select("SELECT * FROM order_item WHERE order_id = #{orderId}")
    List<OrderItem> selectByOrderId(String orderId);

}