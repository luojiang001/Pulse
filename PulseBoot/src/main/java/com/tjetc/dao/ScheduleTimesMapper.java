package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.ScheduleTimes;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ScheduleTimesMapper extends BaseMapper<ScheduleTimes> {
    int deleteByPrimaryKey(Long id);

    int insert(ScheduleTimes record);

    int insertSelective(ScheduleTimes record);

    ScheduleTimes selectByPrimaryKey(Long id);

    int updateByPrimaryKeySelective(ScheduleTimes record);

    int updateByPrimaryKey(ScheduleTimes record);
}