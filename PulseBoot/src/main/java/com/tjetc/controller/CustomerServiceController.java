package com.tjetc.controller;

import com.tjetc.config.SystemConstant;
import com.tjetc.domain.ChatHistory;
import com.tjetc.service.ChatHistoryService;
import com.tjetc.vo.MessageVO;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.messages.Message;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.concurrent.atomic.AtomicReference;


@RequiredArgsConstructor
@RestController
@RequestMapping("/ai")
public class CustomerServiceController {
    private final ChatClient serviceChatClient;
    private final ChatHistoryService chatHistoryService;
    private final ChatMemory chatMemory;

    @RequestMapping(value = "/service", produces = "text/html;charset=utf-8")
    public Flux<String> chat(String prompt, String chatId, Integer userId) {
        AtomicReference<StringBuilder> contentBuilder = new AtomicReference<>(new StringBuilder());

        return serviceChatClient.prompt()
                .system(SystemConstant.getServiceSystemPrompt())
                .user(prompt)
                .advisors(a -> a.param(ChatMemory.CONVERSATION_ID, chatId))
                .stream()
                .content()
                .doOnNext(s -> contentBuilder.get().append(s))
                .doOnComplete(() -> {
                    String fullContent = contentBuilder.get().toString();
                    chatHistoryService.save(userId, chatId,prompt, fullContent);
                })
                // 兜底：若流为空，返回空字符串
                .switchIfEmpty(Flux.just(""));
    }

    @RequestMapping("/history/{userId}")
    public List<String> getChatId(@PathVariable("userId")  Integer userId){
        return chatHistoryService.query(userId);
    }
    @RequestMapping("/history/{userId}/{chatId}")
    public List<MessageVO> getChatHistory(@PathVariable("userId") Integer userId,@PathVariable("chatId") String chatId){
        // 优先从 MySQL 数据库中获取完整历史记录（包含时间戳）
        List<ChatHistory> historyList = chatHistoryService.queryByUserIdAndChatId(userId, chatId);
        if (historyList != null && !historyList.isEmpty()) {
            List<MessageVO> restoredMessages = new java.util.ArrayList<>();
            for (ChatHistory h : historyList) {
                // Log createTime to debug
                System.out.println("DEBUG: Chat " + chatId + " history createTime: " + h.getCreateTime());

                // User message
                MessageVO userMsg = new MessageVO();
                userMsg.setRole("user");
                userMsg.setContent(h.getQuestion());
                if (h.getCreateTime() != null) {
                    userMsg.setCreateTime(h.getCreateTime().getTime());
                } else {
                    userMsg.setCreateTime(System.currentTimeMillis());
                }
                restoredMessages.add(userMsg);
                
                // Assistant message
                if (h.getContext() != null && !h.getContext().isEmpty()) {
                    MessageVO assistantMsg = new MessageVO();
                    assistantMsg.setRole("assistant");
                    assistantMsg.setContent(h.getContext());
                    if (h.getCreateTime() != null) {
                        assistantMsg.setCreateTime(h.getCreateTime().getTime() + 1000);
                    } else {
                        assistantMsg.setCreateTime(System.currentTimeMillis() + 1000);
                    }
                    restoredMessages.add(assistantMsg);
                }
            }
            return restoredMessages;
        }

        // 降级方案：如果数据库没数据（可能是刚开始的内存会话），尝试从 memory 获取
        List<Message> messages = chatMemory.get(chatId);
        if (messages == null) {
            return List.of();
        }
        return messages.stream().map(MessageVO::new).toList();
    }
}