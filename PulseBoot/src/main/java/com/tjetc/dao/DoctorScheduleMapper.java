package com.tjetc.dao;


import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.DoctorScheduleSlot;
import org.apache.ibatis.annotations.*;
import java.time.LocalDate;
import java.util.List;

@Mapper
public interface DoctorScheduleMapper extends BaseMapper<DoctorScheduleSlot> {

    @Select("SELECT id, doctor_id, work_date, time_period, is_available, room_name " +
            "FROM doctor_schedule_slots " +
            "WHERE doctor_id = #{doctorId} " +
            "AND work_date >= #{today} " +
            "ORDER BY work_date ASC, time_period ASC")
    @Results({
            @Result(property = "id", column = "id"),
            @Result(property = "doctorId", column = "doctor_id"),
            @Result(property = "workDate", column = "work_date"),
            @Result(property = "timePeriod", column = "time_period"),
            @Result(property = "isAvailable", column = "is_available"),
            @Result(property = "roomName", column = "room_name")
    })
    List<DoctorScheduleSlot> selectFutureSchedules(
            @Param("doctorId") Integer doctorId,
            @Param("today") LocalDate today
    );

    @Select("SELECT id, doctor_id, work_date, time_period, is_available, room_name " +
            "FROM doctor_schedule_slots " +
            "WHERE doctor_id = #{doctorId} " +
            "AND work_date BETWEEN #{startDate} AND #{endDate} " +
            "ORDER BY work_date ASC, time_period ASC")
    @Results({
            @Result(property = "id", column = "id"),
            @Result(property = "doctorId", column = "doctor_id"),
            @Result(property = "workDate", column = "work_date"),
            @Result(property = "timePeriod", column = "time_period"),
            @Result(property = "isAvailable", column = "is_available"),
            @Result(property = "roomName", column = "room_name")
    })
    List<DoctorScheduleSlot> selectSchedulesByDateRange(
            @Param("doctorId") Integer doctorId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    /**
     * 批量更新排班状态（用于请假）
     */
    @Update("<script>" +
            "UPDATE doctor_schedule_slots SET is_available = #{status} " +
            "WHERE doctor_id = #{doctorId} " +
            "AND work_date = #{workDate} " +
            "AND time_period IN " +
            "<foreach collection='timePeriods' item='period' open='(' separator=',' close=')'>" +
            "#{period}" +
            "</foreach>" +
            "</script>")
    int updateScheduleStatus(
            @Param("doctorId") Integer doctorId,
            @Param("workDate") LocalDate workDate,
            @Param("timePeriods") List<String> timePeriods,
            @Param("status") Integer status
    );


    @Delete("<script>" +
            "DELETE FROM doctor_schedule_slots " +
            "WHERE doctor_id = #{doctorId} " +
            "AND work_date = #{workDate} " +
            "AND time_period IN " +
            "<foreach collection='timePeriods' item='period' open='(' separator=',' close=')'>" +
            "#{period}" +
            "</foreach>" +
            "</script>")
    int deleteSchedules(
            @Param("doctorId") Integer doctorId,
            @Param("workDate") LocalDate workDate,
            @Param("timePeriods") List<String> timePeriods
    );

    /**
     * 插入排班（用于调班/新增）
     * 如果存在则忽略（使用 INSERT IGNORE 或 ON DUPLICATE KEY UPDATE）
     * 这里简单处理：如果想调班，通常是新增记录
     */
    @Insert("<script>" +
            "INSERT INTO doctor_schedule_slots (doctor_id, work_date, time_period, is_available, available_count, room_name) VALUES " +
            "<foreach collection='slots' item='item' separator=','>" +
            "(#{item.doctorId}, #{item.workDate}, #{item.timePeriod}, #{item.isAvailable}, #{item.availableCount}, #{item.roomName})" +
            "</foreach>" +
            "</script>")
    void batchInsertSchedules(@Param("slots") List<DoctorScheduleSlot> slots);

    /**
     * 扣减库存：仅当库存 > 0 时执行减 1
     * 对应表结构：doctor_schedule_slots (doctor_id, work_date, time_period, available_count)
     */
    @Update("UPDATE doctor_schedule_slots " +
            "SET available_count = available_count - 1 " +
            "WHERE doctor_id = #{doctorId} " +
            "AND work_date = #{date} " +
            "AND time_period = #{time} " +
            "AND available_count > 0")
    int decreaseStock(@Param("doctorId") Long doctorId,@Param("date") String date,@Param("time") String time);
}