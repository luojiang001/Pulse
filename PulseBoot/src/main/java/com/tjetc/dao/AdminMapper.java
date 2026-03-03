package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Admin;
import org.apache.ibatis.annotations.Select;

public interface AdminMapper extends BaseMapper<Admin> {
    @Select("select * from admin where username=#{username} ")
    Admin findByUsername(String username);
}
