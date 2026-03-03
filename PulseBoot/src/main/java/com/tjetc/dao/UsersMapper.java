package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Users;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface UsersMapper extends BaseMapper<Users> {
    int deleteByPrimaryKey(Integer id);

    int insert(Users record);

    int insertSelective(Users record);

    Users selectByPrimaryKey(Integer id);

    int updateByPrimaryKeySelective(Users record);

    int updateByPrimaryKey(Users record);

     @Select("select * from users where username=#{username}")
     Users findByUsername(String username);

     @Select("select * from users where id=#{userId} ")
    Users findById(Long userId);
    @Select("select * from users where username like concat('%',#{username},'%') order by id")
    List<Users> list(String username);

    @Select("select * from users where nickname = #{nickname}")
    Users findByNickname(String nickname);

    @Select("select nickname from users where nickname is not null and nickname != ''")
    List<String> findAllNicknames();
}