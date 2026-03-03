package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.ConsultationRoom;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Options;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ConsultationRoomMapper extends BaseMapper<ConsultationRoom> {
    @Select("SELECT * FROM consultation_room")
    List<ConsultationRoom> findAll();

    @Select("SELECT * FROM consultation_room WHERE doctor_id = #{doctorId}")
    List<ConsultationRoom> findByDoctorId(Integer doctorId);

    @Select("SELECT * FROM consultation_room WHERE id = #{id}")
    ConsultationRoom findById(Integer id);

    @Insert("INSERT INTO consultation_room (doctor_id, floor_id, room_no, duty_status) VALUES (#{doctorId}, #{floorId}, #{roomNo}, #{dutyStatus})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(ConsultationRoom room);
}
