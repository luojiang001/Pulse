package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Patient;
import org.apache.ibatis.annotations.*;
import java.util.List;

@Mapper
public interface PatientMapper extends BaseMapper<Patient> {

    // 根据用户ID查询就诊人列表
    @Select("SELECT id, user_id, name, id_card, phone, age, gender, is_default, created_at FROM patients WHERE user_id = #{userId} ORDER BY is_default DESC, created_at DESC")
    @Results({
        @Result(property = "userId", column = "user_id"),
        @Result(property = "idCard", column = "id_card"),
        @Result(property = "isDefault", column = "is_default")
    })
    List<Patient> selectByUserId(Integer userId);

    // 添加就诊人
    @Insert("INSERT INTO patients(user_id, name, id_card, phone, age, gender, is_default) " +
            "VALUES(#{userId}, #{name}, #{idCard}, #{phone}, #{age}, #{gender}, #{isDefault})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(Patient patient);

    // 清除该用户下的所有默认状态（用于设置新默认人之前）
    @Update("UPDATE patients SET is_default = 0 WHERE user_id = #{userId}")
    void clearDefault(Integer userId);

    @Select("select * from patients where name=#{name} and age=#{age} and gender=#{gender} ")
    Patient findByMore(@Param("name") String name,@Param("age") Integer age,@Param("gender") String gender);
}