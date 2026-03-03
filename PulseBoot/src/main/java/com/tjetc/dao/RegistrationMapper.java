package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.RegistrationRecord;
import com.tjetc.vo.PrescriptionVO;
import com.tjetc.vo.Registration;
import com.tjetc.vo.RegistrationRecordVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Date;
import java.util.List;

@Mapper
public interface RegistrationMapper extends BaseMapper<RegistrationRecord> {

    int insert(RegistrationRecord record);

    Registration selectRegistrationWithDoctor(Long id);

    List<Registration> list(@Param("name") String name, @Param("doctorId") Integer doctorId);

    RegistrationRecord selectByRegNo(String regNo);

    int updateDoctorForSchedule(@Param("fromDoctorId") Integer fromDoctorId,
                                @Param("toDoctorId") Integer toDoctorId,
                                @Param("date") String date,
                                @Param("periods") List<String> periods);

    int countMissedAppointments(@Param("userId") Long userId, @Param("startDate") Date startDate);

    List<Registration> findAll();

    List<Registration> findByDoctorId(Integer doctorId);

    List<Registration> findByDoctorIdAndDate(@Param("doctorId") Integer doctorId, @Param("date") String date);

    int updateVisitStatus(@Param("regNo") String regNo, @Param("visitStatus") Integer visitStatus);

    int update(Registration registration);

    List<RegistrationRecordVO> getRecordList(@Param("userId") Long userId);

    int del(String regNo);

    PrescriptionVO findByRegNo(String regNo);

    Registration selectVOByRegNo(String regNo);
}
