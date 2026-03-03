package com.tjetc.service;

import com.tjetc.domain.ChatHistory;

import java.util.List;

public interface ChatHistoryService {
    /**
     *  保存用户会话记录
     * @param userId
     * @param chatId
     */
    void save(Integer userId,String chatId);

    /**
     * 获取用户的会话Id列表
     * @param userId
     * @return  会话Id列表
     */
    List<String> query(Integer userId);

    // 新增重载方法：带聊天内容content，用于实际存储
    void save(Integer userId, String chatId, String prompt, String content);

    List<ChatHistory> queryByUserIdAndChatId(Integer userId, String chatId);

}
