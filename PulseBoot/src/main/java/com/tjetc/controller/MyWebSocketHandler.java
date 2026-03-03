package com.tjetc.controller;

import com.tjetc.domain.ChatMessage;
import com.tjetc.service.ChatService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.net.URI;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArraySet;

/**
 * 自定义 WebSocket 处理器，处理文本消息（和 ArkTS 客户端对接）
 */
@Slf4j // 日志注解
public class MyWebSocketHandler extends TextWebSocketHandler {
    
    private final ChatService chatService;

    public MyWebSocketHandler(ChatService chatService) {
        this.chatService = chatService;
    }

    // 存储所有活跃的 WebSocket 会话（线程安全，支持多客户端连接）
    private static final CopyOnWriteArraySet<WebSocketSession> SESSIONS = new CopyOnWriteArraySet<>();
    private static final Map<String, WebSocketSession> USER_SESSION_MAP = new HashMap<>();
    /**
     * 客户端连接成功时触发
     */
    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        super.afterConnectionEstablished(session);
        // 将新的会话加入集合
        SESSIONS.add(session);
        /*String clientId = getClientId(session);
        log.info("客户端 {} 连接成功，当前在线数：{}", clientId, SESSIONS.size());*/
        String userId = extractUserIdFromUrl(session);
        if (userId != null && !userId.isEmpty()) {
            // 2. 存储 userId 和 Session 的映射（覆盖重复登录的同用户 Session）
            USER_SESSION_MAP.put(userId, session);
            log.info("用户 {} 连接成功，当前在线用户数：{}", userId, USER_SESSION_MAP.size());
            // 3. 给该用户发送欢迎消息，携带用户标识
//            sendMessageToClient(session, "连接成功！你的用户 ID：" + userId);
        } else {
            log.warn("客户端 {} 连接成功，但未携带 userId", session.getId());
//            sendMessageToClient(session, "连接成功！未检测到用户 ID");
        }
        // 可选：给客户端发送连接成功的欢迎消息
//        sendMessageToClient(session, "连接 Spring Boot WebSocket 服务器成功！");
    }
    /**
     * 从 WebSocket 连接 URL 中提取 userId 查询参数
     */
    private String extractUserIdFromUrl(WebSocketSession session) {
        try {
            // 获取连接的 URI
            URI uri = session.getUri();
            if (uri == null) {
                return null;
            }
            // 获取 URL 中的查询参数（如 ?userId=1001）
            String query = uri.getQuery();
            if (query == null || query.isEmpty()) {
                return null;
            }

            // 解析查询参数，提取 userId
            String[] params = query.split("&");
            for (String param : params) {
                String[] keyValue = param.split("=");
                if (keyValue.length == 2 && "userId".equals(keyValue[0])) {
                    // 解码 URL 中的特殊字符（可选，防止 userId 包含特殊字符）
                    return java.net.URLDecoder.decode(keyValue[1], "UTF-8");
                }
            }
            return null;
        } catch (Exception e) {
            log.error("提取 userId 失败：", e);
            return null;
        }
    }
    /**
     * 接收客户端发送的文本消息（核心：处理 ArkTS 客户端发来的消息）
     */
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        super.handleTextMessage(session, message);
        String clientId = getClientId(session);
        String receivedMessage = message.getPayload(); // 获取客户端发送的消息内容

        // Format: content-receiverId
        // Use lastIndexOf to allow content to contain dashes
        int lastDashIndex = receivedMessage.lastIndexOf("-");
        if (lastDashIndex != -1) {
            String content = receivedMessage.substring(0, lastDashIndex);
            String receiverIdStr = receivedMessage.substring(lastDashIndex + 1);

            String senderIdStr = extractUserIdFromUrl(session);
            if (senderIdStr == null) {
                log.warn("Cannot identify sender for session {}", session.getId());
                return;
            }

            try {
                Integer senderId = Integer.parseInt(senderIdStr);
                Integer receiverId = Integer.parseInt(receiverIdStr);

                // Save to DB
                ChatMessage chatMessage = new ChatMessage();
                chatMessage.setSenderId(senderId);
                chatMessage.setReceiverId(receiverId);
                chatMessage.setContent(content);
                chatMessage.setCreateTime(new Date());
                chatService.add(chatMessage);

                // Forward to receiver if online
                WebSocketSession receiverSession = USER_SESSION_MAP.get(receiverIdStr);
                if (receiverSession != null && receiverSession.isOpen()) {
                    // Format: content-senderId (so receiver knows who sent it)
                    sendMessageToClient(receiverSession, content + "-" + senderId);
                }
            } catch (NumberFormatException e) {
                log.error("Invalid ID format in message: {}", receivedMessage);
            }
        } else {
             log.warn("Invalid message format (missing dash): {}", receivedMessage);
        }
    }

    /**
     * 客户端连接断开时触发
     */
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        super.afterConnectionClosed(session, status);
        // 将断开的会话从集合中移除
        SESSIONS.remove(session);
        String clientId = getClientId(session);
        log.info("客户端 {} 连接断开，当前在线数：{}", clientId, SESSIONS.size());
    }

    /**
     * 处理 WebSocket 传输错误
     */
    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        super.handleTransportError(session, exception);
        if (session.isOpen()) {
            session.close();
        }
        SESSIONS.remove(session);
        log.error("客户端 {} 传输错误：{}", getClientId(session), exception.getMessage());
    }


    /**
     * 给单个客户端发送消息
     */
    private void sendMessageToClient(WebSocketSession session, String message) {
        if (session == null || !session.isOpen()) {
            return;
        }
        try {
            // 发送文本消息（TextMessage 是 Spring WebSocket 封装的文本消息对象）
            session.sendMessage(new TextMessage(message));
        } catch (IOException e) {
            log.error("给客户端 {} 发送消息失败：{}", getClientId(session), e.getMessage());
        }
    }

    /**
     * 广播消息（给所有在线客户端发送消息）
     */
    private void broadcastMessage(String message) {
        for (WebSocketSession session : SESSIONS) {
            sendMessageToClient(session, message);
        }
    }

    /**
     * 获取客户端唯一标识（从会话中提取，简化版）
     */
    private String getClientId(WebSocketSession session) {
        return session.getId();
    }
}