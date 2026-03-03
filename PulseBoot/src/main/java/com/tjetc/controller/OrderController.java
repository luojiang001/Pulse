package com.tjetc.controller;
import com.github.pagehelper.PageInfo;
import com.tjetc.domain.Medicine;
import com.tjetc.domain.Orders;
import com.tjetc.service.OrderService;
import com.tjetc.vo.OrderVo;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/order")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @PostMapping("/create")
    public Result create(@RequestBody Orders order) {
        try {
            orderService.createOrder(order);
            return Result.success();
        } catch (Exception e) {
            e.printStackTrace();
            return Result.fail("下单失败：" + e.getMessage());
        }
    }

    @GetMapping("/list")
    public Result list(@RequestParam Long userId) {
        return Result.success(orderService.getOrderList(userId));
    }
    @RequestMapping("/page")
    public PageInfo<OrderVo> page(
            @RequestParam(value = "id",defaultValue = "") String id,
            @RequestParam(value = "pageNum",defaultValue = "1") Integer pageNum,
            @RequestParam(value = "pageSize",defaultValue = "2") Integer pageSize,
            @RequestParam(value = "status",defaultValue = "")String status
    ) {
        return orderService.page(id,status, pageNum, pageSize);
    }
    @GetMapping("/detail/{id}")
    public Result detail(@PathVariable String id) {
        return orderService.getOrderDetails(id);
    }
}