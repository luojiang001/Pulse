package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Orders;
import com.tjetc.vo.OrderVo;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface OrdersMapper extends BaseMapper<Orders> {

    @Insert("INSERT INTO orders (id, user_id, total_amount, status, create_time) " +
            "VALUES (#{id}, #{userId}, #{totalAmount}, #{status}, #{createTime})")
    int insert(Orders order);

    // 关联查询：通过 @Many 调用 OrderItemMapper.selectByOrderId
    @Select("SELECT * FROM orders WHERE user_id = #{userId} ORDER BY create_time DESC")
    @Results({
        @Result(property = "id", column = "id"),
        @Result(property = "userId", column = "user_id"),
        @Result(property = "totalAmount", column = "total_amount"),
        @Result(property = "createTime", column = "create_time"),
        @Result(property = "status", column = "status"),
        // 关键：将 id 列的值作为参数传给 selectByOrderId 查询 items
        @Result(property = "items", column = "id", 
                many = @Many(select = "com.tjetc.dao.OrderItemMapper.selectByOrderId"))
    })
    List<Orders> selectByUserId(Long userId);


    List<Orders> page(@Param("searchId") String searchId,@Param("status") String status);

    Orders selectById(@Param("id") String id);

    int updateById(Orders orders);
}