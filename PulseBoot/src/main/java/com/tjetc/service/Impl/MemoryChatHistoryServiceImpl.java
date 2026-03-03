package com.tjetc.service.Impl;

import com.tjetc.dao.ChatHistoryMapper;
import com.tjetc.domain.ChatHistory;
import com.tjetc.service.ChatHistoryService;
import jakarta.annotation.Resource;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.TimeUnit;

@Component
public class MemoryChatHistoryServiceImpl implements ChatHistoryService {
    // Redis 缓存前缀，用于区分不同业务的缓存键
    private static final String REDIS_KEY_PREFIX = "chat:history:user:";
    // 缓存过期时间（7天，单位：秒）
    private static final long CACHE_EXPIRE_SECONDS = 7 * 24 * 60 * 60;

    @Resource
    private ChatHistoryMapper chatHistoryMapper;

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    // 原无参save方法：调用新增方法，content传空（兼容旧逻辑，实际不会走此路）
    @Override
    public void save(Integer userId, String chatId) {
        this.save(userId, chatId, null, null);
    }

    // 新增核心方法：存储userId+chatId+content，实现MySQL+Redis联动
     @Override
    public void save(Integer userId, String chatId, String prompt, String content) {
        // 1. 写入MySQL数据库：存储完整的userId/chatId/content (无论是否是新会话，都需记录内容)
        ChatHistory chatHistory = new ChatHistory();
        chatHistory.setUserId(userId);
        chatHistory.setChatId(chatId);
        chatHistory.setQuestion(prompt); // 存储用户输入（对应表中prompt字段）
        chatHistory.setContext(content); // 存储聊天内容（对应表中context字段）
        chatHistory.setCreateTime(new Date()); // 入库时间
        chatHistory.setIsDelete(0); // 未删除
        chatHistoryMapper.insert(chatHistory); // 调用Mapper插入数据库

        // 2. 更新Redis缓存：维护用户的会话列表（仅当chatId不存在时添加）
        String redisKey = REDIS_KEY_PREFIX + userId;
        List<String> chatIds = (List<String>) redisTemplate.opsForValue().get(redisKey);
        if (chatIds == null) {
            chatIds = new ArrayList<>();
        }
        
        if (!chatIds.contains(chatId)) {
            chatIds.add(chatId);
            redisTemplate.opsForValue().set(redisKey, chatIds, CACHE_EXPIRE_SECONDS, TimeUnit.SECONDS);
        }
    }


    @Override
    public List<String> query(Integer userId) {
        String redisKey = REDIS_KEY_PREFIX + userId;
        // 1. 先从 Redis 缓存中查询
        List<String> chatIds = (List<String>) redisTemplate.opsForValue().get(redisKey);
        if (chatIds != null) {
            return chatIds;
        }

        // 2. 缓存未命中时，从 MySQL 数据库查询
        List<ChatHistory> historyList = chatHistoryMapper.selectByUserId(userId);
        chatIds = new ArrayList<>();
        for (ChatHistory history : historyList) {
            String chatId = history.getChatId();
            if (!chatIds.contains(chatId)) {
                chatIds.add(chatId);
            }
        }

        // 3. 将查询结果写入 Redis 缓存
        if (!chatIds.isEmpty()) {
            redisTemplate.opsForValue().set(redisKey, chatIds, CACHE_EXPIRE_SECONDS, TimeUnit.SECONDS);
        }
        return chatIds;
    }

    @Override
    public List<ChatHistory> queryByUserIdAndChatId(Integer userId, String chatId) {
        return chatHistoryMapper.selectByMap(new HashMap<String, Object>() {{
            put("userId", userId);
            put("chatId", chatId);
            put("is_delete", 0);
        }});
    }


    /*@Override
    public void save(Integer userId, String chatId) {
         *//*if (!chatHistory.containsKey(userId)) {
            chatHistory.put(userId,new ArrayList<>());
        }
        List<String> chatIds = chatHistory.get(userId);*//*
        List<String> chatIds=chatHistory.computeIfAbsent(userId, k -> new ArrayList<>());
        if (chatIds.contains(chatId)) {
            return;
        }
        chatIds.add(chatId);
    }

    @Override
    public List<String> query(Integer userId) {
       *//*List<String> chatIds=chatHistory.get(userId);
        return chatIds ==null ? new ArrayList<>() : chatIds;*//*
        return chatHistory.getOrDefault(userId, List.of());
    }*/
}
