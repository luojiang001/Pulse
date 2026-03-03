package com.tjetc.controller;

import com.tjetc.config.RabbitConfig;
import com.tjetc.vo.AppointmentParams;
import com.tjetc.vo.Result;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/appointment")
@CrossOrigin // 允许跨域
public class AppointmentController {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @PostMapping("/book")
    public Result book(@RequestBody AppointmentParams params) {
        // 1. 简单校验
        if (params.getUserId() == null || params.getDoctorId() == null || params.getPatientId() == null) {
            return new Result().setCode(400).setMsg("参数错误：ID不能为空");
        }

        // 2. 发送到 RabbitMQ 异步处理
        // 这样可以应对高并发，不会让用户一直转圈等待数据库操作
        try {
            rabbitTemplate.convertAndSend(RabbitConfig.QUEUE_APPOINTMENT, params);
        } catch (Exception e) {
            e.printStackTrace();
            return new Result().setCode(500).setMsg("服务器繁忙，请稍后重试");
        }

        // 3. 立即返回前端
        return new Result().setCode(200).setMsg("预约申请已提交，系统正在处理");
    }
}