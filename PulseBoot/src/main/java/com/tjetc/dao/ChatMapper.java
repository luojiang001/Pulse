package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.ChatMessage;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.List;

@Mapper
public interface ChatMapper extends BaseMapper<ChatMessage> {
    
    @Select("SELECT * FROM chat_message WHERE (sender_id = #{userId} AND receiver_id = #{otherId}) OR (sender_id = #{otherId} AND receiver_id = #{userId}) ORDER BY create_time ASC")
    List<ChatMessage> findHistory(@Param("userId") Integer userId, @Param("otherId") Integer otherId);

    @Select("SELECT DISTINCT sender_id FROM chat_message WHERE receiver_id = #{userId} " +
            "UNION " +
            "SELECT DISTINCT receiver_id FROM chat_message WHERE sender_id = #{userId}")
    List<Integer> findContactIds(@Param("userId") Integer userId);

    @Select("SELECT DISTINCT u.id, u.username, u.nickname, u.avatar FROM users u " +
            "INNER JOIN chat_message cm ON (u.id = cm.sender_id AND cm.receiver_id = #{userId}) " +
            "OR (u.id = cm.receiver_id AND cm.sender_id = #{userId})")
    List<com.tjetc.domain.Users> findContacts(@Param("userId") Integer userId);

    @Select("SELECT COUNT(*) FROM chat_message WHERE receiver_id = #{userId} AND is_read = 0")
    int countUnread(@Param("userId") Integer userId);

    @Update("UPDATE chat_message SET is_read = 1 WHERE sender_id = #{senderId} AND receiver_id = #{receiverId} AND is_read = 0")
    void markAsRead(@Param("senderId") Integer senderId, @Param("receiverId") Integer receiverId);

    @Select("SELECT " +
            "t.id as userId, t.username, t.nickname, t.avatar, " +
            "(SELECT content FROM chat_message cm WHERE (cm.sender_id = t.id AND cm.receiver_id = #{userId}) OR (cm.sender_id = #{userId} AND cm.receiver_id = t.id) ORDER BY create_time DESC LIMIT 1) as lastMessage, " +
            "(SELECT DATE_FORMAT(create_time, '%Y-%m-%d %H:%i:%s') FROM chat_message cm WHERE (cm.sender_id = t.id AND cm.receiver_id = #{userId}) OR (cm.sender_id = #{userId} AND cm.receiver_id = t.id) ORDER BY create_time DESC LIMIT 1) as lastTime, " +
            "(SELECT COUNT(*) FROM chat_message cm WHERE cm.sender_id = t.id AND cm.receiver_id = #{userId} AND is_read = 0) as unreadCount " +
            "FROM (" +
            "SELECT id, username, nickname, avatar FROM users " +
            "UNION " +
            "SELECT id, name as username, name as nickname, image as avatar FROM doctors" +
            ") t " +
            "WHERE t.id IN (SELECT DISTINCT sender_id FROM chat_message WHERE receiver_id = #{userId} UNION SELECT DISTINCT receiver_id FROM chat_message WHERE sender_id = #{userId}) " +
            "ORDER BY lastTime DESC")
    List<com.tjetc.vo.ConversationVO> findConversations(@Param("userId") Integer userId);
}
