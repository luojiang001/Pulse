package com.tjetc.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
@TableName("chat_message")
public class ChatMessage implements Serializable {
    @TableId(type = IdType.AUTO)
    private Integer id;
    
    @TableField("sender_id")
    private Integer senderId;
    
    @TableField("receiver_id")
    private Integer receiverId;
    
    private String content;
    
    @TableField("create_time")
    private Date createTime;

    @TableField("is_read")
    private Integer isRead; // 0: unread, 1: read
}
