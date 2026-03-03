package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.DoctorScheduleSlot;
import com.tjetc.domain.DoctorUser;
import com.tjetc.domain.Doctors;
import com.tjetc.domain.query.DoctorsQuery;
import com.tjetc.vo.DoctorScheduleInfoVO;
import org.apache.ibatis.annotations.*;

import java.time.LocalDate;
import java.util.List;

public interface DoctorsMapper extends BaseMapper<Doctors> {
    int deleteByPrimaryKey(Integer id);

    Doctors selectByPrimaryKey(Integer id);

    @Select("SELECT * from doctors order by id")
    List<Doctors> findAll(DoctorsMapper doctorsMapper);
    @Select("SELECT * FROM doctors WHERE department=#{department} order by id")
    List<Doctors> findByDepartment(String department);

    @Select("select * from doctors where id=#{id}")
    Doctors findById(Integer id);

    @Select("select * from doctor_user where username=#{username}")
    DoctorUser findByUsername(String username);
    @Select("select * from doctors where id = #{id}")
    Doctors selectById(Integer id);
    @Select("select * from doctors where name like concat('%',#{name},'%') order by id")
    List<Doctors> page(String name);
    @Insert("INSERT INTO doctors (name, title, department, specialty, rating, price, image, isreserve, hospital, experience, consultation_count, education) " +
            "VALUES (#{name}, #{title}, #{department}, #{specialty}, #{rating}, #{price}, #{image}, #{isreserve}, #{hospital}, #{experience}, #{consultationCount}, #{education})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(Doctors doctor);

    @Select("SELECT * FROM doctors WHERE name = #{name}")
    Doctors findByName(String name);

    @Select("select * from doctor_user where doctors_id=#{id} ")
    DoctorUser findByDId(Integer id);

    @Update("update doctor_user set password=#{newPassword} where id=#{id} ")
    int updatePassword(@Param("id") Integer id,@Param("newPassword") String newPassword);

    @Update("UPDATE doctors SET isreserve = 0")
    void resetAllDoctorsReserveStatus();

    @Update("UPDATE doctors SET isreserve = 1 WHERE id IN (" +
            "SELECT DISTINCT doctor_id FROM doctor_schedule_slots " +
            "WHERE is_available = 1 AND available_count > 0 " +
            "AND (work_date > CURDATE() OR (work_date = CURDATE() AND STR_TO_DATE(SUBSTRING_INDEX(time_period, '-', 1), '%H:%i') > CURTIME()))" +
            ")")
    void updateDoctorsReserveStatusBasedOnSchedule();

    // 新增：多表联查医生+预约时段+剩余号源，支持动态条件
    // @Param注解指定参数名，与SQL中#{参数名}占位符一一对应
    // 动态条件通过<if>标签实现，MyBatis原生语法，无拼接冗余，天然防注入
    List<DoctorScheduleInfoVO> selectDoctorWithSchedule(
            @Param("query") DoctorsQuery query,
            @Param("scheduleDate") LocalDate scheduleDate
    );

    @Update("update doctors set name=#{name},title=#{title},department=#{department},specialty=#{specialty},price=#{price},image=#{image},hospital=#{hospital},experience=#{experience},consultation_count=#{consultationCount},education=#{education} where id=#{id}")
    int update(Doctors doctors);

    @Insert("insert into doctors ( name, title, department, specialty, price, image, hospital, experience, consultation_count, education) VALUES (#{name},#{title},#{department},#{specialty},#{price},#{image},#{hospital},#{experience},#{consultationCount},#{education})")
    @Options(useGeneratedKeys = true,keyProperty = "id")
    int add(Doctors doctors);

    @Delete("delete from doctors where id=#{id}")
    int del(Integer id);
}