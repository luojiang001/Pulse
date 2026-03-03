package com.tjetc.config;

import org.springframework.amqp.core.Queue;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {
    // 队列名称
    public static final String QUEUE_APPOINTMENT = "appointment_queue";

    @Bean
    public Queue appointmentQueue() {
        return new Queue(QUEUE_APPOINTMENT, true); // true 表示持久化
    }
}