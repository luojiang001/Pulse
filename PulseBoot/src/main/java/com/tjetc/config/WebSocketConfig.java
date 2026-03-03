package com.tjetc.config;

import com.tjetc.controller.MyWebSocketHandler;
import com.tjetc.service.ChatService;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.standard.ServerEndpointExporter;

/**
 * WebSocket 配置类，开启 WebSocket 支持并注册处理器
 */
@Configuration
@EnableWebSocket // 开启 Spring WebSocket 支持
public class WebSocketConfig implements WebSocketConfigurer {

    private final ChatService chatService;

    public WebSocketConfig(ChatService chatService) {
        this.chatService = chatService;
    }

    /**
     * 注册 WebSocket 处理器（指定访问路径、允许跨域）
     */
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry
                // 注册自定义的 WebSocket 处理器
                .addHandler(myWebSocketHandler(), "/ws/echo")
                // 允许跨域（解决 ArkTS 客户端跨域连接问题，开发环境必备）
                .setAllowedOrigins("*");
    }

    /**
     * 注入自定义的 WebSocket 处理器
     */
    @Bean
    public WebSocketHandler myWebSocketHandler() {
        return new MyWebSocketHandler(chatService);
    }

    /**
     * 用于扫描和注册 @ServerEndpoint 注解的端点（如果使用注解方式，需添加此 Bean）
     * 我们这里使用 Handler 方式，此 Bean 可选，添加后不影响功能
     */
    @Bean
    @Profile({"!test"})
    @ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }
}
