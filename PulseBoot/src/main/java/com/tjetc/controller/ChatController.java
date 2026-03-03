package com.tjetc.controller;

import com.tjetc.domain.ChatMessage;
import com.tjetc.domain.Users;
import com.tjetc.service.ChatService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/chat")
public class ChatController {
    @Autowired
    private ChatService chatService;

    @GetMapping("/history")
    public Result history(@RequestParam Integer userId, @RequestParam Integer otherId) {
        List<ChatMessage> history = chatService.getHistory(userId, otherId);
        return Result.success(history);
    }

    @GetMapping("/contacts")
    public Result contacts(@RequestParam Integer userId) {
        List<Users> contacts = chatService.getContacts(userId);
        return Result.success(contacts);
    }

    @GetMapping("/unread")
    public Result unread(@RequestParam Integer userId) {
        int count = chatService.getUnreadCount(userId);
        return Result.success(count);
    }

    @PostMapping("/read")
    public Result markRead(@RequestParam Integer userId, @RequestParam Integer otherId) {
        chatService.markAsRead(userId, otherId);
        return Result.success();
    }

    @GetMapping("/conversations")
    public Result conversations(@RequestParam Integer userId) {
        return Result.success(chatService.getConversations(userId));
    }
}
