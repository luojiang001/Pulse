package com.tjetc.dao;

import com.tjetc.domain.ChatHistory;
import org.apache.ibatis.annotations.*;

import java.util.HashMap;
import java.util.List;

@Mapper
public interface ChatHistoryMapper {
    @Insert("insert into chat_history (user_id, chat_id, question, context, create_time) VALUES (#{userId},#{chatId},#{question},#{context},#{createTime})")
    int insert(ChatHistory chatHistory);

    @Select("select * from chat_history where user_id=#{userId} and is_delete = 0")
    @Results(id = "chatHistoryMap", value = {
        @Result(property = "id", column = "id", id = true),
        @Result(property = "userId", column = "user_id"),
        @Result(property = "chatId", column = "chat_id"),
        @Result(property = "createTime", column = "create_time"),
        @Result(property = "isDelete", column = "is_delete")
    })
    List<ChatHistory> selectByUserId(Integer userId);

    @Select("select * from chat_history where user_id=#{userId} and chat_id=#{chatId} and is_delete = 0")
    @ResultMap("chatHistoryMap")
    List<ChatHistory> selectByMap(HashMap<String, Object> hashMap);
}
