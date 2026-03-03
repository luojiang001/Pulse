package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.github.pagehelper.PageInfo;
import com.tjetc.domain.Orders;
import com.tjetc.vo.OrderVo;
import com.tjetc.vo.Result;

public interface OrderService {
    void createOrder(Orders order);

    Object getOrderList(Long userId);

    PageInfo<OrderVo> page(String id, String status, Integer pageNum, Integer pageSize);

    Result getOrderDetails(String id);

    Orders findById(String orderId);

    void update(Orders orders);
}
