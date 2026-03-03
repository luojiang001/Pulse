package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.UserBlacklist;
import org.apache.ibatis.annotations.*;
import java.util.Date;

@Mapper
public interface UserBlacklistMapper extends BaseMapper<UserBlacklist> {
    @Insert("INSERT INTO user_blacklist(user_id, blocked_until, reason, create_time) " +
            "VALUES(#{userId}, #{blockedUntil}, #{reason}, #{createTime})")
    int insert(UserBlacklist blacklist);

    @Select("SELECT * FROM user_blacklist WHERE user_id = #{userId} AND blocked_until > #{now} ORDER BY blocked_until DESC LIMIT 1")
    UserBlacklist findActiveBlacklist(@Param("userId") Long userId, @Param("now") Date now);
}
