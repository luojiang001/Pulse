package com.tjetc.vo;

import lombok.Data;

@Data
public class ConversationVO {
    private Integer userId;
    private String username;
    private String nickname;
    private String avatar;
    private String lastMessage;
    private String lastTime;
    private Integer unreadCount;
}
