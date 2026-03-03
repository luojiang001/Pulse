package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Notification;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Options;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface NotificationMapper extends BaseMapper<Notification> {

    @Insert("insert into notification(title, content, type, target_user_id, create_time) " +
            "values(#{title}, #{content}, #{type}, #{targetUserId}, #{createTime})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(Notification notification);

    @Select("select * from notification where type = 'ALL' or target_user_id = #{userId} order by create_time desc")
    List<Notification> listByUserId(Integer userId);
}
