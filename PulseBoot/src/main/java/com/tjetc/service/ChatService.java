package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.tjetc.domain.ChatMessage;
import com.tjetc.domain.Users;
import com.tjetc.vo.Result;

import java.util.List;

public interface ChatService extends IService<ChatMessage> {
    Result add(ChatMessage chatMessage);
    List<ChatMessage> getHistory(Integer userId, Integer otherId);
    List<Integer> getContactIds(Integer userId);
    List<Users> getContacts(Integer userId);
    int getUnreadCount(Integer userId);
    void markAsRead(Integer userId, Integer otherId);
    List<com.tjetc.vo.ConversationVO> getConversations(Integer userId);
}
