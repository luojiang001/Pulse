package com.tjetc.vo;

import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.MessageType;

@Data
@NoArgsConstructor
public class MessageVO {
    private String role;
    private String content;
    private Long createTime;
    public MessageVO(Message message) {
        MessageType messageType = message.getMessageType();
        switch (messageType) {
            case USER:
                role="user";
                break;
            case ASSISTANT:
                role="assistant";
                break;
            default:
                role="";
                break;
        }
        this.role = role;
        this.content = message.getText();
        this.createTime = System.currentTimeMillis();
    }
}
