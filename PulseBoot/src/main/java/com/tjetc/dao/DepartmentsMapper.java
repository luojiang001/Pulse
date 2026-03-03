package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Departments;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface DepartmentsMapper extends BaseMapper<Departments> {
    int deleteByPrimaryKey(Integer id);

    int insert(Departments record);

    int insertSelective(Departments record);

    Departments selectByPrimaryKey(Integer id);

    int updateByPrimaryKeySelective(Departments record);

    int updateByPrimaryKey(Departments  record);
    @Select("select * from departments order by id")
    List<Departments> departmentList();
}