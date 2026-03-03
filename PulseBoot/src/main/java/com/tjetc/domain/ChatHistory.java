package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
@RedisHash("chatHistory")
public class ChatHistory implements Serializable {
    private Integer id;
    private Integer userId;
    private String chatId;
    private String question;
    private String context;
    private Date createTime;
    private Integer isDelete;
}
