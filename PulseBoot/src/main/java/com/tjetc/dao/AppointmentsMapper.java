package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Appointments;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AppointmentsMapper extends BaseMapper<Appointments> {
    int deleteByPrimaryKey(Long id);

    int insert(Appointments record);

    int insertSelective(Appointments record);

    Appointments selectByPrimaryKey(Long id);

    int updateByPrimaryKeySelective(Appointments record);

    int updateByPrimaryKey(Appointments record);
}