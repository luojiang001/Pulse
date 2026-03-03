package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.tjetc.dao.ChatMapper;
import com.tjetc.domain.ChatMessage;
import com.tjetc.domain.Users;
import com.tjetc.service.ChatService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ChatServiceImpl extends ServiceImpl<ChatMapper, ChatMessage> implements ChatService {
    @Autowired
    private ChatMapper chatMapper;

    @Override
    public Result add(ChatMessage chatMessage) {
        int rows = chatMapper.insert(chatMessage);
        if (rows > 0) {
            return Result.success(chatMessage);
        }
        return Result.fail("Failed to add message");
    }

    @Override
    public List<ChatMessage> getHistory(Integer userId, Integer otherId) {
        return chatMapper.findHistory(userId, otherId);
    }

    @Override
    public List<Integer> getContactIds(Integer userId) {
        return chatMapper.findContactIds(userId);
    }

    @Override
    public List<Users> getContacts(Integer userId) {
        return chatMapper.findContacts(userId);
    }

    @Override
    public int getUnreadCount(Integer userId) {
        return chatMapper.countUnread(userId);
    }

    @Override
    public void markAsRead(Integer userId, Integer otherId) {
        // userId is the receiver (me), otherId is the sender
        chatMapper.markAsRead(otherId, userId);
    }

    @Override
    public List<com.tjetc.vo.ConversationVO> getConversations(Integer userId) {
        return chatMapper.findConversations(userId);
    }
}
